import DesignSystem
import SwiftUI

public struct A02WelcomeBackScreen: View {
    @Bindable var model: AuthFlowModel
    let knownRoles: Set<HDRole>

    @State private var password: String = ""
    @State private var isRevealed: Bool = false

    public init(model: AuthFlowModel, knownRoles: Set<HDRole>) {
        self.model = model
        self.knownRoles = knownRoles
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDRoleIslandBar(selected: model.selectedRole) { role in
                withAnimation(.easeOut(duration: 0.3)) {
                    model.selectedRole = role
                }
            }
            HDHeader(title: "Welcome back", onBack: { model.path.removeLast() })
            HDScreen {
                HDItemStack {
                    HDIdentityRow(identifier: model.identifier) {
                        model.changeIdentifier()
                    }

                    HDField(
                        label: "Password",
                        placeholder: "••••••••",
                        text: $password,
                        isSecure: !isRevealed
                    ) {
                        HDPasswordRevealButton(isRevealed: $isRevealed)
                    }

                    HDPrimaryButton("Sign in") {
                        Task { await model.signIn(password: password) }
                    }
                }

                forgotPasswordRow

                if let errorMessage = model.errorMessage {
                    HDText(errorMessage, style: HDType.caption, color: .hdAlert)
                }
            }
        }
        .background(Color.hdGround.ignoresSafeArea())
    }

    var forgotPasswordRow: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                model.goToResetPassword()
            } label: {
                HDText("Forgot password?", style: HDType.caption, color: .hdInkSoft)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
        }
    }
}
