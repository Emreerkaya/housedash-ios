import SwiftUI

public struct HDIdentityRow: View {
    public static let minimumHeight: CGFloat = 54
    public static let cornerRadius: CGFloat = 14
    public static let minimumChangeTouchTarget: CGFloat = 44
    public static let stackedVerticalPadding: CGFloat = 14
    public static let horizontalPadding: CGFloat = 18

    public static func stacks(at size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let primary: String
    private let secondary: String?
    let onChange: () -> Void

    public init(identifier: String, onChange: @escaping () -> Void) {
        self.primary = identifier
        self.secondary = nil
        self.onChange = onChange
    }

    public init(primary: String, secondary: String, onChange: @escaping () -> Void) {
        self.primary = primary
        self.secondary = secondary
        self.onChange = onChange
    }

    public var body: some View {
        stack
            .padding(.horizontal, Self.horizontalPadding)
            .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var stack: some View {
        if Self.stacks(at: dynamicTypeSize) {
            VStack(alignment: .leading, spacing: HDSpacing.item) {
                summary
                changeButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.stackedVerticalPadding)
        } else {
            HStack(spacing: HDSpacing.item) {
                summary
                Spacer(minLength: HDSpacing.item)
                changeButton
            }
            .frame(minHeight: Self.minimumHeight)
        }
    }

    @ViewBuilder
    var summary: some View {
        if let secondary {
            VStack(alignment: .leading, spacing: 2) {
                HDText(primary, style: HDType.bodyStrong, color: .hdInk)
                HDText(secondary, style: HDType.caption, color: .hdInkSoft)
            }
            .accessibilityElement(children: .combine)
        } else {
            HDText(primary, style: HDType.body, color: .hdInk, singleLineMinimumScaleFactor: 0.4)
                .accessibilityLabel("Identifier, \(primary)")
        }
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
