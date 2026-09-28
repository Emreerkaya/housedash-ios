public enum HDTab: String, CaseIterable, Identifiable, Sendable {
    case fix
    case jobs
    case photo
    case toolbox
    case profile

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fix: "Fix"
        case .jobs: "Jobs"
        case .photo: "Photo"
        case .toolbox: "Toolbox"
        case .profile: "Profile"
        }
    }

    public var systemImage: String {
        switch self {
        case .fix: "wrench.and.screwdriver"
        case .jobs: "briefcase"
        case .photo: "camera"
        case .toolbox: "hammer"
        case .profile: "person.crop.circle"
        }
    }
}
