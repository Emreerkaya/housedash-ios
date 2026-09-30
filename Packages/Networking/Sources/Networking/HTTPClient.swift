import Foundation

public protocol HTTPClient: Sendable {
    func send<Response: Decodable>(_ request: HTTPRequest) async throws -> Response
}

public func makeHouseDashJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}

public func makeHouseDashJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}

public struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = makeHouseDashJSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    public func send<Response: Decodable>(_ request: HTTPRequest) async throws -> Response {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: false) else {
            throw HTTPClientError.invalidURL
        }
        components.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components.url else {
            throw HTTPClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        if request.body != nil, request.headers["Content-Type"] == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let apiError = try? decoder.decode(APIErrorDTO.self, from: data)
            let retryAfterSeconds = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) }
            throw HTTPClientError.serverError(
                statusCode: httpResponse.statusCode,
                apiError: apiError,
                retryAfterSeconds: retryAfterSeconds
            )
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw HTTPClientError.decodingFailed
        }
    }
}
