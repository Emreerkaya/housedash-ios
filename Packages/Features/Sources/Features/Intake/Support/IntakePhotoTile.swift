import DesignSystem
import SwiftUI

enum IntakePhotoTileKind {
    case captured(timestampLabel: String)
    case add(caption: String)
}

struct IntakePhotoTile: View {
    let kind: IntakePhotoTileKind
    var minimumHeight: CGFloat = 108
    var cornerRadius: CGFloat = 8
    var action: (() -> Void)?

    var body: some View {
        switch kind {
        case .captured(let timestampLabel):
            capturedTile(timestampLabel: timestampLabel)
        case .add(let caption):
            addTile(caption: caption)
        }
    }

    private func capturedTile(timestampLabel: String) -> some View {
        HDText(timestampLabel, style: HDType.caption, color: .hdInkSoft)
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .bottomLeading)
            .background(Color.hdSurfaceSunk, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo added at \(timestampLabel)")
    }

    private func addTile(caption: String) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 4) {
                HDText("+", style: HDType.section, color: .hdInkFaint)
                HDText(caption, style: HDType.caption, color: .hdInkFaint)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .background(Color.hdGround, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.hdHairline, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(caption)
        .accessibilityIdentifier("photo-add-tile")
        .accessibilityAddTraits(.isButton)
    }
}
