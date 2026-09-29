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
    case invertedGround
    case text
    case textOnAnInvertedGround
    case mark
    case boundary
}

public extension HDToken {
    var role: HDTokenRole {
        switch self {
        case .ground, .surface, .surfaceSunk: .screenGround
        case .context, .accentDIY, .accentHire: .invertedGround
        case .ink, .inkSoft, .inkFaint, .alert, .verified: .text
        case .onAccent, .onContext: .textOnAnInvertedGround
        case .held: .mark
        case .hairline, .locked: .boundary
        }
    }

    static func tokens(in role: HDTokenRole) -> [HDToken] {
        allCases.filter { $0.role == role }
    }
}
