import DesignSystem
import SwiftUI

public struct A04AddOtherProfileScreen: View {
    @Bindable var model: AuthFlowModel
    let existingRole: HDRole

    public init(model: AuthFlowModel, existingRole: HDRole) {
        self.model = model
        self.existingRole = existingRole
    }

    private var otherRole: HDRole {
        existingRole == .nester ? .tasker : .nester
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "Add a profile", onBack: { model.path.removeLast() })
            HDScreen {
                HDText(
                    "Same email, same password. Switch between them any time from Profile.",
                    style: HDType.body,
                    color: .hdInkSoft
                )

                notNowButton

                HDPrimaryButton("Add \(otherRole.label) profile") {
                    Task { await model.addOtherProfile(role: otherRole) }
                }
            }
        }
    }

    var notNowButton: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                model.dismissAddOtherProfile(currentRole: existingRole)
            } label: {
                HDText("Not now", style: HDType.body, color: .hdInkSoft)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            Spacer(minLength: 0)
        }
    }
}
