import SwiftUI
import DesignSystem

public struct ToolboxHomeScreen: View {
    public init() {}

    public var body: some View {
        HDScreen {
            HDItemStack {
                HDText("Toolbox", style: HDType.titleLarge)
                HDText(
                    "Guides you have saved and the repairs you have already done yourself.",
                    style: HDType.body,
                    color: .hdInkSoft
                )
            }

            HDItemStack {
                HDText("Saved guides", style: HDType.section)
                HDText(
                    "Placeholder destination. The DIY guide library assembles here.",
                    style: HDType.bodyDense,
                    color: .hdInkFaint
                )
            }
        }
    }
}
