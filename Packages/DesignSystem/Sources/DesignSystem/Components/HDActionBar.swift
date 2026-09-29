import SwiftUI

public struct HDActionBar: View, HDDrawsAStateMark {
    public struct Price {
        public let figure: String
        public let qualifier: String

        public init(figure: String, qualifier: String) {
            self.figure = figure
            self.qualifier = qualifier
        }
    }

    public static let minimumCTAHeight: CGFloat = 52
    public static let ctaCornerRadius: CGFloat = 14
    public static let ctaIdentifier = "action-bar-cta"

    private let price: Price?
    private let ctaTitle: String
    private let isCTAEnabled: Bool
    private let disabledExplanation: String?
    private let action: () -> Void

    public init(
        price: Price? = nil,
        ctaTitle: String,
        isCTAEnabled: Bool = true,
        disabledExplanation: String? = nil,
        action: @escaping () -> Void
    ) {
        self.price = price
        self.ctaTitle = ctaTitle
        self.isCTAEnabled = isCTAEnabled
        self.disabledExplanation = disabledExplanation
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
                HDText(ctaTitle, style: HDType.bodyStrong, color: ctaTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Self.minimumCTAHeight)
                    .background(ctaFill, in: RoundedRectangle(cornerRadius: Self.ctaCornerRadius, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isCTAEnabled)
            .accessibilityIdentifier(Self.ctaIdentifier)
            .accessibilityLabel(ctaAccessibilityLabel)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, HDSpacing.margin)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(Color.hdGround)
    }

    var ctaFill: Color {
        isCTAEnabled ? .hdContext : .hdLocked
    }

    var ctaTextColor: Color {
        isCTAEnabled ? .hdOnContext : .hdInkSoft
    }

    var ctaAccessibilityLabel: String {
        guard !isCTAEnabled, let disabledExplanation else { return ctaTitle }
        return "\(ctaTitle), \(disabledExplanation)"
    }
}
