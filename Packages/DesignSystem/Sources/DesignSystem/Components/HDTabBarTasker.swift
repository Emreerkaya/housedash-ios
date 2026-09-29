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
    public let active: HDTaskerTab
    public let onSelect: (HDTaskerTab) -> Void

    public init(active: HDTaskerTab, onSelect: @escaping (HDTaskerTab) -> Void) {
        self.active = active
        self.onSelect = onSelect
    }

    public var body: some View {
        HDTabBarChrome {
            ForEach(HDTaskerTab.allCases) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    HDTabBarTaskerButton(tab: tab, isActive: tab == active)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == active ? .isSelected : [])
                .frame(maxWidth: .infinity)
            }
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
