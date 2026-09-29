import DesignSystem
import SwiftUI

public struct AuthFlowScreen: View {
    @State private var model: AuthFlowModel

    public init(identityService: IdentityService, onAuthenticated: @escaping (HDRole) -> Void) {
        _model = State(
            initialValue: AuthFlowModel(identityService: identityService, onAuthenticated: onAuthenticated)
        )
    }

    public var body: some View {
        NavigationStack(path: $model.path) {
            A01ContinueScreen(model: model)
                .hdFlowScreen()
                .navigationDestination(for: AuthRoute.self) { route in
                    destination(for: route)
                        .hdFlowScreen()
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .signIn(let knownRoles):
            A02WelcomeBackScreen(model: model, knownRoles: knownRoles)
        case .createAccount:
            A03CreateAccountScreen(model: model)
        case .addOtherProfile(let existingRole):
            A04AddOtherProfileScreen(model: model, existingRole: existingRole)
        case .resetPassword:
            A05ResetPasswordScreen(model: model)
        }
    }
}
