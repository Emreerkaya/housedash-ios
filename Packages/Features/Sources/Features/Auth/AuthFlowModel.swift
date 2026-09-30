import Foundation
import Observation

public enum OTPBannerState: Sendable, Equatable {
    case codeSent
    case wrongCode
    case codeExpired
    case tooManyAttempts
    case rateLimited(retryAfterSeconds: Int)
    case offline
}

@MainActor
@Observable
public final class AuthFlowModel {
    public var identifier: String = ""
    public var path: [AuthRoute] = []
    public var selectedRole: HDRole = .nester
    public var errorMessage: String?
    public var isSubmitting: Bool = false
    public var otpBanner: OTPBannerState?
    public var cooldownRemaining: Int = 0

    private var cooldownTask: Task<Void, Never>?
    private let identityService: IdentityService
    private let onAuthenticated: (HDRole) -> Void

    public init(identityService: IdentityService, onAuthenticated: @escaping (HDRole) -> Void) {
        self.identityService = identityService
        self.onAuthenticated = onAuthenticated
    }

    public func changeIdentifier() {
        path = []
        errorMessage = nil
        otpBanner = nil
        cancelCooldown()
    }

    public func submitIdentifier() async {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let cooldown = try await identityService.requestCode(identifier: identifier)
            otpBanner = .codeSent
            beginCooldown(seconds: cooldown)
            path = [.verifyCode]
        } catch {
            errorMessage = Self.identifierSubmissionMessage(for: error)
        }
    }

    public func continueWithSSO() {
        selectedRole = .nester
        path = [.createAccount]
    }

    public func resendCode() async {
        guard cooldownRemaining == 0 else { return }
        do {
            let cooldown = try await identityService.requestCode(identifier: identifier)
            otpBanner = .codeSent
            beginCooldown(seconds: cooldown)
        } catch {
            applyFailure(error)
        }
    }

    public func verifyCode(_ code: String) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let result = try await identityService.verifyCode(identifier: identifier, code: code)
            otpBanner = nil
            cancelCooldown()
            switch result {
            case .existingAccount(let roles):
                selectedRole = roles.contains(.nester) ? .nester : .tasker
                path = [.signIn(knownRoles: roles)]
            case .newIdentifier:
                selectedRole = .nester
                path = [.createAccount]
            }
        } catch {
            applyFailure(error)
        }
    }

    public func completeSignIn() {
        guard case .signIn(let knownRoles) = path.last else { return }
        if knownRoles.count == 1 {
            path.append(.addOtherProfile(existingRole: selectedRole))
        } else {
            onAuthenticated(selectedRole)
        }
    }

    public func createAccount() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let outcome = try await identityService.createAccount(identifier: identifier, role: selectedRole)
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
            let outcome = try await identityService.createAccount(identifier: identifier, role: role)
            guard case .accountCreated(let addedRole) = outcome else { return }
            onAuthenticated(addedRole)
        } catch {
            onAuthenticated(role == .nester ? .tasker : .nester)
        }
    }

    public func dismissAddOtherProfile(currentRole: HDRole) {
        onAuthenticated(currentRole)
    }

    private func applyFailure(_ error: Error) {
        let banner = Self.bannerState(for: error)
        otpBanner = banner
        if case .rateLimited(let seconds) = banner {
            beginCooldown(seconds: seconds)
        }
    }

    private func beginCooldown(seconds: Int) {
        cancelCooldown()
        cooldownRemaining = max(seconds, 0)
        guard cooldownRemaining > 0 else { return }
        cooldownTask = Task { @MainActor [weak self] in
            while let self, self.cooldownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                self.cooldownRemaining = max(self.cooldownRemaining - 1, 0)
            }
        }
    }

    private func cancelCooldown() {
        cooldownTask?.cancel()
        cooldownTask = nil
        cooldownRemaining = 0
    }

    private static func bannerState(for error: Error) -> OTPBannerState {
        guard let serviceError = error as? IdentityServiceError else { return .offline }
        switch serviceError {
        case .wrongCode: return .wrongCode
        case .codeExpired: return .codeExpired
        case .tooManyAttempts: return .tooManyAttempts
        case .rateLimited(let seconds): return .rateLimited(retryAfterSeconds: seconds)
        case .offline, .notImplemented: return .offline
        }
    }

    private static func identifierSubmissionMessage(for error: Error) -> String {
        guard let serviceError = error as? IdentityServiceError else { return "Something went wrong. Try again." }
        switch serviceError {
        case .offline: return "You're offline. Check your connection and try again."
        case .rateLimited: return "Too many attempts. Try again shortly."
        case .wrongCode, .codeExpired, .tooManyAttempts, .notImplemented: return "Something went wrong. Try again."
        }
    }
}
