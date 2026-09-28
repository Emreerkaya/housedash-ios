import XCTest
@testable import DesignSystem

final class HDFieldSpacingTests: XCTestCase {
    func testFieldInternalLabelToInputGapMatchesItemSpacing() {
        XCTAssertEqual(HDSpacing.item, 8)
    }

    func testStackedFieldsMustUseTheGroupGapNotTheItemGap() {
        XCTAssertGreaterThanOrEqual(
            HDSpacing.group, 9,
            "stacking two HDField instances at Field's own 8pt internal gap made them read as one blurred block; the outer gap between instances must be the group gap"
        )
    }

    func testGroupToItemRatioMeetsR3WhenStackingFields() {
        XCTAssertGreaterThanOrEqual(HDSpacing.groupToItemRatio, HDSpacing.minimumGroupToItemRatio)
    }
}
