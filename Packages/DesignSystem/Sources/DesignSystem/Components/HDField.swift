import SwiftUI

public enum HDFieldMetrics {
    public static let minimumHeight: CGFloat = 54
    public static let padding: CGFloat = 18
    public static let cornerRadius: CGFloat = 14
}

public struct HDField<Accessory: View>: View {
    public static var minimumHeight: CGFloat { HDFieldMetrics.minimumHeight }

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

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsLabel {
                HDText(label, style: HDType.caption, color: .hdInkSoft)
            }

            HStack(alignment: axis == .vertical ? .top : .center, spacing: 0) {
                input
                    .hdTypeStyle(HDType.body)
                    .foregroundStyle(Color.hdInk)
                    .accessibilityIdentifier(label)
                    .accessibilityLabel(label)
                Spacer(minLength: 0)
                if let trailing {
                    HDText(trailing, style: HDType.label, color: .hdInkSoft)
                }
                accessory
            }
            .modifier(HDFieldBox(axis: axis))
        }
    }

    @ViewBuilder
    private var input: some View {
        if isSecure {
            SecureField(
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.hdInkFaint)
            ) {
                Text(placeholder)
            }
        } else {
            TextField(
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.hdInkFaint),
                axis: axis
            ) {
                Text(placeholder)
            }
            .lineLimit(axis == .vertical ? minimumVisibleLines : 1, reservesSpace: axis == .vertical)
        }
    }
}

private struct HDFieldBox: ViewModifier {
    let axis: Axis

    func body(content: Content) -> some View {
        Group {
            if axis == .vertical {
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
