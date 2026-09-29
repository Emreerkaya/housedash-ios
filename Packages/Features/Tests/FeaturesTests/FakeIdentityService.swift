@testable import Features

final class FakeIdentityService: IdentityService, @unchecked Sendable {
    var accounts: [String: Set<HDRole>] = [
        "dana@example.com": [.nester, .tasker],
        "solo@example.com": [.nester]
    ]
    var lookupCallCount = 0
    var signInCallCount = 0
    var createAccountCallCount = 0

    func lookup(identifier: String) async throws -> IdentityLookupResult {
        lookupCallCount += 1
        if let roles = accounts[identifier] {
            return .existingAccount(roles: roles)
        }
        return .newIdentifier
    }

    func signIn(identifier: String, password: String) async throws -> AuthOutcome {
        signInCallCount += 1
        guard let roles = accounts[identifier] else {
            throw IdentityServiceError.invalidCredentials
        }
        let role: HDRole = roles.contains(.nester) ? .nester : .tasker
        return .signedIn(role: role, roles: roles)
    }

    func createAccount(identifier: String, password: String, role: HDRole) async throws -> AuthOutcome {
        createAccountCallCount += 1
        accounts[identifier, default: []].insert(role)
        return .accountCreated(role: role)
    }
}
