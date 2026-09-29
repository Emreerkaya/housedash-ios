import SwiftUI

public extension View {
    func hdAppChrome() -> some View {
        modifier(HDAppChrome())
    }

    func hdFlowScreen() -> some View {
        modifier(HDFlowScreen())
    }
}

private struct HDAppChrome: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.hdGround.ignoresSafeArea()
            content
        }
        .tint(Color.hdInk)
    }
}

private struct HDFlowScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .background(Color.hdGround.ignoresSafeArea())
    }
}
