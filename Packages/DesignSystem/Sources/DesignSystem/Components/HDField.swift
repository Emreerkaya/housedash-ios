import SwiftUI

public struct HDField<Accessory: View>: View {
    public static var minimumHeight: CGFloat { 54 }

    private let label: String
    private let placeholder: String
    @Binding var text: String
    private let trailing: String?
    private let isSecure: Bool
    private let accessory: Accessory

    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        trailing: String? = nil,
        isSecure: Bool = false,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.trailing = trailing
        self.isSecure = isSecure
        self.accessory = accessory()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HDText(label, style: HDType.caption, color: .hdInkSoft)

            HStack(spacing: 0) {
                Group {
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
                            prompt: Text(placeholder).foregroundStyle(Color.hdInkFaint)
                        ) {
                            Text(placeholder)
                        }
                    }
                }
                .hdTypeStyle(HDType.body)
                .foregroundStyle(Color.hdInk)
                Spacer(minLength: 0)
                if let trailing {
                    HDText(trailing, style: HDType.label, color: .hdInkSoft)
                }
                accessory
            }
            .padding(.horizontal, 18)
            .frame(minHeight: Self.minimumHeight)
            .background(Color.hdSurfaceSunk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hdHairline, lineWidth: 1)
            )
        }
    }
}
