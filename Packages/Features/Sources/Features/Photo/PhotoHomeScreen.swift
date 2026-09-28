import SwiftUI
import DesignSystem

public struct PhotoHomeScreen: View {
    public init() {}

    public var body: some View {
        HDTabScreen(tab: .photo) {
            HDScreen {
                HDItemStack {
                    HDText("Photo", style: HDType.titleLarge)
                    HDText(
                        "Snap what broke. This is the photo-first path into the same fork every case ends at.",
                        style: HDType.body,
                        color: .hdInkSoft
                    )
                }

                HDItemStack {
                    HDText("Camera", style: HDType.section)
                    HDText(
                        "Placeholder destination. H09 through H06 assemble here.",
                        style: HDType.bodyDense,
                        color: .hdInkFaint
                    )
                }
            }
        }
    }
}
