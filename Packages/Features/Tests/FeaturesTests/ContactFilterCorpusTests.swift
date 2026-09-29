import XCTest
import CryptoKit
@testable import Features

final class ContactFilterCorpusTests: XCTestCase {
    private static let resource = "i7-corpus"
    private static let sourceRepository = "housedash-core-service"
    private static let sourcePath = "src/test/resources/com/housedash/domain/shared/i7-corpus.tsv"
    private static let sourceCommit = "09e3f81c4d28d0b2a60ffd0f39a6db8ea6962972"
    private static let sourceDigest =
        "b58f45556e5ce0b7bd6a7be4832b71666474565eaa2ac07041b1b7d1e09a527b"
    private static let rowsTheCorpusHolds = 171
    private static let rowsTheGuardAccepts = 103
    private static let rowsTheGuardRejects = 68
    private static let charactersTheAggregateNeeds = 20
    private static let rowsTheAggregateWouldAlsoStore = 67
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
            "the vendored copy of \(Self.sourcePath) no longer hashes to what \(Self.sourceRepository)@\(Self.sourceCommit) holds, so it is a second truth rather than a copy; this digest detects a change to the copy and never movement of the original, which lives on a branch of another repository this suite cannot read"
        )
        XCTAssertEqual(
            rows.count, Self.rowsTheCorpusHolds,
            "the corpus holds \(rows.count) rows, so rows have been added or dropped since \(Self.sourceCommit)"
        )
        XCTAssertEqual(
            rows.filter { $0.behaviour == Self.accept }.count, Self.rowsTheGuardAccepts,
            "the corpus no longer holds \(Self.rowsTheGuardAccepts) rows the server's contact-detail guard accepts, so the denominator of the subset invariant moved"
        )
        XCTAssertEqual(
            rows.filter { $0.behaviour == Self.reject }.count, Self.rowsTheGuardRejects,
            "the corpus no longer holds \(Self.rowsTheGuardRejects) rows that guard rejects"
        )
    }

    func testTheAcceptCountSaysWhichLayerItWasMeasuredAt() throws {
        let (rows, _) = try corpus()
        let accepted = rows.filter { $0.behaviour == Self.accept }
        let throughTheAggregate = accepted.filter { row in
            row.input.precomposedStringWithCanonicalMapping
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .unicodeScalars.count >= Self.charactersTheAggregateNeeds
        }
        XCTAssertEqual(
            throughTheAggregate.count, Self.rowsTheAggregateWouldAlsoStore,
            "\(accepted.count) rows are accepted by the guard and \(throughTheAggregate.count) of them also clear the aggregate's \(Self.charactersTheAggregateNeeds)-character minimum, so the number the subset invariant is measured over is neither of the two unless it says which"
        )
        XCTAssertLessThan(
            throughTheAggregate.count, accepted.count,
            "every accepted row now clears the aggregate's minimum, so the two layers agree and this test no longer distinguishes them"
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
            "the client filter is stricter than the server on \(disagreements.count) of the \(Self.rowsTheGuardAccepts) rows the server's contact-detail guard accepts, of which \(Self.rowsTheAggregateWouldAlsoStore) also clear the aggregate's \(Self.charactersTheAggregateNeeds)-character minimum; the aggregate additionally applies a plain-text rule this repository does not mirror: \(disagreements.joined(separator: " | "))"
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
