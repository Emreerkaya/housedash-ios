import SwiftUI

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

public struct HDRoleIsland: View, HDDrawsAStateMark {
    public enum Side: String, CaseIterable, Identifiable, Sendable {
        case leading
        case trailing

        public var id: String { rawValue }
    }

    public static let size = CGSize(width: 186, height: 38)
    public static let thumbInset: CGFloat = 3
    public static let halfWidth: CGFloat = (size.width - thumbInset * 2) / 2
    public static let segmentHeight: CGFloat = size.height - thumbInset * 2
    public static let minimumTouchTarget: CGFloat = 44
    public static let selectedBoundaryWidth: CGFloat = 1.5

    static var tapExpansion: CGFloat {
        max(0, (minimumTouchTarget - segmentHeight) / 2)
    }

    let leadingTitle: String
    let trailingTitle: String
    let selected: Side
    let onSelect: (Side) -> Void

    public init(
        leading: String,
        trailing: String,
        selected: Side,
        onSelect: @escaping (Side) -> Void
    ) {
        self.leadingTitle = leading
        self.trailingTitle = trailing
        self.selected = selected
        self.onSelect = onSelect
    }

    public func title(of side: Side) -> String {
        switch side {
        case .leading: return leadingTitle
        case .trailing: return trailingTitle
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            segment(.leading)
            segment(.trailing)
        }
        .padding(Self.thumbInset)
        .frame(minWidth: Self.size.width, minHeight: Self.size.height)
        .background(Color.hdSurface, in: Capsule())
        .overlay(Capsule().stroke(Color.hdHairline, lineWidth: 1))
    }

    func segment(_ side: Side) -> some View {
        let isSelected = side == selected
        let appearance = HDRoleIslandAppearance.appearance(isSelected: isSelected)
        let title = title(of: side)

        return Button {
            onSelect(side)
        } label: {
            HDText(title, style: HDType.label, color: isSelected ? .hdOnContext : .hdInkSoft)
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
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
