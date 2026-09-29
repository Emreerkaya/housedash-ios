import SwiftUI

public struct HDIdentityRow: View {
    public static let minimumHeight: CGFloat = 54
    public static let cornerRadius: CGFloat = 14
    public static let minimumChangeTouchTarget: CGFloat = 44

    let identifier: String
    let onChange: () -> Void

    public init(identifier: String, onChange: @escaping () -> Void) {
        self.identifier = identifier
        self.onChange = onChange
    }

    public var body: some View {
        HStack(spacing: HDSpacing.item) {
            HDText(identifier, style: HDType.body, color: .hdInk)
                .accessibilityLabel("Identifier, \(identifier)")

            Spacer(minLength: HDSpacing.item)

            changeButton
        }
        .padding(.horizontal, 18)
        .frame(minHeight: Self.minimumHeight)
        .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    var changeButton: some View {
        Button(action: onChange) {
            HDText("Change", style: HDType.label, color: .hdInkSoft)
                .frame(minWidth: Self.minimumChangeTouchTarget, minHeight: Self.minimumChangeTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change")
        .accessibilityAddTraits(.isButton)
    }
}
