import DesignSystem
import SwiftUI

struct IntakePickRow: View {
    static let horizontalPadding: CGFloat = 18

    static func stacks(at size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let symptom: SymptomOption
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            layout
            .padding(.horizontal, Self.horizontalPadding)
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

    @ViewBuilder
    private var layout: some View {
        if Self.stacks(at: dynamicTypeSize) {
            VStack(alignment: .leading, spacing: HDSpacing.item) {
                summary
                price
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .center, spacing: HDSpacing.item) {
                summary
                Spacer(minLength: HDSpacing.item)
                price
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 2) {
            HDText(symptom.primary, style: HDType.bodyStrong, color: .hdInk)
            HDText(symptom.secondary, style: HDType.caption, color: .hdInkSoft)
        }
    }

    @ViewBuilder
    private var price: some View {
        if let priceRange = symptom.priceRange {
            HDText(priceRange, style: HDType.factRow, color: .hdInkSoft)
        }
    }

    private var accessibilityLabel: String {
        if let priceRange = symptom.priceRange {
            return "\(symptom.primary), \(symptom.secondary), \(priceRange)"
        }
        return "\(symptom.primary), \(symptom.secondary)"
    }
}
