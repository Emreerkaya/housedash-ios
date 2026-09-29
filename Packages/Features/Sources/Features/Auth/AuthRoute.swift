
public enum AuthRoute: Hashable, Sendable {
    case signIn(knownRoles: Set<HDRole>)
    case createAccount
    case addOtherProfile(existingRole: HDRole)
    case resetPassword
}
