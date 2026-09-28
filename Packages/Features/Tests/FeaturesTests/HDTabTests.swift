import XCTest
@testable import Features

final class HDTabTests: XCTestCase {
    func testFiveTabsInSpecOrder() {
        XCTAssertEqual(HDTab.allCases, [.fix, .jobs, .photo, .toolbox, .profile])
    }

    func testEveryTabHasATitleAndAnIcon() {
        for tab in HDTab.allCases {
            XCTAssertFalse(tab.title.isEmpty)
            XCTAssertFalse(tab.systemImage.isEmpty)
        }
    }
}
