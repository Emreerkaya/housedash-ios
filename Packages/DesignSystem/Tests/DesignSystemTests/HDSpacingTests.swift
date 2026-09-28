import XCTest
@testable import DesignSystem

final class HDSpacingTests: XCTestCase {
    func testGroupToItemRatioMeetsR3Minimum() {
        XCTAssertGreaterThanOrEqual(HDSpacing.groupToItemRatio, HDSpacing.minimumGroupToItemRatio)
    }

    func testGroupToItemRatioMatchesGeneratedTokens() {
        XCTAssertEqual(HDSpacing.group, 24)
        XCTAssertEqual(HDSpacing.item, 8)
        XCTAssertEqual(HDSpacing.groupToItemRatio, 3.0, accuracy: 0.0001)
    }

    func testMarginIsCanonicalTwentyPoints() {
        XCTAssertEqual(HDSpacing.margin, 20)
    }
}
