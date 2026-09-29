import DesignSystem
import PhotosUI
import SwiftUI
import UIKit

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
    static let photoCountBadgeCircle: HDToken = .onContext
    static let navigationTitleInset: CGFloat = 44 + HDSpacing.margin
    static let flashIndicatorSide: CGFloat = 44

    let chrome: CameraCaptureChrome
    let capturedCount: Int
    let isCaptureAvailable: Bool
    let permission: CameraPermission
    let onCapture: () -> Void
    let onPickFromLibrary: (String) -> Void

    @State private var pickerSelection: PhotosPickerItem?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            nav
            if permission == .denied {
                permissionDeniedState
            } else {
                preview
                cameraBar
            }
        }
        .background(Color.hdGround.ignoresSafeArea(edges: .top))
        .onChange(of: pickerSelection) { _, newValue in
            guard let newValue else { return }
            onPickFromLibrary(newValue.itemIdentifier ?? UUID().uuidString)
            pickerSelection = nil
        }
    }

    private var permissionDeniedState: some View {
        VStack(spacing: HDSpacing.item) {
            Spacer(minLength: 0)
            HDText("Camera access is off", style: HDType.section, color: .hdInk)
            HDText(
                "HouseDash needs the camera to photograph the problem. Turn it on in Settings.",
                style: HDType.body,
                color: .hdInkSoft
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, HDSpacing.margin)
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.borderedProminent)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: Self.minimumPreviewHeight, maxHeight: .infinity)
        .padding(HDSpacing.margin)
        .accessibilityElement(children: .combine)
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
        if isCaptureAvailable { return "Get the whole fitting in frame, then a close-up" }
        switch permission {
        case .notDetermined: return "Waiting for camera permission…"
        case .denied: return ""
        case .authorized: return "This build has no camera yet, so the shutter is off"
        }
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
        } else if capturedCount == 0 {
            PhotosPicker(selection: $pickerSelection, matching: .images) {
                thumbnail
                    .contentShape(Rectangle())
            }
            .frame(minWidth: 48, minHeight: 48)
            .accessibilityLabel("Add a photo from your library")
            .accessibilityAddTraits(.isButton)
        } else {
            thumbnail
                .frame(minWidth: 48, minHeight: 48)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(capturedCount) photos captured")
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
                    HDCountBadge(count: capturedCount, on: Self.photoCountBadgeCircle)
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
        .accessibilityLabel(isCaptureAvailable ? "Take photo" : "Take photo, camera unavailable")
        .accessibilityAddTraits(.isButton)
    }

    var flashIndicator: some View {
        Image(systemName: "bolt.slash.fill")
            .foregroundStyle(Color.hdOnContext)
            .frame(width: Self.flashIndicatorSide, height: Self.flashIndicatorSide)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Flash unavailable")
    }
}
