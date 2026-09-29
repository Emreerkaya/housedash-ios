import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

@MainActor
final class HDComponentsTests: XCTestCase {

    #if canImport(UIKit)
    private static let cardProposal = CGSize(width: HDTwinCard.size.width, height: 100_000)

    private func measuredSize<V: View>(
        _ view: V,
        proposal: CGSize = CGSize(width: 1000, height: 1000),
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: proposal)
    }

    private func cardSize(_ card: HDTwinCard, dynamicTypeSize: DynamicTypeSize = .large) -> CGSize {
        measuredSize(
            card.fixedSize(horizontal: false, vertical: true),
            proposal: Self.cardProposal,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private func cardHeight(_ card: HDTwinCard, dynamicTypeSize: DynamicTypeSize = .large) -> CGFloat {
        cardSize(card, dynamicTypeSize: dynamicTypeSize).height
    }

    private func pairHeight(
        _ first: HDTwinCard,
        _ second: HDTwinCard,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGFloat {
        measuredSize(
            HDTwinCardPair(first, second).fixedSize(horizontal: false, vertical: true),
            proposal: Self.cardProposal,
            dynamicTypeSize: dynamicTypeSize
        ).height
    }
    #endif

    private static let sixFactHire = HDTwinCardFacts(
        label: "Have someone do it",
        figure: "$90–120",
        qualifier: "typical",
        facts: [
            "Today 4pm earliest",
            "6 people near you",
            "4.8 average",
            "Licensed and insured",
            "Two year workmanship guarantee",
            "Free cancellation up to an hour before"
        ],
        ctaLabel: "Find someone"
    )

    private static let longPriceHire = HDTwinCardFacts(
        label: "Have someone do it",
        figure: "$1,250,000–2,400,000",
        qualifier: "whole building",
        facts: ["Today 4pm earliest", "6 people near you", "4.8 average"],
        ctaLabel: "Find someone"
    )

    private static let germanDIY = HDTwinCardFacts(
        label: "Reparieren Sie es selbst",
        figure: "14 €",
        qualifier: "Ersatzteilkosten",
        facts: [
            "40 Minuten · Einfach",
            "Benötigt: Eckventilschlüssel",
            "1 Video · 4 Arbeitsschritte"
        ],
        ctaLabel: "Reparaturanleitung ansehen"
    )

    private static let thaiHire = HDTwinCardFacts(
        label: "ให้ช่างมาทำให้",
        figure: "฿3,000–4,000",
        qualifier: "ราคาทั่วไป",
        facts: [
            "วันนี้ เร็วที่สุด 16:00 น.",
            "มีช่างว่าง 6 คนอยู่ใกล้คุณ",
            "คะแนนเฉลี่ย 4.8 จาก 5"
        ],
        ctaLabel: "หาช่างที่รับงานนี้"
    )

    private static let longTitleLocked = HDTwinCardLockedDetail(
        label: "Fix it yourself",
        title: "A licensed electrician is required for every part of this job, including replacing one breaker inside the service panel",
        body: "NYC requires a licence for panel work. This is not a recommendation — it is the law, and an unlicensed repair voids the homeowner's insurance for any fire that follows it.",
        ctaLabel: "Why this is locked"
    )

    private static func card(_ content: HDTwinCard.Content) -> HDTwinCard {
        HDTwinCard(content, action: {})
    }

    private static var demandingPairs: [(name: String, first: HDTwinCard.Content, second: HDTwinCard.Content)] {
        [
            ("fixture", .diy(.diyExample), .hire(.hireExample)),
            ("six facts", .diy(.diyExample), .hire(sixFactHire)),
            ("long locked title", .locked(longTitleLocked), .hire(.hireExample)),
            ("german and thai", .diy(germanDIY), .hire(thaiHire)),
            ("twenty character price", .diy(.diyExample), .hire(longPriceHire))
        ]
    }

    #if canImport(UIKit)
    func testAllThreeTwinCardVariantsReportIdenticalSizeAtTheDefaultTextSize() {
        let diy = cardSize(Self.card(.diy(.diyExample)))
        let hire = cardSize(Self.card(.hire(.hireExample)))
        let locked = cardSize(Self.card(.locked(.example)))

        XCTAssertEqual(diy, HDTwinCard.size)
        XCTAssertEqual(hire, HDTwinCard.size)
        XCTAssertEqual(locked, HDTwinCard.size)
    }

    func testLockedVariantKeepsFullHeightWithShorterContent() {
        let locked = cardSize(Self.card(.locked(.example)))
        XCTAssertEqual(locked.height, HDTwinCard.size.height)
        XCTAssertEqual(locked.width, HDTwinCard.size.width)
    }

    func testTwinCardHeightFollowsItsContentAndTheTextSize() {
        XCTAssertEqual(Self.longPriceHire.figure.count, 20)

        let threeFacts = cardHeight(Self.card(.hire(.hireExample)))
        let sixFacts = cardHeight(Self.card(.hire(Self.sixFactHire)))
        let lockedLongTitle = cardHeight(Self.card(.locked(Self.longTitleLocked)))

        XCTAssertEqual(threeFacts, HDTwinCard.size.height)
        XCTAssertGreaterThan(sixFacts, HDTwinCard.size.height)
        XCTAssertGreaterThan(lockedLongTitle, HDTwinCard.size.height)

        let hugeThreeFacts = cardHeight(Self.card(.hire(.hireExample)), dynamicTypeSize: .accessibility5)
        let hugeSixFacts = cardHeight(Self.card(.hire(Self.sixFactHire)), dynamicTypeSize: .accessibility5)

        XCTAssertGreaterThan(hugeThreeFacts, threeFacts)
        XCTAssertGreaterThan(hugeSixFacts, hugeThreeFacts)
    }

    func testTwinCardPairRaisesTheShorterCardToTheTallerCard() {
        for size in [DynamicTypeSize.large, .accessibility5] {
            let short = Self.card(.diy(.diyExample))
            let tall = Self.card(.hire(Self.sixFactHire))

            let shortAlone = cardHeight(short, dynamicTypeSize: size)
            let tallAlone = cardHeight(tall, dynamicTypeSize: size)
            XCTAssertGreaterThan(tallAlone, shortAlone, "\(size): the pair is symmetric, so equality would be vacuous")

            let pair = pairHeight(short, tall, dynamicTypeSize: size)
            XCTAssertEqual(
                pair,
                tallAlone * 2 + HDTwinCardPair.defaultSpacing,
                accuracy: 0.5,
                "\(size): the pair is not two cards of the taller card's height"
            )
            XCTAssertGreaterThan(pair, shortAlone * 2 + HDTwinCardPair.defaultSpacing)
        }
    }

    func testTwinCardPairStaysEqualAcrossEveryDemandingFixture() {
        for size in [DynamicTypeSize.large, .accessibility5] {
            for pair in Self.demandingPairs {
                let first = Self.card(pair.first)
                let second = Self.card(pair.second)
                let tallest = max(cardHeight(first, dynamicTypeSize: size), cardHeight(second, dynamicTypeSize: size))

                XCTAssertEqual(
                    pairHeight(first, second, dynamicTypeSize: size),
                    tallest * 2 + HDTwinCardPair.defaultSpacing,
                    accuracy: 0.5,
                    "\(pair.name) at \(size)"
                )
            }
        }
    }

    func testTwinCardCallToActionIsNeverClippedInEitherCardOfThePair() {
        for scheme in [ColorScheme.light, .dark] {
            for size in [DynamicTypeSize.large, .accessibility5] {
                for pair in Self.demandingPairs {
                    let first = Self.card(pair.first)
                    let second = Self.card(pair.second)
                    let label = "\(pair.name) at \(size) in \(scheme)"

                    guard let bitmap = HDBitmap(
                        HDTwinCardPair(first, second),
                        colorScheme: scheme,
                        dynamicTypeSize: size
                    ) else {
                        XCTFail("could not render \(label)")
                        continue
                    }

                    let painted = bitmap.opaqueBands()
                    guard painted.count == 2 else {
                        XCTFail("\(label): the rendered pair is \(painted.count) painted bands, not two cards")
                        continue
                    }
                    XCTAssertEqual(
                        painted[0].count,
                        painted[1].count,
                        "\(label): the two rendered cards are not the same height"
                    )
                    XCTAssertEqual(
                        CGFloat(painted[1].lowerBound - painted[0].upperBound),
                        HDTwinCardPair.defaultSpacing,
                        accuracy: 1,
                        "\(label): the gap between the cards is not the pair spacing"
                    )
                    XCTAssertGreaterThanOrEqual(
                        CGFloat(painted[0].count),
                        HDTwinCard.size.height,
                        "\(label): the cards are shorter than the floor"
                    )

                    let bands = [(card: first, rows: painted[0]), (card: second, rows: painted[1])]

                    for band in bands {
                        guard let target = HDBitmap.swatch(
                            Color(hdToken: band.card.ctaFillToken),
                            colorScheme: scheme
                        ) else {
                            XCTFail("could not resolve the call to action fill for \(label)")
                            continue
                        }

                        guard let cta = bitmap.bottomMostRun(matching: target, in: band.rows) else {
                            XCTFail("\(label): option \(band.card.content.optionIndex) renders no call to action at all")
                            continue
                        }

                        let expectedBottom = band.rows.upperBound - Int(HDTwinCard.padding) - 1
                        XCTAssertEqual(
                            CGFloat(cta.upperBound),
                            CGFloat(expectedBottom),
                            accuracy: 2,
                            "\(label): option \(band.card.content.optionIndex) call to action bottom edge is not \(Int(HDTwinCard.padding))pt above the card edge"
                        )
                        XCTAssertGreaterThanOrEqual(
                            CGFloat(cta.count),
                            HDTwinCard.ctaHeight - 1,
                            "\(label): option \(band.card.content.optionIndex) call to action is only \(cta.count)pt tall"
                        )
                    }
                }
            }
        }
    }
    func testRenderedTokensActuallyInvertBetweenLightAndDark() {
        for token in [HDToken.surface, .locked, .accentDIY, .accentHire, .surfaceSunk] {
            let light = HDBitmap.swatch(Color(hdToken: token), colorScheme: .light)
            let dark = HDBitmap.swatch(Color(hdToken: token), colorScheme: .dark)
            XCTAssertNotNil(light)
            XCTAssertNotNil(dark)
            XCTAssertNotEqual(light, dark, "\(token) renders the same in both schemes, so the dark renders prove nothing")
        }

        let lightCardFill = HDBitmap.swatch(Color(hdToken: HDToken.locked), colorScheme: .light)
        let lightCtaFill = HDBitmap.swatch(Color(hdToken: HDToken.surfaceSunk), colorScheme: .light)
        XCTAssertNotNil(lightCardFill)
        XCTAssertNotNil(lightCtaFill)
        if let card = lightCardFill, let cta = lightCtaFill {
            XCTAssertFalse(card.matches(cta), "the locked card fill and its call to action fill are indistinguishable")
        }
    }
    #endif

    func testTwinCardAnnouncesWhichOfTheTwoOptionsItIs() {
        XCTAssertEqual(HDTwinCard.optionCount, 2)
        XCTAssertEqual(HDTwinCard.Content.diy(.diyExample).optionIndex, 1)
        XCTAssertEqual(HDTwinCard.Content.locked(.example).optionIndex, 1)
        XCTAssertEqual(HDTwinCard.Content.hire(.hireExample).optionIndex, 2)

        let diy = HDTwinCard(.diy(.diyExample), action: {})
        let hire = HDTwinCard(.hire(.hireExample), action: {})
        let locked = HDTwinCard(.locked(.example), action: {})

        XCTAssertEqual(diy.accessibilityLabelText, "Option 1 of 2. Fix it yourself. See the guide.")
        XCTAssertEqual(hire.accessibilityLabelText, "Option 2 of 2. Have someone do it. Find someone.")
        XCTAssertEqual(locked.accessibilityLabelText, "Option 1 of 2. Fix it yourself. Locked. Why this is locked.")

        XCTAssertEqual(diy.accessibilityValueText, "$14 in parts. 40 min · Easy. Need: basin wrench. 1 video · 4 steps.")
        XCTAssertTrue(hire.accessibilityValueText.hasPrefix("$90–120 typical."))
        XCTAssertTrue(locked.accessibilityValueText.hasPrefix("A licensed electrician is required."))
    }

    func testTwinCardActionSurvivesToTheCaller() {
        var taken: [Int] = []
        let diy = HDTwinCard(.diy(.diyExample), action: { taken.append(1) })
        let hire = HDTwinCard(.hire(.hireExample), action: { taken.append(2) })

        diy.action()
        hire.action()

        XCTAssertEqual(taken, [1, 2])
        XCTAssertTrue(String(describing: type(of: diy.body)).contains("Button"), "the card body has no Button in it")
        XCTAssertTrue(String(describing: type(of: hire.body)).contains("Button"), "the card body has no Button in it")
    }

    func testEqualHeightColumnStacksTheCommonHeightWithOneGapBetween() {
        XCTAssertEqual(HDEqualHeightColumn.stackedHeight(of: 300, count: 2, spacing: 8), 608)
        XCTAssertEqual(HDEqualHeightColumn.stackedHeight(of: 300, count: 1, spacing: 8), 300)
        XCTAssertEqual(HDEqualHeightColumn.stackedHeight(of: 300, count: 0, spacing: 8), 0)
    }

    #if canImport(UIKit)
    func testBubbleHugsAndRespectsMaxWidth() {
        let short = measuredSize(HDBubble("Hi", side: .incoming))
        let long = measuredSize(HDBubble(
            "Message text that wraps naturally at 280 points wide because it is a long sentence with many words in it.",
            side: .outgoing
        ))

        XCTAssertLessThan(short.width, HDBubble.maxWidth)
        XCTAssertLessThanOrEqual(long.width, HDBubble.maxWidth + 0.5)
        XCTAssertEqual(long.width, HDBubble.maxWidth, accuracy: 0.5)
        XCTAssertGreaterThan(long.height, short.height)
    }
    #endif

    func testActiveAndInactiveTabDifferInWeightAndOpacityNotOnlyColor() {
        let active = HDTabBarButtonAppearance.appearance(isActive: true)
        let inactive = HDTabBarButtonAppearance.appearance(isActive: false)

        XCTAssertNotEqual(active.labelWeight, inactive.labelWeight)
        XCTAssertNotEqual(active.iconOpacity, inactive.iconOpacity)
        XCTAssertEqual(active.labelWeight, .semibold)
        XCTAssertEqual(inactive.labelWeight, .regular)
        XCTAssertEqual(active.iconOpacity, 1.0)
        XCTAssertEqual(inactive.iconOpacity, 0.4)
    }

    func testRatingBarsShowsVisiblePipAtZeroPercent() {
        let width = HDRatingBars.fillWidth(percent: 0, trackWidth: 300)
        XCTAssertEqual(width, HDRatingBars.minimumFillWidth)
        XCTAssertEqual(HDRatingBars.minimumFillWidth, HDRatingBars.trackHeight)
    }

    func testRatingBarsFillIsProportionalAboveTheFloor() {
        let width = HDRatingBars.fillWidth(percent: 0.92, trackWidth: 141)
        XCTAssertGreaterThan(width, HDRatingBars.minimumFillWidth)
        XCTAssertEqual(width, 141 * 0.92, accuracy: 0.01)
    }

    func testReticleBracketsScaleAtNonNativeSize() {
        let native = HDReticle.geometry(for: CGSize(width: HDReticle.nativeSize, height: HDReticle.nativeSize))
        XCTAssertEqual(native.armLength, 42, accuracy: 0.01)
        XCTAssertEqual(native.thickness, 3, accuracy: 0.01)

        let scaledSide: CGFloat = 250
        let scaled = HDReticle.geometry(for: CGSize(width: scaledSide, height: scaledSide))
        let expectedArm = 42 * scaledSide / HDReticle.nativeSize

        XCTAssertEqual(scaled.armLength, expectedArm, accuracy: 0.01)
        XCTAssertNotEqual(scaled.armLength, native.armLength)

        for bar in scaled.bars {
            XCTAssertGreaterThanOrEqual(bar.minX, 0)
            XCTAssertGreaterThanOrEqual(bar.minY, 0)
            XCTAssertLessThanOrEqual(bar.maxX, scaledSide + 0.01)
            XCTAssertLessThanOrEqual(bar.maxY, scaledSide + 0.01)
        }

        let touchesLeft = scaled.bars.contains { abs($0.minX - 0) < 0.01 }
        let touchesRight = scaled.bars.contains { abs($0.maxX - scaledSide) < 0.01 }
        let touchesTop = scaled.bars.contains { abs($0.minY - 0) < 0.01 }
        let touchesBottom = scaled.bars.contains { abs($0.maxY - scaledSide) < 0.01 }

        XCTAssertTrue(touchesLeft)
        XCTAssertTrue(touchesRight)
        XCTAssertTrue(touchesTop)
        XCTAssertTrue(touchesBottom)
    }
}

#if canImport(UIKit)
struct HDPixel: Equatable {
    let red: Int
    let green: Int
    let blue: Int

    func matches(_ other: HDPixel, tolerance: Int = 4) -> Bool {
        abs(red - other.red) <= tolerance
            && abs(green - other.green) <= tolerance
            && abs(blue - other.blue) <= tolerance
    }
}

struct HDBitmap {
    let width: Int
    let height: Int
    private let bytes: [UInt8]

    @MainActor
    init?<V: View>(_ view: V, colorScheme: ColorScheme, dynamicTypeSize: DynamicTypeSize) {
        let renderer = ImageRenderer(
            content: view
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = 1
        guard let image = renderer.cgImage, image.width > 0, image.height > 0 else { return nil }

        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        self.width = width
        self.height = height
        self.bytes = bytes
    }

    func pixel(x: Int, y: Int) -> HDPixel {
        let offset = (y * width + x) * 4
        return HDPixel(red: Int(bytes[offset]), green: Int(bytes[offset + 1]), blue: Int(bytes[offset + 2]))
    }

    private func rowIsPainted(_ y: Int) -> Bool {
        for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 0 {
            return true
        }
        return false
    }

    func opaqueBands() -> [Range<Int>] {
        var bands: [Range<Int>] = []
        var start: Int?
        for y in 0..<height {
            if rowIsPainted(y) {
                if start == nil { start = y }
            } else if let open = start {
                bands.append(open..<y)
                start = nil
            }
        }
        if let open = start { bands.append(open..<height) }
        return bands
    }

    private func row(_ y: Int, contains target: HDPixel) -> Bool {
        let inset = Int(HDTwinCard.padding)
        for x in inset..<max(inset + 1, width - inset) where pixel(x: x, y: y).matches(target) {
            return true
        }
        return false
    }

    func bottomMostRun(matching target: HDPixel, in rows: Range<Int>) -> ClosedRange<Int>? {
        guard var bottom = rows.reversed().first(where: { row($0, contains: target) }) else { return nil }
        var top = bottom
        while top - 1 >= rows.lowerBound, row(top - 1, contains: target) {
            top -= 1
        }
        bottom = max(bottom, top)
        return top...bottom
    }

    @MainActor
    static func swatch(_ color: Color, colorScheme: ColorScheme) -> HDPixel? {
        let side = Int(HDTwinCard.padding) * 3
        guard let bitmap = HDBitmap(
            Rectangle().fill(color).frame(width: CGFloat(side), height: CGFloat(side)),
            colorScheme: colorScheme,
            dynamicTypeSize: .large
        ) else { return nil }
        return bitmap.pixel(x: side / 2, y: side / 2)
    }
}
#endif
