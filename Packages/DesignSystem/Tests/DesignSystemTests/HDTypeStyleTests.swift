import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

final class HDTypeStyleTests: XCTestCase {
    func testTitleLargeIsZillaSlabFamily() {
        XCTAssertEqual(HDType.titleLarge.family, .zillaSlabSemiBold)
    }

    func testTitleLargeTrackingMatchesDerivedD448Value() {
        XCTAssertEqual(HDType.titleLarge.tracking, -0.6665, accuracy: 0.00001)
    }

    func testEveryOtherStyleStaysSystemFont() {
        let others: [HDTypeStyle] = [
            HDType.money, HDType.headlineFigure, HDType.quote, HDType.title,
            HDType.section, HDType.body, HDType.bodyStrong, HDType.label,
            HDType.factRow, HDType.bodyDense, HDType.caption
        ]
        for style in others {
            XCTAssertEqual(style.family, .system)
        }
    }

    #if canImport(UIKit)
    func testZillaSlabActuallyRegistersAndIsNotTheSystemFont() {
        _ = HDType.titleLarge.font

        let resolved = UIFont(name: HDZillaSlab.postScriptName, size: HDType.titleLarge.size)
        XCTAssertNotNil(
            resolved,
            "Zilla Slab SemiBold did not register with the font system — Title/Large silently fell back to the system font"
        )

        let systemFallback = UIFont.systemFont(ofSize: HDType.titleLarge.size, weight: .semibold)
        XCTAssertNotEqual(resolved?.fontName, systemFallback.fontName)
        XCTAssertNotEqual(resolved?.familyName, systemFallback.familyName)
    }
    #endif
}
