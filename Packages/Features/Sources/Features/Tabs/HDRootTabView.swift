import SwiftUI
import DesignSystem

public struct HDRootTabView: View {
    @State private var selection: HDNesterTab = .fix
    @State private var isTabBarHidden = false
    private let problemCatalogue: ProblemCatalogue
    private let camera: PhotoCapture

    public init(problemCatalogue: ProblemCatalogue, camera: PhotoCapture) {
        self.problemCatalogue = problemCatalogue
        self.camera = camera
    }

    public var body: some View {
        Group {
            if selection == .photo {
                PhotoHomeScreen(camera: camera, tabBar: { tabBar })
            } else {
                rootScreen(for: selection)
                    .onHDTabBarHiddenChange { isTabBarHidden = $0 }
                    .safeAreaInset(edge: .bottom) {
                        if !isTabBarHidden {
                            tabBar
                        }
                    }
            }
        }
        .tint(Color.hdInk)
    }

    @ViewBuilder
    private func rootScreen(for tab: HDNesterTab) -> some View {
        switch tab {
        case .fix:
            FixHomeScreen(problemCatalogue: problemCatalogue, camera: camera)
        case .jobs:
            JobsHomeScreen()
        case .photo:
            EmptyView()
        case .diy:
            ToolboxHomeScreen()
        case .profile:
            ProfileHomeScreen()
        }
    }

    private var tabBar: some View {
        HDTabBarNester(active: selection) { tab in
            selection = tab
        }
    }
}
