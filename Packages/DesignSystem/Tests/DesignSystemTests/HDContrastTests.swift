import XCTest
import SwiftUI
@testable import DesignSystem

final class HDContrastTests: XCTestCase {
    private static let wcagAAForBodyText: Double = 4.5

    private static let textOnBackground: [(HDToken, HDToken, String)] = [
        (.ink, .ground, "body text on the screen"),
        (.inkSoft, .surface, "secondary text on a card"),
        (.inkFaint, .ground, "hint text on the screen"),
        (.inkFaint, .surface, "hint text on a card"),
        (.inkFaint, .surfaceSunk, "the field and composer placeholder"),
        (.inkSoft, .surfaceSunk, "a field's typed value against its own fill"),
        (.ink, .surfaceSunk, "a photo tile's timestamp"),
        (.onContext, .context, "the action bar CTA and the camera pills"),
        (.context, .onContext, "the photo count badge"),
        (.inkSoft, .locked, "a disabled CTA"),
        (.alert, .surface, "the rejection banner")
    ]

    func testEveryTextPairTheseScreensUseClearsAAInBothBands() {
        for (foreground, background, use) in Self.textOnBackground {
            for band in HDBand.allCases {
                let ratio = HDContrast.ratio(of: foreground, on: background, in: band)
                XCTAssertGreaterThanOrEqual(
                    ratio, Self.wcagAAForBodyText,
                    "\(use): \(foreground)/\(background) is \(String(format: "%.2f", ratio)):1 in \(band)"
                )
            }
        }
    }

    func testNoTextPairResolvesToItsOwnBackgroundValueInEitherBand() {
        for (foreground, background, use) in Self.textOnBackground {
            for band in HDBand.allCases {
                XCTAssertNotEqual(
                    HDPalette.pair(for: foreground).hex(in: band).uppercased(),
                    HDPalette.pair(for: background).hex(in: band).uppercased(),
                    "\(use): \(foreground) and \(background) are the same value in \(band), so the text is invisible"
                )
            }
        }
    }

    func testThePhotoCountBadgeIsNotBoundToTheTokenItsCircleIsFilledWith() {
        for band in HDBand.allCases {
            XCTAssertEqual(
                HDContrast.ratio(of: .ink, on: .onContext, in: band) == 1,
                band == .dark,
                "this is the pair the badge used to carry; the guard exists because it reads 1.00:1 in dark"
            )
        }
    }

    func testTheRatioComputationAgreesWithAKnownPair() {
        XCTAssertEqual(HDContrast.ratio(of: .ink, on: .ground, in: .light), 10.63, accuracy: 0.01)
        XCTAssertEqual(HDContrast.ratio(of: .ink, on: .ground, in: .dark), 13.04, accuracy: 0.01)
        XCTAssertEqual(HDContrast.ratio(of: .inkFaint, on: .surfaceSunk, in: .light), 4.52, accuracy: 0.01)
        XCTAssertEqual(HDContrast.ratio(of: .inkFaint, on: .surfaceSunk, in: .dark), 4.53, accuracy: 0.01)
    }
}
