import DesignSystem
import SwiftUI

public struct A02WelcomeBackScreen: View {
    @Bindable var model: AuthFlowModel
    let knownRoles: Set<HDRole>

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

                    HDText(
                        "You're verified. Continue as \(model.selectedRole.label.lowercased()).",
                        style: HDType.body,
                        color: .hdInkSoft
                    )

                    HDPrimaryButton("Continue") {
                        model.completeSignIn()
                    }
                }

                if let errorMessage = model.errorMessage {
                    HDText(errorMessage, style: HDType.caption, color: .hdAlert)
                }
            }
        }
    }
}
