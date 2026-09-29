import DesignSystem
import SwiftUI

struct IntakeComposer: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(
            text: $text,
            prompt: Text(placeholder).foregroundStyle(Color.hdInkFaint),
            axis: .vertical
        ) {
            Text(placeholder)
        }
        .hdTypeStyle(HDType.body)
        .foregroundStyle(Color.hdInk)
        .accessibilityIdentifier("composer")
        .lineLimit(4...)
        .padding(18)
        .background(Color.hdSurfaceSunk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hdHairline, lineWidth: 1)
        )
        .accessibilityLabel("In your own words")
    }
}
