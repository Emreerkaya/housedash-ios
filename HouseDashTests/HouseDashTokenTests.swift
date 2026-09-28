import XCTest
import UIKit
@testable import DesignSystem

final class HouseDashTokenTests: XCTestCase {
    func testGroundTokenResolvesDifferentlyInLightAndDark() {
        let dynamicColor = UIColor(hdToken: .ground)
        let resolvedLight = dynamicColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let resolvedDark = dynamicColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertNotEqual(resolvedLight, resolvedDark)
    }

    func testGroupToItemSpacingRatioHoldsR3() {
        XCTAssertGreaterThanOrEqual(HDSpacing.groupToItemRatio, HDSpacing.minimumGroupToItemRatio)
        XCTAssertEqual(HDSpacing.group, 24)
        XCTAssertEqual(HDSpacing.item, 8)
    }

    func testCanonicalLeftMarginIsTwentyPoints() {
        XCTAssertEqual(HDSpacing.margin, 20)
    }
}
