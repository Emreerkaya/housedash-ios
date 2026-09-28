import SwiftUI

public struct HDScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            HDGroupStack {
                content
            }
            .padding(.horizontal, HDSpacing.margin)
            .padding(.vertical, HDSpacing.margin)
        }
        .background(Color.hdGround)
    }
}
