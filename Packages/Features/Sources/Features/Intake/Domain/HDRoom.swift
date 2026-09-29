public enum HDRoom: String, CaseIterable, Identifiable, Sendable {
    case kitchen
    case bathroom
    case bedroom
    case outdoors

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .kitchen: "Kitchen"
        case .bathroom: "Bathroom"
        case .bedroom: "Bedroom"
        case .outdoors: "Outdoors"
        }
    }
}
