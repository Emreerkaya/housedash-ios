import SwiftUI
import DesignSystem

public struct HDRootTabView: View {
    @State private var selection: HDNesterTab = .fix

    public init() {}

    public var body: some View {
        NavigationStack {
            rootScreen(for: selection)
        }
        .safeAreaInset(edge: .bottom) {
            HDTabBarNester(active: selection) { tab in
                selection = tab
            }
        }
        .tint(Color.hdInk)
    }

    @ViewBuilder
    private func rootScreen(for tab: HDNesterTab) -> some View {
        switch tab {
        case .fix:
            FixHomeScreen()
        case .jobs:
            JobsHomeScreen()
        case .photo:
            PhotoHomeScreen()
        case .diy:
            ToolboxHomeScreen()
        case .profile:
            ProfileHomeScreen()
        }
    }
}
