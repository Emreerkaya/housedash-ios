import XCTest
import DesignSystem
@testable import Features

final class LookupTableTests: XCTestCase {
    func testEveryRoomHasTheLabelTheSpecGivesIt() {
        XCTAssertEqual(
            HDRoom.allCases.map(\.label),
            ["Kitchen", "Bathroom", "Bedroom", "Outdoors"],
            "the room labels are \(HDRoom.allCases.map(\.label)), and B01's chip rail reads them straight off this table"
        )
        XCTAssertEqual(HDRoom.allCases.map(\.id), HDRoom.allCases.map(\.rawValue))
    }

    func testEveryTabHasTheLabelAndGlyphTheSpecGivesIt() {
        XCTAssertEqual(
            HDNesterTab.allCases.map(\.label),
            ["Fix", "Jobs", "Photo", "DIY", "Profile"],
            "the tab labels are \(HDNesterTab.allCases.map(\.label))"
        )
        XCTAssertEqual(
            HDNesterTab.allCases.map(\.systemImage),
            [
                "wrench.and.screwdriver.fill",
                "list.bullet",
                "camera.fill",
                "hammer.fill",
                "person.crop.circle.fill"
            ],
            "the tab glyphs are \(HDNesterTab.allCases.map(\.systemImage))"
        )
        XCTAssertEqual(
            Set(HDNesterTab.allCases.map(\.systemImage)).count, HDNesterTab.allCases.count,
            "two tabs share a glyph, so one of them is unrecognisable"
        )
    }

    func testEveryContactSignalKindReadsAsSomethingAPersonCanAct0n() {
        XCTAssertEqual(
            ContactSignalKind.allCases.map(\.guidance),
            ["a phone number", "an email address", "a payment link or handle"],
            "the guidance strings are \(ContactSignalKind.allCases.map(\.guidance)), and every rejection summary is built from them"
        )
        for kind in ContactSignalKind.allCases {
            XCTAssertFalse(
                kind.guidance.contains(kind.rawValue),
                "\(kind) reads its own case name back at the person as '\(kind.guidance)'"
            )
        }
    }

    func testEveryLookupTableIsSweptRatherThanSampled() {
        XCTAssertEqual(HDRoom.allCases.count, 4)
        XCTAssertEqual(HDNesterTab.allCases.count, 5)
        XCTAssertEqual(
            ContactSignalKind.allCases.count, 3,
            "a kind was added or removed, so the rows asserted above are no longer all of them"
        )
    }
}
