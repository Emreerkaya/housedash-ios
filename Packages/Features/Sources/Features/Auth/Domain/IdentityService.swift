public enum IdentityLookupResult: Sendable, Equatable {
    case existingAccount(roles: Set<HDRole>)
    case newIdentifier
}

public enum AuthOutcome: Sendable, Equatable {
    case signedIn(role: HDRole, roles: Set<HDRole>)
    case accountCreated(role: HDRole)
}

public enum IdentityServiceError: Error, Sendable, Equatable {
    case wrongCode
    case codeExpired
    case tooManyAttempts
    case rateLimited(retryAfterSeconds: Int)
    case offline
    case notImplemented
}

public protocol IdentityService: Sendable {
    func requestCode(identifier: String) async throws -> Int
    func verifyCode(identifier: String, code: String) async throws -> IdentityLookupResult
    func createAccount(identifier: String, role: HDRole) async throws -> AuthOutcome
}
