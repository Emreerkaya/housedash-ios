import SwiftUI

public enum HDRole: String, CaseIterable, Identifiable, Sendable {
    case nester
    case tasker

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .nester: return "Nester"
        case .tasker: return "Tasker"
        }
    }
}

struct HDRoleIslandAppearance: Equatable {
    let weight: Font.Weight

    static func appearance(isSelected: Bool) -> HDRoleIslandAppearance {
        HDRoleIslandAppearance(weight: isSelected ? .semibold : .regular)
    }
}

struct HDRoleIslandTapExpansion: Shape {
    let vertical: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: 0, dy: -vertical))
    }
}

public struct HDRoleIsland: View {
    public static let size = CGSize(width: 186, height: 38)
    public static let thumbInset: CGFloat = 3
    public static let halfWidth: CGFloat = (size.width - thumbInset * 2) / 2
    public static let segmentHeight: CGFloat = size.height - thumbInset * 2
    public static let minimumTouchTarget: CGFloat = 44
    public static let selectedBoundaryWidth: CGFloat = 1.5

    static var tapExpansion: CGFloat {
        max(0, (minimumTouchTarget - segmentHeight) / 2)
    }

    let selected: HDRole
    let onSelect: (HDRole) -> Void

    public init(selected: HDRole, onSelect: @escaping (HDRole) -> Void) {
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            segment(.nester)
            segment(.tasker)
        }
        .padding(Self.thumbInset)
        .frame(minWidth: Self.size.width, minHeight: Self.size.height)
        .background(Color.hdSurface, in: Capsule())
        .overlay(Capsule().stroke(Color.hdHairline, lineWidth: 1))
    }

    func segment(_ role: HDRole) -> some View {
        let isSelected = role == selected
        let appearance = HDRoleIslandAppearance.appearance(isSelected: isSelected)

        return Button {
            onSelect(role)
        } label: {
            HDText(role.label, style: HDType.label, color: isSelected ? .hdOnContext : .hdInkSoft)
                .fontWeight(appearance.weight)
                .padding(.horizontal, 6)
                .frame(minWidth: Self.halfWidth, minHeight: Self.segmentHeight)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.hdContext)
                            .overlay(Capsule().strokeBorder(Color.hdOnContext, lineWidth: Self.selectedBoundaryWidth))
                    }
                }
        }
        .buttonStyle(.plain)
        .contentShape(HDRoleIslandTapExpansion(vertical: Self.tapExpansion))
        .accessibilityLabel(role.label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
