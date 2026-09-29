import SwiftUI

public struct HDSecondaryButton: View {
    public static let minimumHeight: CGFloat = 52
    public static let cornerRadius: CGFloat = 14

    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HDText(title, style: HDType.bodyStrong, color: .hdInk)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Self.minimumHeight)
        }
        .buttonStyle(.plain)
        .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .stroke(Color.hdHairline, lineWidth: 1)
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
