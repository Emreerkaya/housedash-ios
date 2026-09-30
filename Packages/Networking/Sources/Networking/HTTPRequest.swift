import Foundation

public struct HTTPRequest: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public var method: Method
    public var path: String
    public var queryItems: [URLQueryItem]
    public var body: Data?
    public var headers: [String: String]

    public init(
        method: Method = .get,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
}

public enum HTTPClientError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, apiError: APIErrorDTO?, retryAfterSeconds: Int?)
    case decodingFailed
}
