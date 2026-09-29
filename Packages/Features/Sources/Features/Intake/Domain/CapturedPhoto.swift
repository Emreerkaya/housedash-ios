public struct CapturedPhoto: Sendable, Equatable, Identifiable, Hashable {
    public let id: String
    public let timestampLabel: String

    public init(id: String, timestampLabel: String) {
        self.id = id
        self.timestampLabel = timestampLabel
    }
}
