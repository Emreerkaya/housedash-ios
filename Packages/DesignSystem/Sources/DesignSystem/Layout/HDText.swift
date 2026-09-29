import SwiftUI

public struct HDText: View {
    private let text: Text
    private let style: HDTypeStyle
    private let color: Color
    private let singleLineMinimumScaleFactor: CGFloat?

    public init(
        _ content: String,
        style: HDTypeStyle = HDType.body,
        color: Color = .hdInk,
        singleLineMinimumScaleFactor: CGFloat? = nil
    ) {
        self.text = Text(content)
        self.style = style
        self.color = color
        self.singleLineMinimumScaleFactor = singleLineMinimumScaleFactor
    }

    public var body: some View {
        if let singleLineMinimumScaleFactor {
            text
                .hdTypeStyle(style)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(singleLineMinimumScaleFactor)
        } else {
            text
                .hdTypeStyle(style)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

public extension View {
    func hdHugging() -> some View {
        fixedSize(horizontal: false, vertical: true)
    }
}
