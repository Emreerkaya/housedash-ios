import Foundation
import XCTest
import Networking
@testable import Features
@testable import HouseDash

final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    var result: Result<Any, Error> = .success(())
    private(set) var requests: [HTTPRequest] = []

    func send<Response: Decodable>(_ request: HTTPRequest) async throws -> Response {
        requests.append(request)
        switch result {
        case .success(let value):
            guard let typed = value as? Response else {
                throw HTTPClientError.decodingFailed
            }
            return typed
        case .failure(let error):
            throw error
        }
    }
}

final class RemoteIdentityServiceTests: XCTestCase {
    func testRequestCodeReturnsTheServersCooldownAndHitsTheIssuePath() async throws {
        let client = StubHTTPClient()
        client.result = .success(OTPIssueResponseDTO(cooldownSeconds: 45))
        let service = RemoteIdentityService(httpClient: client)

        let cooldown = try await service.requestCode(identifier: "dana@example.com")

        XCTAssertEqual(cooldown, 45)
        XCTAssertEqual(client.requests.first?.path, "/identity/otp/issue")
    }

    func testVerifyCodeMapsAnExistingAccountResponse() async throws {
        let client = StubHTTPClient()
        client.result = .success(OTPVerifyResponseDTO(status: "existingAccount", roles: ["nester", "tasker"]))
        let service = RemoteIdentityService(httpClient: client)

        let result = try await service.verifyCode(identifier: "dana@example.com", code: "123456")

        guard case .existingAccount(let roles) = result else {
            return XCTFail("expected existingAccount")
        }
        XCTAssertEqual(roles, [.nester, .tasker])
    }

    func testVerifyCodeMapsANewIdentifierResponse() async throws {
        let client = StubHTTPClient()
        client.result = .success(OTPVerifyResponseDTO(status: "newIdentifier", roles: nil))
        let service = RemoteIdentityService(httpClient: client)

        let result = try await service.verifyCode(identifier: "brandnew@example.com", code: "123456")

        guard case .newIdentifier = result else {
            return XCTFail("expected newIdentifier")
        }
    }

    func testAWrongCodeStatusMapsToWrongCodeError() async {
        let client = StubHTTPClient()
        client.result = .failure(HTTPClientError.serverError(statusCode: 422, apiError: nil, retryAfterSeconds: nil))
        let service = RemoteIdentityService(httpClient: client)

        do {
            _ = try await service.verifyCode(identifier: "dana@example.com", code: "000000")
            XCTFail("expected wrongCode")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .wrongCode)
        }
    }

    func testAnAPIErrorCodeTakesPrecedenceOverTheStatusCode() async {
        let client = StubHTTPClient()
        client.result = .failure(
            HTTPClientError.serverError(
                statusCode: 400,
                apiError: APIErrorDTO(code: "code_expired", message: "expired"),
                retryAfterSeconds: nil
            )
        )
        let service = RemoteIdentityService(httpClient: client)

        do {
            _ = try await service.verifyCode(identifier: "dana@example.com", code: "000000")
            XCTFail("expected codeExpired")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .codeExpired)
        }
    }

    func testRateLimitedIssuanceCarriesTheRetryAfterHeader() async {
        let client = StubHTTPClient()
        client.result = .failure(HTTPClientError.serverError(statusCode: 429, apiError: nil, retryAfterSeconds: 90))
        let service = RemoteIdentityService(httpClient: client)

        do {
            _ = try await service.requestCode(identifier: "dana@example.com")
            XCTFail("expected rateLimited")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .rateLimited(retryAfterSeconds: 90))
        }
    }

    func testTooManyVerifyAttemptsMapsFromTheStatusCodeAlone() async {
        let client = StubHTTPClient()
        client.result = .failure(HTTPClientError.serverError(statusCode: 429, apiError: nil, retryAfterSeconds: nil))
        let service = RemoteIdentityService(httpClient: client)

        do {
            _ = try await service.verifyCode(identifier: "dana@example.com", code: "000000")
            XCTFail("expected tooManyAttempts")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .tooManyAttempts)
        }
    }

    func testANetworkingLayerErrorMapsToOfflineRatherThanPropagatingRaw() async {
        let client = StubHTTPClient()
        client.result = .failure(URLError(.notConnectedToInternet))
        let service = RemoteIdentityService(httpClient: client)

        do {
            _ = try await service.requestCode(identifier: "dana@example.com")
            XCTFail("expected offline")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .offline)
        }
    }

    func testCreateAccountMapsTheCreatedRole() async throws {
        let client = StubHTTPClient()
        client.result = .success(OTPCreateAccountResponseDTO(role: "tasker"))
        let service = RemoteIdentityService(httpClient: client)

        let outcome = try await service.createAccount(identifier: "new@example.com", role: .tasker)

        guard case .accountCreated(let role) = outcome else {
            return XCTFail("expected accountCreated")
        }
        XCTAssertEqual(role, .tasker)
    }
}
