import SwiftUI

public struct HDRatingBarsRow: Sendable, Equatable, Identifiable {
    public let star: Int
    public let percent: Double

    public var id: Int { star }

    public init(star: Int, percent: Double) {
        self.star = star
        self.percent = percent
    }
}

public struct HDRatingBars: View {
    public static let trackHeight: CGFloat = 6
    public static let minimumFillWidth: CGFloat = trackHeight

    public static let exampleRows: [HDRatingBarsRow] = [
        HDRatingBarsRow(star: 5, percent: 0.92),
        HDRatingBarsRow(star: 4, percent: 0.06),
        HDRatingBarsRow(star: 3, percent: 0.02),
        HDRatingBarsRow(star: 2, percent: 0.0),
        HDRatingBarsRow(star: 1, percent: 0.0)
    ]

    public static func fillWidth(percent: Double, trackWidth: CGFloat) -> CGFloat {
        max(minimumFillWidth, trackWidth * CGFloat(percent))
    }

    public let rows: [HDRatingBarsRow]

    public init(rows: [HDRatingBarsRow] = HDRatingBars.exampleRows) {
        self.rows = rows
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows) { row in
                HDRatingBarRow(row: row)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HDRatingBarRow: View {
    let row: HDRatingBarsRow

    var body: some View {
        HStack(spacing: 12) {
            Text("\(row.star)")
                .hdTypeStyle(HDType.caption)
                .foregroundStyle(Color.hdInkSoft)
                .fixedSize()

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: HDRatingBars.trackHeight / 2)
                        .fill(Color.hdSurfaceSunk)
                    RoundedRectangle(cornerRadius: HDRatingBars.trackHeight / 2)
                        .fill(Color.hdVerified)
                        .frame(width: HDRatingBars.fillWidth(percent: row.percent, trackWidth: proxy.size.width))
                }
            }
            .frame(height: HDRatingBars.trackHeight)

            Text("\(Int((row.percent * 100).rounded()))%")
                .hdTypeStyle(HDType.caption)
                .foregroundStyle(Color.hdInkFaint)
                .fixedSize()
        }
    }
}
