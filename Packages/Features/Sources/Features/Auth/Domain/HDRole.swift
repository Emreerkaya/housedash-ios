public enum HDRole: String, CaseIterable, Identifiable, Sendable {
    case nester
    case tasker

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .nester: return "Nester"
        case .tasker: return "Tasker"
        }
    }
}
