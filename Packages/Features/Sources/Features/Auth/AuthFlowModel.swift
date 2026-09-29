import Foundation
import Observation

@MainActor
@Observable
public final class AuthFlowModel {
    public var identifier: String = ""
    public var path: [AuthRoute] = []
    public var selectedRole: HDRole = .nester
    public var errorMessage: String?
    public var isSubmitting: Bool = false

    private var rememberedPassword: String = ""
    private let identityService: IdentityService
    private let onAuthenticated: (HDRole) -> Void

    public init(identityService: IdentityService, onAuthenticated: @escaping (HDRole) -> Void) {
        self.identityService = identityService
        self.onAuthenticated = onAuthenticated
    }

    public func changeIdentifier() {
        path = []
        errorMessage = nil
    }

    public func submitIdentifier() async {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            switch try await identityService.lookup(identifier: identifier) {
            case .existingAccount(let roles):
                selectedRole = roles.contains(.nester) ? .nester : .tasker
                path = [.signIn(knownRoles: roles)]
            case .newIdentifier:
                selectedRole = .nester
                path = [.createAccount]
            }
        } catch {
            errorMessage = "Something went wrong. Try again."
        }
    }

    public func continueWithSSO() {
        selectedRole = .nester
        path = [.createAccount]
    }

    public func signIn(password: String) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let outcome = try await identityService.signIn(identifier: identifier, password: password)
            guard case .signedIn(let role, let roles) = outcome else { return }
            rememberedPassword = password
            if roles.count == 1 {
                path.append(.addOtherProfile(existingRole: role))
            } else {
                onAuthenticated(role)
            }
        } catch {
            errorMessage = "That password doesn't match this account."
        }
    }

    public func createAccount(password: String) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let outcome = try await identityService.createAccount(
                identifier: identifier,
                password: password,
                role: selectedRole
            )
            guard case .accountCreated(let role) = outcome else { return }
            onAuthenticated(role)
        } catch {
            errorMessage = "We couldn't create that account. Try again."
        }
    }

    public func addOtherProfile(role: HDRole) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let outcome = try await identityService.createAccount(
                identifier: identifier,
                password: rememberedPassword,
                role: role
            )
            guard case .accountCreated(let addedRole) = outcome else { return }
            onAuthenticated(addedRole)
        } catch {
            onAuthenticated(role == .nester ? .tasker : .nester)
        }
    }

    public func dismissAddOtherProfile(currentRole: HDRole) {
        onAuthenticated(currentRole)
    }

    public func requestPasswordReset() {
        path = []
    }

    public func goToResetPassword() {
        path.append(.resetPassword)
    }
}
