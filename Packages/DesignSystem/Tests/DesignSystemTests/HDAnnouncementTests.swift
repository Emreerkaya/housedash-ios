import XCTest
import SwiftUI
@testable import DesignSystem

final class HDAnnouncementTests: XCTestCase {
    func testOnlyAMessageWithSomethingInItIsWorthAnnouncing() {
        XCTAssertNil(HDAnnouncement.worthAnnouncing(nil))
        XCTAssertNil(HDAnnouncement.worthAnnouncing(""))
        XCTAssertNil(
            HDAnnouncement.worthAnnouncing("   \n  "),
            "a message of nothing but whitespace posts an empty announcement, which VoiceOver reads as silence and still clears the model's message"
        )
        XCTAssertEqual(HDAnnouncement.worthAnnouncing("Case ready"), "Case ready")
    }

    func testTheMessageIsPostedAsWrittenRatherThanReformatted() {
        let summary = "This looks like it includes a phone number. Every job is coordinated and paid through HouseDash."
        XCTAssertEqual(
            HDAnnouncement.worthAnnouncing(summary), summary,
            "the announcement is altered on the way out, so what VoiceOver reads is not what the screen says"
        )
    }
}
