import XCTest
@testable import Features

final class ContactFilterFamilyTests: XCTestCase {
    private static let separators = ["-", ".", " ", ",", ";"]
    private static let marksTheThousandsArmOwns: Set<Character> = [",", ";", ":"]
    private static let mostDigitsBeforeAThousandsSeparator = 3
    private static let digitsInAThousandsGroup = 3
    private static let groupLengths = 1...4
    private static let mostGroupsSwept = 4
    private static let carrier = "the plate reads "
    private static let trailer = " next to the valve"

    private static func isGroupedByTheThousandsMarks(_ separators: [String]) -> Bool {
        guard !separators.isEmpty else { return false }
        return separators.allSatisfy { separator in
            guard let mark = separator.first, marksTheThousandsArmOwns.contains(mark) else { return false }
            let trailing = separator.dropFirst()
            return trailing.count <= 2 && trailing.allSatisfy { $0 == " " }
        }
    }

    private static func isGroupedLikeThousands(_ groups: [Int]) -> Bool {
        guard let leading = groups.first else { return false }
        return leading <= mostDigitsBeforeAThousandsSeparator
            && groups.dropFirst().allSatisfy { $0 == digitsInAThousandsGroup }
    }

    private static func isDialableUnderTheServersRule(_ groups: [Int], _ separators: [String]) -> Bool {
        if isGroupedByTheThousandsMarks(separators), isGroupedLikeThousands(groups) { return false }
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
        XCTAssertEqual(all.count, 33_684, "the sweep covers \(all.count) shapes, not the family it claims to")
        XCTAssertTrue(
            all.contains { $0.groups == [3, 3, 4, 2] && $0.separators == ["-", "-", "-"] },
            "the sweep does not contain [3,3,4,2], the shape the previous fix was not checked against"
        )
        XCTAssertTrue(
            all.contains { $0.groups == [4, 3, 4, 2] && $0.separators == ["-", "-", "-"] },
            "the sweep does not contain [4,3,4,2], the one shape in its class that cannot exhibit the bug"
        )
        XCTAssertTrue(
            all.contains { $0.groups == [3, 3, 3, 4] && $0.separators == [",", " ", " "] },
            "the sweep varies the separator set uniformly per candidate, so the mixed spelling that leaked is outside it"
        )
        XCTAssertGreaterThan(
            Set(all.flatMap(\.separators)).count, 1,
            "every candidate in the sweep uses one separator throughout, so a separator-dependent rule cannot be reached"
        )
        XCTAssertTrue(
            all.contains { Set($0.separators).count > 1 },
            "no shape in the sweep mixes two separator spellings, which is the shape the client and the server disagreed on"
        )
    }

    func testOneCommaInASpaceSeparatedListIsNotAPhoneNumber() {
        for accepted in [
            "Radiator widths are 400, 600 900 1200 mm across the flat here",
            "Radiator widths are 400 600 900 1200 mm across the flat here",
            "Radiator widths are 400,600,900,1200 mm across the flat here",
            "the shelf sizes are 300, 600 900 1200 in the hall",
            "we counted 100, 200 300 4000 litres over the week"
        ] {
            XCTAssertFalse(
                DescriptionFilter.signals(in: accepted).contains(.phoneNumber),
                "'\(accepted)' is refused as a phone number and the server accepts it, because the client's separator class does not hold the mark the server's does"
            )
        }
        for refused in [
            "the plate reads 917,555,0199 next to the valve",
            "the plate reads 917, 555 0199 next to the valve",
            "the plate reads 917-555 0199 next to the valve"
        ] {
            XCTAssertTrue(
                DescriptionFilter.signals(in: refused).contains(.phoneNumber),
                "'\(refused)' is let through, so widening the separator class lost a dialable shape the server catches"
            )
        }
    }

    func testAThousandsGroupedRunIsNotADialableNumberEvenWithAnInternationalPrefix() {
        for accepted in [
            "the quote came to +1,234,567,890 lira all in",
            "the quote came to 1,234,567,890 lira all in",
            "the reading was +12,345,678,901 units"
        ] {
            XCTAssertFalse(
                DescriptionFilter.signals(in: accepted).contains(.phoneNumber),
                "'\(accepted)' is refused and the server vetoes it as thousands-grouped before it ever reads the prefix"
            )
        }
        XCTAssertTrue(
            DescriptionFilter.signals(in: "reach me on +1 917 555 0199 any evening").contains(.phoneNumber),
            "the thousands veto swallowed an ordinary internationally prefixed number"
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
            let dialable = Self.isDialableUnderTheServersRule(shape.groups, shape.separators)
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
        for shape in Self.shapes() where Self.isDialableUnderTheServersRule(shape.groups, shape.separators) {
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
