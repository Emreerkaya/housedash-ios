import SwiftUI
import DesignSystem

public struct ProfileHomeScreen: View {
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
                HDText("Account", style: HDType.section)
                HDText(
                    "Placeholder destination. Auth (S01 through S05) assembles here.",
                    style: HDType.bodyDense,
                    color: .hdInkFaint
                )
            }
        }
    }
}
