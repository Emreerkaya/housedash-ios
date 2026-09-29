import SwiftUI

public struct HDActionBar: View {
    public struct Price {
        public let figure: String
        public let qualifier: String

        public init(figure: String, qualifier: String) {
            self.figure = figure
            self.qualifier = qualifier
        }
    }

    private let price: Price?
    private let ctaTitle: String
    private let action: () -> Void

    public init(price: Price? = nil, ctaTitle: String, action: @escaping () -> Void) {
        self.price = price
        self.ctaTitle = ctaTitle
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 16) {
            if let price {
                VStack(alignment: .leading, spacing: 0) {
                    HDText(price.figure, style: HDType.bodyStrong, color: .hdInk)
                    HDText(price.qualifier, style: HDType.caption, color: .hdInkFaint)
                }
            }

            Button(action: action) {
                HDText(ctaTitle, style: HDType.bodyStrong, color: .hdOnContext)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.plain)
            .background(Color.hdContext, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, HDSpacing.margin)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(Color.hdGround)
    }
}
