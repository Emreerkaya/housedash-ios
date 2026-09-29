public enum IdentityLookupResult: Sendable, Equatable {
    case existingAccount(roles: Set<HDRole>)
    case newIdentifier
}

public enum AuthOutcome: Sendable, Equatable {
    case signedIn(role: HDRole, roles: Set<HDRole>)
    case accountCreated(role: HDRole)
}

public enum IdentityServiceError: Error, Sendable, Equatable {
    case invalidCredentials
    case notImplemented
}

public protocol IdentityService: Sendable {
    func lookup(identifier: String) async throws -> IdentityLookupResult
    func signIn(identifier: String, password: String) async throws -> AuthOutcome
    func createAccount(identifier: String, password: String, role: HDRole) async throws -> AuthOutcome
}
