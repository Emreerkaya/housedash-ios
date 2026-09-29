import XCTest
import SwiftUI
@testable import DesignSystem

final class HDContrastTests: XCTestCase {
    private static let wcagAAForBodyText: Double = 4.5

    private static let wcagAAForNonTextContrast: Double = 3

    func testEveryTextTokenClearsAAOnEveryScreenGroundInBothBands() {
        var failures: [String] = []
        for foreground in HDToken.tokens(in: .text) {
            for background in HDToken.tokens(in: .screenGround) {
                for band in HDBand.allCases {
                    let ratio = HDContrast.ratio(of: foreground, on: background, in: band)
                    if ratio < Self.wcagAAForBodyText {
                        failures.append(
                            "\(foreground)/\(background) is \(String(format: "%.2f", ratio)):1 in \(band)"
                        )
                    }
                }
            }
        }
        XCTAssertEqual(
            failures, [],
            "\(failures.count) of the \(HDToken.tokens(in: .text).count * HDToken.tokens(in: .screenGround).count * HDBand.allCases.count) text-on-ground pairs the palette can produce fail AA: \(failures.joined(separator: ", "))"
        )
    }

    func testEveryInvertedGroundCarriesItsOwnTextTokenAtAA() {
        var failures: [String] = []
        for background in HDToken.tokens(in: .invertedGround) {
            let legible = HDToken.tokens(in: .textOnAnInvertedGround).filter { foreground in
                HDBand.allCases.allSatisfy { band in
                    HDContrast.ratio(of: foreground, on: background, in: band) >= Self.wcagAAForBodyText
                }
            }
            if legible.isEmpty {
                failures.append(
                    "\(background) has no token in \(HDToken.tokens(in: .textOnAnInvertedGround)) that clears AA on it in both bands"
                )
            }
        }
        XCTAssertEqual(failures, [], failures.joined(separator: ", "))
    }

    func testTheSweepCoversEveryTokenExactlyOnce() {
        let counted = HDTokenRole.allCases.flatMap { HDToken.tokens(in: $0) }
        XCTAssertEqual(
            Set(counted), Set(HDToken.allCases),
            "the roles do not partition the palette, so a token can be added without being swept"
        )
        XCTAssertEqual(
            counted.count, HDToken.allCases.count,
            "a token carries more than one role, so the sweep counts it twice"
        )
        XCTAssertFalse(
            HDToken.tokens(in: .text).isEmpty || HDToken.tokens(in: .screenGround).isEmpty,
            "one side of the sweep is empty, so the sweep above asserts nothing"
        )
    }

    func testAMarkClearsTheNonTextRatioOnEveryScreenGround() {
        var failures: [String] = []
        for foreground in HDToken.tokens(in: .mark) {
            for background in HDToken.tokens(in: .screenGround) {
                for band in HDBand.allCases {
                    let ratio = HDContrast.ratio(of: foreground, on: background, in: band)
                    if ratio < Self.wcagAAForNonTextContrast {
                        failures.append(
                            "\(foreground)/\(background) is \(String(format: "%.2f", ratio)):1 in \(band)"
                        )
                    }
                }
            }
        }
        XCTAssertEqual(
            failures, [],
            "\(failures.count) marks fall below \(Self.wcagAAForNonTextContrast):1 against a screen ground: \(failures.joined(separator: ", "))"
        )
    }

    func testASelectedChipIsSeparatedFromAnUnselectedOneInEveryBand() {
        for band in HDBand.allCases {
            let fills = HDContrast.ratio(of: .context, on: .surfaceSunk, in: band)
            let boundaryAgainstTheGround = HDToken.tokens(in: .screenGround)
                .map { HDContrast.ratio(of: .onContext, on: $0, in: band) }
                .min() ?? 0
            let labelsDiffer = HDPalette.pair(for: .onContext).hex(in: band).uppercased()
                != HDPalette.pair(for: .ink).hex(in: band).uppercased()
            let indicators = [
                "the fill at \(String(format: "%.2f", fills)):1": fills >= Self.wcagAAForNonTextContrast,
                "the boundary at \(String(format: "%.2f", boundaryAgainstTheGround)):1": boundaryAgainstTheGround >= Self.wcagAAForNonTextContrast,
                "the label token": labelsDiffer
            ]
            XCTAssertTrue(
                indicators.values.contains(true),
                "in \(band) nothing separates a selected chip from an unselected one: \(indicators.keys.sorted().joined(separator: ", ")) all fall short"
            )
        }
    }

    func testTheBoundaryIsWhatSeparatesThemInDarkAndTheFillIsWhatSeparatesThemInLight() {
        XCTAssertGreaterThanOrEqual(
            HDContrast.ratio(of: .context, on: .surfaceSunk, in: .light),
            Self.wcagAAForNonTextContrast,
            "the selected chip's fill no longer separates it from an unselected one in light, and the boundary is near-white there"
        )
        XCTAssertLessThan(
            HDContrast.ratio(of: .context, on: .surfaceSunk, in: .dark),
            Self.wcagAAForNonTextContrast,
            "the fill now separates the two states in dark on its own, so HDChip's boundary is no longer load-bearing and this test should say so"
        )
        XCTAssertGreaterThanOrEqual(
            HDContrast.ratio(of: .onContext, on: .ground, in: .dark),
            Self.wcagAAForNonTextContrast,
            "the boundary that carries the selected state in dark is invisible against the screen behind it"
        )
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
        XCTAssertEqual(HDContrast.ratio(of: .alert, on: .ground, in: .light), 5.22, accuracy: 0.01)
        XCTAssertEqual(HDContrast.ratio(of: .alert, on: .surfaceSunk, in: .light), 4.66, accuracy: 0.01)
    }
}
