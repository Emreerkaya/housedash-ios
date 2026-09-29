import SwiftUI

public struct HDTwinCardFacts: Sendable, Equatable {
    public let label: String
    public let figure: String
    public let qualifier: String
    public let facts: [String]
    public let ctaLabel: String

    public init(label: String, figure: String, qualifier: String, facts: [String], ctaLabel: String) {
        self.label = label
        self.figure = figure
        self.qualifier = qualifier
        self.facts = facts
        self.ctaLabel = ctaLabel
    }

    public static let diyExample = HDTwinCardFacts(
        label: "Fix it yourself",
        figure: "$14",
        qualifier: "in parts",
        facts: ["40 min · Easy", "Need: basin wrench", "1 video · 4 steps"],
        ctaLabel: "See the guide"
    )

    public static let hireExample = HDTwinCardFacts(
        label: "Have someone do it",
        figure: "$90–120",
        qualifier: "typical",
        facts: ["Today 4pm earliest", "6 people near you", "4.8 average"],
        ctaLabel: "Find someone"
    )
}

public struct HDTwinCardLockedDetail: Sendable, Equatable {
    public let label: String
    public let title: String
    public let body: String
    public let ctaLabel: String

    public init(label: String, title: String, body: String, ctaLabel: String) {
        self.label = label
        self.title = title
        self.body = body
        self.ctaLabel = ctaLabel
    }

    public static let example = HDTwinCardLockedDetail(
        label: "Fix it yourself",
        title: "A licensed electrician is required",
        body: "NYC requires a licence for panel work. This is not a recommendation — it is the law.",
        ctaLabel: "Why this is locked"
    )
}

public struct HDEqualHeightColumn: Layout {
    public let spacing: CGFloat

    public init(spacing: CGFloat) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = Self.commonHeight(of: subviews, width: proposal.width)
        let width = subviews.reduce(CGFloat.zero) { widest, subview in
            max(widest, subview.sizeThatFits(ProposedViewSize(width: proposal.width, height: height)).width)
        }
        return CGSize(width: width, height: Self.stackedHeight(of: height, count: subviews.count, spacing: spacing))
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let height = Self.commonHeight(of: subviews, width: bounds.width)
        var y = bounds.minY
        for subview in subviews {
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: height)
            )
            y += height + spacing
        }
    }

    static func commonHeight(of subviews: Subviews, width: CGFloat?) -> CGFloat {
        subviews.reduce(CGFloat.zero) { tallest, subview in
            max(tallest, subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height)
        }
    }

    static func stackedHeight(of common: CGFloat, count: Int, spacing: CGFloat) -> CGFloat {
        common * CGFloat(count) + spacing * CGFloat(max(0, count - 1))
    }
}

public struct HDTwinCardPair: View {
    public static let defaultSpacing: CGFloat = HDSpacing.item

    private let first: HDTwinCard
    private let second: HDTwinCard
    private let spacing: CGFloat

    public init(_ first: HDTwinCard, _ second: HDTwinCard, spacing: CGFloat = HDTwinCardPair.defaultSpacing) {
        self.first = first
        self.second = second
        self.spacing = spacing
    }

    public var body: some View {
        HDEqualHeightColumn(spacing: spacing) {
            first
            second
        }
    }
}

public struct HDTwinCard: View {
    public static let size = CGSize(width: 353, height: 258)
    public static let padding: CGFloat = 22
    public static let cornerRadius: CGFloat = 22
    public static let ctaHeight: CGFloat = 50
    public static let ctaCornerRadius: CGFloat = 14
    public static let optionCount = 2

    public enum Content {
        case diy(HDTwinCardFacts)
        case hire(HDTwinCardFacts)
        case locked(HDTwinCardLockedDetail)

        public var optionIndex: Int {
            switch self {
            case .diy, .locked: 1
            case .hire: 2
            }
        }
    }

    public let content: Content
    let action: () -> Void

    public init(_ content: Content, action: @escaping () -> Void) {
        self.content = content
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            card
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityValueText)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            Spacer(minLength: HDSpacing.item)
            cta
        }
        .padding(Self.padding)
        .frame(width: Self.size.width, alignment: .topLeading)
        .frame(minHeight: Self.size.height, alignment: .topLeading)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var head: some View {
        switch content {
        case let .diy(facts):
            factsHead(facts, labelColor: .hdAccentDIY)
        case let .hire(facts):
            factsHead(facts, labelColor: .hdAccentHire)
        case let .locked(detail):
            lockedHead(detail)
        }
    }

    private func factsHead(_ facts: HDTwinCardFacts, labelColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(facts.label)
                .hdTypeStyle(HDType.label)
                .foregroundStyle(labelColor)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(facts.figure)
                    .hdTypeStyle(HDType.headlineFigure)
                    .foregroundStyle(Color.hdInk)
                Text(facts.qualifier)
                    .hdTypeStyle(HDType.caption)
                    .foregroundStyle(Color.hdInkFaint)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(facts.facts.enumerated()), id: \.offset) { _, fact in
                    Text(fact)
                        .hdTypeStyle(HDType.factRow)
                        .foregroundStyle(Color.hdInkSoft)
                }
            }
            .padding(.top, 10)
        }
    }

    private func lockedHead(_ detail: HDTwinCardLockedDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.hdInkSoft)
                    .frame(width: 16, height: 16)
                Text(detail.label)
                    .hdTypeStyle(HDType.label)
                    .foregroundStyle(Color.hdInkSoft)
            }
            Text(detail.title)
                .hdTypeStyle(HDType.bodyStrong)
                .foregroundStyle(Color.hdInk)
            Text(detail.body)
                .hdTypeStyle(HDType.caption)
                .foregroundStyle(Color.hdInkSoft)
        }
    }

    private var cta: some View {
        Text(ctaLabel)
            .hdTypeStyle(HDType.bodyStrong)
            .foregroundStyle(ctaTextColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Self.ctaHeight)
            .background(ctaFill)
            .clipShape(RoundedRectangle(cornerRadius: Self.ctaCornerRadius, style: .continuous))
    }

    private var ctaLabel: String {
        switch content {
        case let .diy(facts): facts.ctaLabel
        case let .hire(facts): facts.ctaLabel
        case let .locked(detail): detail.ctaLabel
        }
    }

    var accessibilityLabelText: String {
        let ordinal = "Option \(content.optionIndex) of \(Self.optionCount)"
        switch content {
        case let .diy(facts), let .hire(facts):
            return "\(ordinal). \(facts.label). \(facts.ctaLabel)."
        case let .locked(detail):
            return "\(ordinal). \(detail.label). Locked. \(detail.ctaLabel)."
        }
    }

    var accessibilityValueText: String {
        switch content {
        case let .diy(facts), let .hire(facts):
            return (["\(facts.figure) \(facts.qualifier)"] + facts.facts).joined(separator: ". ") + "."
        case let .locked(detail):
            return "\(detail.title). \(detail.body)"
        }
    }

    var fillToken: HDToken {
        switch content {
        case .diy, .hire: .surface
        case .locked: .locked
        }
    }

    var ctaFillToken: HDToken {
        switch content {
        case .diy: .accentDIY
        case .hire: .accentHire
        case .locked: .surfaceSunk
        }
    }

    private var fill: Color {
        switch content {
        case .diy, .hire: .hdSurface
        case .locked: .hdLocked
        }
    }

    private var ctaFill: Color {
        switch content {
        case .diy: .hdAccentDIY
        case .hire: .hdAccentHire
        case .locked: .hdSurfaceSunk
        }
    }

    private var ctaTextColor: Color {
        switch content {
        case .diy, .hire: .hdOnAccent
        case .locked: .hdInkSoft
        }
    }
}
