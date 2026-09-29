import XCTest
import SwiftUI
@testable import DesignSystem

final class HDContrastTests: XCTestCase {
    private static let wcagAAForBodyText: Double = 4.5

    private static let wcagAAForNonTextContrast: Double = 3

    private static let placementsTheRolesHold = 24

    private static let surfaceTheTwinCardDrawsItsAccentLabelOn = HDToken.surface

    private static var inkDrawnOnAScreen: [HDToken] {
        HDToken.tokens(in: .text).filter { !$0.roles.contains(.invertedGround) }
    }

    private static var inkDrawnOnAnInvertedGround: [HDToken] {
        HDToken.tokens(in: .text).filter { $0.roles.contains(.invertedGround) }
    }

    private static var boundariesAlsoDrawnAsInk: [HDToken] {
        HDToken.tokens(in: .boundary).filter { $0.roles.contains(.text) }
    }

    private static var boundariesDrawnOnAnInvertedGround: [HDToken] {
        HDToken.tokens(in: .boundary).filter {
            $0.roles.contains(.invertedGround) || $0.roles.contains(.textOnAnInvertedGround)
        }
    }

    private static var boundariesThatAreDecorationOnly: [HDToken] {
        HDToken.tokens(in: .boundary).filter {
            !$0.roles.contains(.text) && !$0.roles.contains(.invertedGround)
                && !$0.roles.contains(.textOnAnInvertedGround)
        }
    }

    private func shortfalls(
        _ foregrounds: [HDToken],
        on backgrounds: [HDToken],
        below bar: Double
    ) -> [String] {
        var failures: [String] = []
        for foreground in foregrounds {
            for background in backgrounds {
                for band in HDBand.allCases {
                    let ratio = HDContrast.ratio(of: foreground, on: background, in: band)
                    if ratio < bar {
                        failures.append("\(foreground)/\(background) is \(String(format: "%.2f", ratio)):1 in \(band)")
                    }
                }
            }
        }
        return failures
    }

    func testEveryTextTokenClearsAAOnEveryScreenGround() {
        let foregrounds = Self.inkDrawnOnAScreen
        let backgrounds = HDToken.tokens(in: .screenGround)
        let failures = shortfalls(foregrounds, on: backgrounds, below: Self.wcagAAForBodyText)
        XCTAssertFalse(
            foregrounds.isEmpty || backgrounds.isEmpty,
            "one side of this sweep is empty, so it asserts nothing"
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) of the \(foregrounds.count * backgrounds.count * HDBand.allCases.count) text-on-ground pairs the palette can produce fail AA: \(failures.joined(separator: ", ")); this sweep leaves out \(Self.inkDrawnOnAnInvertedGround), which are drawn as text only on \(Self.surfaceTheTwinCardDrawsItsAccentLabelOn), and \(HDToken.tokens(in: .controlGround)), which is a control's own fill"
        )
    }

    func testEveryTokenDrawnAsTextOnASurfaceOnlyClearsAAOnThatSurface() {
        let foregrounds = Self.inkDrawnOnAnInvertedGround
        XCTAssertFalse(
            foregrounds.isEmpty,
            "no token is placed in both .text and .invertedGround, so this sweep asserts nothing and the two-role placement it exists for has been undone"
        )
        let failures = shortfalls(
            foregrounds,
            on: [Self.surfaceTheTwinCardDrawsItsAccentLabelOn],
            below: Self.wcagAAForBodyText
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) accent-as-text pairs fail AA on the surface they are drawn on: \(failures.joined(separator: ", "))"
        )
    }

    func testEveryTokenDrawnAsTextOnAnInvertedGroundClearsAAOnTheGroundItsNameClaims() {
        var failures: [String] = []
        var claimed: Set<HDToken> = []
        for foreground in HDToken.tokens(in: .textOnAnInvertedGround) {
            let grounds = foreground.invertedGroundItsNameClaims
            XCTAssertFalse(
                grounds.isEmpty,
                "\(foreground) is placed as text on an inverted ground and its name claims none, so nothing pairs it with a ground and the sweep skips it"
            )
            claimed.formUnion(grounds)
            failures += shortfalls([foreground], on: grounds, below: Self.wcagAAForBodyText)
        }
        XCTAssertEqual(
            Set(HDToken.tokens(in: .invertedGround)).subtracting(claimed), [],
            "\(Set(HDToken.tokens(in: .invertedGround)).subtracting(claimed).map(\.rawValue).sorted()) is an inverted ground no text token's name claims, so no pair covers it and an existential would have passed it"
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) of the pairs a token's own name claims fail AA, and this sweep is universal over those pairs rather than existential over the role: \(failures.joined(separator: ", "))"
        )
    }

    func testEveryTextTokenClearsTheNonTextRatioOnEveryControlGround() {
        let backgrounds = HDToken.tokens(in: .controlGround)
        XCTAssertFalse(backgrounds.isEmpty, "no token is placed as a control ground, so this sweep asserts nothing")
        let failures = shortfalls(Self.inkDrawnOnAScreen, on: backgrounds, below: Self.wcagAAForNonTextContrast)
        XCTAssertEqual(
            failures, [],
            "\(failures.count) text-on-control-ground pairs fall below \(Self.wcagAAForNonTextContrast):1: \(failures.joined(separator: ", ")); the bar here is the non-text ratio rather than AA because WCAG 1.4.3 exempts the label of an inactive control while 1.4.11 still asks the control be discernible, and the foregrounds are the ink drawn on a ground rather than \(Self.inkDrawnOnAnInvertedGround), which is an accent label drawn only on \(Self.surfaceTheTwinCardDrawsItsAccentLabelOn)"
        )
    }

    func testTheSweepCoversEveryTokenExactlyOncePerRoleItIsDrawnIn() {
        let placements = HDToken.placements
        XCTAssertEqual(
            Set(placements.map(\.token)), Set(HDToken.allCases),
            "the roles do not cover the palette, so a token can be added without being swept"
        )
        XCTAssertEqual(
            placements.count, Set(placements.map { "\($0.token)/\($0.role)" }).count,
            "a token is placed in the same role twice, so the sweep counts it twice"
        )
        XCTAssertGreaterThan(
            placements.count, HDToken.allCases.count,
            "every token carries exactly one role, so the per-role placement this sweep exists for is not in use and a token drawn in two roles is checked in only one of them"
        )
        XCTAssertEqual(
            placements.count, Self.placementsTheRolesHold,
            "the palette places \(placements.count) token-and-role pairs rather than \(Self.placementsTheRolesHold), so a token has gained or lost a role; this count is what makes such a change deliberate, and the sweep that tests the draw rather than the declaration is the rendered selection sweep in FeaturesTests"
        )
        for role in HDTokenRole.allCases {
            XCTAssertFalse(
                HDToken.tokens(in: role).isEmpty,
                "\(role) holds no token, so every sweep over it is vacuous"
            )
        }
        for token in HDToken.allCases {
            XCTAssertFalse(
                token.roles.isEmpty,
                "\(token) is drawn as nothing, so no sweep reaches it"
            )
        }
    }

    func testAMarkClearsTheNonTextRatioOnEveryScreenGround() {
        let failures = shortfalls(
            HDToken.tokens(in: .mark),
            on: HDToken.tokens(in: .screenGround),
            below: Self.wcagAAForNonTextContrast
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) marks fall below \(Self.wcagAAForNonTextContrast):1 against a screen ground: \(failures.joined(separator: ", "))"
        )
    }

    func testEveryBoundaryAlsoDrawnAsInkClearsTheNonTextRatioOnEveryScreenGround() {
        let foregrounds = Self.boundariesAlsoDrawnAsInk
        XCTAssertFalse(
            foregrounds.isEmpty,
            "no token is placed in both .boundary and .text, so this sweep asserts nothing about the strokes a state is drawn with"
        )
        let failures = shortfalls(
            foregrounds,
            on: HDToken.tokens(in: .screenGround),
            below: Self.wcagAAForNonTextContrast
        )
        XCTAssertEqual(
            failures, [],
            "\(failures.count) boundary-as-ink pairs fall below \(Self.wcagAAForNonTextContrast):1 on a screen ground: \(failures.joined(separator: ", ")); this sweep reaches neither \(Self.boundariesDrawnOnAnInvertedGround.map(\.rawValue).sorted()), which are drawn on an inverted ground and are covered by the rendered selection sweep in FeaturesTests, nor \(Self.boundariesThatAreDecorationOnly.map(\.rawValue).sorted()), which carry no state and sit between 1.15:1 and 1.85:1 against every screen ground"
        )
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
