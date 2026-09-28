public struct APIErrorDTO: Decodable, Sendable, Equatable {
    public let code: String
    public let message: String
}
