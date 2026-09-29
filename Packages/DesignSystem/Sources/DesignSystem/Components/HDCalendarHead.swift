import SwiftUI

public struct HDCalendarHead: View {
    public static let size = CGSize(width: 353, height: 74)

    private static let weekdayX: [CGFloat] = [20.71, 69.64, 121.57, 170, 222.43, 273.36, 323.29]
    private static let weekdayY: CGFloat = 44
    private static let ruleY: CGFloat = 70

    public let monthYear: String
    public let weekdaySymbols: [String]
    public let onPrevious: (() -> Void)?
    public let onNext: (() -> Void)?

    public init(
        monthYear: String = "October 2026",
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
        ZStack(alignment: .topLeading) {
            chevron("‹", action: onPrevious, accessibilityLabel: "Previous month")
                .offset(x: 0, y: 3)

            Text(monthYear)
                .hdTypeStyle(HDType.bodyStrong)
                .foregroundStyle(Color.hdInk)
                .offset(x: 119, y: 6)

            chevron("›", action: onNext, accessibilityLabel: "Next month")
                .offset(x: 342, y: 3)

            ForEach(Array(zip(Self.weekdayX.indices, weekdaySymbols)), id: \.0) { index, symbol in
                Text(symbol)
                    .hdTypeStyle(HDType.caption)
                    .foregroundStyle(Color.hdInkFaint)
                    .offset(x: Self.weekdayX[index], y: Self.weekdayY)
            }

            Rectangle()
                .fill(Color.hdHairline)
                .frame(width: Self.size.width, height: 1)
                .offset(x: 0, y: Self.ruleY)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder
    private func chevron(_ glyph: String, action: (() -> Void)?, accessibilityLabel: String) -> some View {
        let label = Text(glyph)
            .font(.system(size: 30, weight: .regular))
            .foregroundStyle(Color.hdInkSoft)

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
