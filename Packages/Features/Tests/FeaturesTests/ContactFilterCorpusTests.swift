import XCTest
import CryptoKit
@testable import Features

final class ContactFilterCorpusTests: XCTestCase {
    private static let resource = "i7-corpus"
    private static let sourceRepository = "housedash-core-service"
    private static let sourcePath = "src/test/resources/com/housedash/domain/shared/i7-corpus.tsv"
    private static let sourceCommit = "9eaec8c850f4129c655f84e34aef6594d5785b6b"
    private static let sourceDigest =
        "e0805b0a107a5a6f5147de1792685a7cc5cf2f1ccc15444d9b610c45eaf9c2a1"
    private static let rowsTheCorpusHolds = 140
    private static let rowsTheServerAccepts = 84
    private static let rowsTheServerRejects = 56
    private static let header = ["want", "behaviour", "kinds", "input", "note"]
    private static let accept = "ACCEPT"
    private static let reject = "REJECT"

    private struct Row {
        let line: Int
        let behaviour: String
        let input: String
        let note: String
    }

    private func corpus() throws -> (rows: [Row], digest: String) {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: Self.resource, withExtension: "tsv"),
            "\(Self.resource).tsv is not in the test bundle, so this test measured nothing"
        )
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(
            lines.first?.components(separatedBy: "\t"), Self.header,
            "the corpus header changed shape, so the columns this test reads are not the columns it means"
        )
        let rows = lines.dropFirst().enumerated().map { index, line -> Row in
            let columns = line.components(separatedBy: "\t")
            return Row(
                line: index + 2,
                behaviour: columns[1],
                input: columns[3].replacingOccurrences(of: "\\n", with: "\n"),
                note: columns.count > 4 ? columns[4] : ""
            )
        }
        return (rows, digest)
    }

    func testTheVendoredCorpusIsTheFileTheServerMeasuredAgainst() throws {
        let (rows, digest) = try corpus()
        XCTAssertEqual(
            digest, Self.sourceDigest,
            "the vendored copy of \(Self.sourcePath) no longer hashes to what \(Self.sourceRepository)@\(Self.sourceCommit) holds, so it is a second truth rather than a copy"
        )
        XCTAssertEqual(
            rows.count, Self.rowsTheCorpusHolds,
            "the corpus holds \(rows.count) rows, so rows have been added or dropped since \(Self.sourceCommit)"
        )
        XCTAssertEqual(
            rows.filter { $0.behaviour == Self.accept }.count, Self.rowsTheServerAccepts,
            "the corpus no longer holds \(Self.rowsTheServerAccepts) rows the server accepts, so the denominator of the subset invariant moved"
        )
        XCTAssertEqual(
            rows.filter { $0.behaviour == Self.reject }.count, Self.rowsTheServerRejects,
            "the corpus no longer holds \(Self.rowsTheServerRejects) rows the server rejects"
        )
    }

    func testTheClientRefusesNothingTheServerAccepts() throws {
        let (rows, _) = try corpus()
        var disagreements: [String] = []
        for row in rows where row.behaviour == Self.accept {
            let signals = DescriptionFilter.signals(in: row.input)
            if !signals.isEmpty {
                disagreements.append(
                    "line \(row.line): the server accepts \(row.input.debugDescription) and the client reports \(signals.map(\.rawValue)) — \(row.note)"
                )
            }
        }
        XCTAssertEqual(
            disagreements, [],
            "the client filter is stricter than the server on \(disagreements.count) of \(Self.rowsTheServerAccepts) accepted rows: \(disagreements.joined(separator: " | "))"
        )
    }

    func testTheCorpusReachesEveryArmTheClientHas() throws {
        let (rows, _) = try corpus()
        var reached: Set<ContactSignalKind> = []
        for row in rows {
            reached.formUnion(DescriptionFilter.signals(in: row.input))
        }
        XCTAssertEqual(
            reached, Set(ContactSignalKind.allCases),
            "the corpus never drives the client into \(Set(ContactSignalKind.allCases).subtracting(reached).map(\.rawValue)), so those arms are unmeasured by it"
        )
    }
}
