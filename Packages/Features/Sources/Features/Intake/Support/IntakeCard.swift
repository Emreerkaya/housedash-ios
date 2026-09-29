import DesignSystem
import SwiftUI

struct IntakeCard: View {
    static let width: CGFloat = 158
    static let photoHeight: CGFloat = 112

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let problem: ProblemSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            column
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(problem.title), \(problem.priceRange)")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var column: some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content.frame(width: Self.width, alignment: .leading)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: HDSpacing.item) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.hdSurfaceSunk)
                .frame(height: Self.photoHeight)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.hdInkFaint)
                }
                .accessibilityHidden(true)

            HDText(problem.title, style: HDType.label, color: .hdInk)
            HDText(problem.priceRange, style: HDType.caption, color: .hdInkSoft)
        }
    }
}
