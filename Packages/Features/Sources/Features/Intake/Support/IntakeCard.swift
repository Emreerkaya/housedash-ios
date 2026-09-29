import DesignSystem
import SwiftUI

struct IntakeCard: View {
    static let width: CGFloat = 158
    static let photoHeight: CGFloat = 112

    let problem: ProblemSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.hdSurfaceSunk)
                    .frame(width: Self.width, height: Self.photoHeight)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.hdInkFaint)
                    }

                HDText(problem.title, style: HDType.label, color: .hdInk)
                HDText(problem.priceRange, style: HDType.caption, color: .hdInkSoft)
            }
            .frame(width: Self.width, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(problem.title), \(problem.priceRange)")
        .accessibilityAddTraits(.isButton)
    }
}
