import Foundation
import XCTest

final class FeatureLayerBoundaryTests: XCTestCase {
    private static let importsEachLayerMayName: [String: Set<String>] = [
        "Domain": ["Foundation"],
        "Flow": ["DesignSystem", "Foundation", "Observation", "SwiftUI"],
        "Screens": ["DesignSystem", "SwiftUI"],
        "Support": ["AVFoundation", "DesignSystem", "Foundation", "PhotosUI", "SwiftUI", "UIKit"]
    ]
    private static let swiftFilesUnderEachLayer: [String: Int] = [
        "Domain": 7,
        "Flow": 13,
        "Screens": 12,
        "Support": 9
    ]
    private static let featureDirectoriesTheScanMustCover: Set<String> = [
        "Auth",
        "Fix",
        "Intake",
        "Jobs",
        "Photo",
        "Profile",
        "Tabs",
        "Toolbox"
    ]
    private static let filesTheDomainLayerHolds: Set<String> = [
        "Auth/Domain/HDRole.swift",
        "Auth/Domain/IdentityService.swift",
        "Intake/Domain/CapturedPhoto.swift",
        "Intake/Domain/DescriptionFilter.swift",
        "Intake/Domain/HDRoom.swift",
        "Intake/Domain/PhotoCapture.swift",
        "Intake/Domain/ProblemCatalogue.swift"
    ]
    private static let importStatementsTheScanMustRead = 68
    private static let packagesTheWorkspaceHolds: Set<String> = ["DesignSystem", "Features", "Networking"]
    private static let packagesFeaturesMayDependOn: Set<String> = ["DesignSystem"]
    private static let layerOfAFileSittingDirectlyUnderItsFeature = "Flow"
    private static let importStatement = "^[ \\t]*(?:@testable[ \\t]+)?import[ \\t]+([A-Za-z_][A-Za-z0-9_]*)"
    private static let packageByRelativePath = "\\.package\\(path:[ \\t]*\"\\.\\./([A-Za-z_][A-Za-z0-9_]*)\"\\)"
    private static let featuresTargetDependencies =
        "name:[ \\t]*\"Features\",[\\s]*dependencies:[ \\t]*\\[([^\\]]*)\\]"
    private static let quotedName = "\"([A-Za-z_][A-Za-z0-9_]*)\""

    private struct ScannedFile {
        let relativePath: String
        let feature: String
        let layer: String
        let imports: [String]
    }

    private static func featuresPackageDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func packagesDirectory() -> URL {
        featuresPackageDirectory().deletingLastPathComponent()
    }

    private static func sourcesDirectory() -> URL {
        featuresPackageDirectory()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Features")
    }

    private static func captures(of pattern: String, in text: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return []
        }
        return expression
            .matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .compactMap { match in
                guard let found = Range(match.range(at: 1), in: text) else { return nil }
                return String(text[found])
            }
    }

    private static func scan() -> [ScannedFile] {
        let root = sourcesDirectory().standardizedFileURL
        let depth = root.pathComponents.count
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        return walker
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .compactMap { file -> ScannedFile? in
                let components = Array(file.standardizedFileURL.pathComponents.dropFirst(depth))
                guard components.count >= 2, let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
                return ScannedFile(
                    relativePath: components.joined(separator: "/"),
                    feature: components[0],
                    layer: components.count > 2 ? components[1] : layerOfAFileSittingDirectlyUnderItsFeature,
                    imports: captures(of: importStatement, in: text)
                )
            }
            .sorted { $0.relativePath < $1.relativePath }
    }

    func testEveryLayerInsideFeaturesImportsOnlyWhatItsAllowlistNames() {
        let files = Self.scan()
        XCTAssertEqual(
            Set(files.map(\.layer)), Set(Self.importsEachLayerMayName.keys),
            "the scan found the layers \(Set(files.map(\.layer)).sorted()) under \(Self.sourcesDirectory().lastPathComponent) and the allowlist speaks for \(Self.importsEachLayerMayName.keys.sorted()); a directory nobody wrote an allowance for is an unpoliced layer, so a new one is an entry someone adds here on purpose rather than a silent exemption"
        )

        var trespasses: [String] = []
        for file in files {
            guard let allowed = Self.importsEachLayerMayName[file.layer] else { continue }
            for module in Set(file.imports).subtracting(allowed).sorted() {
                trespasses.append(
                    "\(file.relativePath) sits in the \(file.layer) layer and imports \(module); \(file.layer) may import only \(allowed.sorted().joined(separator: ", "))"
                )
            }
        }
        XCTAssertEqual(
            trespasses, [],
            "\(trespasses.count) file(s) inside Features reach past the layer they sit in: \(trespasses.joined(separator: " · ")); the list above is an allowlist rather than a ban list, so the fix is either to move the code to a layer that may name the module or to add the module to that layer's allowance in front of a reviewer"
        )

        var allowancesNoFileUses: [String] = []
        for (layer, allowed) in Self.importsEachLayerMayName {
            let observed = Set(files.filter { $0.layer == layer }.flatMap(\.imports))
            for module in allowed.subtracting(observed).sorted() {
                allowancesNoFileUses.append("\(layer) is allowed to import \(module) and no file in \(layer) does")
            }
        }
        XCTAssertEqual(
            allowancesNoFileUses.sorted(), [],
            "\(allowancesNoFileUses.count) allowance(s) outlived the code that needed them: \(allowancesNoFileUses.sorted().joined(separator: " · ")); an allowlist that is wider than the tree stops being a statement anyone can read, and this leg is also what fails when the import scan reads nothing at all, so a silent allowlist and a satisfied one stay distinguishable"
        )
    }

    func testTheImportScanReadsTheWholeFeaturesTreeAndNoOtherOne() {
        let files = Self.scan()
        var tally: [String: Int] = [:]
        for file in files { tally[file.layer, default: 0] += 1 }
        XCTAssertEqual(
            tally, Self.swiftFilesUnderEachLayer,
            "the scan walked \(Self.sourcesDirectory().path) and counted \(tally.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }) rather than \(Self.swiftFilesUnderEachLayer.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }); these are pinned counts rather than a floor, because a floor of one would be satisfied by a scan that found a single file out of forty"
        )
        XCTAssertEqual(
            Set(files.map(\.feature)), Self.featureDirectoriesTheScanMustCover,
            "the scan covered the features \(Set(files.map(\.feature)).sorted()) rather than \(Self.featureDirectoriesTheScanMustCover.sorted()); this leg names the directories rather than counting them, so a tree with the right number of features in the wrong place still reddens"
        )
        XCTAssertEqual(
            Set(files.filter { $0.layer == "Domain" }.map(\.relativePath)), Self.filesTheDomainLayerHolds,
            "the Domain layer holds \(Set(files.filter { $0.layer == "Domain" }.map(\.relativePath)).sorted()) rather than \(Self.filesTheDomainLayerHolds.sorted()); Domain is the layer whose allowance is narrowest, so its extent is pinned by name and a domain file that slips into another directory is visible here"
        )
        XCTAssertEqual(
            files.reduce(0) { $0 + $1.imports.count }, Self.importStatementsTheScanMustRead,
            "the scan read \(files.reduce(0) { $0 + $1.imports.count }) import statements across \(files.count) files rather than \(Self.importStatementsTheScanMustRead); the allowlist above is vacuous for any file whose imports this regular expression cannot see, so the number of lines it reads is pinned separately from the number of files it opens"
        )
        let neighbours = Set(
            (try? FileManager.default.contentsOfDirectory(atPath: Self.packagesDirectory().path))?
                .filter { !$0.hasPrefix(".") } ?? []
        )
        XCTAssertEqual(
            neighbours, Self.packagesTheWorkspaceHolds,
            "the directory above the package under scan is \(Self.packagesDirectory().path) and holds \(neighbours.sorted()) rather than \(Self.packagesTheWorkspaceHolds.sorted()); this leg pins which package the scan is standing in, because counts taken inside the wrong package can be right by coincidence"
        )
    }

    func testFeaturesDeclaresOnlyThePackagesItsAllowlistNames() throws {
        let manifest = Self.featuresPackageDirectory().appendingPathComponent("Package.swift")
        let text = try String(contentsOf: manifest, encoding: .utf8)
        XCTAssertEqual(
            Set(Self.captures(of: Self.packageByRelativePath, in: text)), Self.packagesFeaturesMayDependOn,
            "\(manifest.path) declares the packages \(Set(Self.captures(of: Self.packageByRelativePath, in: text)).sorted()) rather than \(Self.packagesFeaturesMayDependOn.sorted()); a package declared here and imported nowhere is a door left open for the first caller to walk through unwatched, so adding one is an edit to this pin as well"
        )
        let targetDependencies = Set(
            Self.captures(of: Self.featuresTargetDependencies, in: text)
                .flatMap { Self.captures(of: Self.quotedName, in: $0) }
        )
        XCTAssertEqual(
            targetDependencies, Self.packagesFeaturesMayDependOn,
            "the Features target depends on \(targetDependencies.sorted()) rather than \(Self.packagesFeaturesMayDependOn.sorted()); the package-level and target-level lists are read separately because a module reaches a source file only through the second one"
        )
        let modulesAnyLayerMayImport = Set(Self.importsEachLayerMayName.values.flatMap { $0 })
        XCTAssertEqual(
            Self.packagesFeaturesMayDependOn.subtracting(modulesAnyLayerMayImport), [],
            "\(Self.packagesFeaturesMayDependOn.subtracting(modulesAnyLayerMayImport).sorted()) are linked into Features and no layer's allowlist names them, so the graph permits a module that no layer is allowed to import"
        )
    }
}
