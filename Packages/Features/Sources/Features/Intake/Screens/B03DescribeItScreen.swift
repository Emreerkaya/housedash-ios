import DesignSystem
import SwiftUI

struct B03DescribeItScreen: View {
    @Bindable var model: IntakeFlowModel
    let symptom: SymptomOption

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "Describe it", onBack: { model.goBack() })
            HDScreen {
                HDText("Step 2 of 2", style: HDType.caption, color: .hdInkFaint)

                if let problem = model.selectedProblem {
                    HDIdentityRow(
                        primary: problem.fullTitle,
                        secondary: "\(problem.category) · \(problem.priceRange) typical",
                        onChange: { model.goBack() }
                    )
                }

                if let rejection = model.rejection {
                    IntakeRejectionBanner(rejection: rejection)
                }

                HDItemStack {
                    HDField(
                        label: "What is it doing?",
                        placeholder: symptom.secondary,
                        text: $model.descriptionText
                    )
                    HDField(
                        label: "Where",
                        placeholder: "Street or neighbourhood",
                        text: $model.locationText,
                        trailing: model.selectedRoom.label
                    )
                }

                photos
            }
            .safeAreaInset(edge: .bottom) {
                HDActionBar(
                    ctaTitle: "See both ways to fix it",
                    isCTAEnabled: model.canSubmit,
                    disabledExplanation: "say what it is doing first"
                ) {
                    model.submit()
                }
            }
        }
        .hdAnnounce(model.announcement) { model.acknowledgeAnnouncement() }
        .hdTabBarHidden()
    }

    private var photos: some View {
        HDItemStack {
            HDGroupHeading("Photos")
            HStack(spacing: HDSpacing.item) {
                ForEach(0..<IntakeFlowModel.photoLimit, id: \.self) { index in
                    if index < model.photos.count {
                        IntakePhotoTile(kind: .captured(timestampLabel: model.photos[index].timestampLabel))
                    } else {
                        IntakePhotoTile(kind: .add(caption: "Add")) {
                            model.beginPhotoCapture()
                        }
                        .disabled(!model.isCameraAvailable)
                    }
                }
            }
            if model.photos.count < IntakeFlowModel.photoLimit {
                HDText(
                    "Add two more so nobody has to ask.",
                    style: HDType.caption,
                    color: .hdInkFaint
                )
            }
        }
    }
}
