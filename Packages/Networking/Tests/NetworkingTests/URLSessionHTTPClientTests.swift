import XCTest
@testable import Networking

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: HTTPClientError.invalidResponse)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private struct EchoDTO: Codable, Equatable {
    let value: String
}

final class URLSessionHTTPClientTests: XCTestCase {
    private func makeClient() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(baseURL: URL(string: "https://api.housedash.test")!, session: session)
    }

    func testSuccessfulResponseDecodes() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/echo")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = try! JSONEncoder().encode(EchoDTO(value: "ok"))
            return (response, data)
        }

        let client = makeClient()
        let result: EchoDTO = try await client.send(HTTPRequest(path: "/echo"))
        XCTAssertEqual(result, EchoDTO(value: "ok"))
    }

    func testServerErrorThrows() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = makeClient()
        do {
            let _: EchoDTO = try await client.send(HTTPRequest(path: "/echo"))
            XCTFail("expected serverError")
        } catch let error as HTTPClientError {
            XCTAssertEqual(error, .serverError(statusCode: 500))
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}
