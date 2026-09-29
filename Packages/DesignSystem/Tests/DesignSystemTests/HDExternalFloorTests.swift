import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

final class HDExternalFloorTests: XCTestCase {
    private static let pointsWCAGAsksForATouchTarget: CGFloat = 44

    func testEveryConstantStandingInForWCAGsTouchTargetStillIsIt() {
        for (name, value) in [
            ("HDTabBarChromeMetrics.minimumTouchTarget", HDTabBarChromeMetrics.minimumTouchTarget),
            ("HDIdentityRow.minimumChangeTouchTarget", HDIdentityRow.minimumChangeTouchTarget),
            ("HDChip.minimumHeight", HDChip.minimumHeight),
            ("HDHeader.minimumBackTouchTarget", HDHeader.minimumBackTouchTarget)
        ] {
            XCTAssertGreaterThanOrEqual(
                value, Self.pointsWCAGAsksForATouchTarget,
                "\(name) is \(value), and WCAG's \(Self.pointsWCAGAsksForATouchTarget) points is not ours to move"
            )
        }
    }

    func testTheRowHeightsThatCarryATouchTargetClearItToo() {
        for (name, value) in [
            ("HDIdentityRow.minimumHeight", HDIdentityRow.minimumHeight),
            ("HDFieldMetrics.minimumHeight", HDFieldMetrics.minimumHeight)
        ] {
            XCTAssertGreaterThanOrEqual(
                value, Self.pointsWCAGAsksForATouchTarget,
                "\(name) is \(value), below the \(Self.pointsWCAGAsksForATouchTarget) points a row someone taps has to reach"
            )
        }
    }

    #if canImport(UIKit)
    func testTheSelectedChipDrawsABoundaryItsUnselectedTwinDoesNot() {
        let selected = UIColor(HDChip("Kitchen", state: .selected) {}.boundary)
        let unselected = UIColor(HDChip("Kitchen", state: .unselected) {}.boundary)
        let ground = UIColor(Color.hdGround)
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        var alpha: CGFloat = 0
        unselected.resolvedColor(with: dark).getWhite(nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0, accuracy: 0.001, "an unselected chip draws a boundary too, so the boundary marks nothing")

        var selectedAlpha: CGFloat = 0
        selected.resolvedColor(with: dark).getWhite(nil, alpha: &selectedAlpha)
        XCTAssertEqual(
            selectedAlpha, 1, accuracy: 0.001,
            "the selected chip's boundary is transparent in dark, where its fill is 1.45:1 against an unselected chip's"
        )
        XCTAssertGreaterThanOrEqual(
            ratio(selected.resolvedColor(with: dark), ground.resolvedColor(with: dark)), 3,
            "the boundary that carries the selected state in dark does not read against the screen behind it"
        )
        XCTAssertGreaterThan(
            HDChip.selectedBoundaryWidth, 0,
            "the boundary is drawn at zero width, so its colour is irrelevant"
        )
    }

    private func ratio(_ first: UIColor, _ second: UIColor) -> Double {
        let lighter = max(luminance(first), luminance(second))
        let darker = min(luminance(first), luminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func luminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linearise(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearise(red) + 0.7152 * linearise(green) + 0.0722 * linearise(blue)
    }
    #endif
}
