import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

final class HDPaletteTests: XCTestCase {
    func testEveryTokenHasDistinctLightAndDarkHex() {
        for token in HDToken.allCases {
            let pair = HDPalette.pair(for: token)
            XCTAssertNotEqual(pair.light, pair.dark, "\(token) uses the same hex in light and dark")
        }
    }

    func testHexComponentsParseKnownGroundValue() {
        let components = HDHexComponents(hex: "#E3DCD6")
        XCTAssertNotNil(components)
        XCTAssertEqual(components?.red ?? 0, 0xE3.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(components?.green ?? 0, 0xDC.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(components?.blue ?? 0, 0xD6.0 / 255.0, accuracy: 0.001)
    }

    #if canImport(UIKit)
    func testGroundTokenResolvesToDifferentColorsInLightAndDark() {
        let dynamicColor = UIColor(hdToken: .ground)
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)

        let resolvedLight = dynamicColor.resolvedColor(with: lightTrait)
        let resolvedDark = dynamicColor.resolvedColor(with: darkTrait)

        XCTAssertNotEqual(resolvedLight, resolvedDark)

        let expectedLight = HDHexComponents(hex: HDPalette.pair(for: .ground).light)!
        let expectedDark = HDHexComponents(hex: HDPalette.pair(for: .ground).dark)!

        var lightRed: CGFloat = 0, lightGreen: CGFloat = 0, lightBlue: CGFloat = 0, lightAlpha: CGFloat = 0
        resolvedLight.getRed(&lightRed, green: &lightGreen, blue: &lightBlue, alpha: &lightAlpha)
        XCTAssertEqual(Double(lightRed), expectedLight.red, accuracy: 0.005)
        XCTAssertEqual(Double(lightGreen), expectedLight.green, accuracy: 0.005)
        XCTAssertEqual(Double(lightBlue), expectedLight.blue, accuracy: 0.005)

        var darkRed: CGFloat = 0, darkGreen: CGFloat = 0, darkBlue: CGFloat = 0, darkAlpha: CGFloat = 0
        resolvedDark.getRed(&darkRed, green: &darkGreen, blue: &darkBlue, alpha: &darkAlpha)
        XCTAssertEqual(Double(darkRed), expectedDark.red, accuracy: 0.005)
        XCTAssertEqual(Double(darkGreen), expectedDark.green, accuracy: 0.005)
        XCTAssertEqual(Double(darkBlue), expectedDark.blue, accuracy: 0.005)
    }

    func testEveryTokenResolvesToDifferentColorsInLightAndDark() {
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)

        for token in HDToken.allCases {
            let dynamicColor = UIColor(hdToken: token)
            let resolvedLight = dynamicColor.resolvedColor(with: lightTrait)
            let resolvedDark = dynamicColor.resolvedColor(with: darkTrait)
            XCTAssertNotEqual(resolvedLight, resolvedDark, "\(token) resolved identically in light and dark")
        }
    }
    #endif
}
