import SwiftUI

public struct HDTimeSliderRange: Sendable, Equatable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = min(start, end)
        self.end = max(start, end)
    }
}

public enum HDTimeSliderValue: Sendable, Equatable {
    case single(Int)
    case range(HDTimeSliderRange)

    public static func range(start: Int, end: Int) -> HDTimeSliderValue {
        .range(HDTimeSliderRange(start: start, end: end))
    }
}

public struct HDTimeSlider: View {
    public static let size = CGSize(width: 353, height: 104)
    public static let defaultBounds = 6 * 60...22 * 60
    public static let thumbTapTarget: CGFloat = 44

    private static let trackHeight: CGFloat = 3
    private static let trackY: CGFloat = 83
    private static let thumbSize: CGFloat = 24
    private static let thumbY: CGFloat = 74
    private static let pillHeight: CGFloat = 32
    private static let pillY: CGFloat = 8
    private static let stemHeight: CGFloat = 26

    @Binding public var value: HDTimeSliderValue
    public let bounds: ClosedRange<Int>

    public init(value: Binding<HDTimeSliderValue>, bounds: ClosedRange<Int> = HDTimeSlider.defaultBounds) {
        self._value = value
        self.bounds = bounds
    }

    private var minutes: [Int] {
        switch value {
        case let .single(minute):
            [minute]
        case let .range(range):
            [range.start, range.end]
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let xs = minutes.map { x(forMinute: $0, trackWidth: width) }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Self.trackHeight / 2)
                    .fill(Color.hdHairline)
                    .frame(width: width, height: Self.trackHeight)
                    .offset(y: Self.trackY)

                if case .range = value, let leading = xs.first, let trailing = xs.last {
                    RoundedRectangle(cornerRadius: Self.trackHeight / 2)
                        .fill(Color.hdContext)
                        .frame(width: max(0, trailing - leading), height: Self.trackHeight)
                        .offset(x: leading, y: Self.trackY)
                }

                ForEach(xs.indices, id: \.self) { index in
                    stem(x: xs[index])
                    pill(x: xs[index], label: Self.format(minute: minutes[index]))
                    thumb(index: index, x: xs[index], trackWidth: width)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { event in
                        handleTap(atX: event.location.x, trackWidth: width)
                    }
            )
        }
        .frame(height: Self.size.height)
        .frame(maxWidth: .infinity)
    }

    func fraction(forMinute minute: Int) -> CGFloat {
        let span = CGFloat(bounds.upperBound - bounds.lowerBound)
        guard span > 0 else { return 0 }
        let clamped = min(max(minute, bounds.lowerBound), bounds.upperBound)
        return CGFloat(clamped - bounds.lowerBound) / span
    }

    func x(forMinute minute: Int, trackWidth: CGFloat) -> CGFloat {
        fraction(forMinute: minute) * trackWidth
    }

    func minute(forX x: CGFloat, trackWidth: CGFloat) -> Int {
        guard trackWidth > 0 else { return bounds.lowerBound }
        let span = bounds.upperBound - bounds.lowerBound
        let fraction = min(max(x / trackWidth, 0), 1)
        return bounds.lowerBound + Int((fraction * CGFloat(span)).rounded())
    }

    func handleTap(atX x: CGFloat, trackWidth: CGFloat) {
        let tapped = minute(forX: x, trackWidth: trackWidth)
        switch value {
        case let .single(existing):
            value = .range(start: existing, end: tapped)
        case .range:
            value = .single(tapped)
        }
    }

    private func dragGesture(index: Int, trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let dragged = minute(forX: drag.location.x, trackWidth: trackWidth)
                switch value {
                case .single:
                    value = .single(dragged)
                case let .range(range):
                    value = index == 0
                        ? .range(start: dragged, end: range.end)
                        : .range(start: range.start, end: dragged)
                }
            }
    }

    private func thumb(index: Int, x: CGFloat, trackWidth: CGFloat) -> some View {
        Circle()
            .fill(Color.hdContext)
            .frame(width: Self.thumbSize, height: Self.thumbSize)
            .frame(width: Self.thumbTapTarget, height: Self.thumbTapTarget)
            .contentShape(Rectangle())
            .position(x: x, y: Self.thumbY + Self.thumbSize / 2)
            .gesture(dragGesture(index: index, trackWidth: trackWidth))
    }

    private func stem(x: CGFloat) -> some View {
        Rectangle()
            .fill(Color.hdContext)
            .frame(width: 2, height: Self.stemHeight)
            .position(x: x, y: Self.pillY + Self.pillHeight + Self.stemHeight / 2)
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
            .position(x: x, y: Self.pillY + Self.pillHeight / 2)
    }

    public static func format(minute: Int) -> String {
        let hour24 = (minute / 60) % 24
        let minutePart = minute % 60
        let period = hour24 < 12 ? "am" : "pm"
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        if minutePart == 0 {
            return "\(hour12) \(period)"
        }
        return String(format: "%d:%02d %@", hour12, minutePart, period)
    }
}
