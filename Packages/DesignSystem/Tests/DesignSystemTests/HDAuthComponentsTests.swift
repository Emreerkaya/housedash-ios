import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDAuthComponentsTests: XCTestCase {

    private func measuredSize<V: View>(
        _ view: V,
        proposal: CGSize = CGSize(width: 1000, height: 1000),
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: proposal)
    }

    func testBrandStyleIsZillaSlabAndLargerThanTitleLarge() {
        XCTAssertEqual(HDType.brand.family, .zillaSlabSemiBold)
        XCTAssertEqual(HDType.brand.size, 40)
        XCTAssertGreaterThan(HDType.brand.size, HDType.titleLarge.size)
    }

    func testPrimaryButtonMeetsItsMinimumHeightAtDefaultTextSize() {
        let size = measuredSize(HDPrimaryButton("Continue") {}.frame(width: 353))
        XCTAssertGreaterThanOrEqual(size.height, HDPrimaryButton.minimumHeight)
    }

    func testPrimaryButtonGrowsPastItsMinimumHeightAtLargestAccessibilitySizeInsteadOfClipping() {
        let normal = measuredSize(HDPrimaryButton("Continue") {}.frame(width: 353), dynamicTypeSize: .large)
        let huge = measuredSize(HDPrimaryButton("Continue") {}.frame(width: 353), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
        XCTAssertGreaterThanOrEqual(huge.height, HDPrimaryButton.minimumHeight)
    }

    func testPrimaryButtonActionReachesItsCaller() {
        var tapped = false
        let button = HDPrimaryButton("Continue") { tapped = true }
        button.action()
        XCTAssertTrue(tapped)
        XCTAssertTrue(
            String(describing: type(of: button.body)).contains("Button"),
            "the button body has no Button in it, so the stored action is unreachable from a real tap"
        )
    }

    func testSecondaryButtonMeetsItsMinimumHeightAtDefaultTextSize() {
        let size = measuredSize(HDSecondaryButton("Continue with Apple") {}.frame(width: 353))
        XCTAssertGreaterThanOrEqual(size.height, HDSecondaryButton.minimumHeight)
    }

    func testSecondaryButtonGrowsPastItsMinimumHeightAtLargestAccessibilitySizeInsteadOfClipping() {
        let normal = measuredSize(HDSecondaryButton("Continue with Google") {}.frame(width: 353), dynamicTypeSize: .large)
        let huge = measuredSize(HDSecondaryButton("Continue with Google") {}.frame(width: 353), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
        XCTAssertGreaterThanOrEqual(huge.height, HDSecondaryButton.minimumHeight)
    }

    func testSecondaryButtonActionReachesItsCaller() {
        var tapped = false
        let button = HDSecondaryButton("Continue with Apple") { tapped = true }
        button.action()
        XCTAssertTrue(tapped)
        XCTAssertTrue(
            String(describing: type(of: button.body)).contains("Button"),
            "the button body has no Button in it, so the stored action is unreachable from a real tap"
        )
    }

    func testIdentityRowMeetsItsMinimumHeightAtDefaultTextSize() {
        let size = measuredSize(HDIdentityRow(identifier: "dana@example.com") {}.frame(width: 353))
        XCTAssertGreaterThanOrEqual(size.height, HDIdentityRow.minimumHeight)
    }

    func testIdentityRowGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(HDIdentityRow(identifier: "dana@example.com") {}.frame(width: 353), dynamicTypeSize: .large)
        let huge = measuredSize(HDIdentityRow(identifier: "dana@example.com") {}.frame(width: 353), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testIdentityRowChangeActionReachesItsCaller() {
        var tapped = false
        let row = HDIdentityRow(identifier: "dana@example.com") { tapped = true }
        row.onChange()
        XCTAssertTrue(tapped)
        XCTAssertTrue(
            String(describing: type(of: row.body)).contains("Button"),
            "the row body has no Button in it, so Change is unreachable from a real tap"
        )
    }

    func testIdentityRowChangeMeetsTheFortyFourPointTouchTarget() {
        XCTAssertGreaterThanOrEqual(HDIdentityRow.minimumChangeTouchTarget, 44)

        let row = HDIdentityRow(identifier: "dana@example.com") {}
        let changeSize = measuredSize(row.changeButton)
        XCTAssertGreaterThanOrEqual(changeSize.width, 44)
        XCTAssertGreaterThanOrEqual(changeSize.height, 44)
    }

    func testRoleIslandHalvesAreGeometricallyEqual() {
        XCTAssertEqual(HDRoleIsland.halfWidth, 90)
        XCTAssertEqual(HDRoleIsland.size.width, 186)
        XCTAssertEqual(HDRoleIsland.size.height, 38)
        XCTAssertEqual(HDRoleIsland.halfWidth * 2 + HDRoleIsland.thumbInset * 2, HDRoleIsland.size.width)
    }

    func testRoleIslandBothSelectionsMeasureTheSameOverallSizeAtDefaultTextSize() {
        let nesterSelected = measuredSize(HDRoleIsland(selected: .nester) { _ in })
        let taskerSelected = measuredSize(HDRoleIsland(selected: .tasker) { _ in })

        XCTAssertEqual(nesterSelected.width, taskerSelected.width, accuracy: 0.5)
        XCTAssertEqual(nesterSelected.height, taskerSelected.height, accuracy: 0.5)
        XCTAssertEqual(nesterSelected.width, HDRoleIsland.size.width, accuracy: 0.5)
        XCTAssertEqual(nesterSelected.height, HDRoleIsland.size.height, accuracy: 0.5)
    }

    func testRoleIslandMeetsTheFortyFourPointTouchTargetOnEachHalf() {
        XCTAssertGreaterThanOrEqual(HDRoleIsland.halfWidth, 44)
        XCTAssertGreaterThanOrEqual(HDRoleIsland.segmentHeight + HDRoleIsland.tapExpansion * 2, 44)

        let expandedRect = HDRoleIslandTapExpansion(vertical: HDRoleIsland.tapExpansion)
            .path(in: CGRect(x: 0, y: 0, width: HDRoleIsland.halfWidth, height: HDRoleIsland.segmentHeight))
            .boundingRect
        XCTAssertGreaterThanOrEqual(expandedRect.height, 44)
        XCTAssertGreaterThanOrEqual(expandedRect.width, 44)
    }

    func testRoleIslandRenderedHalvesAreEqualWidthAtDefaultTextSize() {
        let island = HDRoleIsland(selected: .nester) { _ in }
        let nesterHalf = measuredSize(island.segment(.nester))
        let taskerHalf = measuredSize(island.segment(.tasker))

        XCTAssertEqual(nesterHalf.width, taskerHalf.width, accuracy: 0.5)
        XCTAssertEqual(nesterHalf.width, HDRoleIsland.halfWidth, accuracy: 0.5)
        XCTAssertEqual(nesterHalf.height, taskerHalf.height, accuracy: 0.5)
    }

    func testRoleIslandSelectedAndUnselectedDifferInWeightNotOnlyColor() {
        let selected = HDRoleIslandAppearance.appearance(isSelected: true)
        let unselected = HDRoleIslandAppearance.appearance(isSelected: false)

        XCTAssertNotEqual(selected.weight, unselected.weight)
        XCTAssertEqual(selected.weight, .semibold)
        XCTAssertEqual(unselected.weight, .regular)
    }

    func testRoleIslandExposesSelectionAsAnAccessibilityTraitNotOnlyFill() {
        var reported: [HDRole] = []
        let island = HDRoleIsland(selected: .nester) { reported.append($0) }
        island.onSelect(.tasker)
        XCTAssertEqual(reported, [.tasker])
        XCTAssertTrue(
            String(describing: type(of: island.body)).contains("Button"),
            "the island body has no Button in it, so a role tap is unreachable from a real tap"
        )
    }

    func testRoleIslandSelectedHalfPaintsAThumbShapeTheUnselectedHalfDoesNot() {
        guard let bitmap = HDBitmap(
            HDRoleIsland(selected: .nester) { _ in }
                .frame(width: HDRoleIsland.size.width, height: HDRoleIsland.size.height)
                .padding(4)
                .background(Color.hdSurface),
            colorScheme: .light,
            dynamicTypeSize: .large
        ) else {
            XCTFail("could not render the role island")
            return
        }

        guard let contextSwatch = HDBitmap.swatch(Color.hdContext, colorScheme: .light) else {
            XCTFail("could not resolve color/context")
            return
        }

        func regionContainsContext(columns: Range<Int>, rows: Range<Int>) -> Bool {
            for y in rows {
                for x in columns where bitmap.pixel(x: x, y: y).matches(contextSwatch) {
                    return true
                }
            }
            return false
        }

        let margin = 8
        let rows = margin..<(bitmap.height - margin)
        let leftColumns = (margin + 4)..<(4 + Int(HDRoleIsland.halfWidth) - margin)
        let rightColumns = (bitmap.width - 4 - Int(HDRoleIsland.halfWidth) + margin)..<(bitmap.width - margin - 4)

        XCTAssertTrue(
            regionContainsContext(columns: leftColumns, rows: rows),
            "selected (Nester) half should be painted with the context-filled thumb"
        )
        XCTAssertFalse(
            regionContainsContext(columns: rightColumns, rows: rows),
            "unselected (Tasker) half must not carry the thumb fill — the difference must be more than colour"
        )
    }

    func testRoleIslandGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(HDRoleIsland(selected: .nester) { _ in }, dynamicTypeSize: .large)
        let huge = measuredSize(HDRoleIsland(selected: .nester) { _ in }, dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
        XCTAssertGreaterThanOrEqual(huge.width, normal.width)
    }

    func testRoleIslandThumbFillIsContextNeverInkNeverAccent() {
        let context = UIColor(Color.hdContext)
        let ink = UIColor(Color.hdInk)
        let accentDIY = UIColor(Color.hdAccentDIY)
        let accentHire = UIColor(Color.hdAccentHire)

        func luminance(_ color: UIColor, _ style: UIUserInterfaceStyle) -> CGFloat {
            let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return 0.2126 * red + 0.7152 * green + 0.0722 * blue
        }

        XCTAssertGreaterThan(
            luminance(ink, .dark), 0.7,
            "color/ink inverts to near-white in dark — a thumb filled with ink would go light-on-light"
        )
        XCTAssertLessThan(
            luminance(context, .dark), 0.3,
            "color/context must stay dark in dark mode, unlike color/ink, which inverts"
        )
        XCTAssertLessThan(luminance(context, .light), 0.3, "color/context should read near-black in light")

        for style in [UIUserInterfaceStyle.light, .dark] {
            let trait = UITraitCollection(userInterfaceStyle: style)
            let resolvedContext = context.resolvedColor(with: trait)
            XCTAssertNotEqual(resolvedContext, accentDIY.resolvedColor(with: trait))
            XCTAssertNotEqual(resolvedContext, accentHire.resolvedColor(with: trait))
        }
    }
}
#endif
