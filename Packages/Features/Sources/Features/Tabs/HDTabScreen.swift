import SwiftUI

public struct HDTabScreen<Content: View>: View {
    private let tab: HDTab
    private let content: Content

    public init(tab: HDTab, @ViewBuilder content: () -> Content) {
        self.tab = tab
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.hdActiveTab, tab)
    }
}
