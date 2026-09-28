import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

final class HDChipTests: XCTestCase {
    #if canImport(UIKit)
    func testSelectedFillResolvesDifferentlyInLightAndDark() {
        let chip = HDChip("Label", state: .selected) {}
        let resolvedFill = UIColor(chip.fill)

        let light = resolvedFill.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = resolvedFill.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertNotEqual(light, dark, "Selected chip fill must resolve differently in light and dark")
    }

    func testSelectedFillDoesNotInvertInDarkLikeInkWould() {
        let chip = HDChip("Label", state: .selected) {}
        let fillColor = UIColor(chip.fill)
        let inkColor = UIColor(Color.hdInk)

        func luminance(_ color: UIColor, _ style: UIUserInterfaceStyle) -> CGFloat {
            let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return 0.2126 * red + 0.7152 * green + 0.0722 * blue
        }

        XCTAssertLessThan(luminance(inkColor, .light), 0.3)
        XCTAssertGreaterThan(
            luminance(inkColor, .dark), 0.7,
            "color/ink inverts to near-white in dark — this is exactly why a fill must never use it"
        )

        XCTAssertLessThan(luminance(fillColor, .light), 0.3, "color/context should read near-black in light")
        XCTAssertLessThan(
            luminance(fillColor, .dark), 0.3,
            "the selected chip's fill must stay dark in dark mode, unlike color/ink, which inverts"
        )
    }

    func testUnselectedUsesSurfaceSunkFill() {
        let chip = HDChip("Label", state: .unselected) {}
        let resolvedFill = UIColor(chip.fill)
        let expected = UIColor(Color.hdSurfaceSunk)

        for style in [UIUserInterfaceStyle.light, .dark] {
            let trait = UITraitCollection(userInterfaceStyle: style)
            XCTAssertEqual(
                resolvedFill.resolvedColor(with: trait),
                expected.resolvedColor(with: trait)
            )
        }
    }
    #endif
}
