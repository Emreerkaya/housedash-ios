import SwiftUI
import DesignSystem

public struct JobsHomeScreen: View {
    public init() {}

    public var body: some View {
        HDTabScreen(tab: .jobs) {
            HDScreen {
                HDItemStack {
                    HDText("Jobs", style: HDType.titleLarge)
                    HDText(
                        "Everything you have booked, scheduled, or hired out, in one place.",
                        style: HDType.body,
                        color: .hdInkSoft
                    )
                }

                HDItemStack {
                    HDText("Nothing scheduled yet", style: HDType.section)
                    HDText(
                        "Placeholder destination. The booking and case-tracking screens assemble here.",
                        style: HDType.bodyDense,
                        color: .hdInkFaint
                    )
                }
            }
        }
    }
}
