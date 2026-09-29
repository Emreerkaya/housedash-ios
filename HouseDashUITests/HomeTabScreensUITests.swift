import CoreGraphics
import UIKit
import XCTest

@MainActor
final class HomeTabScreensUITests: XCTestCase {
    private static let settleInterval: TimeInterval = 1.2

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() {
        MainActor.assumeIsolated { XCUIDevice.shared.appearance = .light }
        super.tearDown()
    }

    private enum Band: String, CaseIterable {
        case light
        case dark

        var appearance: XCUIDevice.Appearance {
            switch self {
            case .light: .light
            case .dark: .dark
            }
        }
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func settle() {
        Thread.sleep(forTimeInterval: Self.settleInterval)
    }

    private func launch(band: Band) -> XCUIApplication {
        XCUIDevice.shared.appearance = band.appearance
        let app = XCUIApplication()
        app.launch()
        settle()
        return app
    }

    private func reachTheTabRootWithoutTyping(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Continue with Apple"].waitForExistence(timeout: 10))
        app.buttons["Continue with Apple"].tap()
        settle()
        XCTAssertTrue(app.buttons["Create account"].waitForExistence(timeout: 10))
        app.buttons["Create account"].tap()
        settle()
        settle()
        XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 10))
    }

    func testJobsToolboxAndProfileRenderAcrossBothBands() throws {
        for band in Band.allCases {
            let app = launch(band: band)
            reachTheTabRootWithoutTyping(app)

            app.buttons["Jobs"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Jobs"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["Upcoming"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["Past"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-jobs-upcoming")

            app.buttons["Past"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Nothing finished yet"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-jobs-past")

            app.buttons["DIY"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Toolbox"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["Saved"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["Done myself"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-toolbox-saved")

            app.buttons["Done myself"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Nothing marked done yet"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-toolbox-done-myself")

            app.buttons["Profile"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 10))
            let signIn = app.buttons["Sign in"]
            XCTAssertTrue(signIn.waitForExistence(timeout: 10))
            XCTAssertFalse(signIn.isEnabled, "Sign in is tappable with no account setup wired up, so it is a silent no-op")
            attach(app, named: "\(band.rawValue)-profile")
        }
    }
}
