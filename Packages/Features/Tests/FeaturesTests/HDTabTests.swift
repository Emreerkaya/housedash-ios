import XCTest
import DesignSystem
@testable import Features

final class HDTabTests: XCTestCase {
    func testFiveTabsInSpecOrder() {
        XCTAssertEqual(HDNesterTab.allCases, [.fix, .jobs, .photo, .diy, .profile])
    }

    func testEveryTabHasALabelAndAnIcon() {
        for tab in HDNesterTab.allCases {
            XCTAssertFalse(tab.label.isEmpty)
            XCTAssertFalse(tab.systemImage.isEmpty)
        }
    }

    func testDIYTabIsNamedByD127NotTheOldToolboxName() {
        XCTAssertEqual(HDNesterTab.diy.label, "DIY")
    }
}
