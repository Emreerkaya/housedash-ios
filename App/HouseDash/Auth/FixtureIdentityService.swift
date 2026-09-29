#if DEBUG
import Features

struct FixtureIdentityService: IdentityService {
    private static let fixtureAccounts: [String: Set<HDRole>] = [
        "dana@example.com": [.nester, .tasker],
        "solo@example.com": [.nester]
    ]

    func lookup(identifier: String) async throws -> IdentityLookupResult {
        if let roles = Self.fixtureAccounts[identifier] {
            return .existingAccount(roles: roles)
        }
        return .newIdentifier
    }

    func signIn(identifier: String, password: String) async throws -> AuthOutcome {
        guard let roles = Self.fixtureAccounts[identifier], !password.isEmpty else {
            throw IdentityServiceError.invalidCredentials
        }
        let role: HDRole = roles.contains(.nester) ? .nester : .tasker
        return .signedIn(role: role, roles: roles)
    }

    func createAccount(identifier: String, password: String, role: HDRole) async throws -> AuthOutcome {
        .accountCreated(role: role)
    }
}
#endif
