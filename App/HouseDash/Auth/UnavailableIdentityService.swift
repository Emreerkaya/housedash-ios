import Features

struct UnavailableIdentityService: IdentityService {
    func requestCode(identifier: String) async throws -> Int {
        throw IdentityServiceError.notImplemented
    }

    func verifyCode(identifier: String, code: String) async throws -> IdentityLookupResult {
        throw IdentityServiceError.notImplemented
    }

    func createAccount(identifier: String, role: HDRole) async throws -> AuthOutcome {
        throw IdentityServiceError.notImplemented
    }
}
