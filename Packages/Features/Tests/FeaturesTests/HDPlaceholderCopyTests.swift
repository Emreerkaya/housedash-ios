import Foundation
import XCTest

final class HDPlaceholderCopyTests: XCTestCase {
    private static let forbidden = "Placeholder|Lorem|TODO|Coming soon|assembles here"

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

    func testNoShippedSourceReadsAsAnUnfinishedScreen() throws {
        let files = Self.sourceFiles()
        XCTAssertFalse(files.isEmpty, "the scan read no Swift sources, so its silence measures nothing")

        let expression = try XCTUnwrap(try? NSRegularExpression(pattern: Self.forbidden))

        var offenders: [String] = []
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let matches = expression.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                offenders.append("\(file.lastPathComponent): \"\(text[range])\"")
            }
        }

        XCTAssertEqual(
            offenders, [],
            "\(offenders.count) shipped source file(s) still read as unfinished, which is a shipped defect rather than an open work item: \(offenders.joined(separator: " · "))"
        )
    }
}
