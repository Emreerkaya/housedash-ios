import Features
import Foundation
import Networking

struct RemoteIdentityService: IdentityService {
    private static let issuePath = "/identity/otp/issue"
    private static let verifyPath = "/identity/otp/verify"
    private static let accountPath = "/identity/account"
    private static let existingAccountStatus = "existingAccount"

    let httpClient: HTTPClient
    let encoder: JSONEncoder

    init(httpClient: HTTPClient, encoder: JSONEncoder = makeHouseDashJSONEncoder()) {
        self.httpClient = httpClient
        self.encoder = encoder
    }

    func requestCode(identifier: String) async throws -> Int {
        do {
            let body = try encoder.encode(OTPIssueRequestDTO(identifier: identifier))
            let response: OTPIssueResponseDTO = try await httpClient.send(
                HTTPRequest(method: .post, path: Self.issuePath, body: body)
            )
            return response.cooldownSeconds
        } catch {
            throw Self.mapIssueError(error)
        }
    }

    func verifyCode(identifier: String, code: String) async throws -> IdentityLookupResult {
        do {
            let body = try encoder.encode(OTPVerifyRequestDTO(identifier: identifier, code: code))
            let response: OTPVerifyResponseDTO = try await httpClient.send(
                HTTPRequest(method: .post, path: Self.verifyPath, body: body)
            )
            guard response.status == Self.existingAccountStatus else {
                return .newIdentifier
            }
            let roles = Set((response.roles ?? []).compactMap(HDRole.init(rawValue:)))
            return .existingAccount(roles: roles)
        } catch {
            throw Self.mapVerifyError(error)
        }
    }

    func createAccount(identifier: String, role: HDRole) async throws -> AuthOutcome {
        do {
            let body = try encoder.encode(OTPCreateAccountRequestDTO(identifier: identifier, role: role.rawValue))
            let response: OTPCreateAccountResponseDTO = try await httpClient.send(
                HTTPRequest(method: .post, path: Self.accountPath, body: body)
            )
            guard let createdRole = HDRole(rawValue: response.role) else {
                throw IdentityServiceError.notImplemented
            }
            return .accountCreated(role: createdRole)
        } catch let error as IdentityServiceError {
            throw error
        } catch {
            throw Self.mapVerifyError(error)
        }
    }

    private static func mapIssueError(_ error: Error) -> IdentityServiceError {
        guard case .serverError(let statusCode, let apiError, let retryAfterSeconds) = error as? HTTPClientError else {
            return .offline
        }
        if let mapped = codeForAPIError(apiError, retryAfterSeconds: retryAfterSeconds) {
            return mapped
        }
        return statusCode == 429 ? .rateLimited(retryAfterSeconds: retryAfterSeconds ?? 30) : .offline
    }

    private static func mapVerifyError(_ error: Error) -> IdentityServiceError {
        guard case .serverError(let statusCode, let apiError, let retryAfterSeconds) = error as? HTTPClientError else {
            return .offline
        }
        if let mapped = codeForAPIError(apiError, retryAfterSeconds: retryAfterSeconds) {
            return mapped
        }
        switch statusCode {
        case 429: return .tooManyAttempts
        case 410: return .codeExpired
        case 401, 422: return .wrongCode
        default: return .offline
        }
    }

    private static func codeForAPIError(_ apiError: APIErrorDTO?, retryAfterSeconds: Int?) -> IdentityServiceError? {
        switch apiError?.code {
        case "wrong_code": return .wrongCode
        case "code_expired": return .codeExpired
        case "too_many_attempts": return .tooManyAttempts
        case "rate_limited": return .rateLimited(retryAfterSeconds: retryAfterSeconds ?? 30)
        default: return nil
        }
    }
}
