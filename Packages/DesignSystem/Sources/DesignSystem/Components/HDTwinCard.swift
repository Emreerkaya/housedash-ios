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

public struct HDTwinCard: View {
    public static let size = CGSize(width: 353, height: 258)
    public static let padding: CGFloat = 22
    public static let cornerRadius: CGFloat = 22

    public enum Content {
        case diy(HDTwinCardFacts)
        case hire(HDTwinCardFacts)
        case locked(HDTwinCardLockedDetail)
    }

    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            Spacer(minLength: 0)
            cta
        }
        .padding(Self.padding)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
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
                ForEach(facts.facts, id: \.self) { fact in
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
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(ctaFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var ctaLabel: String {
        switch content {
        case let .diy(facts): facts.ctaLabel
        case let .hire(facts): facts.ctaLabel
        case let .locked(detail): detail.ctaLabel
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
