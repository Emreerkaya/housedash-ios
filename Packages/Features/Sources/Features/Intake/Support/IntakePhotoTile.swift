import DesignSystem
import SwiftUI

enum IntakePhotoTileKind {
    case captured(timestampLabel: String)
    case add(caption: String)
}

struct IntakePhotoTile: View {
    let kind: IntakePhotoTileKind
    var height: CGFloat = 108
    var cornerRadius: CGFloat = 8
    var action: (() -> Void)?

    var body: some View {
        Group {
            switch kind {
            case .captured(let timestampLabel):
                capturedTile(timestampLabel: timestampLabel)
            case .add(let caption):
                addTile(caption: caption)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func capturedTile(timestampLabel: String) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.hdSurfaceSunk)
            .overlay(alignment: .bottomLeading) {
                HDText(timestampLabel, style: HDType.caption, color: .hdInkSoft)
                    .padding(8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo added at \(timestampLabel)")
    }

    private func addTile(caption: String) -> some View {
        Button {
            action?()
        } label: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.hdHairline, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .background(Color.hdGround, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    VStack(spacing: 4) {
                        HDText("+", style: HDType.section, color: .hdInkFaint)
                        HDText(caption, style: HDType.caption, color: .hdInkFaint)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(caption)
        .accessibilityIdentifier("photo-add-tile")
        .accessibilityAddTraits(.isButton)
    }
}
