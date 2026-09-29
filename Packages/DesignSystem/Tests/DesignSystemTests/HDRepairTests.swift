import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDRepairTests: XCTestCase {

    private func measuredSize<V: View>(_ view: V, proposal: CGSize = CGSize(width: 1000, height: 1000)) -> CGSize {
        let controller = UIHostingController(rootView: view)
        return controller.sizeThatFits(in: proposal)
    }

    private final class MutableBox<Value> {
        var value: Value
        init(_ value: Value) { self.value = value }
    }

    private func mutableBinding<Value>(_ initial: Value) -> (Binding<Value>, MutableBox<Value>) {
        let box = MutableBox(initial)
        let binding = Binding(get: { box.value }, set: { box.value = $0 })
        return (binding, box)
    }

    private func realWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ??
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    func testEveryNesterTabIconIsARealSFSymbol() {
        for tab in HDNesterTab.allCases {
            XCTAssertNotNil(
                UIImage(systemName: tab.systemImage),
                "\(tab) uses '\(tab.systemImage)', which does not resolve on this SDK"
            )
        }
    }

    func testEveryTaskerTabIconIsARealSFSymbol() {
        for tab in HDTaskerTab.allCases {
            XCTAssertNotNil(
                UIImage(systemName: tab.systemImage),
                "\(tab) uses '\(tab.systemImage)', which does not resolve on this SDK"
            )
        }
    }

    func testDIYTabNoLongerUsesTheNonExistentToolboxSymbol() {
        XCTAssertNotEqual(HDNesterTab.diy.systemImage, "toolbox.fill")
        XCTAssertNotEqual(HDNesterTab.diy.systemImage, "toolbox")
    }

    func testTabBarFillsItsProposedWidthAtEveryDeviceSize() {
        for contentWidth: CGFloat in [335, 353, 362, 380, 400] {
            let size = measuredSize(
                HDTabBarNester(active: .fix) { _ in }.frame(width: contentWidth),
                proposal: CGSize(width: contentWidth, height: 200)
            )
            XCTAssertEqual(size.width, contentWidth, accuracy: 0.5)
        }
    }

    func testTappingEachNesterTabReportsThatExactTab() {
        for tab in HDNesterTab.allCases {
            var reported: HDNesterTab?
            let bar = HDTabBarNester(active: .fix) { reported = $0 }
            bar.onSelect(tab)
            XCTAssertEqual(reported, tab)
        }
    }

    func testTappingEachTaskerTabReportsThatExactTab() {
        for tab in HDTaskerTab.allCases {
            var reported: HDTaskerTab?
            let bar = HDTabBarTasker(active: .requests) { reported = $0 }
            bar.onSelect(tab)
            XCTAssertEqual(reported, tab)
        }
    }

    func testTabBarHugsAFixedContentHeightRegardlessOfWindowAttachment() throws {
        guard let scene = realWindowScene() else {
            throw XCTSkip("No real UIWindowScene is available in this test bundle; see HouseDashTests for the app-hosted safe-area proof.")
        }

        let widthProposal = CGSize(width: 393, height: 1000)
        let detachedHeight = measuredSize(HDTabBarNester(active: .fix) { _ in }, proposal: widthProposal).height

        let window = UIWindow(windowScene: scene)
        let attachedController = UIHostingController(rootView: HDTabBarNester(active: .fix) { _ in })
        window.rootViewController = attachedController
        window.isHidden = false
        window.makeKeyAndVisible()
        attachedController.view.setNeedsLayout()
        attachedController.view.layoutIfNeeded()

        let attachedHeight = attachedController.sizeThatFits(in: widthProposal).height

        XCTAssertEqual(
            attachedHeight, detachedHeight, accuracy: 1,
            "safe-area accommodation is left to composition (.safeAreaInset plus .ignoresSafeArea), not baked into the bar's own measured size"
        )
    }

    func testChipHugsALongLabelInsteadOfTruncatingIt() {
        let short = measuredSize(HDChip("Label", state: .unselected) {})
        let long = measuredSize(HDChip("Heating and cooling", state: .unselected) {})

        XCTAssertGreaterThan(long.width, short.width)
        XCTAssertGreaterThan(long.width, 92)
    }

    func testChipMeetsTheFortyFourPointTouchTarget() {
        let size = measuredSize(HDChip("Plumbing", state: .selected) {})
        XCTAssertGreaterThanOrEqual(size.height, HDChip.minimumHeight)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testCalendarHeadFillsItsProposedWidthAtEveryDeviceSize() {
        for contentWidth: CGFloat in [335, 353, 362, 380, 400] {
            let size = measuredSize(
                HDCalendarHead(monthYear: "May 2026").frame(width: contentWidth),
                proposal: CGSize(width: contentWidth, height: 200)
            )
            XCTAssertEqual(size.width, contentWidth, accuracy: 0.5)
        }
    }

    private func inkColumnExtent(
        in cgImage: CGImage,
        rows: ClosedRange<Int>,
        columns: ClosedRange<Int>,
        backgroundThreshold: UInt8 = 235
    ) -> (minX: Int, maxX: Int)? {
        guard let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return nil }
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        var minX: Int?
        var maxX: Int?

        for y in rows {
            for x in columns {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = bytes[offset], g = bytes[offset + 1], b = bytes[offset + 2]
                let isBackground = r > backgroundThreshold && g > backgroundThreshold && b > backgroundThreshold
                if !isBackground {
                    minX = min(minX ?? x, x)
                    maxX = max(maxX ?? x, x)
                }
            }
        }

        guard let lo = minX, let hi = maxX else { return nil }
        return (lo, hi)
    }

    func testCalendarHeadMonthLabelIsCenteredRegardlessOfItsWidth() {
        for month in ["May 2026", "October 2026", "September 2026"] {
            let renderer = ImageRenderer(
                content: HDCalendarHead(monthYear: month)
                    .frame(width: 353, height: 74)
                    .background(Color.white)
                    .environment(\.colorScheme, .light)
            )
            renderer.scale = 1

            guard let cgImage = renderer.cgImage else {
                XCTFail("could not render the calendar head for \(month)")
                continue
            }

            guard let extent = inkColumnExtent(in: cgImage, rows: 8...26, columns: 50...302) else {
                XCTFail("could not locate the month label's ink for \(month)")
                continue
            }

            let center = CGFloat(extent.minX + extent.maxX) / 2
            XCTAssertEqual(
                center, 353 / 2, accuracy: 4,
                "\(month) should be centred in the 353pt head, not anchored by its leading edge"
            )
        }
    }

    func testCalendarHeadChevronsMeetTheFortyFourPointTouchTarget() {
        let head = HDCalendarHead(monthYear: "May 2026", onPrevious: {}, onNext: {})

        let leading = measuredSize(head.chevron("‹", action: {}, accessibilityLabel: "Previous month"))
        let trailing = measuredSize(head.chevron("›", action: {}, accessibilityLabel: "Next month"))

        XCTAssertEqual(leading.width, HDCalendarHead.chevronTapTarget, accuracy: 0.5)
        XCTAssertEqual(leading.height, HDCalendarHead.chevronTapTarget, accuracy: 0.5)
        XCTAssertEqual(trailing.width, HDCalendarHead.chevronTapTarget, accuracy: 0.5)
        XCTAssertEqual(trailing.height, HDCalendarHead.chevronTapTarget, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(leading.width, 44)
        XCTAssertGreaterThanOrEqual(leading.height, 44)
    }

    func testTimeSliderFillsItsProposedWidthAtEveryDeviceSize() {
        for contentWidth: CGFloat in [335, 353, 362, 380, 400] {
            let size = measuredSize(
                HDTimeSlider(value: .constant(.single(600))).frame(width: contentWidth),
                proposal: CGSize(width: contentWidth, height: 200)
            )
            XCTAssertEqual(size.width, contentWidth, accuracy: 0.5)
        }
    }

    func testTimeSliderThumbXScalesWithTrackWidthNotAFixedPlaceholder() {
        let slider = HDTimeSlider(value: .constant(.single(6 * 60 + 30)))
        let narrow = slider.x(forMinute: 6 * 60 + 30, trackWidth: 335)
        let wide = slider.x(forMinute: 6 * 60 + 30, trackWidth: 400)

        XCTAssertNotEqual(narrow, wide)
        XCTAssertEqual(narrow / 335, wide / 400, accuracy: 0.001)
    }

    func testTimeSliderThumbSitsAtTheFractionOfItsValueWithinBounds() {
        let slider = HDTimeSlider(value: .constant(.single(0)), bounds: 0...100)
        XCTAssertEqual(slider.x(forMinute: 0, trackWidth: 300), 0, accuracy: 0.01)
        XCTAssertEqual(slider.x(forMinute: 50, trackWidth: 300), 150, accuracy: 0.01)
        XCTAssertEqual(slider.x(forMinute: 100, trackWidth: 300), 300, accuracy: 0.01)
    }

    func testTimeSliderLabelsAreFormattedFromTheValueNotHardcoded() {
        XCTAssertEqual(HDTimeSlider.format(minute: 10 * 60), "10 am")
        XCTAssertEqual(HDTimeSlider.format(minute: 14 * 60), "2 pm")
        XCTAssertEqual(HDTimeSlider.format(minute: 11 * 60 + 30), "11:30 am")
        XCTAssertEqual(HDTimeSlider.format(minute: 18 * 60 + 45), "6:45 pm")
    }

    func testTimeSliderTapExtendsASingleValueIntoARange() {
        let (binding, box) = mutableBinding(HDTimeSliderValue.single(10 * 60))
        let slider = HDTimeSlider(value: binding)
        slider.handleTap(atX: 300, trackWidth: 353)

        if case let .range(range) = box.value {
            XCTAssertEqual(range.start, 10 * 60)
        } else {
            XCTFail("expected a single value to extend into a range on a second tap")
        }
    }

    func testTimeSliderTapCollapsesARangeBackToASingleValue() {
        let (binding, box) = mutableBinding(HDTimeSliderValue.range(start: 10 * 60, end: 14 * 60))
        let slider = HDTimeSlider(value: binding)
        slider.handleTap(atX: 0, trackWidth: 353)

        if case .single = box.value {
        } else {
            XCTFail("expected a range to collapse back to a single value on tap")
        }
    }

    func testTimeSliderThumbTapTargetIsFortyFourPoints() {
        XCTAssertGreaterThanOrEqual(HDTimeSlider.thumbTapTarget, 44)
    }

    func testRatingBarsAndCalendarHeadRequireTheirData() {
        let rows = [HDRatingBarsRow(star: 5, percent: 1.0)]
        XCTAssertEqual(HDRatingBars(rows: rows).rows, rows)
        XCTAssertEqual(HDCalendarHead(monthYear: "May 2026").monthYear, "May 2026")
    }

    func testBubbleIncomingBorderIsAFullPointNotHalfClipped() {
        let scale: CGFloat = 8
        let renderer = ImageRenderer(
            content: HDBubble("Hi", side: .incoming)
                .padding(20)
                .background(Color.white)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = scale

        guard let cgImage = renderer.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            XCTFail("could not render the bubble")
            return
        }

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let midY = cgImage.height / 2

        func pixelComponents(_ x: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
            let offset = midY * bytesPerRow + x * bytesPerPixel
            return (
                r: CGFloat(bytes[offset]) / 255,
                g: CGFloat(bytes[offset + 1]) / 255,
                b: CGFloat(bytes[offset + 2]) / 255
            )
        }

        func resolvedComponents(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
            let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
            return (r, g, b)
        }

        func distance(_ a: (r: CGFloat, g: CGFloat, b: CGFloat), _ b: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
            sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))
        }

        let hairline = resolvedComponents(UIColor(Color.hdHairline))
        let surface = resolvedComponents(UIColor(Color.hdSurface))
        let white = (r: CGFloat(1), g: CGFloat(1), b: CGFloat(1))

        func classify(_ x: Int) -> String {
            let pixel = pixelComponents(x)
            let distances = [
                ("hairline", distance(pixel, hairline)),
                ("surface", distance(pixel, surface)),
                ("white", distance(pixel, white))
            ]
            return distances.min(by: { $0.1 < $1.1 })!.0
        }

        var borderStart: Int?
        let searchStart = Int(20 * scale)
        for x in searchStart..<(searchStart + Int(10 * scale)) {
            if classify(x) != "white" {
                borderStart = x
                break
            }
        }

        guard let start = borderStart else {
            XCTFail("could not locate the bubble's left edge in the render")
            return
        }

        var hairlineRunLength = 0
        var x = start
        while x < start + Int(4 * scale), classify(x) == "hairline" {
            hairlineRunLength += 1
            x += 1
        }

        let expectedFullPointRun = scale
        XCTAssertGreaterThanOrEqual(
            CGFloat(hairlineRunLength), expectedFullPointRun * 0.75,
            "at \(scale)x scale a full 1pt hairline should be about \(Int(scale)) device pixels wide (measured \(hairlineRunLength)), not half-clipped"
        )
    }
}
#endif
