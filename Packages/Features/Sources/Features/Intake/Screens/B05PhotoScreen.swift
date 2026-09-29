import DesignSystem
import SwiftUI

struct B05PhotoScreen<TabBar: View>: View {
    @Bindable var model: PhotoFirstFlowModel
    let tabBar: TabBar

    var body: some View {
        CameraCaptureScreen(
            chrome: .tabRoot(title: "Show us the problem"),
            capturedCount: model.photos.count,
            onCapture: { model.capturePhoto() },
            onReview: { model.reviewPhotos() }
        )
        .safeAreaInset(edge: .bottom) {
            tabBar
        }
    }
}
