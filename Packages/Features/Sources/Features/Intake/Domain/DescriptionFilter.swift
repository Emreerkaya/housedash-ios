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
    public let signals: [ContactSignalKind]

    public init(signals: [ContactSignalKind]) {
        self.signals = signals
    }

    public var summary: String {
        let kinds = signals.map(\.guidance)
        let joined: String
        switch kinds.count {
        case 0:
            joined = "something"
        case 1:
            joined = kinds[0]
        case 2:
            joined = "\(kinds[0]) and \(kinds[1])"
        default:
            joined = kinds.dropLast().joined(separator: ", ") + ", and " + kinds[kinds.count - 1]
        }
        return "This looks like it includes \(joined). Every job is coordinated and paid through HouseDash, so contact details and payment links can't go in a description — remove that part and you're set."
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

public enum DescriptionFilter {
    private static let groupedNANPPhone = try! NSRegularExpression(
        pattern: #"(?:\+?1[-.\s]?)?\(?(?<!\d)\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}(?!\d)"#
    )
    private static let email = try! NSRegularExpression(
        pattern: #"[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9-]{1,63}(?:\.[A-Za-z0-9-]{1,63})*\.[A-Za-z]{2,24}(?![A-Za-z])"#
    )
    private static let cashtag = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z0-9])\$[A-Za-z][A-Za-z0-9_]{1,14}\b"#
    )
    private static let paymentLink = try! NSRegularExpression(
        pattern: #"\b(?:cash\.app|venmo\.com|paypal\.me)/\S+"#,
        options: .caseInsensitive
    )

    public static func signals(in text: String) -> [ContactSignalKind] {
        var found: [ContactSignalKind] = []
        if matches(email, in: text) {
            found.append(.emailAddress)
        }
        if matches(groupedNANPPhone, in: text) {
            found.append(.phoneNumber)
        }
        if matches(cashtag, in: text) || matches(paymentLink, in: text) {
            found.append(.paymentHandle)
        }
        return found
    }

    private static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}
