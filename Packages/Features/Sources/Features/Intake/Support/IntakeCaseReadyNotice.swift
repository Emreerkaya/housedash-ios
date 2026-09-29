import DesignSystem
import SwiftUI

enum IntakeNoticeTone {
    case onSurface
    case onContext

    var fill: Color {
        switch self {
        case .onSurface: .hdSurface
        case .onContext: .hdContext
        }
    }

    var text: Color {
        switch self {
        case .onSurface: .hdInk
        case .onContext: .hdOnContext
        }
    }

    var supportingText: Color {
        switch self {
        case .onSurface: .hdInkSoft
        case .onContext: .hdOnContext
        }
    }
}

struct IntakeCaseReadyNotice: View {
    static let unbuiltForkExplanation =
        "Comparing the DIY guide against nearby people isn't built yet — that's next."

    let submission: IntakeSubmission
    let tone: IntakeNoticeTone
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HDText(headline, style: HDType.bodyStrong, color: tone.text)
                .accessibilityAddTraits(.isHeader)
            HDText(Self.unbuiltForkExplanation, style: HDType.caption, color: tone.supportingText)
            Button("Got it", action: onAcknowledge)
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .hdTypeStyle(HDType.label)
                .foregroundStyle(tone.supportingText)
                .accessibilityAddTraits(.isButton)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var headline: String {
        let photoCount = submission.photos.count
        guard photoCount > 0 else { return "Case ready: \"\(submission.description.text)\"" }
        let noun = photoCount == 1 ? "photo" : "photos"
        return "Case ready: \"\(submission.description.text)\", \(photoCount) \(noun)"
    }
}
