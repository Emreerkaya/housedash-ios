import SwiftUI

public struct HDText: View {
    private let text: Text
    private let style: HDTypeStyle
    private let color: Color

    public init(_ content: String, style: HDTypeStyle = HDType.body, color: Color = .hdInk) {
        self.text = Text(content)
        self.style = style
        self.color = color
    }

    public var body: some View {
        text
            .hdTypeStyle(style)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

public extension View {
    func hdHugging() -> some View {
        fixedSize(horizontal: false, vertical: true)
    }
}
