import DesignSystem
import SwiftUI

public struct A01ContinueScreen: View {
    @Bindable var model: AuthFlowModel

    public init(model: AuthFlowModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: nil)
            HDScreen {
                HDItemStack {
                    HDText("HouseDash", style: HDType.brand, singleLineMinimumScaleFactor: 0.4)
                    HDText(
                        "Fix it yourself, or get someone who will.",
                        style: HDType.body,
                        color: .hdInkSoft
                    )
                }

                HDItemStack {
                    HDField(
                        label: "Email or phone",
                        placeholder: "Either one works",
                        text: $model.identifier
                    )
                    HDPrimaryButton("Continue") {
                        Task { await model.submitIdentifier() }
                    }
                }

                HDItemStack {
                    HDSecondaryButton("Continue with Apple") {
                        model.continueWithSSO()
                    }
                    HDSecondaryButton("Continue with Google") {
                        model.continueWithSSO()
                    }
                }

                legalLine
            }
        }
        .background(Color.hdGround.ignoresSafeArea())
    }

    private var legalLine: some View {
        Text(
            "By continuing you agree to the [Terms](https://housedash.app/terms) and [Privacy Policy](https://housedash.app/privacy)."
        )
        .hdTypeStyle(HDType.caption)
        .foregroundStyle(Color.hdInkFaint)
        .tint(Color.hdInk)
    }
}
