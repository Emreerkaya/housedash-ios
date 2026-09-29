import XCTest
import CryptoKit
@testable import Features

final class ContactFilterCorpusTests: XCTestCase {
    private static let resource = "i7-corpus"
    private static let sourceRepository = "housedash-core-service"
    private static let sourcePath = "src/test/resources/com/housedash/domain/shared/i7-corpus.tsv"
    private static let sourceCommit = "92aa2d7ac70acf7d9bba2c28ecc9124c910c282b"
    private static let sourceDigest =
        "807b326d6e2f2d4a56eb216373666140b3ae8acdbc43e08e3ed4914a3a20b285"
    private static let rowsTheCorpusHolds = 203
    private static let rowsTheGuardAccepts = 110
    private static let rowsTheGuardRejects = 93
    private static let rowsBothColumnsAccept = 59
    private static let rowsTheGuardAcceptsAndTheRuleRefuses = 42
    private static let charactersTheAggregateNeeds = 20
    private static let rowsTheAggregateWouldAlsoStore = 74
    private static let sharedGapsTheClientAlreadyCloses = 0
    private static let question = "QUESTION"
    private static let acceptedRowsTheRuleHasNotDecided = 9
    private static let header = ["want", "behaviour", "kinds", "input", "note"]
    private static let accept = "ACCEPT"
    private static let reject = "REJECT"

    private struct Row {
        let line: Int
        let want: String
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
                want: columns[0],
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
            "the corpus no longer holds \(Self.rowsTheGuardAccepts) rows the server's contact-detail guard accepts"
        )
        XCTAssertEqual(
            rows.filter { $0.behaviour == Self.reject }.count, Self.rowsTheGuardRejects,
            "the corpus no longer holds \(Self.rowsTheGuardRejects) rows that guard rejects"
        )
    }

    func testTheTwoColumnsAreNotTheSameQuestionAndTheSubsetReadsTheOneAboutIntent() throws {
        let (rows, _) = try corpus()
        let bothAccept = rows.filter { $0.want == Self.accept && $0.behaviour == Self.accept }
        let sharedGaps = rows.filter { $0.want == Self.reject && $0.behaviour == Self.accept }
        XCTAssertEqual(
            bothAccept.count, Self.rowsBothColumnsAccept,
            "the rows both columns accept are the only denominator an assertion about what the client should do may use, and there are now \(bothAccept.count) of them"
        )
        XCTAssertEqual(
            sharedGaps.count, Self.rowsTheGuardAcceptsAndTheRuleRefuses,
            "\(sharedGaps.count) rows record a guard that accepts text the rule says to refuse; a subset assertion whose denominator is behaviour carries every one of them as an accept, so a client that started catching one would fail"
        )
        let undecided = rows.filter { $0.want == Self.question && $0.behaviour == Self.accept }
        XCTAssertEqual(
            undecided.count, Self.acceptedRowsTheRuleHasNotDecided,
            "\(undecided.count) accepted rows carry a want of \(Self.question), which is neither an intent to accept nor one to refuse, so they belong in no assertion about what the client should do"
        )
        XCTAssertEqual(
            bothAccept.count + sharedGaps.count + undecided.count, Self.rowsTheGuardAccepts,
            "the want column no longer partitions the accepted rows into meant-to-accept, meant-to-refuse and undecided, so one of the counts above is measuring something else"
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

    func testTheClientRefusesNothingBothColumnsAccept() throws {
        let (rows, _) = try corpus()
        var disagreements: [String] = []
        for row in rows where row.want == Self.accept && row.behaviour == Self.accept {
            let signals = DescriptionFilter.signals(in: row.input)
            if !signals.isEmpty {
                disagreements.append(
                    "line \(row.line): both columns accept \(row.input.debugDescription) and the client reports \(signals.map(\.rawValue)) — \(row.note)"
                )
            }
        }
        XCTAssertEqual(
            disagreements, [],
            "the client filter is stricter than the server on \(disagreements.count) of the \(Self.rowsBothColumnsAccept) rows the server's guard accepts and the rule means it to accept; the \(Self.rowsTheGuardAcceptsAndTheRuleRefuses) rows the guard accepts against its own intent are not in this denominator, because a client that closed one of those would otherwise fail: \(disagreements.joined(separator: " | "))"
        )
    }

    func testClosingASharedGapIsAnImprovementRatherThanAFailure() throws {
        let (rows, _) = try corpus()
        var closed: [String] = []
        for row in rows where row.want == Self.reject && row.behaviour == Self.accept {
            if !DescriptionFilter.signals(in: row.input).isEmpty {
                closed.append("line \(row.line): \(row.input.debugDescription)")
            }
        }
        XCTAssertGreaterThanOrEqual(
            closed.count, Self.sharedGapsTheClientAlreadyCloses,
            "the client used to catch \(Self.sharedGapsTheClientAlreadyCloses) of the \(Self.rowsTheGuardAcceptsAndTheRuleRefuses) rows the server accepts against its own intent and now catches \(closed.count), so a gap this repository had already closed has reopened: \(closed.joined(separator: " | "))"
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
