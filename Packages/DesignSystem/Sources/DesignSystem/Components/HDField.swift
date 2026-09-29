import SwiftUI

public struct HDField: View {
    private let label: String
    private let placeholder: String
    @Binding var text: String
    private let trailing: String?

    public init(label: String, placeholder: String, text: Binding<String>, trailing: String? = nil) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.trailing = trailing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HDText(label, style: HDType.caption, color: .hdInkSoft)

            HStack(spacing: 0) {
                TextField(
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(Color.hdInkFaint)
                ) {
                    Text(placeholder)
                }
                .hdTypeStyle(HDType.body)
                .foregroundStyle(Color.hdInk)
                Spacer(minLength: 0)
                if let trailing {
                    HDText(trailing, style: HDType.label, color: .hdInkSoft)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(Color.hdSurfaceSunk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hdHairline, lineWidth: 1)
            )
        }
    }
}
