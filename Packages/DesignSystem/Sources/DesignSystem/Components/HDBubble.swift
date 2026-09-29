import SwiftUI

public enum HDBubbleSide: Sendable, Equatable {
    case incoming
    case outgoing
}

public struct HDBubble: View {
    public static let maxWidth: CGFloat = 280
    public static let cornerRadius: CGFloat = 22

    public let text: String
    public let side: HDBubbleSide

    public init(_ text: String, side: HDBubbleSide) {
        self.text = text
        self.side = side
    }

    public var body: some View {
        Text(text)
            .hdTypeStyle(HDType.body)
            .foregroundStyle(textColor)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .hdHuggingWidth(upTo: Self.maxWidth)
            .background(fill)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    private var fill: Color {
        switch side {
        case .incoming: .hdSurface
        case .outgoing: .hdContext
        }
    }

    private var textColor: Color {
        switch side {
        case .incoming: .hdInk
        case .outgoing: .hdOnContext
        }
    }

    @ViewBuilder
    private var border: some View {
        switch side {
        case .incoming:
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(Color.hdHairline, lineWidth: 1)
        case .outgoing:
            EmptyView()
        }
    }
}


struct HDHuggingWidthLayout: Layout {
    let limit: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else { return .zero }
        let ideal = subview.sizeThatFits(.unspecified).width
        let width = min(ideal, limit)
        let height = subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        subview.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )
    }
}

extension View {
    func hdHuggingWidth(upTo limit: CGFloat) -> some View {
        HDHuggingWidthLayout(limit: limit) { self }
    }
}
