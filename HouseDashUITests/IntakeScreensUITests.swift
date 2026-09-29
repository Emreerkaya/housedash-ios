import CoreGraphics
import UIKit
import XCTest

final class IntakeScreensUITests: XCTestCase {
    private static let settleInterval: TimeInterval = 1.2

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
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

    private static let brightestMeanADarkScreenDraws: Double = 0.35

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
                guard let element = issue.element else {
                    findings.record("\(issue.compactDescription) names no element, so it cannot be placed inside or outside the region and is kept")
                    return true
                }
                guard region.contains(element.frame) else { return true }
                findings.record("\(issue.compactDescription) on '\(element.label)' at \(element.frame)")
                return true
            }
        }
        XCTAssertEqual(
            findings.all, [],
            "performAccessibilityAudit on \(stage) reports \(findings.all.count) issues inside the \(region) it can sample: \(findings.all.joined(separator: " · "))"
        )
    }

    private static let headerTraitBit: UInt64 = 65536
    private static let headerHeightAtTheDefaultContentSize: CGFloat = 37.33
    private static let shortestHeaderAnAccessibilitySizeDraws: CGFloat = 100

    private func traitMask(_ element: XCUIElement) -> UInt64? {
        (element.value(forKey: "traits") as? NSNumber)?.uint64Value
    }

    private func assertIsAHeading(_ element: XCUIElement, _ site: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(site) is not on screen at all")
        guard let mask = traitMask(element) else {
            return XCTFail("\(site) reports no trait mask, so no heading anywhere can be held to the trait")
        }
        XCTAssertEqual(
            mask & Self.headerTraitBit, Self.headerTraitBit,
            "\(site) reads traits=\(mask), which does not carry UIAccessibilityTraits.header"
        )
    }

    private func assertIsNotAHeading(_ element: XCUIElement, _ site: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(site) is not on screen at all")
        guard let mask = traitMask(element) else {
            return XCTFail("\(site) reports no trait mask, so this test cannot fail in either direction")
        }
        XCTAssertEqual(
            mask & Self.headerTraitBit, 0,
            "\(site) reads traits=\(mask) and carries the header trait, so everything on the screen is a heading"
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
        XCTAssertTrue(
            field.waitForExistence(timeout: 10),
            "the field to type into never appeared, so nothing below measured anything"
        )
        let cta = app.buttons["action-bar-cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 10),
            "the action bar CTA never appeared, so the scroll below has nothing to scroll the field clear of"
        )

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

    private func launch(
        contentSize: String = "UICTContentSizeCategoryL",
        band: Band = .light
    ) -> XCUIApplication {
        XCUIDevice.shared.appearance = band.appearance
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize]
        app.launch()
        settle()
        assertTheScreenIsDrawnIn(band, app)
        return app
    }

    private func meanLuminance(of app: XCUIApplication) -> Double? {
        guard let image = app.screenshot().image.cgImage else { return nil }
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard
            let context = CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        func linearise(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        var total = 0.0
        var counted = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            total += 0.2126 * linearise(Double(pixels[index]) / 255)
                + 0.7152 * linearise(Double(pixels[index + 1]) / 255)
                + 0.0722 * linearise(Double(pixels[index + 2]) / 255)
            counted += 1
        }
        return counted == 0 ? nil : total / Double(counted)
    }

    private func assertTheScreenIsDrawnIn(_ band: Band, _ app: XCUIApplication) {
        guard let mean = meanLuminance(of: app) else {
            return XCTFail("the screenshot carried no pixels, so this run cannot say which band it drew")
        }
        switch band {
        case .light:
            XCTAssertGreaterThan(
                mean, Self.brightestMeanADarkScreenDraws,
                "this run says light and the screen means \(String(format: "%.3f", mean)) luminance, so it is drawing dark and every audit below is measuring the other band"
            )
        case .dark:
            XCTAssertLessThan(
                mean, Self.brightestMeanADarkScreenDraws,
                "this run says dark and the screen means \(String(format: "%.3f", mean)) luminance, so the appearance never took and the dark band is still unexercised"
            )
        }
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
        XCTAssertTrue(
            drippingTapCard.waitForExistence(timeout: 10),
            "the Dripping tap card is not on B01, so the rest of this flow cannot start"
        )
        safeTap(drippingTapCard)
        settle()
        XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 10))
    }

    func testTheSuiteDrawsBothBandsAndTheyAreNotTheSameScreen() throws {
        XCTAssertEqual(
            Band.allCases.count, 2,
            "the suite lists \(Band.allCases.map(\.rawValue)) bands, so the walks below that loop over them enter fewer than both"
        )
        var means: [Band: Double] = [:]
        for band in Band.allCases {
            let app = launch(band: band)
            reachTheTabRootWithoutTyping(app)
            let mean = meanLuminance(of: app)
            XCTAssertNotNil(mean, "B01 in \(band.rawValue) produced no pixels, so its band cannot be told apart from any other")
            means[band] = mean ?? 0
            attach(app, named: "band-probe-\(band.rawValue)")
        }
        let light = means[.light] ?? 0
        let dark = means[.dark] ?? 0
        XCTAssertGreaterThan(
            light - dark, Self.brightestMeanADarkScreenDraws,
            "B01 means \(String(format: "%.3f", light)) in light and \(String(format: "%.3f", dark)) in dark, so the two bands render the same screen and every audit below runs one band twice"
        )
    }

    func testTheActionBarCTARespondsToATapAnywhereOnThePillItDraws() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)
        reachPickTheProblem(app)

        app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
        settle()

        let cta = app.buttons["Next"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 10),
            "there is no Next button on B02 to sweep taps across"
        )
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
        XCTAssertTrue(
            disabled.waitForExistence(timeout: 10),
            "Next is not announced as disabled with nothing selected, so its label no longer says why"
        )
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
        for band in Band.allCases {
            let app = launch(band: band)
            attach(app, named: "\(band.rawValue)-A01-launch")
            reachTheTabRootWithoutTyping(app)
            attach(app, named: "\(band.rawValue)-B01-fix")

            XCTAssertLessThan(
                app.staticTexts["What needs fixing?"].frame.height,
                Self.shortestHeaderAnAccessibilitySizeDraws,
                "the B01 header is \(app.staticTexts["What needs fixing?"].frame.height)pt, so this run is not at the default content size and the pair of content-size passes is measuring one size twice"
            )
            auditEveryCategory(app, on: "\(band.rawValue) B01 at the default content size")

            reachPickTheProblem(app)
            attach(app, named: "\(band.rawValue)-B02-pick-the-problem")
            auditEveryCategory(app, on: "\(band.rawValue) B02 at the default content size")

            app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
            app.buttons["Next"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B03-describe-it-clean")
            auditEveryCategory(app, on: "\(band.rawValue) B03 at the default content size")

            type(app, into: app.textFields["What is it doing?"], "call me on 917-555-0199 about the tap")
            app.buttons["See both ways to fix it"].tap()
            settle()
            attach(app, named: "\(band.rawValue)-B03-describe-it-rejected")
            XCTAssertTrue(
                app.descendants(matching: .any)
                    .matching(NSPredicate(format: "label CONTAINS[c] %@", "phone number"))
                    .firstMatch
                    .waitForExistence(timeout: 4)
            )

            let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
            XCTAssertGreaterThan(
                addPhotoTiles.count, 0,
                "B03 offers no add-photo tile, so the camera is unreachable from the description step"
            )
            addPhotoTiles.firstMatch.tap()
            settle()
            XCTAssertTrue(app.staticTexts["Photograph it"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B06-photograph-it")
            auditEveryCategory(app, on: "\(band.rawValue) B06 at the default content size")

            app.buttons["Take photo"].tap()
            settle()
            app.buttons["Back"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B03-describe-it-with-photo")

            app.buttons["Change"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Pick the problem"].waitForExistence(timeout: 10))

            app.buttons["None of these, Describe it yourself"].tap()
            app.buttons["Next"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["In your own words"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B04-something-else")
            auditEveryCategory(app, on: "\(band.rawValue) B04 at the default content size")

            type(app, into: app.textFields["In your own words"], "The radiator in the back bedroom never gets hot.")
            app.buttons["See both ways to fix it"].tap()
            settle()
            settle()
            XCTAssertTrue(app.staticTexts["What needs fixing?"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B01-fix-with-completion-notice")

            app.buttons["Got it"].tap()
            settle()

            app.buttons["Photo"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B05-photo")
            auditEveryCategory(app, on: "\(band.rawValue) B05 at the default content size")

            app.buttons["Take photo"].tap()
            settle()
            app.buttons["Review 1 captured photos"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["A few details"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B07-a-few-details")
            auditEveryCategory(app, on: "\(band.rawValue) B07 at the default content size")

            type(app, into: app.textFields["What is it doing?"], "Drips constantly from the tap.")
            app.buttons["See both ways to fix it"].tap()
            settle()
            settle()
            XCTAssertTrue(app.staticTexts["Show us the problem"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-B05-photo-with-completion-notice")
        }
    }

    func testEveryScreenStillReadsAtTheLargestContentSize() throws {
        for band in Band.allCases {
            let app = launch(contentSize: "UICTContentSizeCategoryAccessibilityXXXL", band: band)
            attach(app, named: "\(band.rawValue)-AX5-A01-launch")
            reachTheTabRootWithoutTyping(app)
            settle()
            attach(app, named: "\(band.rawValue)-AX5-B01-fix")

            XCTAssertGreaterThan(
                app.staticTexts["What needs fixing?"].frame.height,
                Self.shortestHeaderAnAccessibilitySizeDraws,
                "the B01 header is \(app.staticTexts["What needs fixing?"].frame.height)pt, and it is \(Self.headerHeightAtTheDefaultContentSize)pt at the default content size, so this run is not at an accessibility content size and nothing below measures one"
            )
            auditEveryCategory(app, on: "\(band.rawValue) B01 at the largest content size")

            for label in ["What needs fixing?", "Common in a kitchen", "Under $100", "Worth doing before winter"] {
                XCTAssertTrue(
                    app.staticTexts[label].waitForExistence(timeout: 4),
                    "'\(label)' is not readable at the largest content size"
                )
            }

            reachPickTheProblem(app)
            attach(app, named: "\(band.rawValue)-AX5-B02-pick-the-problem")
            auditEveryCategory(app, on: "\(band.rawValue) B02 at the largest content size")

            app.buttons["Drips constantly, Worse when the hot tap is on, $90–140"].tap()
            app.buttons["Next"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["Describe it"].waitForExistence(timeout: 10))
            settle()
            attach(app, named: "\(band.rawValue)-AX5-B03-describe-it")
            auditEveryCategory(app, on: "\(band.rawValue) B03 at the largest content size")
            XCTAssertTrue(
                app.staticTexts["Dripping tap or faucet"].exists,
                "the chosen problem title is broken up or missing at the largest content size"
            )

            let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
            addPhotoTiles.firstMatch.tap()
            settle()
            XCTAssertTrue(app.staticTexts["Photograph it"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-AX5-B06-photograph-it")
            auditEveryCategory(app, on: "\(band.rawValue) B06 at the largest content size")
            app.buttons["Back"].tap()
            settle()

            app.buttons["Change"].tap()
            settle()
            app.buttons["None of these, Describe it yourself"].tap()
            app.buttons["Next"].tap()
            settle()
            XCTAssertTrue(app.staticTexts["In your own words"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-AX5-B04-something-else")
            auditEveryCategory(app, on: "\(band.rawValue) B04 at the largest content size")

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
            attach(app, named: "\(band.rawValue)-AX5-B05-photo")
            auditEveryCategory(app, on: "\(band.rawValue) B05 at the largest content size")

            app.buttons["Take photo"].tap()
            settle()
            app.buttons["Review 1 captured photos"].tap()
            settle()
            settle()
            XCTAssertTrue(app.staticTexts["A few details"].waitForExistence(timeout: 10))
            attach(app, named: "\(band.rawValue)-AX5-B07-a-few-details")
            auditEveryCategory(app, on: "\(band.rawValue) B07 at the largest content size")
        }
    }

    func testEveryHeadingSiteCarriesTheHeaderTrait() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)

        assertIsAHeading(app.staticTexts["What needs fixing?"], "HDHeader's title on B01")
        assertIsAHeading(app.staticTexts["Common in a kitchen"], "HDGroupHeading on B01")
        assertIsNotAHeading(app.staticTexts["Dripping tap"], "a rail card's title on B01")
        assertIsNotAHeading(app.staticTexts["$90\u{2013}140"], "a rail card's price on B01")

        reachPickTheProblem(app)
        assertIsAHeading(app.staticTexts["Pick the problem"], "HDHeader's title on B02")

        app.buttons["Drips constantly, Worse when the hot tap is on, $90\u{2013}140"].tap()
        app.buttons["Next"].tap()
        settle()
        assertIsAHeading(app.staticTexts["Describe it"], "HDHeader's title on B03")
        assertIsAHeading(app.staticTexts["Photos"], "HDGroupHeading on B03")

        let addPhotoTiles = app.buttons.matching(identifier: "photo-add-tile")
        addPhotoTiles.firstMatch.tap()
        settle()
        assertIsAHeading(app.staticTexts["Photograph it"], "the camera navigation title on B06")
        app.buttons["Back"].tap()
        settle()

        type(app, into: app.textFields["What is it doing?"], "The tap drips whenever the hot side is on.")
        app.buttons["See both ways to fix it"].tap()
        settle()
        settle()
        assertIsAHeading(
            app.staticTexts.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Case ready")
            ).firstMatch,
            "IntakeCaseReadyNotice's headline on B01"
        )

        app.buttons["Got it"].tap()
        settle()
        app.buttons["Photo"].tap()
        settle()
        assertIsAHeading(app.staticTexts["Show us the problem"], "the camera navigation title on B05")
    }

    func testEveryTabRespondsToATapAnywhereAcrossTheSlotItDraws() throws {
        let app = launch()
        reachTheTabRootWithoutTyping(app)

        let roots = [
            ("Jobs", "Jobs"),
            ("DIY", "Toolbox"),
            ("Profile", "Profile"),
            ("Photo", "Show us the problem")
        ]
        let offsets: [CGFloat] = [0.06, 0.25, 0.5, 0.75, 0.94]

        for (tab, heading) in roots {
            for offset in offsets {
                let fix = app.buttons["Fix"]
                XCTAssertTrue(fix.waitForExistence(timeout: 10), "the Fix tab is gone, so this sweep cannot return to a known screen")
                fix.tap()
                settle()
                XCTAssertTrue(
                    app.staticTexts["What needs fixing?"].waitForExistence(timeout: 6),
                    "tapping Fix did not return to B01, so the next assertion cannot tell a dead tap from a stale screen"
                )

                let button = app.buttons[tab]
                XCTAssertTrue(button.waitForExistence(timeout: 6), "the \(tab) tab is not on screen")
                let index = try XCTUnwrap(Self.tabBarLabels.firstIndex(of: tab))
                let slotWidth = app.windows.firstMatch.frame.width / CGFloat(Self.tabBarLabels.count)
                let x = slotWidth * (CGFloat(index) + offset)
                XCTAssertLessThanOrEqual(
                    button.frame.width, slotWidth + 1,
                    "the \(tab) button reports a frame wider than the \(slotWidth)pt slot it is drawn in, so the sweep below is aiming outside the bar"
                )
                tap(app, x: x, y: button.frame.midY)
                settle()
                XCTAssertTrue(
                    app.staticTexts[heading].waitForExistence(timeout: 6),
                    "a tap \(Int(offset * 100))% across the \(tab) slot, at x=\(x) y=\(button.frame.midY), landed on the drawn tab bar and nothing happened; the \(tab) button reports a \(button.frame.width)pt frame in a \(slotWidth)pt slot"
                )
            }
        }
        attach(app, named: "tab-bar-tap-sweep-complete")
    }
}
