import SwiftUI
import DesignSystem

public struct HDTabScreen<Content: View>: View {
    private let tab: HDNesterTab
    private let content: Content

    public init(tab: HDNesterTab, @ViewBuilder content: () -> Content) {
        self.tab = tab
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.hdActiveTab, tab)
    }
}
