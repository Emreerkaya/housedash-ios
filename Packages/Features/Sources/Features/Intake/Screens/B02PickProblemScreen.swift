import DesignSystem
import SwiftUI

struct B02PickProblemScreen: View {
    @Bindable var model: IntakeFlowModel

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "Pick the problem", onBack: { model.goBack() })
            HDScreen {
                HDText("Step 1 of 2", style: HDType.caption, color: .hdInkFaint)
                HDItemStack {
                    ForEach(model.symptoms) { symptom in
                        IntakePickRow(
                            symptom: symptom,
                            isSelected: model.selectedSymptom == symptom
                        ) {
                            model.selectSymptomForReview(symptom)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HDActionBar(
                    ctaTitle: "Next",
                    isCTAEnabled: model.canConfirmSymptom,
                    disabledExplanation: "pick a problem first"
                ) {
                    model.confirmSymptomSelection()
                }
            }
        }
        .hdAnnounce(model.announcement) { model.acknowledgeAnnouncement() }
        .hdTabBarHidden()
    }
}
