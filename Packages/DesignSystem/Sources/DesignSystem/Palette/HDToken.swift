public enum HDToken: String, CaseIterable, Sendable {
    case ground
    case surface
    case surfaceSunk
    case ink
    case inkSoft
    case inkFaint
    case hairline
    case locked
    case accentDIY
    case accentHire
    case alert
    case held
    case verified
    case onAccent
    case context
    case onContext
}

public enum HDTokenRole: Sendable, Equatable, CaseIterable {
    case screenGround
    case controlGround
    case invertedGround
    case text
    case textOnAnInvertedGround
    case mark
    case boundary
}

public extension HDToken {
    var roles: Set<HDTokenRole> {
        switch self {
        case .ground, .surface, .surfaceSunk: [.screenGround]
        case .locked: [.controlGround]
        case .context: [.invertedGround, .boundary]
        case .accentDIY, .accentHire: [.invertedGround, .text]
        case .ink: [.text, .boundary]
        case .inkSoft, .inkFaint: [.text]
        case .alert: [.text, .boundary]
        case .verified: [.text, .mark]
        case .held: [.mark]
        case .hairline: [.boundary]
        case .onAccent, .onContext: [.textOnAnInvertedGround, .boundary]
        }
    }

    static func tokens(in role: HDTokenRole) -> [HDToken] {
        allCases.filter { $0.roles.contains(role) }
    }

    static var placements: [(token: HDToken, role: HDTokenRole)] {
        allCases.flatMap { token in
            HDTokenRole.allCases.filter { token.roles.contains($0) }.map { (token, $0) }
        }
    }

    var invertedGroundItsNameClaims: [HDToken] {
        let name = rawValue
        guard name.hasPrefix("on"), name.count > 2 else { return [] }
        let stem = name.dropFirst(2).lowercased()
        return Self.tokens(in: .invertedGround).filter { $0.rawValue.lowercased().hasPrefix(stem) }
    }
}
