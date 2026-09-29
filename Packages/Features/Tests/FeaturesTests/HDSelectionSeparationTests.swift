import Foundation
import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignSystem
@testable import Features

#if canImport(UIKit)
@MainActor
final class HDSelectionSeparationTests: XCTestCase {
    private static let wcagNonTextContrast: Double = 3
    private static let renderScale: CGFloat = 2
    private static let alphaAPixelMustCarryToBeRead: UInt8 = 200
    private static let leastShareOfDifferingPixelsAMarkMustSeparate = 0.05
    private static let pairsWhoseSecondStateIsInactive: Set<String> = ["HDActionBar"]
    private static let marksNoPairOfRenderingsCanIsolate: Set<String> = ["HDTimeSlider"]
    private static let bandsTheSweepMustCover: [ColorScheme] = [.light, .dark]
    private static let componentsTheSweepMustCover: Set<String> = [
        "HDActionBar",
        "HDBubble",
        "HDChip",
        "HDRoleIsland",
        "HDTabBarNester",
        "HDTabBarTasker",
        "IntakePickRow"
    ]
    private static let swiftFilesUnderEachPackagesSources = [
        "DesignSystem": 33,
        "Features": 39,
        "Networking": 3
    ]
    private static let typeDeclaration = "\\b(?:struct|class|enum|actor)\\s+([A-Za-z_][A-Za-z0-9_]*)"
    private static let conformanceDeclaration =
        "\\b(?:struct|class|enum|actor|extension)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(?:<[^>]*>)?\\s*:([^{]*)\\{"

    private static var nameOfTheMarkTheFamilyIsKeyedOn: String {
        String(describing: HDDrawsAStateMark.self)
    }

    private static func extent() -> Set<String> {
        Set(componentsTheSweepMustCover.flatMap { component in
            bandsTheSweepMustCover.map { "\(component)/\($0)" }
        })
    }

    private struct StatePair {
        let component: String
        let width: CGFloat
        let selected: AnyView
        let unselected: AnyView
    }

    private struct Separation {
        let differing: Int
        let read: Int
        let separated: Int
        let best: Double

        var differingShare: Double { read == 0 ? 0 : Double(differing) / Double(read) }
        var separatedShare: Double { differing == 0 ? 0 : Double(separated) / Double(differing) }
    }

    private static func onTheGround<V: View>(_ view: V, width: CGFloat) -> AnyView {
        AnyView(
            view
                .frame(width: width)
                .padding(8)
                .background(Color.hdGround)
        )
    }

    private static func pair<Component: View & HDDrawsAStateMark>(
        width: CGFloat,
        selected: Component,
        unselected: Component
    ) -> StatePair {
        StatePair(
            component: String(describing: Component.self),
            width: width,
            selected: onTheGround(selected, width: width),
            unselected: onTheGround(unselected, width: width)
        )
    }

    private static func symptom(_ price: String?) -> SymptomOption {
        SymptomOption(
            id: "drips-constantly",
            primary: "Drips constantly",
            secondary: "Worse when the hot tap is on",
            priceRange: price
        )
    }

    private static func statePairs() -> [StatePair] {
        [
            pair(
                width: 140,
                selected: HDChip("Kitchen", state: .selected) {},
                unselected: HDChip("Kitchen", state: .unselected) {}
            ),
            pair(
                width: 318,
                selected: IntakePickRow(symptom: symptom("$90–140"), isSelected: true) {},
                unselected: IntakePickRow(symptom: symptom("$90–140"), isSelected: false) {}
            ),
            pair(
                width: 200,
                selected: HDRoleIsland(selected: .nester) { _ in },
                unselected: HDRoleIsland(selected: .tasker) { _ in }
            ),
            pair(
                width: 402,
                selected: HDTabBarNester(active: .fix) { _ in },
                unselected: HDTabBarNester(active: .jobs) { _ in }
            ),
            pair(
                width: 402,
                selected: HDTabBarTasker(active: .requests) { _ in },
                unselected: HDTabBarTasker(active: .calendar) { _ in }
            ),
            pair(
                width: 280,
                selected: HDBubble("On my way, about ten minutes", side: .outgoing),
                unselected: HDBubble("On my way, about ten minutes", side: .incoming)
            ),
            pair(
                width: 402,
                selected: HDActionBar(ctaTitle: "Next", isCTAEnabled: true) {},
                unselected: HDActionBar(ctaTitle: "Next", isCTAEnabled: false, disabledExplanation: "pick one first") {}
            )
        ]
    }

    private struct Raster {
        let width: Int
        let height: Int
        let pixels: [UInt8]
    }

    private func raster(_ view: AnyView, height: CGFloat, in scheme: ColorScheme) throws -> Raster {
        let renderer = ImageRenderer(
            content: view
                .frame(height: height, alignment: .top)
                .environment(\.colorScheme, scheme)
        )
        renderer.scale = Self.renderScale
        let image = try XCTUnwrap(
            renderer.uiImage?.cgImage,
            "the view rendered to nothing in \(scheme), so this test measured nothing"
        )
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Raster(width: image.width, height: image.height, pixels: pixels)
    }

    private func luminance(_ pixels: [UInt8], at index: Int) -> Double {
        func linearise(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearise(Double(pixels[index]) / 255)
            + 0.7152 * linearise(Double(pixels[index + 1]) / 255)
            + 0.0722 * linearise(Double(pixels[index + 2]) / 255)
    }

    private func height(of pair: StatePair) -> CGFloat {
        [pair.selected, pair.unselected]
            .map { UIHostingController(rootView: $0).sizeThatFits(in: CGSize(width: pair.width + 16, height: .infinity)).height }
            .reduce(0, max)
    }

    private func separation(of pair: StatePair, in scheme: ColorScheme) throws -> Separation {
        let tall = height(of: pair)
        let selected = try raster(pair.selected, height: tall, in: scheme)
        let unselected = try raster(pair.unselected, height: tall, in: scheme)
        XCTAssertEqual(
            [selected.width, selected.height], [unselected.width, unselected.height],
            "\(pair.component) renders its two states at different pixel sizes, so no pixel can be compared with its own position"
        )
        XCTAssertGreaterThan(
            selected.width * selected.height, 0,
            "\(pair.component) rendered at zero size in \(scheme)"
        )
        var differing = 0
        var read = 0
        var separated = 0
        var best = 1.0
        for index in stride(from: 0, to: min(selected.pixels.count, unselected.pixels.count), by: 4) {
            guard
                selected.pixels[index + 3] > Self.alphaAPixelMustCarryToBeRead,
                unselected.pixels[index + 3] > Self.alphaAPixelMustCarryToBeRead
            else { continue }
            read += 1
            guard
                selected.pixels[index] != unselected.pixels[index]
                    || selected.pixels[index + 1] != unselected.pixels[index + 1]
                    || selected.pixels[index + 2] != unselected.pixels[index + 2]
            else { continue }
            differing += 1
            let first = luminance(selected.pixels, at: index)
            let second = luminance(unselected.pixels, at: index)
            let ratio = (max(first, second) + 0.05) / (min(first, second) + 0.05)
            if ratio >= Self.wcagNonTextContrast { separated += 1 }
            best = max(best, ratio)
        }
        return Separation(differing: differing, read: read, separated: separated, best: best)
    }

    func testEverySelectionStateIsSeparatedFromItsNeighbourOnRenderedPixelsInBothBands() throws {
        var failures: [String] = []
        var measured: Set<String> = []
        for pair in Self.statePairs() {
            for scheme in Self.bandsTheSweepMustCover {
                let found = try separation(of: pair, in: scheme)
                measured.insert("\(pair.component)/\(scheme)")
                if found.differing == 0 {
                    failures.append(
                        "\(pair.component) in \(scheme) renders its two states identically over all \(found.read) readable pixels, so the state is drawn nowhere"
                    )
                    continue
                }
                if found.best < Self.wcagNonTextContrast {
                    failures.append(
                        "\(pair.component) in \(scheme): \(String(format: "%.2f", found.differingShare * 100))% of readable pixels differ and the best differing pair is only \(String(format: "%.2f", found.best)):1, under \(Self.wcagNonTextContrast):1"
                    )
                    continue
                }
                guard !Self.pairsWhoseSecondStateIsInactive.contains(pair.component) else { continue }
                if found.separatedShare < Self.leastShareOfDifferingPixelsAMarkMustSeparate {
                    failures.append(
                        "\(pair.component) in \(scheme): only \(String(format: "%.2f", found.separatedShare * 100))% of its differing pixels reach \(Self.wcagNonTextContrast):1, under the floor, so the difference a person sees is not the difference that carries the state"
                    )
                }
            }
        }
        let extent = Self.extent()
        XCTAssertEqual(
            measured, extent,
            "the sweep is silent about \(extent.subtracting(measured).sorted()) and measured \(measured.subtracting(extent).sorted()), which the extent does not name; the extent is the pinned list of components crossed with the two bands rather than a count the pair list produces, so removing a pair names the component it removed"
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) of \(measured.count) component-and-band combinations draw a state their neighbour is not separated from; the statistic that carries the verdict is separatedShare, the share of differing pixels reaching \(Self.wcagNonTextContrast):1, with a floor of \(String(format: "%.0f", Self.leastShareOfDifferingPixelsAMarkMustSeparate * 100))%, and best is only a second leg that catches a state drawn nowhere; \(Self.pairsWhoseSecondStateIsInactive.sorted()) are exempt from the floor because their second state is an inactive control, which 1.4.11 does not require to be separated: \(failures.joined(separator: " · "))"
        )
    }

    func testTheSweepReportsTheNumbersItsVerdictRestsOn() throws {
        var lines: [String: String] = [:]
        for pair in Self.statePairs() {
            for scheme in Self.bandsTheSweepMustCover {
                let found = try separation(of: pair, in: scheme)
                lines["\(pair.component)/\(scheme)"] =
                    "differing \(String(format: "%.2f", found.differingShare * 100))%, of those \(String(format: "%.1f", found.separatedShare * 100))% reach \(Self.wcagNonTextContrast):1, best \(String(format: "%.2f", found.best)):1"
                XCTAssertGreaterThan(
                    found.read, 0,
                    "\(pair.component) in \(scheme) has no readable pixel at all, so every ratio above it is vacuous"
                )
            }
        }
        let extent = Self.extent()
        XCTAssertEqual(
            Set(lines.keys), extent,
            "the measurement table is missing \(extent.subtracting(lines.keys).sorted()) and carries \(Set(lines.keys).subtracting(extent).sorted()) the extent does not name: \(lines.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: " · "))"
        )
    }

    private static func packagesDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func sourceFiles() -> [URL] {
        let root = packagesDirectory()
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        return walker.compactMap { $0 as? URL }.filter {
            $0.pathExtension == "swift" && $0.path.contains("/Sources/")
        }
    }

    private static func packageHolding(_ file: URL, under root: URL) -> String {
        let depth = root.standardizedFileURL.pathComponents.count
        let components = file.standardizedFileURL.pathComponents
        guard components.count > depth else { return file.lastPathComponent }
        return components[depth]
    }

    private static func captures(of pattern: String, in text: String, groups: Int) -> [[String]] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return expression
            .matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .map { match in
                (1...groups).map { group in
                    guard let found = Range(match.range(at: group), in: text) else { return "" }
                    return String(text[found])
                }
            }
    }

    private static func typesDeclaringTheMark(in text: String) -> Set<String> {
        Set(
            captures(of: conformanceDeclaration, in: text, groups: 2)
                .filter { capture in
                    capture[1]
                        .components(separatedBy: CharacterSet(charactersIn: ",&"))
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .contains(nameOfTheMarkTheFamilyIsKeyedOn)
                }
                .map { $0[0] }
        )
    }

    func testEveryTypeDeclaringTheMarkIsInTheSweepAndTheScanReadsTheWholeTree() throws {
        let root = Self.packagesDirectory()
        let files = Self.sourceFiles()
        var tally: [String: Int] = [:]
        for file in files { tally[Self.packageHolding(file, under: root), default: 0] += 1 }
        XCTAssertEqual(
            tally, Self.swiftFilesUnderEachPackagesSources,
            "the scan walked \(root.path) and found \(tally.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }) rather than \(Self.swiftFilesUnderEachPackagesSources.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }), so it is reading a different tree from the one this sweep claims to cover; these are pinned counts rather than a floor, so a tree that grows is an edit someone makes here on purpose"
        )

        var declared: Set<String> = []
        var family: Set<String> = []
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            declared.formUnion(Self.captures(of: Self.typeDeclaration, in: text, groups: 1).map { $0[0] })
            family.formUnion(Self.typesDeclaringTheMark(in: text))
        }
        XCTAssertFalse(
            family.isEmpty,
            "no type under \(root.lastPathComponent) declares \(Self.nameOfTheMarkTheFamilyIsKeyedOn), so either the mark was renamed out from under this scan or the scan read nothing"
        )

        let swept = Set(Self.statePairs().map(\.component))
        XCTAssertEqual(
            family.subtracting(swept).subtracting(Self.marksNoPairOfRenderingsCanIsolate).sorted(), [],
            "\(family.subtracting(swept).subtracting(Self.marksNoPairOfRenderingsCanIsolate).sorted()) declare \(Self.nameOfTheMarkTheFamilyIsKeyedOn) and no pair of renderings measures them, so a drawn state reaches a person that nothing reads; the key here is the declaring type rather than the file it sits in or the modifier it announces with, so a second marked type in an already-swept file is a second row of work"
        )
        XCTAssertEqual(
            swept.subtracting(family).sorted(), [],
            "the sweep renders \(swept.subtracting(family).sorted()), which this scan does not see declaring \(Self.nameOfTheMarkTheFamilyIsKeyedOn) although the compiler required it of every pair, so the scan's reading of a declaration disagrees with the compiler's and its silence elsewhere means nothing"
        )
        XCTAssertEqual(
            Self.componentsTheSweepMustCover.subtracting(declared).sorted(), [],
            "the extent names \(Self.componentsTheSweepMustCover.subtracting(declared).sorted()), which no type under \(root.lastPathComponent) declares, so the extent is pinning a spelling rather than a component"
        )
        XCTAssertEqual(
            Self.marksNoPairOfRenderingsCanIsolate.subtracting(family).sorted(), [],
            "\(Self.marksNoPairOfRenderingsCanIsolate.subtracting(family).sorted()) are excused from the sweep and no longer declare \(Self.nameOfTheMarkTheFamilyIsKeyedOn), so the excuse outlived the thing it excused"
        )
    }
}
#endif
