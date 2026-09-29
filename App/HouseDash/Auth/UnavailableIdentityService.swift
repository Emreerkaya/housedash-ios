import Features

struct UnavailableIdentityService: IdentityService {
    func lookup(identifier: String) async throws -> IdentityLookupResult {
        throw IdentityServiceError.notImplemented
    }

    func signIn(identifier: String, password: String) async throws -> AuthOutcome {
        throw IdentityServiceError.notImplemented
    }

    func createAccount(identifier: String, password: String, role: HDRole) async throws -> AuthOutcome {
        throw IdentityServiceError.notImplemented
    }
}
