import DesignSystem
import SwiftUI

public struct HDPasswordRevealButton: View {
    @Binding var isRevealed: Bool

    public init(isRevealed: Binding<Bool>) {
        self._isRevealed = isRevealed
    }

    public var body: some View {
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .foregroundStyle(Color.hdInkSoft)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        .accessibilityAddTraits(.isButton)
    }
}
