import UIKit
import XCTest

@MainActor
final class AuthOTPUITests: XCTestCase {
    private static let settleInterval: TimeInterval = 1.0

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() {
        MainActor.assumeIsolated { XCUIDevice.shared.appearance = .light }
        super.tearDown()
    }

    private enum Band: String {
        case light
        case dark

        var appearance: XCUIDevice.Appearance {
            switch self {
            case .light: .light
            case .dark: .dark
            }
        }
    }

    private func settle() {
        Thread.sleep(forTimeInterval: Self.settleInterval)
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launch(band: Band) -> XCUIApplication {
        XCUIDevice.shared.appearance = band.appearance
        let app = XCUIApplication()
        app.launch()
        settle()
        return app
    }

    private func submitIdentifier(_ app: XCUIApplication, identifier: String? = nil) {
        let field = app.textFields["Email or phone"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        if let identifier {
            field.tap()
            field.typeText(identifier)
            settle()
        }
        app.buttons["Continue"].tap()
        settle()
    }

    private func enterCode(_ app: XCUIApplication, _ code: String) {
        let field = app.textFields["Verification code"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "the code entry field never appeared")
        field.tap()
        field.typeText(code)
        settle()
    }

    private func returnToVerifyCodeScreen(_ app: XCUIApplication) {
        app.buttons["Change"].tap()
        settle()
        submitIdentifier(app)
        XCTAssertTrue(app.staticTexts["Enter your code"].waitForExistence(timeout: 10))
    }

    func testTheAuthFlowInLight() {
        walkTheFlow(band: .light)
    }

    func testTheAuthFlowInDark() {
        walkTheFlow(band: .dark)
    }

    private func walkTheFlow(band: Band) {
        let app = launch(band: band)
        attach(app, named: "\(band)-01-continue")

        submitIdentifier(app, identifier: "dana@example.com")
        XCTAssertTrue(app.staticTexts["Enter your code"].waitForExistence(timeout: 10))
        attach(app, named: "\(band)-02-verify-code-sent")

        enterCode(app, "000000")
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["That code doesn't match. Try again."].waitForExistence(timeout: 10))
        attach(app, named: "\(band)-03-wrong-code")

        returnToVerifyCodeScreen(app)
        enterCode(app, FixtureIdentityServiceCodes.expired)
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(
            app.staticTexts["That code expired. Send a new one to keep going."].waitForExistence(timeout: 10)
        )
        attach(app, named: "\(band)-04-code-expired")

        returnToVerifyCodeScreen(app)
        enterCode(app, FixtureIdentityServiceCodes.tooManyAttempts)
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(
            app.staticTexts["Too many tries. Send a new code to keep going."].waitForExistence(timeout: 10)
        )
        attach(app, named: "\(band)-05-too-many-attempts")

        returnToVerifyCodeScreen(app)
        enterCode(app, FixtureIdentityServiceCodes.rateLimited)
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Too many requests. Try again in 45s."].waitForExistence(timeout: 10))
        attach(app, named: "\(band)-06-rate-limited")

        returnToVerifyCodeScreen(app)
        enterCode(app, FixtureIdentityServiceCodes.offline)
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(
            app.staticTexts["You're offline. Check your connection and try again."].waitForExistence(timeout: 10)
        )
        attach(app, named: "\(band)-07-offline")

        returnToVerifyCodeScreen(app)
        enterCode(app, FixtureIdentityServiceCodes.valid)
        app.buttons["Verify"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Welcome back"].waitForExistence(timeout: 10))
        attach(app, named: "\(band)-08-welcome-back")

        app.buttons["Continue"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 10))
        attach(app, named: "\(band)-09-tab-root")
    }
}

private enum FixtureIdentityServiceCodes {
    static let valid = "123456"
    static let expired = "222222"
    static let tooManyAttempts = "333333"
    static let rateLimited = "444444"
    static let offline = "555555"
}
