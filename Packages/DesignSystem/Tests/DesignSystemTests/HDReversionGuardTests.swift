import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDReversionGuardTests: XCTestCase {
    private func measuredSize<V: View>(
        _ view: V,
        width: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: CGSize(width: width, height: CGFloat.infinity))
    }

    func testAChipLabelScalesToOneLineRatherThanBreakingTheWordAcrossTwo() {
        let chipWidth: CGFloat = 100
        let chip = measuredSize(
            HDChip("Kitchen", state: .unselected) {}.frame(width: chipWidth),
            width: chipWidth,
            dynamicTypeSize: .accessibility5
        )
        let wrappedWithoutAScaleFactor = measuredSize(
            HDText("Kitchen", style: HDType.label, color: .hdInk),
            width: chipWidth - 2 * 18,
            dynamicTypeSize: .accessibility5
        )

        XCTAssertLessThan(
            chip.height, wrappedWithoutAScaleFactor.height,
            "the chip is \(chip.height)pt where an unscaled label needs \(wrappedWithoutAScaleFactor.height)pt, "
                + "so the label is wrapping instead of scaling"
        )
        XCTAssertEqual(chip.height, HDChip.minimumHeight, accuracy: 0.5)
    }

    func testTheActionBarReportsTheHeightItsCTAActuallyNeeds() {
        let bar = HDActionBar(ctaTitle: "See both ways to fix it") {}
        let normal = measuredSize(bar, width: 402, dynamicTypeSize: .large)
        let huge = measuredSize(bar, width: 402, dynamicTypeSize: .accessibility5)

        XCTAssertGreaterThan(
            huge.height, normal.height,
            "the bar is \(huge.height)pt at accessibility5 and \(normal.height)pt at large, so it is pinned "
                + "to a fixed height and will bleed over the content above it"
        )

        let ctaTitle = measuredSize(
            HDText("See both ways to fix it", style: HDType.bodyStrong, color: .hdOnContext),
            width: 402 - 2 * HDSpacing.margin,
            dynamicTypeSize: .accessibility5
        )
        XCTAssertGreaterThanOrEqual(huge.height, ctaTitle.height, "the bar is shorter than the title inside it")
    }

    func testADisabledCTAIsNotDrawnInTheSameFillAsAnEnabledOne() {
        let enabled = HDActionBar(ctaTitle: "Next") {}
        let disabled = HDActionBar(ctaTitle: "Next", isCTAEnabled: false, disabledExplanation: "pick a problem first") {}

        for style in [UIUserInterfaceStyle.light, .dark] {
            let trait = UITraitCollection(userInterfaceStyle: style)
            XCTAssertNotEqual(
                UIColor(enabled.ctaFill).resolvedColor(with: trait),
                UIColor(disabled.ctaFill).resolvedColor(with: trait),
                "a disabled CTA resolves to the same fill as an enabled one in \(style == .light ? "light" : "dark")"
            )
        }
        XCTAssertEqual(enabled.ctaAccessibilityLabel, "Next")
        XCTAssertEqual(disabled.ctaAccessibilityLabel, "Next, pick a problem first")
    }

    func testEveryTabBarButtonMeetsTheFortyFourPointTouchTargetAndScalesWithDynamicType() {
        for width: CGFloat in [335, 353, 402] {
            let normal = measuredSize(
                HDTabBarNester(active: .fix) { _ in }.frame(width: width),
                width: width,
                dynamicTypeSize: .large
            )
            let huge = measuredSize(
                HDTabBarNester(active: .fix) { _ in }.frame(width: width),
                width: width,
                dynamicTypeSize: .accessibility5
            )

            XCTAssertGreaterThanOrEqual(
                normal.height, HDTabBarChromeMetrics.minimumTouchTarget,
                "a \(width)pt bar is only \(normal.height)pt tall, so no button in it can reach 44pt"
            )
            XCTAssertGreaterThan(
                huge.height, normal.height,
                "the tab labels are the same size at accessibility5 as at large"
            )
        }
    }

    func testEachTabBarButtonFillsItsSlotAndClearsFortyFourPointsOnItsOwn() {
        let slotWidth = 402 / CGFloat(HDNesterTab.allCases.count)
        for tab in HDNesterTab.allCases {
            let size = measuredSize(
                HDTabBarNesterButton(tab: tab, isActive: tab == .fix),
                width: slotWidth,
                dynamicTypeSize: .large
            )
            XCTAssertGreaterThanOrEqual(
                size.height, HDTabBarChromeMetrics.minimumTouchTarget,
                "the \(tab.label) button is \(size.height)pt tall on its own, so its hit region misses 44pt"
            )
            XCTAssertEqual(
                size.width, slotWidth, accuracy: 0.5,
                "the \(tab.label) button is \(size.width)pt wide in an \(slotWidth)pt slot, so most of the slot is dead"
            )
        }
    }

    func testTheChosenRowGivesItsTitleTheWholeWidthAtAccessibilitySizes() {
        let contentWidth: CGFloat = 353
        let row = HDIdentityRow(primary: "Dripping tap or faucet", secondary: "Water · $90–140 typical", onChange: {})
        let changeWidth = measuredSize(row.changeButton, width: 1000, dynamicTypeSize: .accessibility5).width
        let gutters = 2 * HDIdentityRow.horizontalPadding
        let available = HDIdentityRow.stacks(at: .accessibility5)
            ? contentWidth - gutters
            : contentWidth - gutters - changeWidth - HDSpacing.item

        for word in ["Dripping", "faucet"] {
            let needed = measuredSize(
                HDText(word, style: HDType.bodyStrong, color: .hdInk),
                width: 10_000,
                dynamicTypeSize: .accessibility5
            ).width
            XCTAssertGreaterThanOrEqual(
                available, needed,
                "'\(word)' needs \(needed)pt and the row gives its title \(available)pt, so it breaks mid-word"
            )
        }
    }

    func testEveryTabLabelStillFitsItsSlotAtTheLargestContentSize() {
        let deviceWidth: CGFloat = 402
        let slotWidth = deviceWidth / CGFloat(HDNesterTab.allCases.count)
        let available = slotWidth - 2 * HDTabBarChromeMetrics.slotPadding

        for tab in HDNesterTab.allCases {
            let ideal = measuredSize(
                HDText(tab.label, style: HDTabBarChromeMetrics.labelStyle(weight: .semibold), color: .hdInk),
                width: 10_000,
                dynamicTypeSize: .accessibility5
            ).width
            XCTAssertLessThanOrEqual(
                ideal * HDTabBarChromeMetrics.labelScaleFloor, available,
                "'\(tab.label)' needs \(ideal * HDTabBarChromeMetrics.labelScaleFloor)pt at its scale floor "
                    + "and the slot offers \(available)pt, so it is clipped"
            )
        }
    }

    func testTheTabBarLabelStyleIsTheOneDynamicTypeScales() {
        XCTAssertEqual(HDTabBarChromeMetrics.labelStyle(weight: .regular).size, HDTabBarChromeMetrics.labelSize)
        XCTAssertEqual(HDTabBarChromeMetrics.labelStyle(weight: .semibold).weight, .semibold)
    }
}
#endif
