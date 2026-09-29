import SwiftUI
import DesignSystem

public struct PhotoHomeScreen<TabBar: View>: View {
    @State private var model: PhotoFirstFlowModel
    private let tabBar: TabBar

    public init(camera: PhotoCapture, @ViewBuilder tabBar: () -> TabBar) {
        _model = State(initialValue: PhotoFirstFlowModel(camera: camera))
        self.tabBar = tabBar()
    }

    public var body: some View {
        HDTabScreen(tab: .photo) {
            NavigationStack(path: $model.path) {
                B05PhotoScreen(model: model, tabBar: tabBar)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: PhotoFirstRoute.self) { route in
                        destination(for: route)
                            .navigationBarBackButtonHidden(true)
                    }
                    .overlay(alignment: .top) {
                        if let submission = model.completedSubmission {
                            IntakeCaseReadyNotice(submission: submission, tone: .onContext) {
                                model.acknowledgeCompletion()
                            }
                            .padding(HDSpacing.margin)
                        }
                    }
                    .hdAnnounce(model.announcement) { model.acknowledgeAnnouncement() }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: PhotoFirstRoute) -> some View {
        switch route {
        case .aFewDetails:
            B07AFewDetailsScreen(model: model)
        }
    }
}
