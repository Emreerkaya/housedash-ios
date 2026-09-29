import XCTest

final class IntakeScreensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func settle() {
        Thread.sleep(forTimeInterval: 1.2)
    }

    private func safeTap(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
    }

    func testTheSevenIntakeScreensRenderAcrossBothFlows() throws {
        let app = XCUIApplication()
        app.launch()
        settle()
        attach(app, named: "A01-launch")

        app.buttons["Continue with Apple"].tap()
        settle()

        let password = app.secureTextFields["Password"]
        XCTAssertTrue(password.waitForExistence(timeout: 5))
        password.tap()
        password.typeText("correct-horse-battery")
        app.keyboards.buttons["Return"].tap()
        settle()
        app.buttons["Create account"].tap()
        settle(); settle()

        XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 5))
        attach(app, named: "B01-fix")

        let drippingTapCard = app.buttons["Dripping tap, $90–140"]
        XCTAssertTrue(drippingTapCard.waitForExistence(timeout: 5))
        safeTap(drippingTapCard)
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 5))
        attach(app, named: "B02-pick-the-problem")

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 5))
        attach(app, named: "B03-describe-it-clean")

        let whatIsItDoing = app.textFields["What is it doing?"]
        XCTAssertTrue(whatIsItDoing.exists)
        whatIsItDoing.tap()
        settle()
        whatIsItDoing.typeText("call me on 917-555-0199 about the tap")
        app.buttons["See both ways to fix it"].tap()
        settle()
        attach(app, named: "B03-describe-it-rejected")
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "phone number"))
                .firstMatch
                .waitForExistence(timeout: 3)
        )

        let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
        XCTAssertGreaterThan(addPhotoTiles.count, 0)
        addPhotoTiles.firstMatch.tap()
        settle()
        XCTAssertTrue(app.staticTexts["Photograph it"].waitForExistence(timeout: 5))
        attach(app, named: "B06-photograph-it")

        app.buttons["Take photo"].tap()
        settle()
        app.buttons["Back"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 5))
        attach(app, named: "B03-describe-it-with-photo")

        app.buttons["Change"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 5))

        app.buttons["None of these, Describe it yourself"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["In your own words"].waitForExistence(timeout: 5))
        attach(app, named: "B04-something-else")

        let composer = app.textFields["composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 3))
        composer.tap()
        settle()
        composer.typeText("The radiator in the back bedroom never gets hot.")
        app.buttons["See both ways to fix it"].tap()
        settle(); settle()
        XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 5))
        attach(app, named: "B01-fix-with-completion-notice")

        app.buttons["Got it"].tap()
        settle()

        app.buttons["Photo"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 5))
        attach(app, named: "B05-photo")

        app.buttons["Take photo"].tap()
        settle()
        app.buttons["Review 1 captured photos"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["A few details"].waitForExistence(timeout: 5))
        attach(app, named: "B07-a-few-details")

        let b07Field = app.textFields["What is it doing?"]
        b07Field.tap()
        settle()
        b07Field.typeText("Drips constantly from the tap.")
        app.buttons["See both ways to fix it"].tap()
        settle(); settle()
        XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 5))
        attach(app, named: "B05-photo-with-completion-notice")
    }
}
