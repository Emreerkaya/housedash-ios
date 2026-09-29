import SwiftUI
import DesignSystem

public struct ProfileHomeScreen: View {
    static let signInDisabledReason = "arrives with account setup"
    static let supportLine =
        "Have a question before then? [Message support](https://housedash.app/support)."

    public init() {}

    public var body: some View {
        HDScreen {
            HDItemStack {
                HDText("Profile", style: HDType.titleLarge)
                HDText(
                    "Your account, your other profile, and how HouseDash reaches you.",
                    style: HDType.body,
                    color: .hdInkSoft
                )
            }

            HDItemStack {
                HDGroupHeading("Account")
                HDText(
                    "This device is not signed in to anyone yet.",
                    style: HDType.bodyDense,
                    color: .hdInkFaint
                )
                HDSecondaryButton("Sign in") {}
                    .disabled(true)
                    .accessibilityHint(Self.signInDisabledReason)
            }

            HDItemStack {
                Text(LocalizedStringKey(Self.supportLine))
                    .hdTypeStyle(HDType.caption)
                    .foregroundStyle(Color.hdInkFaint)
                    .tint(Color.hdInk)
            }
        }
    }
}
