import SwiftUI
import DesignSystem

public struct HDRootTabView: View {
    @State private var selection: HDTab = .fix

    public init() {}

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(HDTab.allCases) { tab in
                NavigationStack {
                    rootScreen(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(Color.hdAccentHire)
    }

    @ViewBuilder
    private func rootScreen(for tab: HDTab) -> some View {
        switch tab {
        case .fix:
            FixHomeScreen()
        case .jobs:
            JobsHomeScreen()
        case .photo:
            PhotoHomeScreen()
        case .toolbox:
            ToolboxHomeScreen()
        case .profile:
            ProfileHomeScreen()
        }
    }
}
