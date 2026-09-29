import DesignSystem
import SwiftUI

struct B05PhotoScreen<TabBar: View>: View {
    @Bindable var model: PhotoFirstFlowModel
    let tabBar: TabBar

    var body: some View {
        CameraCaptureScreen(
            chrome: .tabRoot(title: "Show us the problem", onReview: { model.reviewPhotos() }),
            capturedCount: model.photos.count,
            isCaptureAvailable: model.isCameraAvailable,
            permission: model.cameraPermission,
            onCapture: { model.capturePhoto() },
            onPickFromLibrary: { model.adoptLibraryPhoto(identifier: $0) }
        )
        .safeAreaInset(edge: .bottom) {
            tabBar
        }
    }
}
