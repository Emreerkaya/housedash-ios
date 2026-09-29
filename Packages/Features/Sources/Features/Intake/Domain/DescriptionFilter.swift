import Foundation

public enum ContactSignalKind: String, Sendable, CaseIterable, Equatable {
    case phoneNumber
    case emailAddress
    case paymentHandle

    public var guidance: String {
        switch self {
        case .phoneNumber: "a phone number"
        case .emailAddress: "an email address"
        case .paymentHandle: "a payment link or handle"
        }
    }
}

public struct DescriptionRejection: Sendable, Equatable {
    public static let anUnnamedField = "a description"

    public let signals: [ContactSignalKind]
    public let fieldLabels: [String]

    public init(signals: [ContactSignalKind], fieldLabels: [String] = []) {
        self.signals = signals
        self.fieldLabels = fieldLabels
    }

    public var summary: String {
        "This looks like it includes \(listed(signals.map(\.guidance))). Every job is coordinated and paid through HouseDash, so contact details and payment links can't go in \(whereItWasTyped) — remove that part and you're set."
    }

    private var whereItWasTyped: String {
        fieldLabels.isEmpty ? Self.anUnnamedField : listed(fieldLabels.map { "\u{201C}\($0)\u{201D}" })
    }

    private func listed(_ parts: [String]) -> String {
        switch parts.count {
        case 0:
            return "something"
        case 1:
            return parts[0]
        case 2:
            return "\(parts[0]) and \(parts[1])"
        default:
            return parts.dropLast().joined(separator: ", ") + ", and " + parts[parts.count - 1]
        }
    }
}

public enum DescriptionValidationError: Error, Sendable, Equatable {
    case rejected(DescriptionRejection)
}

public struct Description: Sendable, Equatable {
    public let text: String

    private init(text: String) {
        self.text = text
    }

    public static func of(_ raw: String) -> Result<Description, DescriptionValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let signals = DescriptionFilter.signals(in: trimmed)
        guard signals.isEmpty else {
            return .failure(.rejected(DescriptionRejection(signals: signals)))
        }
        return .success(Description(text: trimmed))
    }
}

public struct Location: Sendable, Equatable {
    public static let unspecified = Location(text: "")

    public let text: String

    private init(text: String) {
        self.text = text
    }

    public static func of(_ raw: String) -> Result<Location, DescriptionValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let signals = DescriptionFilter.signals(in: trimmed)
        guard signals.isEmpty else {
            return .failure(.rejected(DescriptionRejection(signals: signals)))
        }
        return .success(Location(text: trimmed))
    }
}

public enum DescriptionFilter {
    public static let digitsInADialableNumber = 10
    public static let digitsInTheLineGroup = 4
    public static let digitsInAPhoneNumber = 9...15
    public static let digitsInTheGroupBeforeTheLine = 3...4
    public static let mostDigitsInAPhoneGroup = 6
    public static let phoneGroupsADialableNumberHas = 3...6
    public static let fewestDomainLabels = 2
    public static let punctuationTheThousandsArmOwns = ",;:"
    public static let mostDigitsBeforeAThousandsSeparator = 3
    public static let digitsInAThousandsGroup = 3
    public static let digitsAStrayGroupHolds = 1

    private static let phoneCandidate = expression(
        #"\+?+\p{Nd}(?:[^\p{L}\p{Nd}]{0,8}+\p{Nd}){0,31}+"#
    )
    private static let thousandsSeparator = expression(
        #"^[\#(punctuationTheThousandsArmOwns)]\p{Zs}{0,2}+$"#
    )
    private static let digitGroup = expression(#"\p{Nd}++"#)
    private static let emailCandidate = expression(
        #"(?i)[A-Za-z0-9._%+\-]{1,64}+@([A-Za-z0-9\-]{1,63}+(?:\.[A-Za-z0-9\-]{1,63}+)*+)"#
    )
    private static let topLevelLabel = expression(#"^[A-Za-z]{2,24}$"#)
    private static let cashtag = expression(#"(?<![A-Za-z0-9])\$[A-Za-z][A-Za-z0-9_]{1,14}+\b"#)
    private static let paymentLink = expression(
        #"(?i)\b(?:cash\.app|venmo\.com|paypal\.me)/\S+"#
    )

    static let categoriesStrippedBeforeMatching: Set<Unicode.GeneralCategory> = [
        .format, .nonspacingMark, .spacingMark, .enclosingMark
    ]

    static let lineBreaksADescriptionBoxCreates: Set<Unicode.Scalar> = [
        "\n", "\r", "\t", "\u{0B}", "\u{0C}", "\u{85}", "\u{2028}", "\u{2029}"
    ]

    public static func signals(in text: String) -> [ContactSignalKind] {
        let folded = foldedForMatchingOnly(text)
        var found: [ContactSignalKind] = []
        if holdsEmailAddress(in: folded) {
            found.append(.emailAddress)
        }
        if holdsPhoneNumber(in: folded) {
            found.append(.phoneNumber)
        }
        if matches(cashtag, in: folded) || matches(paymentLink, in: folded) {
            found.append(.paymentHandle)
        }
        return found
    }

    static func foldedForMatchingOnly(_ text: String) -> String {
        var folded = String.UnicodeScalarView()
        for scalar in text.decomposedStringWithCompatibilityMapping.unicodeScalars {
            if categoriesStrippedBeforeMatching.contains(scalar.properties.generalCategory) { continue }
            if lineBreaksADescriptionBoxCreates.contains(scalar) {
                folded.append(" ")
            } else if let shape = digitThisShapeStandsFor(scalar) {
                folded.append(shape)
            } else {
                folded.append(scalar)
            }
        }
        return String(folded)
    }

    static func digitThisShapeStandsFor(_ scalar: Unicode.Scalar) -> Unicode.Scalar? {
        guard scalar.properties.generalCategory != .decimalNumber else { return nil }
        guard let value = scalar.properties.numericValue, value >= 0, value <= 9 else { return nil }
        let digit = Int(value)
        guard Double(digit) == value else { return nil }
        return Unicode.Scalar(UInt8(UInt8(ascii: "0") + UInt8(digit)))
    }

    static func holdsPhoneNumber(in text: String) -> Bool {
        candidates(phoneCandidate, in: text).contains(where: isDialable)
    }

    static func separatorsBetweenGroups(in candidate: String) -> [String] {
        let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
        let groups = digitGroup.matches(in: candidate, range: range)
        guard groups.count > 1 else { return [] }
        return (1..<groups.count).compactMap { index in
            let start = groups[index - 1].range.upperBound
            let gap = NSRange(location: start, length: groups[index].range.lowerBound - start)
            return Range(gap, in: candidate).map { String(candidate[$0]) }
        }
    }

    static func isGroupedByTheThousandsMarks(_ separators: [String]) -> Bool {
        !separators.isEmpty && separators.allSatisfy { matches(thousandsSeparator, in: $0) }
    }

    static func isGroupedLikeThousands(_ groups: [Int]) -> Bool {
        guard let leading = groups.first else { return false }
        return leading <= mostDigitsBeforeAThousandsSeparator
            && groups.dropFirst().allSatisfy { $0 == digitsInAThousandsGroup }
    }

    static func isDialable(_ candidate: String) -> Bool {
        let groups = candidates(digitGroup, in: candidate).map(\.count)
        let digits = groups.reduce(0, +)
        guard digitsInAPhoneNumber.contains(digits) else { return false }
        let separators = separatorsBetweenGroups(in: candidate)
        if isGroupedByTheThousandsMarks(separators), isGroupedLikeThousands(groups) { return false }
        if candidate.hasPrefix("+") { return true }
        if endsLikeAnExchangeAndALine(groups) { return true }
        let trimmed = Array(
            groups
                .drop(while: { $0 == digitsAStrayGroupHolds })
                .reversed()
                .drop(while: { $0 == digitsAStrayGroupHolds })
                .reversed()
        )
        guard trimmed.count != groups.count, digitsInAPhoneNumber.contains(trimmed.reduce(0, +)) else { return false }
        return endsLikeAnExchangeAndALine(trimmed)
    }

    static func endsLikeAnExchangeAndALine(_ groups: [Int]) -> Bool {
        guard
            phoneGroupsADialableNumberHas.contains(groups.count),
            groups.allSatisfy({ $0 <= mostDigitsInAPhoneGroup }),
            groups.reduce(0, +) == digitsInADialableNumber,
            groups.last == digitsInTheLineGroup,
            digitsInTheGroupBeforeTheLine.contains(groups[groups.count - 2])
        else { return false }
        return true
    }

    static func holdsEmailAddress(in text: String) -> Bool {
        domains(in: text).contains(where: hasDomainShape)
    }

    static func hasDomainShape(_ domain: String) -> Bool {
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= fewestDomainLabels, let last = labels.last else { return false }
        return matches(topLevelLabel, in: String(last))
    }

    static func domains(in text: String) -> [String] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return emailCandidate.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: 1), in: text).map { String(text[$0]) }
        }
    }

    private static func candidates(_ regex: NSRegularExpression, in text: String) -> [String] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    private static func expression(_ pattern: String) -> NSRegularExpression {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            preconditionFailure("Malformed filter pattern \(pattern)")
        }
        return regex
    }
}
