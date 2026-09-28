import SwiftUI

public struct HDChip: View {
    public enum State: Sendable, Equatable {
        case selected
        case unselected
    }

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
            HDText(label, style: HDType.label, color: textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 18)
                .frame(width: 92, height: 40)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
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
