@testable import Features

final class FakeIdentityService: IdentityService, @unchecked Sendable {
    static let validCode = "123456"

    var accounts: [String: Set<HDRole>] = [
        "dana@example.com": [.nester, .tasker],
        "solo@example.com": [.nester]
    ]
    var requestCodeCallCount = 0
    var verifyCodeCallCount = 0
    var createAccountCallCount = 0
    var requestCodeCooldown = 30
    var nextRequestCodeError: IdentityServiceError?
    var nextVerifyCodeError: IdentityServiceError?

    func requestCode(identifier: String) async throws -> Int {
        requestCodeCallCount += 1
        if let error = nextRequestCodeError {
            throw error
        }
        return requestCodeCooldown
    }

    func verifyCode(identifier: String, code: String) async throws -> IdentityLookupResult {
        verifyCodeCallCount += 1
        if let error = nextVerifyCodeError {
            throw error
        }
        guard code == Self.validCode else {
            throw IdentityServiceError.wrongCode
        }
        if let roles = accounts[identifier] {
            return .existingAccount(roles: roles)
        }
        return .newIdentifier
    }

    func createAccount(identifier: String, role: HDRole) async throws -> AuthOutcome {
        createAccountCallCount += 1
        accounts[identifier, default: []].insert(role)
        return .accountCreated(role: role)
    }
}
