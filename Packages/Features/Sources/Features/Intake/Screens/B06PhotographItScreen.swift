import DesignSystem
import SwiftUI

struct B06PhotographItScreen: View {
    @Bindable var model: IntakeFlowModel

    var body: some View {
        CameraCaptureScreen(
            chrome: .pushed(title: "Photograph it", onBack: { model.finishPhotoCapture() }),
            capturedCount: model.photos.count,
            onCapture: { model.capturePhoto() },
            onReview: nil
        )
        .hdTabBarHidden()
    }
}
