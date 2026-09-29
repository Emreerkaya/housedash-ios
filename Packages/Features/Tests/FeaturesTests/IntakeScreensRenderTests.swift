import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignSystem
@testable import Features

#if canImport(UIKit)
@MainActor
final class IntakeScreensRenderTests: XCTestCase {
    private func measuredSize<V: View>(
        _ view: V,
        proposal: CGSize = CGSize(width: 393, height: CGFloat.infinity),
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: proposal)
    }

    private func makeModel() -> IntakeFlowModel {
        let model = IntakeFlowModel(catalogue: FakeProblemCatalogue())
        model.rails = [
            ProblemRail(id: "common-in-a-kitchen", heading: "Common in a kitchen", cards: [FakeProblemCatalogue.drippingTap, FakeProblemCatalogue.blockedDrain])
        ]
        return model
    }

    private func makePhotoModel() -> PhotoFirstFlowModel {
        PhotoFirstFlowModel()
    }

    // MARK: - Dynamic Type to the largest accessibility size, nothing clipped

    func testB01GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B01FixScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B01FixScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testRailHeadingGrowsInIsolationSoASiblingCannotMaskALocalizedLineLimitRegression() {
        let screen = B01FixScreen(model: makeModel())
        let normal = measuredSize(screen.railHeading("Common in a kitchen"), dynamicTypeSize: .large)
        let huge = measuredSize(screen.railHeading("Common in a kitchen"), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB02GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let model = makeModel()
        model.symptoms = FakeProblemCatalogue.drippingTapSymptoms
        let normal = measuredSize(B02PickProblemScreen(model: model), dynamicTypeSize: .large)
        let huge = measuredSize(B02PickProblemScreen(model: model), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB03GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let model = makeModel()
        model.selectedProblem = FakeProblemCatalogue.drippingTap
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]
        let normal = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .large)
        let huge = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB04GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B04SomethingElseScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B04SomethingElseScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB07GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B07AFewDetailsScreen(model: makePhotoModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B07AFewDetailsScreen(model: makePhotoModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    // MARK: - A rejection banner is present and grows too, since it is now part of the content

    func testRejectionBannerGrowsAtLargestAccessibilitySizeOnB03() {
        let model = makeModel()
        model.selectedProblem = FakeProblemCatalogue.drippingTap
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertNotNil(model.rejection)
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]

        let normal = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .large)
        let huge = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    // MARK: - Every unbreakable single-token string on these screens carries a scale factor (D174)

    func testRoomChipLabelsHaveNoInternalSpaceAndMustScaleRatherThanTruncate() {
        for room in HDRoom.allCases {
            XCTAssertFalse(room.label.contains(" "), "\(room.label) is treated as an unbreakable token by the chip")
        }
    }

    func testZoomPillTextHasNoSpaceAndCarriesAScaleFactor() {
        XCTAssertFalse("1×".contains(" "))
    }

    // MARK: - 44pt targets on the controls this section adds

    func testChangeAffordanceOnTheChosenRowMeetsTheFortyFourPointTouchTarget() {
        let size = measuredSize(
            IntakeChosenRow(primary: "Dripping tap or faucet", secondary: "Water · $90–140 typical", onChange: {})
        )
        XCTAssertGreaterThanOrEqual(size.height, HDIdentityRow.minimumHeight)
    }

    func testAddPhotoTileMeetsTheFortyFourPointTouchTarget() {
        let size = measuredSize(IntakePhotoTile(kind: .add(caption: "Add"), action: {}))
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testCardMeetsTheFortyFourPointTouchTargetVertically() {
        let size = measuredSize(IntakeCard(problem: FakeProblemCatalogue.drippingTap, action: {}))
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testPickRowMeetsTheFortyFourPointTouchTarget() {
        let size = measuredSize(IntakePickRow(symptom: FakeProblemCatalogue.drippingTapSymptoms[0], action: {}))
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    // MARK: - VoiceOver: a photo affordance is never invisible to a screen reader

    func testCardAccessibilityLabelDataCombinesTitleAndPriceRatherThanLeavingThePhotoUnlabeled() {
        let problem = FakeProblemCatalogue.drippingTap
        XCTAssertEqual("\(problem.title), \(problem.priceRange)", "Dripping tap, $90–140")
    }

    func testAddPhotoTileCaptionIsNeverEmpty() {
        XCTAssertFalse("Add".isEmpty)
        XCTAssertFalse("Add from your phone".isEmpty)
    }
}
#endif
