import SwiftUI

public struct HDChip: View {
    public enum State: Sendable, Equatable {
        case selected
        case unselected
    }

    public static let minimumHeight: CGFloat = 44

    private let label: String
    private let state: State
    private let action: () -> Void

    public init(_ label: String, state: State, action: @escaping () -> Void) {
        self.label = label
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HDText(label, style: HDType.label, color: textColor, singleLineMinimumScaleFactor: 0.6)
                .padding(.horizontal, 18)
                .frame(minHeight: Self.minimumHeight)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    var fill: Color {
        switch state {
        case .selected:
            return .hdContext
        case .unselected:
            return .hdSurfaceSunk
        }
    }

    var textColor: Color {
        switch state {
        case .selected:
            return .hdOnContext
        case .unselected:
            return .hdInk
        }
    }
}
