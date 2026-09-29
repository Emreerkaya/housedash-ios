import XCTest

final class IntakeScreensUITests: XCTestCase {
    private static let settleInterval: TimeInterval = 1.2

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private static let auditedCategories: [XCUIAccessibilityAuditType] = [
        .contrast,
        .elementDetection,
        .hitRegion,
        .sufficientElementDescription,
        .textClipped,
        .dynamicType,
        .trait
    ]

    private static let tabBarLabels = ["Fix", "Jobs", "Photo", "DIY", "Profile"]

    private func regionTheAuditCanSample(_ app: XCUIApplication) -> CGRect {
        let window = app.windows.firstMatch.frame
        var bars = Self.tabBarLabels.map { app.buttons[$0] }
        bars.append(app.buttons["action-bar-cta"])
        let barTop = bars
            .filter { $0.exists }
            .map { $0.frame.minY }
            .min()
        guard let barTop, barTop > window.minY else { return window }
        return CGRect(x: window.minX, y: window.minY, width: window.width, height: barTop - window.minY)
    }

    private final class AuditFindings: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [String] = []

        func record(_ line: String) {
            lock.lock()
            lines.append(line)
            lock.unlock()
        }

        var all: [String] {
            lock.lock()
            defer { lock.unlock() }
            return lines
        }
    }

    private func auditEveryCategory(_ app: XCUIApplication, on stage: String) {
        let region = regionTheAuditCanSample(app)
        let findings = AuditFindings()
        for category in Self.auditedCategories {
            try? app.performAccessibilityAudit(for: category) { @Sendable issue in
                guard let element = issue.element, region.contains(element.frame) else { return true }
                findings.record("\(issue.compactDescription) on '\(element.label)' at \(element.frame)")
                return true
            }
        }
        XCTAssertEqual(
            findings.all, [],
            "performAccessibilityAudit on \(stage) reports \(findings.all.count) issues inside the \(region) it can sample: \(findings.all.joined(separator: " · "))"
        )
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

    private func safeTap(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
    }

    private func tap(_ app: XCUIApplication, x: CGFloat, y: CGFloat) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: x, dy: y))
            .tap()
    }

    private func type(
        _ app: XCUIApplication,
        into field: XCUIElement,
        _ text: String
    ) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let cta = app.buttons["action-bar-cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 10))

        var attempts = 0
        while field.frame.maxY > cta.frame.minY && attempts < 6 {
            app.scrollViews.firstMatch.swipeUp()
            settle()
            attempts += 1
        }
        XCTAssertLessThanOrEqual(
            field.frame.maxY, cta.frame.minY,
            "'\(field.identifier)' stays behind the action bar however far the screen is scrolled"
        )

        field.tap()
        settle()
        field.typeText(text)
        settle()
        XCTAssertEqual(field.value as? String, text, "'\(field.identifier)' did not receive the typed text")
    }

    private func launch(contentSize: String = "UICTContentSizeCategoryL") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize]
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
        XCTAssertTrue(
            app.staticTexts["What needs fixing?"].waitForExistence(timeout: 10),
            "the fixture identity service no longer reaches the tab root without a keyboard"
        )
    }

    private func reachPickTheProblem(_ app: XCUIApplication) {
        let drippingTapCard = app.buttons["Dripping tap, $90–140"]
        XCTAssertTrue(drippingTapCard.waitForExistence(timeout: 10))
        safeTap(drippingTapCard)
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 10))
    }

    func testTheActionBarCTARespondsToATapAnywhereOnThePillItDraws() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)
        reachPickTheProblem(app)

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        settle()

        let cta = app.buttons["Next"]
        XCTAssertTrue(cta.waitForExistence(timeout: 10))
        let screenWidth = app.windows.firstMatch.frame.width
        let pillMidY = cta.frame.midY
        let sweep: [CGFloat] = [
            30,
            60,
            90,
            110,
            screenWidth / 2,
            screenWidth - 60,
            screenWidth - 30
        ]

        for x in sweep {
            tap(app, x: x, y: pillMidY)
            settle()
            XCTAssertTrue(
                app.staticTexts["Describe it"].waitForExistence(timeout: 4),
                "a tap at x=\(x), y=\(pillMidY) landed on the drawn CTA and nothing happened"
            )
            app.buttons["Back"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 4))
        }
        attach(app, named: "B02-cta-tap-sweep-complete")
    }

    func testTheCTAIsDisabledUntilThereIsSomethingToSubmit() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)
        reachPickTheProblem(app)

        let disabled = app.buttons["Next, pick a problem first"]
        XCTAssertTrue(disabled.waitForExistence(timeout: 10))
        XCTAssertFalse(disabled.isEnabled, "Next is tappable with nothing selected, so it is a silent no-op")
        attach(app, named: "B02-cta-disabled")

        let screenWidth = app.windows.firstMatch.frame.width
        tap(app, x: screenWidth / 2, y: disabled.frame.midY)
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].exists, "a disabled Next navigated anyway")

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        settle()
        XCTAssertTrue(app.buttons["Next"].isEnabled)
    }

    func testTheFlashIsNotAnnouncedAsAControlItCannotBe() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)

        app.buttons["Photo"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 10))

        XCTAssertFalse(app.buttons["Flash"].exists, "the flash is announced as a button and still does nothing")
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Flash unavailable"))
                .firstMatch
                .exists,
            "there is no flash affordance at all, so a sighted user sees a glyph with no explanation"
        )

        let before = app.buttons.allElementsBoundByIndex.map { $0.label }.sorted()
        app.buttons["Take photo"].tap()
        settle()
        let after = app.buttons.allElementsBoundByIndex.map { $0.label }.sorted()
        XCTAssertNotEqual(before, after, "the shutter changed nothing a screen reader can observe")
        attach(app, named: "B05-after-one-capture")
    }

    func testTheSevenIntakeScreensRenderAcrossBothFlows() throws {
        let app = launch()
        attach(app, named: "A01-launch")
        reachTheTabRootWithoutTyping(app)
        attach(app, named: "B01-fix")
        auditEveryCategory(app, on: "B01 at the default content size")

        reachPickTheProblem(app)
        attach(app, named: "B02-pick-the-problem")
        auditEveryCategory(app, on: "B02 at the default content size")

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
        attach(app, named: "B03-describe-it-clean")
        auditEveryCategory(app, on: "B03 at the default content size")

        type(app, into: app.textFields["What is it doing?"], "call me on 917-555-0199 about the tap")
        app.buttons["See both ways to fix it"].tap()
        settle()
        attach(app, named: "B03-describe-it-rejected")
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "phone number"))
                .firstMatch
                .waitForExistence(timeout: 4)
        )

        let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
        XCTAssertGreaterThan(addPhotoTiles.count, 0)
        addPhotoTiles.firstMatch.tap()
        settle()
        XCTAssertTrue(app.staticTexts["Photograph it"].waitForExistence(timeout: 10))
        attach(app, named: "B06-photograph-it")
        auditEveryCategory(app, on: "B06 at the default content size")

        app.buttons["Take photo"].tap()
        settle()
        app.buttons["Back"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
        attach(app, named: "B03-describe-it-with-photo")

        app.buttons["Change"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 10))

        app.buttons["None of these, Describe it yourself"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["In your own words"].waitForExistence(timeout: 10))
        attach(app, named: "B04-something-else")
        auditEveryCategory(app, on: "B04 at the default content size")

        type(app, into: app.textFields["In your own words"], "The radiator in the back bedroom never gets hot.")
        app.buttons["See both ways to fix it"].tap()
        settle()
        settle()
        XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 10))
        attach(app, named: "B01-fix-with-completion-notice")

        app.buttons["Got it"].tap()
        settle()

        app.buttons["Photo"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 10))
        attach(app, named: "B05-photo")
        auditEveryCategory(app, on: "B05 at the default content size")

        app.buttons["Take photo"].tap()
        settle()
        app.buttons["Review 1 captured photos"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["A few details"].waitForExistence(timeout: 10))
        attach(app, named: "B07-a-few-details")
        auditEveryCategory(app, on: "B07 at the default content size")

        type(app, into: app.textFields["What is it doing?"], "Drips constantly from the tap.")
        app.buttons["See both ways to fix it"].tap()
        settle()
        settle()
        XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 10))
        attach(app, named: "B05-photo-with-completion-notice")
    }

    func testEveryScreenStillReadsAtTheLargestContentSize() throws {
        let app = launch(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        attach(app, named: "AX5-A01-launch")
        reachTheTabRootWithoutTyping(app)
        settle()
        attach(app, named: "AX5-B01-fix")
        auditEveryCategory(app, on: "B01 at the largest content size")

        for label in ["What needs fixing?", "Common in a kitchen", "Under $100", "Worth doing before winter"] {
            XCTAssertTrue(
                app.staticTexts[label].waitForExistence(timeout: 4),
                "'\(label)' is not readable at the largest content size"
            )
        }

        reachPickTheProblem(app)
        attach(app, named: "AX5-B02-pick-the-problem")
        auditEveryCategory(app, on: "B02 at the largest content size")

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
        settle()
        attach(app, named: "AX5-B03-describe-it")
        auditEveryCategory(app, on: "B03 at the largest content size")
        XCTAssertTrue(
            app.staticTexts["Dripping tap or faucet"].exists,
            "the chosen problem title is broken up or missing at the largest content size"
        )

        let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
        addPhotoTiles.firstMatch.tap()
        settle()
        XCTAssertTrue(app.staticTexts["Photograph it"].waitForExistence(timeout: 10))
        attach(app, named: "AX5-B06-photograph-it")
        auditEveryCategory(app, on: "B06 at the largest content size")
        app.buttons["Back"].tap()
        settle()

        app.buttons["Change"].tap()
        settle()
        app.buttons["None of these, Describe it yourself"].tap()
        app.buttons["Next"].tap()
        settle()
        XCTAssertTrue(app.staticTexts["In your own words"].waitForExistence(timeout: 10))
        attach(app, named: "AX5-B04-something-else")
        auditEveryCategory(app, on: "B04 at the largest content size")

        app.buttons["Back"].tap()
        settle()
        app.buttons["Back"].tap()
        settle()
        app.buttons["Photo"].tap()
        settle()
        settle()
        XCTAssertTrue(
            app.staticTexts["Show us the problem"].waitForExistence(timeout: 10),
            "the camera title truncates at the largest content size"
        )
        attach(app, named: "AX5-B05-photo")
        auditEveryCategory(app, on: "B05 at the largest content size")

        app.buttons["Take photo"].tap()
        settle()
        app.buttons["Review 1 captured photos"].tap()
        settle()
        settle()
        XCTAssertTrue(app.staticTexts["A few details"].waitForExistence(timeout: 10))
        attach(app, named: "AX5-B07-a-few-details")
        auditEveryCategory(app, on: "B07 at the largest content size")
    }
}
