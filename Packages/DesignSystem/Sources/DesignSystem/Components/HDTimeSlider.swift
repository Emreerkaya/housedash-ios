import SwiftUI

public enum HDTimeSliderMode: Sendable, Equatable {
    case range(start: String, end: String)
    case single(String)
}

public struct HDTimeSlider: View {
    public static let size = CGSize(width: 353, height: 104)

    private static let trackHeight: CGFloat = 3
    private static let trackY: CGFloat = 83
    private static let thumbSize: CGFloat = 24
    private static let thumbY: CGFloat = 74
    private static let pillHeight: CGFloat = 32
    private static let pillY: CGFloat = 8

    public let mode: HDTimeSliderMode

    public init(mode: HDTimeSliderMode) {
        self.mode = mode
    }

    private var thumbXs: [CGFloat] {
        switch mode {
        case .range: [74, 268]
        case .single: [150]
        }
    }

    private var pillXs: [CGFloat] {
        switch mode {
        case .range: [52.5, 250]
        case .single: [132]
        }
    }

    private var labels: [String] {
        switch mode {
        case let .range(start, end): [start, end]
        case let .single(label): [label]
        }
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Self.trackHeight / 2)
                .fill(Color.hdHairline)
                .frame(width: Self.size.width, height: Self.trackHeight)
                .offset(x: 0, y: Self.trackY)

            if case .range = mode, let leading = thumbXs.first, let trailing = thumbXs.last {
                RoundedRectangle(cornerRadius: Self.trackHeight / 2)
                    .fill(Color.hdContext)
                    .frame(width: (trailing - leading), height: Self.trackHeight)
                    .offset(x: leading + Self.thumbSize / 2, y: Self.trackY)
            }

            ForEach(thumbXs.indices, id: \.self) { index in
                stem(thumbX: thumbXs[index])
                pill(x: pillXs[index], label: labels[index])
                thumb(x: thumbXs[index])
            }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }

    private func thumb(x: CGFloat) -> some View {
        Circle()
            .fill(Color.hdContext)
            .frame(width: Self.thumbSize, height: Self.thumbSize)
            .offset(x: x, y: Self.thumbY)
    }

    private func stem(thumbX: CGFloat) -> some View {
        let pillBottom = Self.pillY + Self.pillHeight
        let thumbCenterX = thumbX + Self.thumbSize / 2
        let stemHeight = max(0, Self.thumbY - pillBottom)
        return Rectangle()
            .fill(Color.hdContext)
            .frame(width: 2, height: stemHeight)
            .offset(x: thumbCenterX - 1, y: pillBottom)
    }

    private func pill(x: CGFloat, label: String) -> some View {
        Text(label)
            .hdTypeStyle(HDType.label)
            .foregroundStyle(Color.hdOnContext)
            .padding(.horizontal, 12)
            .frame(height: Self.pillHeight)
            .background(Color.hdContext)
            .clipShape(Capsule())
            .fixedSize()
            .offset(x: x, y: Self.pillY)
    }
}
