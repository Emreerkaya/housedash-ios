import XCTest
import DesignSystem
@testable import Features

@MainActor
final class IntakeFlowRoutingTests: XCTestCase {
    private func makeModel() -> (IntakeFlowModel, FakeProblemCatalogue) {
        let catalogue = FakeProblemCatalogue()
        let model = IntakeFlowModel(catalogue: catalogue)
        return (model, catalogue)
    }

    func testRoomDefaultsToKitchenAndRailsLoadOnAppear() async {
        let (model, catalogue) = makeModel()
        await model.loadRails()
        XCTAssertEqual(model.selectedRoom, .kitchen)
        XCTAssertEqual(model.rails.count, 1)
        XCTAssertEqual(catalogue.railsCallCount, 1)
    }

    func testSelectingAnUncuratedRoomShowsNoRailsRatherThanStaleOnes() async {
        let (model, _) = makeModel()
        await model.loadRails()
        await model.selectRoom(.bathroom)
        XCTAssertTrue(model.rails.isEmpty)
    }

    func testPickingACardPushesB02AndLoadsItsSymptoms() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)])
        XCTAssertEqual(model.symptoms, FakeProblemCatalogue.drippingTapSymptoms)
    }

    func testPickingASymptomWithAPriceRoutesToDescribeIt() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]

        model.selectSymptomForReview(symptom)
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)], "review alone must not navigate")

        model.confirmSymptomSelection()
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap), .describeIt(symptom)])
    }

    func testPickingNoneOfTheseRoutesToSomethingElseWithNoPrice() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        let escapeHatch = FakeProblemCatalogue.drippingTapSymptoms.last!
        XCTAssertTrue(escapeHatch.isEscapeHatch)

        model.selectSymptomForReview(escapeHatch)
        model.confirmSymptomSelection()

        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap), .somethingElse])
    }

    func testChoosingNoneOfTheseAfterTypingOnDescribeItDoesNotLeakThatTextIntoSomethingElse() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.descriptionText = "call me on 917-555-0199"

        model.goBack()
        let escapeHatch = FakeProblemCatalogue.drippingTapSymptoms.last!
        model.selectSymptomForReview(escapeHatch)
        model.confirmSymptomSelection()

        XCTAssertEqual(model.descriptionText, "")
        XCTAssertNil(model.rejection)
    }

    func testGoBackFromDescribeItReturnsToPickProblemAndClearsAnyRejection() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertNotNil(model.rejection)

        model.goBack()

        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)])
        XCTAssertNil(model.rejection)
    }

    func testBeginAndFinishPhotoCaptureRoundTripsThePath() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()

        model.beginPhotoCapture()
        XCTAssertEqual(model.path.last, .photograph)

        model.capturePhoto()
        XCTAssertEqual(model.photos.count, 1)

        model.finishPhotoCapture()
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap), .describeIt(FakeProblemCatalogue.drippingTapSymptoms[0])])
        XCTAssertEqual(model.photos.count, 1, "leaving the camera must not discard what was captured")
    }

    func testCapturingMoreThanThreePhotosIsIgnoredBecauseTheStripHasThreeSlots() {
        let (model, _) = makeModel()
        model.capturePhoto()
        model.capturePhoto()
        model.capturePhoto()
        model.capturePhoto()
        XCTAssertEqual(model.photos.count, 3)
    }

    // MARK: - Submission: I7 rejection is recoverable, success resets for the next case

    func testRejectedSubmissionKeepsTheTypedTextAndDoesNotNavigate() {
        let (model, _) = makeModel()
        model.descriptionText = "call me on 917-555-0199 about the tap"
        model.path = [.pickProblem(FakeProblemCatalogue.drippingTap)]

        model.submit()

        XCTAssertEqual(model.descriptionText, "call me on 917-555-0199 about the tap")
        XCTAssertNotNil(model.rejection)
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)])
        XCTAssertNil(model.completedDescription)
    }

    func testEditingAfterARejectionAndResubmittingCanSucceed() {
        let (model, _) = makeModel()
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertNotNil(model.rejection)

        model.descriptionText = "drips constantly from the base"
        model.submit()

        XCTAssertNil(model.rejection)
        XCTAssertEqual(model.completedDescription?.text, "drips constantly from the base")
    }

    func testSuccessfulSubmissionClearsThePathForANextCase() {
        let (model, _) = makeModel()
        model.descriptionText = "drips constantly from the base"
        model.path = [.pickProblem(FakeProblemCatalogue.drippingTap), .describeIt(FakeProblemCatalogue.drippingTapSymptoms[0])]

        model.submit()

        XCTAssertEqual(model.path, [])
        XCTAssertNotNil(model.completedDescription)
    }

    func testAcknowledgingCompletionResetsStateForANewCase() {
        let (model, _) = makeModel()
        model.descriptionText = "drips constantly"
        model.submit()
        XCTAssertNotNil(model.completedDescription)

        model.acknowledgeCompletion()

        XCTAssertNil(model.completedDescription)
        XCTAssertEqual(model.descriptionText, "")
        XCTAssertTrue(model.photos.isEmpty)
    }
}
