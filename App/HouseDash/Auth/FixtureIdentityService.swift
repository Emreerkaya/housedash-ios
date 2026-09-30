#if DEBUG
import Features

struct FixtureIdentityService: IdentityService {
    static let fixtureCode = "123456"
    static let expiredCode = "222222"
    static let tooManyAttemptsCode = "333333"
    static let rateLimitedCode = "444444"
    static let offlineCode = "555555"

    private static let fixtureAccounts: [String: Set<HDRole>] = [
        "dana@example.com": [.nester, .tasker],
        "solo@example.com": [.nester]
    ]

    func requestCode(identifier: String) async throws -> Int {
        30
    }

    func verifyCode(identifier: String, code: String) async throws -> IdentityLookupResult {
        switch code {
        case Self.fixtureCode:
            if let roles = Self.fixtureAccounts[identifier] {
                return .existingAccount(roles: roles)
            }
            return .newIdentifier
        case Self.expiredCode:
            throw IdentityServiceError.codeExpired
        case Self.tooManyAttemptsCode:
            throw IdentityServiceError.tooManyAttempts
        case Self.rateLimitedCode:
            throw IdentityServiceError.rateLimited(retryAfterSeconds: 45)
        case Self.offlineCode:
            throw IdentityServiceError.offline
        default:
            throw IdentityServiceError.wrongCode
        }
    }

    func createAccount(identifier: String, role: HDRole) async throws -> AuthOutcome {
        .accountCreated(role: role)
    }
}
#endif
