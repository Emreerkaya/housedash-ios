import DesignSystem
import SwiftUI

struct IntakePickRow: View {
    let symptom: SymptomOption
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: HDSpacing.item) {
                VStack(alignment: .leading, spacing: 2) {
                    HDText(symptom.primary, style: HDType.bodyStrong, color: .hdInk)
                    HDText(symptom.secondary, style: HDType.caption, color: .hdInkSoft)
                }
                Spacer(minLength: HDSpacing.item)
                if let priceRange = symptom.priceRange {
                    HDText(priceRange, style: HDType.factRow, color: .hdInkSoft)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hdContext, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var accessibilityLabel: String {
        if let priceRange = symptom.priceRange {
            return "\(symptom.primary), \(symptom.secondary), \(priceRange)"
        }
        return "\(symptom.primary), \(symptom.secondary)"
    }
}
