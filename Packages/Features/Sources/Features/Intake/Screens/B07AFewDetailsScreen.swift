import DesignSystem
import SwiftUI

struct B07AFewDetailsScreen: View {
    @Bindable var model: PhotoFirstFlowModel

    private let columns = [GridItem(.flexible(), spacing: HDSpacing.item), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "A few details", onBack: { model.path.removeLast() })
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
                HDActionBar(ctaTitle: "See both ways to fix it") {
                    model.submit()
                }
            }
        }
        .background(Color.hdGround.ignoresSafeArea())
    }

    private var photos: some View {
        HDItemStack {
            HDText("Photos", style: HDType.bodyStrong, color: .hdInk)
            LazyVGrid(columns: columns, spacing: HDSpacing.item) {
                ForEach(0..<4, id: \.self) { index in
                    if index < model.photos.count {
                        IntakePhotoTile(
                            kind: .captured(timestampLabel: model.photos[index].timestampLabel),
                            height: 124,
                            cornerRadius: 10
                        )
                    } else {
                        IntakePhotoTile(
                            kind: .add(caption: "Add from your phone"),
                            height: 124,
                            cornerRadius: 10
                        ) {
                            model.capturePhoto()
                        }
                    }
                }
            }
        }
    }
}
