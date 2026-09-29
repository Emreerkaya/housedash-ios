import SwiftUI

public enum HDNesterTab: String, CaseIterable, Identifiable, Sendable {
    case fix
    case jobs
    case photo
    case diy
    case profile

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .fix: "Fix"
        case .jobs: "Jobs"
        case .photo: "Photo"
        case .diy: "DIY"
        case .profile: "Profile"
        }
    }

    public var systemImage: String {
        switch self {
        case .fix: "wrench.and.screwdriver.fill"
        case .jobs: "list.bullet"
        case .photo: "camera.fill"
        case .diy: "hammer.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

public struct HDTabBarNester: View {
    public let active: HDNesterTab
    public let onSelect: (HDNesterTab) -> Void

    public init(active: HDNesterTab, onSelect: @escaping (HDNesterTab) -> Void) {
        self.active = active
        self.onSelect = onSelect
    }

    public var body: some View {
        HDTabBarChrome {
            ForEach(HDNesterTab.allCases) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    HDTabBarNesterButton(tab: tab, isActive: tab == active)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == active ? .isSelected : [])
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct HDTabBarButtonAppearance: Equatable {
    let iconOpacity: Double
    let labelWeight: Font.Weight

    static func appearance(isActive: Bool) -> HDTabBarButtonAppearance {
        HDTabBarButtonAppearance(
            iconOpacity: isActive ? 1.0 : 0.4,
            labelWeight: isActive ? .semibold : .regular
        )
    }
}

private struct HDTabBarNesterButton: View {
    let tab: HDNesterTab
    let isActive: Bool

    var body: some View {
        let appearance = HDTabBarButtonAppearance.appearance(isActive: isActive)
        VStack(spacing: 5) {
            Image(systemName: tab.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: HDTabBarChromeMetrics.iconSize, height: HDTabBarChromeMetrics.iconSize)
                .foregroundStyle(Color.hdInk)
                .opacity(appearance.iconOpacity)
            Text(tab.label)
                .font(.system(size: 13, weight: appearance.labelWeight))
                .tracking(-0.042)
                .foregroundStyle(isActive ? Color.hdInk : Color.hdInkFaint)
        }
        .accessibilityElement(children: .combine)
    }
}

enum HDTabBarChromeMetrics {
    static let iconSize: CGFloat = 24
}

struct HDTabBarChrome<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.hdHairline)
                .frame(height: 1)

            HStack(spacing: 0) {
                content
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(Color.hdSurface.ignoresSafeArea(edges: .bottom))
        .frame(maxWidth: .infinity)
    }
}
