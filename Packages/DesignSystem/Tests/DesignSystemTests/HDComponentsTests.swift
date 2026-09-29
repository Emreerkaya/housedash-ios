import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

@MainActor
final class HDComponentsTests: XCTestCase {

    #if canImport(UIKit)
    private func measuredSize<V: View>(_ view: V, proposal: CGSize = CGSize(width: 1000, height: 1000)) -> CGSize {
        let controller = UIHostingController(rootView: view)
        return controller.sizeThatFits(in: proposal)
    }
    #endif

    #if canImport(UIKit)
    func testAllThreeTwinCardVariantsReportIdenticalSize() {
        let diy = measuredSize(HDTwinCard(.diy(.diyExample)))
        let hire = measuredSize(HDTwinCard(.hire(.hireExample)))
        let locked = measuredSize(HDTwinCard(.locked(.example)))

        XCTAssertEqual(diy, HDTwinCard.size)
        XCTAssertEqual(hire, HDTwinCard.size)
        XCTAssertEqual(locked, HDTwinCard.size)
        XCTAssertEqual(diy, hire)
        XCTAssertEqual(hire, locked)
    }

    func testLockedVariantKeepsFullHeightWithShorterContent() {
        let locked = measuredSize(HDTwinCard(.locked(.example)))
        XCTAssertEqual(locked.height, HDTwinCard.size.height)
        XCTAssertEqual(locked.width, HDTwinCard.size.width)
    }

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
