import DesignSystem
import SwiftUI

struct IntakeChosenRow: View {
    let primary: String
    let secondary: String
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: HDSpacing.item) {
            VStack(alignment: .leading, spacing: 2) {
                HDText(primary, style: HDType.bodyStrong, color: .hdInk)
                HDText(secondary, style: HDType.caption, color: .hdInkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            changeButton
        }
        .padding(.horizontal, 18)
        .frame(minHeight: HDIdentityRow.minimumHeight)
        .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: HDIdentityRow.cornerRadius, style: .continuous))
    }

    private var changeButton: some View {
        Button(action: onChange) {
            HDText("Change", style: HDType.label, color: .hdInkSoft)
                .frame(
                    minWidth: HDIdentityRow.minimumChangeTouchTarget,
                    minHeight: HDIdentityRow.minimumChangeTouchTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change")
        .accessibilityAddTraits(.isButton)
    }
}
