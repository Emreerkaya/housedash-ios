import SwiftUI
import DesignSystem

public struct FixHomeScreen: View {
    public init() {}

    public var body: some View {
        HDTabScreen(tab: .fix) {
            HDScreen {
                HDItemStack {
                    HDText("Fix", style: HDType.titleLarge)
                    HDText(
                        "Tell us what broke and we will give you both the do-it-yourself guide and the nearby people who can take it off your hands.",
                        style: HDType.body,
                        color: .hdInkSoft
                    )
                }

                HDItemStack {
                    HDText("Start a new case", style: HDType.section)
                    HDText(
                        "Placeholder destination. The intake flow (H2A through H06) assembles here once its screens are built.",
                        style: HDType.bodyDense,
                        color: .hdInkFaint
                    )
                }
            }
        }
    }
}
