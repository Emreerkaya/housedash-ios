import Foundation
import XCTest

final class HDGroundOwnershipTests: XCTestCase {
    private static let filesAllowedToPaintTheGround: Set<String> = [
        "HDScreen.swift",
        "HDActionBar.swift",
        "HDAppChrome.swift",
        "CameraCaptureScreen.swift"
    ]

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

    func testTheGroundIsPaintedOnlyWhereTheChromeOwnsIt() throws {
        let files = Self.sourceFiles()
        XCTAssertFalse(files.isEmpty, "the scan read no Swift sources, so its silence measures nothing")

        var painters: [String] = []
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let paintsWholeSurface = text.split(separator: "\n").contains {
                $0.contains("background(Color.hdGround") && !$0.contains(", in:")
            }
            guard paintsWholeSurface else { continue }
            painters.append(file.lastPathComponent)
        }

        XCTAssertEqual(
            Set(painters).subtracting(Self.filesAllowedToPaintTheGround).sorted(), [],
            "\(Set(painters).subtracting(Self.filesAllowedToPaintTheGround).sorted()) paint the ground themselves; a screen that paints its own ground stops one edge short of the safe area and leaves a white band behind the status bar, which is what hdAppChrome and hdFlowScreen exist to prevent"
        )
        XCTAssertEqual(
            Self.filesAllowedToPaintTheGround.subtracting(painters).sorted(), [],
            "\(Self.filesAllowedToPaintTheGround.subtracting(painters).sorted()) are excused from this rule and no longer paint the ground, so the excuse outlived the thing it excused"
        )
    }
}
