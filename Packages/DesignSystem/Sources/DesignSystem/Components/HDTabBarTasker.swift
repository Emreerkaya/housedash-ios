import SwiftUI

public enum HDTaskerTab: String, CaseIterable, Identifiable, Sendable {
    case requests
    case calendar
    case earnings
    case profile

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .requests: "Requests"
        case .calendar: "Calendar"
        case .earnings: "Earnings"
        case .profile: "Profile"
        }
    }

    public var systemImage: String {
        switch self {
        case .requests: "list.bullet"
        case .calendar: "calendar"
        case .earnings: "dollarsign.circle.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

public struct HDTabBarTasker: View {
    public static let height: CGFloat = 83

    public let active: HDTaskerTab

    public init(active: HDTaskerTab) {
        self.active = active
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(HDTaskerTab.allCases) { tab in
                HDTabBarTaskerButton(tab: tab, isActive: tab == active)
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

private struct HDTabBarTaskerButton: View {
    let tab: HDTaskerTab
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
