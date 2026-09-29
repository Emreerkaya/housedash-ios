import DesignSystem
import SwiftUI

enum CameraCaptureChrome {
    case tabRoot(title: String)
    case pushed(title: String, onBack: () -> Void)

    var title: String {
        switch self {
        case .tabRoot(let title), .pushed(let title, _):
            return title
        }
    }
}

struct CameraCaptureScreen: View {
    let chrome: CameraCaptureChrome
    let capturedCount: Int
    let onCapture: () -> Void
    let onReview: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            nav
            preview
            cameraBar
        }
        .background(Color.hdGround.ignoresSafeArea(edges: .top))
    }

    private var nav: some View {
        ZStack {
            HDText(chrome.title, style: HDType.bodyStrong, color: .hdInk, singleLineMinimumScaleFactor: 0.6)
                .frame(maxWidth: 240)

            if case .pushed(_, let onBack) = chrome {
                HStack {
                    Button(action: onBack) {
                        HDText("‹", style: HDType.chevron, color: .hdInk)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .accessibilityAddTraits(.isButton)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, HDSpacing.margin)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var preview: some View {
        Color.hdContext
            .overlay {
                HDReticle()
                    .aspectRatio(1, contentMode: .fit)
                    .padding(40)
                    .opacity(0.55)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) {
                pill(
                    "Get the whole fitting in frame, then a close-up",
                    minimumScaleFactor: nil
                )
                .padding(HDSpacing.margin)
            }
            .overlay(alignment: .topTrailing) {
                pill("1×", minimumScaleFactor: 0.5)
                    .padding(HDSpacing.margin)
                    .accessibilityLabel("Zoom, 1 times")
            }
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .clipped()
    }

    private func pill(_ text: String, minimumScaleFactor: CGFloat?) -> some View {
        HDText(text, style: HDType.caption, color: .hdOnContext, singleLineMinimumScaleFactor: minimumScaleFactor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.hdContext, in: Capsule())
    }

    private var cameraBar: some View {
        HStack(alignment: .center) {
            lastShotThumbnail
            Spacer(minLength: 0)
            shutter
            Spacer(minLength: 0)
            flashButton
        }
        .padding(.horizontal, HDSpacing.margin)
        .padding(.vertical, 20)
        .frame(minHeight: 132)
        .frame(maxWidth: .infinity)
        .background(Color.hdContext)
    }

    private var lastShotThumbnail: some View {
        Button {
            onReview?()
        } label: {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.hdSurfaceSunk)
                .frame(width: 48, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.hdOnContext, lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    if capturedCount > 0 {
                        HDText("\(capturedCount)", style: HDType.caption, color: .hdInk)
                            .padding(4)
                            .background(Color.hdOnContext, in: Circle())
                            .offset(x: 6, y: 6)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(onReview == nil || capturedCount == 0)
        .frame(minWidth: 48, minHeight: 48)
        .accessibilityLabel(
            capturedCount > 0 ? "Review \(capturedCount) captured photos" : "No photos captured yet"
        )
        .accessibilityAddTraits(onReview != nil && capturedCount > 0 ? .isButton : [])
    }

    private var shutter: some View {
        Button(action: onCapture) {
            ZStack {
                Circle()
                    .stroke(Color.hdOnContext, lineWidth: 3)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(Color.hdOnContext)
                    .frame(width: 60, height: 60)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 72, minHeight: 72)
        .accessibilityLabel("Take photo")
        .accessibilityAddTraits(.isButton)
    }

    private var flashButton: some View {
        Button {
        } label: {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Color.hdOnContext)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Flash")
        .accessibilityAddTraits(.isButton)
    }
}
