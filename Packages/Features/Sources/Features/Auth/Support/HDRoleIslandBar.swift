import DesignSystem
import SwiftUI

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
            HDRoleIsland(selected: selected, onSelect: onSelect)
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
