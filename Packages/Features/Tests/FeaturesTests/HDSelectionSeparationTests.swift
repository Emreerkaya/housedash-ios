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
    private static let traitTheScanTreatsAsASelectionState = ".isSelected"
    private static let filesTheScanExpectsAtLeast = 1
    private static let leastShareOfDifferingPixelsAMarkMustSeparate = 0.05
    private static let pairsWhoseSecondStateIsInactive: Set<String> = ["HDActionBar"]

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
            StatePair(
                component: "HDChip",
                width: 140,
                selected: onTheGround(HDChip("Kitchen", state: .selected) {}, width: 140),
                unselected: onTheGround(HDChip("Kitchen", state: .unselected) {}, width: 140)
            ),
            StatePair(
                component: "IntakePickRow",
                width: 318,
                selected: onTheGround(IntakePickRow(symptom: symptom("$90–140"), isSelected: true) {}, width: 318),
                unselected: onTheGround(IntakePickRow(symptom: symptom("$90–140"), isSelected: false) {}, width: 318)
            ),
            StatePair(
                component: "HDRoleIsland",
                width: 200,
                selected: onTheGround(HDRoleIsland(selected: .nester) { _ in }, width: 200),
                unselected: onTheGround(HDRoleIsland(selected: .tasker) { _ in }, width: 200)
            ),
            StatePair(
                component: "HDTabBarNester",
                width: 402,
                selected: onTheGround(HDTabBarNester(active: .fix) { _ in }, width: 402),
                unselected: onTheGround(HDTabBarNester(active: .jobs) { _ in }, width: 402)
            ),
            StatePair(
                component: "HDTabBarTasker",
                width: 402,
                selected: onTheGround(HDTabBarTasker(active: .requests) { _ in }, width: 402),
                unselected: onTheGround(HDTabBarTasker(active: .calendar) { _ in }, width: 402)
            ),
            StatePair(
                component: "HDBubble",
                width: 280,
                selected: onTheGround(HDBubble("On my way, about ten minutes", side: .outgoing), width: 280),
                unselected: onTheGround(HDBubble("On my way, about ten minutes", side: .incoming), width: 280)
            ),
            StatePair(
                component: "HDActionBar",
                width: 402,
                selected: onTheGround(HDActionBar(ctaTitle: "Next", isCTAEnabled: true) {}, width: 402),
                unselected: onTheGround(
                    HDActionBar(ctaTitle: "Next", isCTAEnabled: false, disabledExplanation: "pick one first") {},
                    width: 402
                )
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
        var measured = 0
        for pair in Self.statePairs() {
            for scheme in [ColorScheme.light, .dark] {
                let found = try separation(of: pair, in: scheme)
                measured += 1
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
        XCTAssertEqual(
            measured, Self.statePairs().count * 2,
            "the sweep measured \(measured) of the \(Self.statePairs().count * 2) component-and-band combinations it lists, so it is silent about the rest"
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) of \(measured) component-and-band combinations draw a state their neighbour is not separated from; the statistic that carries the verdict is separatedShare, the share of differing pixels reaching \(Self.wcagNonTextContrast):1, with a floor of \(String(format: "%.0f", Self.leastShareOfDifferingPixelsAMarkMustSeparate * 100))%, and best is only a second leg that catches a state drawn nowhere; \(Self.pairsWhoseSecondStateIsInactive.sorted()) are exempt from the floor because their second state is an inactive control, which 1.4.11 does not require to be separated: \(failures.joined(separator: " · "))"
        )
    }

    func testTheSweepReportsTheNumbersItsVerdictRestsOn() throws {
        var lines: [String] = []
        for pair in Self.statePairs() {
            for scheme in [ColorScheme.light, .dark] {
                let found = try separation(of: pair, in: scheme)
                lines.append(
                    "\(pair.component)/\(scheme): differing \(String(format: "%.2f", found.differingShare * 100))%, of those \(String(format: "%.1f", found.separatedShare * 100))% reach \(Self.wcagNonTextContrast):1, best \(String(format: "%.2f", found.best)):1"
                )
                XCTAssertGreaterThan(
                    found.read, 0,
                    "\(pair.component) in \(scheme) has no readable pixel at all, so every ratio above it is vacuous"
                )
            }
        }
        XCTAssertEqual(
            lines.count, Self.statePairs().count * 2,
            "the measurement table is \(lines.count) rows over \(Self.statePairs().count) components in two bands: \(lines.joined(separator: " · "))"
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

    func testEveryComponentThatDrawsASelectionStateIsInTheSweep() throws {
        let files = Self.sourceFiles()
        XCTAssertGreaterThan(
            files.count, Self.filesTheScanExpectsAtLeast,
            "the scan found \(files.count) source files under \(Self.packagesDirectory().path), so it read nothing and cannot say the sweep is complete"
        )
        let swept = Set(Self.statePairs().map(\.component))
        var declared: Set<String> = []
        var uncovered: [String] = []
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let types = Set(
                text.components(separatedBy: "struct ")
                    .dropFirst()
                    .compactMap { $0.prefix(while: { $0.isLetter || $0.isNumber || $0 == "_" }) }
                    .map(String.init)
                    .filter { !$0.isEmpty }
            )
            declared.formUnion(types)
            guard text.contains("accessibilityAddTraits"), text.contains(Self.traitTheScanTreatsAsASelectionState) else { continue }
            if types.isDisjoint(with: swept) {
                uncovered.append("\(file.lastPathComponent) declares \(types.sorted()) and none of them is swept")
            }
        }
        XCTAssertEqual(
            uncovered, [],
            "\(uncovered.count) source files add the \(Self.traitTheScanTreatsAsASelectionState) trait and no type they declare is in the sweep, so a component has a selection state nothing measures: \(uncovered.joined(separator: " · "))"
        )
        XCTAssertEqual(
            swept.subtracting(declared), [],
            "the sweep names \(swept.subtracting(declared).sorted()), which no source file under \(Self.packagesDirectory().lastPathComponent) declares, so the sweep is measuring a name rather than a component"
        )
    }
}
#endif
