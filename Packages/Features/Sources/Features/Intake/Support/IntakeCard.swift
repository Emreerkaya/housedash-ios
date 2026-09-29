import DesignSystem
import SwiftUI

enum IntakeCardPhotoResolution: Equatable {
    case asset(name: String)
    case emptyState
}

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

    static func resolvePhoto(for problem: ProblemSummary, in bundle: Bundle) -> IntakeCardPhotoResolution {
        switch HDBundledImage.resolution(named: problem.id, in: bundle) {
        case .found: .asset(name: problem.id)
        case .missing: .emptyState
        }
    }

    private var resolution: IntakeCardPhotoResolution {
        Self.resolvePhoto(for: problem, in: .module)
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
            photo
            HDText(problem.title, style: HDType.label, color: .hdInk)
            HDText(problem.priceRange, style: HDType.caption, color: .hdInkSoft)
        }
    }

    @ViewBuilder
    private var photo: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.hdSurfaceSunk)
            .frame(height: Self.photoHeight)
            .overlay { photoContent }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var photoContent: some View {
        switch resolution {
        case .asset(let name):
            if let image = HDBundledImage.image(named: name, in: .module) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: Self.photoHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                emptyState
            }
        case .emptyState:
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 22))
                .foregroundStyle(Color.hdInkFaint)
            HDText("No photo yet", style: HDType.caption, color: .hdInkFaint)
        }
    }
}
