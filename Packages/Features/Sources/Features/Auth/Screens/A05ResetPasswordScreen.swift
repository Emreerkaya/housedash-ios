import DesignSystem
import SwiftUI

public struct A05ResetPasswordScreen: View {
    @Bindable var model: AuthFlowModel
    @State private var identifier: String = ""

    public init(model: AuthFlowModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "Reset your password", onBack: { model.path.removeLast() })
            HDScreen {
                HDText(
                    "Enter the email or phone on your account and we will send you a link.",
                    style: HDType.body,
                    color: .hdInkSoft
                )

                HDItemStack {
                    HDField(
                        label: "Email or phone",
                        placeholder: "Either one works",
                        text: $identifier
                    )
                    HDPrimaryButton("Send reset link") {
                        model.requestPasswordReset()
                    }
                }

                HDText(
                    "The link works once and expires in 30 minutes.",
                    style: HDType.caption,
                    color: .hdInkFaint
                )
            }
        }
    }
}
