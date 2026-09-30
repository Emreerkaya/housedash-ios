import DesignSystem
import SwiftUI

public struct A03CreateAccountScreen: View {
    @Bindable var model: AuthFlowModel

    public init(model: AuthFlowModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDRoleIslandBar(selected: model.selectedRole) { role in
                withAnimation(.easeOut(duration: 0.3)) {
                    model.selectedRole = role
                }
            }
            HDHeader(title: "Create your account", onBack: { model.path.removeLast() })
            HDScreen {
                HDText(tagline, style: HDType.body, color: .hdInkSoft)

                HDItemStack {
                    HDIdentityRow(identifier: model.identifier) {
                        model.changeIdentifier()
                    }

                    HDPrimaryButton("Create account") {
                        Task { await model.createAccount() }
                    }
                }

                HDText(closingNotice, style: HDType.caption, color: .hdInkSoft)

                if let errorMessage = model.errorMessage {
                    HDText(errorMessage, style: HDType.caption, color: .hdAlert)
                }
            }
        }
    }

    private var tagline: String {
        switch model.selectedRole {
        case .nester:
            return "Post a job, compare quotes, book someone. Owner or renter: it works the same."
        case .tasker:
            return "Take jobs near you. You set the price, the area and the calendar."
        }
    }

    private var closingNotice: String {
        switch model.selectedRole {
        case .nester:
            return "You only pay when you accept a quote."
        case .tasker:
            return "Free trial, then $29 a month. Never per job, never per lead."
        }
    }
}
