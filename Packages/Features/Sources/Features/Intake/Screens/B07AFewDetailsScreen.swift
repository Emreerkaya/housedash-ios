import DesignSystem
import SwiftUI

struct B07AFewDetailsScreen: View {
    @Bindable var model: PhotoFirstFlowModel

    private let columns = [GridItem(.flexible(), spacing: HDSpacing.item), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "A few details", onBack: { model.goBack() })
            HDScreen {
                if let rejection = model.rejection {
                    IntakeRejectionBanner(rejection: rejection)
                }

                HDField(
                    label: "What is it doing?",
                    placeholder: "Drips constantly, worse when hot",
                    text: $model.descriptionText
                )

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
    }

    private var addTileCaption: String {
        model.isCameraAvailable ? "Add from your phone" : "No camera in this build"
    }

    private var photos: some View {
        HDItemStack {
            HDGroupHeading("Photos")
            LazyVGrid(columns: columns, spacing: HDSpacing.item) {
                ForEach(0..<PhotoFirstFlowModel.photoLimit, id: \.self) { index in
                    if index < model.photos.count {
                        IntakePhotoTile(
                            kind: .captured(timestampLabel: model.photos[index].timestampLabel),
                            minimumHeight: 124,
                            cornerRadius: 10
                        )
                    } else {
                        IntakePhotoTile(
                            kind: .add(caption: addTileCaption),
                            minimumHeight: 124,
                            cornerRadius: 10
                        ) {
                            model.capturePhoto()
                        }
                        .disabled(!model.isCameraAvailable)
                    }
                }
            }
        }
    }
}
