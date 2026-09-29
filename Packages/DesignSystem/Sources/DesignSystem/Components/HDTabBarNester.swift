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
        case .diy: "toolbox.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

public struct HDTabBarNester: View {
    public static let height: CGFloat = 83

    public let active: HDNesterTab

    public init(active: HDNesterTab) {
        self.active = active
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(HDNesterTab.allCases) { tab in
                HDTabBarNesterButton(tab: tab, isActive: tab == active)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, minHeight: Self.height, alignment: .top)
        .background(Color.hdSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.hdHairline)
                .frame(height: 1)
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
                .font(.system(size: 24))
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
