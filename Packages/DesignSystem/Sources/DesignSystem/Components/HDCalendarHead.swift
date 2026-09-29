import SwiftUI

public struct HDCalendarHead: View {
    public static let size = CGSize(width: 353, height: 74)
    public static let chevronTapTarget: CGFloat = 44

    private static let weekdayXFractions: [CGFloat] = [20.71, 69.64, 121.57, 170, 222.43, 273.36, 323.29]
        .map { $0 / size.width }
    private static let weekdayY: CGFloat = 44
    private static let ruleY: CGFloat = 70

    public let monthYear: String
    public let weekdaySymbols: [String]
    public let onPrevious: (() -> Void)?
    public let onNext: (() -> Void)?

    public init(
        monthYear: String,
        weekdaySymbols: [String] = ["S", "M", "T", "W", "T", "F", "S"],
        onPrevious: (() -> Void)? = nil,
        onNext: (() -> Void)? = nil
    ) {
        self.monthYear = monthYear
        self.weekdaySymbols = weekdaySymbols
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    chevron("‹", action: onPrevious, accessibilityLabel: "Previous month")
                    Spacer(minLength: 0)
                    chevron("›", action: onNext, accessibilityLabel: "Next month")
                }
                .frame(width: width)
                .offset(y: -4)

                Text(monthYear)
                    .hdTypeStyle(HDType.bodyStrong)
                    .foregroundStyle(Color.hdInk)
                    .frame(width: width, alignment: .center)
                    .multilineTextAlignment(.center)
                    .offset(y: 6)

                ForEach(Array(zip(Self.weekdayXFractions.indices, weekdaySymbols)), id: \.0) { index, symbol in
                    Text(symbol)
                        .hdTypeStyle(HDType.caption)
                        .foregroundStyle(Color.hdInkFaint)
                        .offset(x: Self.weekdayXFractions[index] * width, y: Self.weekdayY)
                }

                Rectangle()
                    .fill(Color.hdHairline)
                    .frame(width: width, height: 1)
                    .offset(y: Self.ruleY)
            }
        }
        .frame(height: Self.size.height)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func chevron(_ glyph: String, action: (() -> Void)?, accessibilityLabel: String) -> some View {
        let label = Text(glyph)
            .hdTypeStyle(HDType.chevron)
            .foregroundStyle(Color.hdInkSoft)
            .frame(width: Self.chevronTapTarget, height: Self.chevronTapTarget)
            .contentShape(Rectangle())

        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
        } else {
            label
                .accessibilityHidden(true)
        }
    }
}
