import SwiftUI

public struct HDPrimaryButton: View {
    public static let minimumHeight: CGFloat = 54
    public static let cornerRadius: CGFloat = 14

    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HDText(title, style: HDType.bodyStrong, color: .hdOnContext)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Self.minimumHeight)
        }
        .buttonStyle(.plain)
        .background(Color.hdContext, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
