import SwiftUI

public enum HDFieldMetrics {
    public static let minimumHeight: CGFloat = 54
    public static let padding: CGFloat = 18
    public static let cornerRadius: CGFloat = 14
}

public struct HDField<Accessory: View>: View {
    public static var minimumHeight: CGFloat { HDFieldMetrics.minimumHeight }

    public static func wraps(at size: DynamicTypeSize, axis: Axis) -> Bool {
        axis == .vertical || size.isAccessibilitySize
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let label: String
    private let placeholder: String
    @Binding var text: String
    private let trailing: String?
    private let isSecure: Bool
    private let axis: Axis
    private let showsLabel: Bool
    private let minimumVisibleLines: Int
    private let accessory: Accessory

    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        trailing: String? = nil,
        isSecure: Bool = false,
        axis: Axis = .horizontal,
        showsLabel: Bool = true,
        minimumVisibleLines: Int = 1,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.trailing = trailing
        self.isSecure = isSecure
        self.axis = axis
        self.showsLabel = showsLabel
        self.minimumVisibleLines = minimumVisibleLines
        self.accessory = accessory()
    }

    private var wraps: Bool { Self.wraps(at: dynamicTypeSize, axis: axis) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsLabel {
                HDText(label, style: HDType.caption, color: .hdInkSoft)
            }

            HStack(alignment: wraps ? .top : .center, spacing: 0) {
                ZStack(alignment: wraps ? .topLeading : .leading) {
                    if text.isEmpty {
                        HDText(placeholder, style: HDType.body, color: .hdInkFaint)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    input
                        .hdTypeStyle(HDType.body)
                        .foregroundStyle(Color.hdInk)
                        .accessibilityIdentifier(label)
                        .accessibilityLabel(label)
                        .accessibilityValue(text.isEmpty ? placeholder : text)
                }
                Spacer(minLength: 0)
                if let trailing {
                    HDText(trailing, style: HDType.label, color: .hdInkSoft)
                }
                accessory
            }
            .modifier(HDFieldBox(wraps: wraps))
        }
    }

    @ViewBuilder
    private var input: some View {
        if isSecure {
            SecureField(text: $text, prompt: nil) {
                Text(placeholder)
            }
        } else if axis == .vertical {
            TextField(text: $text, prompt: nil, axis: .vertical) {
                Text(placeholder)
            }
            .lineLimit(minimumVisibleLines, reservesSpace: true)
        } else if wraps {
            TextField(text: $text, prompt: nil, axis: .vertical) {
                Text(placeholder)
            }
        } else {
            TextField(text: $text, prompt: nil, axis: .horizontal) {
                Text(placeholder)
            }
            .lineLimit(1)
        }
    }
}

private struct HDFieldBox: ViewModifier {
    let wraps: Bool

    func body(content: Content) -> some View {
        Group {
            if wraps {
                content.padding(HDFieldMetrics.padding)
            } else {
                content
                    .padding(.horizontal, HDFieldMetrics.padding)
                    .frame(minHeight: HDFieldMetrics.minimumHeight)
            }
        }
        .background(
            Color.hdSurfaceSunk,
            in: RoundedRectangle(cornerRadius: HDFieldMetrics.cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HDFieldMetrics.cornerRadius, style: .continuous)
                .stroke(Color.hdHairline, lineWidth: 1)
        )
    }
}
