import DesignSystem
import SwiftUI

enum CameraCaptureChrome {
    case tabRoot(title: String, onReview: () -> Void)
    case pushed(title: String, onBack: () -> Void)

    var title: String {
        switch self {
        case .tabRoot(let title, _), .pushed(let title, _):
            return title
        }
    }

    var onReview: (() -> Void)? {
        switch self {
        case .tabRoot(_, let onReview):
            return onReview
        case .pushed:
            return nil
        }
    }

    var onBack: (() -> Void)? {
        switch self {
        case .tabRoot:
            return nil
        case .pushed(_, let onBack):
            return onBack
        }
    }
}

struct CameraCaptureScreen: View {
    static let minimumPreviewHeight: CGFloat = 320
    static let photoCountBadgeInk: HDToken = .context
    static let navigationTitleInset: CGFloat = 44 + HDSpacing.margin
    static let flashIndicatorSide: CGFloat = 44

    let chrome: CameraCaptureChrome
    let capturedCount: Int
    let isCaptureAvailable: Bool
    let onCapture: () -> Void

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
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Self.navigationTitleInset)
                .accessibilityAddTraits(.isHeader)

            if let onBack = chrome.onBack {
                HStack {
                    Button(action: onBack) {
                        HDText("‹", style: HDType.chevron, color: .hdInk)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
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
                pill(hint, minimumScaleFactor: nil)
                .padding(HDSpacing.margin)
            }
            .overlay(alignment: .topTrailing) {
                pill("1×", minimumScaleFactor: 0.5)
                    .padding(HDSpacing.margin)
                    .accessibilityLabel("Zoom, 1 times")
            }
            .frame(maxWidth: .infinity, minHeight: Self.minimumPreviewHeight, maxHeight: .infinity)
            .clipped()
    }

    var hint: String {
        isCaptureAvailable
            ? "Get the whole fitting in frame, then a close-up"
            : "This build has no camera yet, so the shutter is off"
    }

    func pill(_ text: String, minimumScaleFactor: CGFloat?) -> some View {
        HDText(text, style: HDType.caption, color: .hdOnContext, singleLineMinimumScaleFactor: minimumScaleFactor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.hdContext, in: Capsule())
            .overlay(Capsule().stroke(Color.hdOnContext, lineWidth: 1))
    }

    private var cameraBar: some View {
        HStack(alignment: .center) {
            lastShotThumbnail
            Spacer(minLength: 0)
            shutter
            Spacer(minLength: 0)
            flashIndicator
        }
        .padding(.horizontal, HDSpacing.margin)
        .padding(.vertical, 20)
        .frame(minHeight: 132)
        .frame(maxWidth: .infinity)
        .background(Color.hdContext)
    }

    @ViewBuilder
    private var lastShotThumbnail: some View {
        if let onReview = chrome.onReview, capturedCount > 0 {
            Button(action: onReview) {
                thumbnail
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(minWidth: 48, minHeight: 48)
            .accessibilityLabel("Review \(capturedCount) captured photos")
            .accessibilityAddTraits(.isButton)
        } else {
            thumbnail
                .frame(minWidth: 48, minHeight: 48)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    capturedCount > 0 ? "\(capturedCount) photos captured" : "No photos captured yet"
                )
        }
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Color.hdSurfaceSunk)
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.hdOnContext, lineWidth: 1)
            )
            .overlay(alignment: .bottomTrailing) {
                if capturedCount > 0 {
                    HDText("\(capturedCount)", style: HDType.caption, color: Color(hdToken: Self.photoCountBadgeInk))
                        .padding(4)
                        .background(Color.hdOnContext, in: Circle())
                        .offset(x: 6, y: 6)
                }
            }
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isCaptureAvailable)
        .frame(minWidth: 72, minHeight: 72)
        .accessibilityLabel(isCaptureAvailable ? "Take photo" : "Take photo, no camera in this build")
        .accessibilityAddTraits(.isButton)
    }

    var flashIndicator: some View {
        Image(systemName: "bolt.slash.fill")
            .foregroundStyle(Color.hdOnContext)
            .frame(width: Self.flashIndicatorSide, height: Self.flashIndicatorSide)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Flash unavailable, this build has no camera")
    }
}
