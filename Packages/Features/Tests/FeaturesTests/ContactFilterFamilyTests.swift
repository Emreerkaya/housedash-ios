import XCTest
@testable import Features

final class ContactFilterFamilyTests: XCTestCase {
    private static let separators = ["-", ".", " "]
    private static let groupLengths = 1...4
    private static let mostGroupsSwept = 4
    private static let carrier = "the plate reads "
    private static let trailer = " next to the valve"

    private static func isDialableUnderTheServersRule(_ groups: [Int]) -> Bool {
        guard groups.count >= 3, groups.count <= 6 else { return false }
        guard groups.allSatisfy({ $0 <= 6 }) else { return false }
        guard groups.reduce(0, +) == 10 else { return false }
        guard groups.last == 4 else { return false }
        return (3...4).contains(groups[groups.count - 2])
    }

    private static func run(_ groups: [Int], _ separators: [String]) -> String {
        var digits = "0123456789012345678901234567890123456789"
        var text = ""
        for (index, length) in groups.enumerated() {
            if index > 0 { text += separators[index - 1] }
            text += String(digits.prefix(length))
            digits.removeFirst(length)
        }
        return text
    }

    private static func shapes() -> [(groups: [Int], separators: [String])] {
        var all: [(groups: [Int], separators: [String])] = []
        for count in 1...mostGroupsSwept {
            var groupTuples: [[Int]] = [[]]
            for _ in 0..<count {
                groupTuples = groupTuples.flatMap { tuple in groupLengths.map { tuple + [$0] } }
            }
            var separatorTuples: [[String]] = [[]]
            for _ in 0..<max(0, count - 1) {
                separatorTuples = separatorTuples.flatMap { tuple in separators.map { tuple + [$0] } }
            }
            for groups in groupTuples {
                for separatorTuple in separatorTuples {
                    all.append((groups, separatorTuple))
                }
            }
        }
        return all
    }

    func testTheSweepIsWideEnoughToHoldTheShapeThatWasMissed() {
        let all = Self.shapes()
        XCTAssertEqual(all.count, 7540, "the sweep covers \(all.count) shapes, not the family it claims to")
        XCTAssertTrue(
            all.contains { $0.groups == [3, 3, 4, 2] && $0.separators == ["-", "-", "-"] },
            "the sweep does not contain [3,3,4,2], the shape the previous fix was not checked against"
        )
        XCTAssertTrue(
            all.contains { $0.groups == [4, 3, 4, 2] && $0.separators == ["-", "-", "-"] },
            "the sweep does not contain [4,3,4,2], the one shape in its class that cannot exhibit the bug"
        )
    }

    func testTheClientRefusesOnlyRunsTheServersShapeRuleCallsDialable() {
        var stricter: [String] = []
        for shape in Self.shapes() {
            let digits = Self.run(shape.groups, shape.separators)
            let text = Self.carrier + digits + Self.trailer
            let refused = !DescriptionFilter.signals(in: text).contains(.phoneNumber)
                ? false
                : true
            let dialable = Self.isDialableUnderTheServersRule(shape.groups)
            if refused && !dialable {
                stricter.append("\(shape.groups) over \(shape.separators): \(digits)")
            }
        }
        XCTAssertEqual(
            stricter.count, 0,
            "the client refuses \(stricter.count) runs the server's shape rule accepts, starting with \(stricter.prefix(8).joined(separator: " | "))"
        )
    }

    func testTheClientStillRefusesTheRunsTheServersShapeRuleCallsDialable() {
        var missed: [String] = []
        for shape in Self.shapes() where Self.isDialableUnderTheServersRule(shape.groups) {
            let digits = Self.run(shape.groups, shape.separators)
            let text = Self.carrier + digits + Self.trailer
            if !DescriptionFilter.signals(in: text).contains(.phoneNumber) {
                missed.append("\(shape.groups) over \(shape.separators): \(digits)")
            }
        }
        XCTAssertEqual(
            missed.count, 0,
            "the client lets \(missed.count) dialable runs through, starting with \(missed.prefix(8).joined(separator: " | "))"
        )
    }

    func testALeadingOrTrailingDigitGroupTakesARunOutOfTheDialableCount() {
        let dialable = "917-555-0199"
        XCTAssertTrue(
            DescriptionFilter.signals(in: "call me on \(dialable)").contains(.phoneNumber),
            "the bare dialable run is not refused, so every case below is vacuous"
        )
        for longer in [
            "the plate reads 1234 \(dialable) next to the valve",
            "the unit is stamped 12 \(dialable) on the plate",
            "the part number is 141-445-2266-01 on the label",
            "the part number is 0141-445-2266-01 on the label",
            "\(dialable)-01 is the part",
            "0141-\(dialable) is the part"
        ] {
            XCTAssertFalse(
                DescriptionFilter.signals(in: longer).contains(.phoneNumber),
                "'\(longer)' is refused, and the server accepts it, because the digit run around the dialable window is not being counted"
            )
        }
    }

    func testTheLastDomainLabelHasToBeLettersAllTheWayDown() {
        for accepted in [
            "bob@example.com2",
            "bob@example.co.uk1",
            "bob@mail.example.c0m",
            "bob@example.c0m is a typo",
            "bob@example..com",
            "bob@example"
        ] {
            XCTAssertFalse(
                DescriptionFilter.signals(in: accepted).contains(.emailAddress),
                "'\(accepted)' is refused, and the server accepts it, because its last domain label is not all letters"
            )
        }
        for refused in [
            "bob@example.com",
            "bob@mail.example.com",
            "bob@example.co.uk",
            "bob@example.comx"
        ] {
            XCTAssertTrue(
                DescriptionFilter.signals(in: refused).contains(.emailAddress),
                "'\(refused)' is let through, so the email arm no longer catches an ordinary address"
            )
        }
    }

    func testEveryDomainLabelCountAndTailIsSweptRatherThanSampled() {
        var stricter: [String] = []
        let tails = ["com", "uk", "com2", "c0m", "1", "co1", "verylongtoplevellabelthatkeepsgoing"]
        for labels in 1...3 {
            for tail in tails {
                let domain = Array(repeating: "example", count: labels).joined(separator: ".") + "." + tail
                let text = "write to bob@\(domain) about it"
                let refused = DescriptionFilter.signals(in: text).contains(.emailAddress)
                let lastIsAllLetters = tail.allSatisfy(\.isLetter) && (2...24).contains(tail.count)
                if refused != lastIsAllLetters {
                    stricter.append("\(domain) refused=\(refused) lastIsAllLetters=\(lastIsAllLetters)")
                }
            }
        }
        XCTAssertEqual(
            stricter, [],
            "the email arm and the server's last-label rule disagree on \(stricter.count) domains: \(stricter.joined(separator: " | "))"
        )
    }
}
