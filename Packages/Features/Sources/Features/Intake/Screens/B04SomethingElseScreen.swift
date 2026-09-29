import DesignSystem
import SwiftUI

struct B04SomethingElseScreen: View {
    @Bindable var model: IntakeFlowModel

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "In your own words", onBack: { model.goBack() })
            HDScreen {
                HDText(
                    "The more you say, the fewer questions you get back.",
                    style: HDType.body,
                    color: .hdInkSoft
                )

                if let rejection = model.rejection {
                    IntakeRejectionBanner(rejection: rejection)
                }

                IntakeComposer(
                    placeholder: "The radiator in the back bedroom never gets hot, even with the valve fully open.",
                    text: $model.descriptionText
                )
            }
            .safeAreaInset(edge: .bottom) {
                HDActionBar(ctaTitle: "See both ways to fix it") {
                    model.submit()
                }
            }
        }
        .background(Color.hdGround.ignoresSafeArea())
        .hdTabBarHidden()
    }
}
