public enum AuthRoute: Hashable, Sendable {
    case verifyCode
    case signIn(knownRoles: Set<HDRole>)
    case createAccount
    case addOtherProfile(existingRole: HDRole)
}
