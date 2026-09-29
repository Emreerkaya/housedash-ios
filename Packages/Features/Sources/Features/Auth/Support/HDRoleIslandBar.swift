import DesignSystem
import SwiftUI

extension HDRole {
    var islandSide: HDRoleIsland.Side {
        switch self {
        case .nester: return .leading
        case .tasker: return .trailing
        }
    }

    init(islandSide: HDRoleIsland.Side) {
        switch islandSide {
        case .leading: self = .nester
        case .trailing: self = .tasker
        }
    }
}

public struct HDRoleIslandBar: View {
    let selected: HDRole
    let onSelect: (HDRole) -> Void

    public init(selected: HDRole, onSelect: @escaping (HDRole) -> Void) {
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack {
            Spacer(minLength: 0)
            HDRoleIsland(
                leading: HDRole.nester.label,
                trailing: HDRole.tasker.label,
                selected: selected.islandSide
            ) { side in
                onSelect(HDRole(islandSide: side))
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let other: HDRole = selected == .nester ? .tasker : .nester
                        withAnimation(.easeOut(duration: 0.3)) {
                            onSelect(other)
                        }
                    }
            )
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}
