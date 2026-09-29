public struct ProblemSummary: Sendable, Equatable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let fullTitle: String
    public let category: String
    public let priceRange: String

    public init(id: String, title: String, fullTitle: String? = nil, category: String, priceRange: String) {
        self.id = id
        self.title = title
        self.fullTitle = fullTitle ?? title
        self.category = category
        self.priceRange = priceRange
    }
}

public struct ProblemRail: Sendable, Equatable, Identifiable {
    public let id: String
    public let heading: String
    public let cards: [ProblemSummary]

    public init(id: String, heading: String, cards: [ProblemSummary]) {
        self.id = id
        self.heading = heading
        self.cards = cards
    }
}

public struct SymptomOption: Sendable, Equatable, Identifiable, Hashable {
    public enum Kind: Sendable, Equatable, Hashable {
        case symptom(priceRange: String?)
        case ownWords
    }

    public let id: String
    public let primary: String
    public let secondary: String
    public let kind: Kind

    public init(id: String, primary: String, secondary: String, priceRange: String?) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
        self.kind = .symptom(priceRange: priceRange)
    }

    private init(id: String, primary: String, secondary: String, kind: Kind) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
        self.kind = kind
    }

    public static func ownWords(id: String, primary: String, secondary: String) -> SymptomOption {
        SymptomOption(id: id, primary: primary, secondary: secondary, kind: .ownWords)
    }

    public var priceRange: String? {
        switch kind {
        case .symptom(let priceRange): priceRange
        case .ownWords: nil
        }
    }

    public var isEscapeHatch: Bool { kind == .ownWords }
}

public enum ProblemCatalogueError: Error, Sendable, Equatable {
    case notImplemented
}

public protocol ProblemCatalogue: Sendable {
    func rails(for room: HDRoom) async throws -> [ProblemRail]
    func symptoms(for problem: ProblemSummary) async throws -> [SymptomOption]
}
