import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignSystem
@testable import Features

#if canImport(UIKit)
@MainActor
final class HomeTabEmptyStateTests: XCTestCase {
    private static let forbidden = "Placeholder|Lorem|TODO|Coming soon|assembles here"

    private func measuredSize<V: View>(
        _ view: V,
        width: CGFloat = 393,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: CGSize(width: width, height: CGFloat.infinity))
    }

    private func bodyTypeName<V: View>(_ view: V) -> String {
        String(describing: type(of: view.body))
    }

    private func assertHonestCopy(_ text: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let expression = try XCTUnwrap(try? NSRegularExpression(pattern: Self.forbidden))
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        XCTAssertNil(
            expression.firstMatch(in: text, range: range),
            "'\(text)' still reads as an unfinished screen",
            file: file,
            line: line
        )
        XCTAssertFalse(text.isEmpty, file: file, line: line)
    }

    // MARK: Jobs

    func testJobsChipsCoverBothFiltersAndEachRendersItsOwnHonestEmptyMessage() throws {
        for filter: JobsHomeScreen.Filter in [.upcoming, .past] {
            let screen = JobsHomeScreen(initialFilter: filter)
            try assertHonestCopy(screen.emptyStateHeading)
            try assertHonestCopy(screen.emptyStateMessage)
        }
        XCTAssertNotEqual(
            JobsHomeScreen.message(for: .upcoming), JobsHomeScreen.message(for: .past),
            "the two filters must not share one message, or selecting a chip changes nothing a person can see"
        )
        XCTAssertNotEqual(JobsHomeScreen.heading(for: .upcoming), JobsHomeScreen.heading(for: .past))
    }

    func testJobsInitialFilterDrivesTheRenderedEmptyState() {
        XCTAssertEqual(JobsHomeScreen(initialFilter: .upcoming).emptyStateMessage, JobsHomeScreen.message(for: .upcoming))
        XCTAssertEqual(JobsHomeScreen(initialFilter: .past).emptyStateMessage, JobsHomeScreen.message(for: .past))
    }

    func testJobsBodyEmbedsTheFilterChips() {
        XCTAssertTrue(bodyTypeName(JobsHomeScreen()).contains("HDChip"), "the two filter controls are gone from the screen body")
    }

    func testJobsSupportLineIsARealWorkingLink() throws {
        try assertHonestCopy(JobsHomeScreen.supportLine)
        XCTAssertTrue(JobsHomeScreen.supportLine.contains("[Message support](https://housedash.app/support)"))
    }

    func testJobsGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(JobsHomeScreen(), dynamicTypeSize: .large)
        let huge = measuredSize(JobsHomeScreen(), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testJobsFilterChipsMeetTheFortyFourPointTouchTarget() {
        let chip = measuredSize(HDChip("Upcoming", state: .selected) {})
        XCTAssertGreaterThanOrEqual(chip.height, 44)
    }

    // MARK: Toolbox

    func testToolboxChipsCoverBothFociAndEachRendersItsOwnHonestEmptyMessage() throws {
        for focus: ToolboxHomeScreen.Focus in [.saved, .doneMyself] {
            let screen = ToolboxHomeScreen(initialFocus: focus)
            try assertHonestCopy(screen.emptyStateHeading)
            try assertHonestCopy(screen.emptyStateMessage)
        }
        XCTAssertNotEqual(
            ToolboxHomeScreen.message(for: .saved), ToolboxHomeScreen.message(for: .doneMyself),
            "the two foci must not share one message, or selecting a chip changes nothing a person can see"
        )
        XCTAssertNotEqual(ToolboxHomeScreen.heading(for: .saved), ToolboxHomeScreen.heading(for: .doneMyself))
    }

    func testToolboxInitialFocusDrivesTheRenderedEmptyState() {
        XCTAssertEqual(ToolboxHomeScreen(initialFocus: .saved).emptyStateMessage, ToolboxHomeScreen.message(for: .saved))
        XCTAssertEqual(
            ToolboxHomeScreen(initialFocus: .doneMyself).emptyStateMessage,
            ToolboxHomeScreen.message(for: .doneMyself)
        )
    }

    func testToolboxBodyEmbedsTheFocusChips() {
        XCTAssertTrue(bodyTypeName(ToolboxHomeScreen()).contains("HDChip"), "the two focus controls are gone from the screen body")
    }

    func testToolboxSupportLineIsARealWorkingLink() throws {
        try assertHonestCopy(ToolboxHomeScreen.supportLine)
        XCTAssertTrue(ToolboxHomeScreen.supportLine.contains("[Message support](https://housedash.app/support)"))
    }

    func testToolboxGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(ToolboxHomeScreen(), dynamicTypeSize: .large)
        let huge = measuredSize(ToolboxHomeScreen(), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    // MARK: Profile

    func testProfileSignInIsDisabledWithAReasonRatherThanQuietlyDoingNothing() throws {
        try assertHonestCopy(ProfileHomeScreen.signInDisabledReason)
        XCTAssertTrue(bodyTypeName(ProfileHomeScreen()).contains("HDSecondaryButton"), "the sign-in control is gone from the screen body")
    }

    func testProfileSupportLineIsARealWorkingLink() throws {
        try assertHonestCopy(ProfileHomeScreen.supportLine)
        XCTAssertTrue(ProfileHomeScreen.supportLine.contains("[Message support](https://housedash.app/support)"))
    }

    func testProfileGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(ProfileHomeScreen(), dynamicTypeSize: .large)
        let huge = measuredSize(ProfileHomeScreen(), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testProfileSignInButtonMeetsTheFortyFourPointTouchTarget() {
        let button = measuredSize(HDSecondaryButton("Sign in") {}.disabled(true))
        XCTAssertGreaterThanOrEqual(button.height, 44)
    }

    // MARK: No screen paints its own ground

    func testNoneOfTheThreeHomeScreensPaintTheGroundThemselves() throws {
        let files = ["Jobs/JobsHomeScreen.swift", "Toolbox/ToolboxHomeScreen.swift", "Profile/ProfileHomeScreen.swift"]
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Features")
        for relative in files {
            let text = try String(contentsOf: root.appendingPathComponent(relative), encoding: .utf8)
            XCTAssertFalse(
                text.contains("background(Color.hdGround"),
                "\(relative) paints the ground itself; chrome is set once at the root and HDScreen already owns it"
            )
        }
    }
}
#endif
