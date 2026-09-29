import XCTest
import DesignSystem
@testable import Features

@MainActor
final class IntakeFlowRoutingTests: XCTestCase {
    private func makeModel() -> (IntakeFlowModel, FakeProblemCatalogue) {
        let catalogue = FakeProblemCatalogue()
        let model = IntakeFlowModel(catalogue: catalogue, camera: FakeCamera())
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

    func testReconfirmingTheSameSymptomKeepsWhatTheUserAlreadyTyped() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]
        model.selectSymptomForReview(symptom)
        model.confirmSymptomSelection()
        model.descriptionText = "drips constantly from the base"
        model.locationText = "Greenwich Village"

        model.goBack()
        model.selectSymptomForReview(symptom)
        model.confirmSymptomSelection()

        XCTAssertEqual(model.descriptionText, "drips constantly from the base")
        XCTAssertEqual(model.locationText, "Greenwich Village")
    }

    func testTheEscapeHatchDropsThePhotosAndTheProblemItsScreenCannotShow() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.capturePhoto()
        XCTAssertEqual(model.photos.count, 1)

        model.goBack()
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms.last!)
        model.confirmSymptomSelection()
        model.descriptionText = "the radiator never gets hot"
        model.submit()

        XCTAssertTrue(model.photos.isEmpty, "B04 shows no photo strip, so it must carry no photos")
        XCTAssertNil(
            model.completedSubmission?.problem,
            "the user said none of these, so the catalogue problem must not ride along"
        )
        XCTAssertEqual(model.completedSubmission?.photos, [])
    }

    func testABlankDescriptionCannotBeSubmittedAndProducesNoCase() {
        for blank in ["", "   ", "\n\t "] {
            let (model, _) = makeModel()
            model.descriptionText = blank

            XCTAssertFalse(model.canSubmit, "\(blank.debugDescription) must not enable the CTA")
            model.submit()

            XCTAssertNil(model.completedSubmission, "\(blank.debugDescription) produced a case")
        }
    }

    func testNextIsBlockedUntilASymptomIsPicked() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)

        XCTAssertFalse(model.canConfirmSymptom)
        model.confirmSymptomSelection()
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)], "Next must not be a silent no-op")

        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        XCTAssertTrue(model.canConfirmSymptom)
    }

    func testTheDefaultCameraIsAbsentSoNoBuildCanFabricateAPhotoWithoutOne() {
        XCTAssertFalse(UnavailableCamera().isAvailable)
        XCTAssertNil(UnavailableCamera().capture(sequence: 1))

        let model = IntakeFlowModel(catalogue: FakeProblemCatalogue())
        model.capturePhoto()
        XCTAssertTrue(model.photos.isEmpty, "the default model fabricated a photo with no camera injected")

        let photoModel = PhotoFirstFlowModel()
        photoModel.capturePhoto()
        XCTAssertTrue(photoModel.photos.isEmpty, "the default photo model fabricated a photo with no camera injected")
    }

    func testWithNoCameraTheShutterAddsNothingRatherThanFabricatingAPhoto() {
        let catalogue = FakeProblemCatalogue()
        let model = IntakeFlowModel(catalogue: catalogue, camera: FakeCamera(isAvailable: false))
        model.capturePhoto()

        XCTAssertFalse(model.isCameraAvailable)
        XCTAssertTrue(model.photos.isEmpty)
    }

    func testARejectionIsAnnouncedAndSoIsACompletedCase() {
        let (model, _) = makeModel()
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertEqual(model.announcement, model.rejection?.summary)

        model.acknowledgeAnnouncement()
        model.descriptionText = "drips constantly from the base"
        model.submit()
        XCTAssertEqual(model.announcement, "Case ready")
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

    func testRejectedSubmissionKeepsTheTypedTextAndDoesNotNavigate() {
        let (model, _) = makeModel()
        model.descriptionText = "call me on 917-555-0199 about the tap"
        model.path = [.pickProblem(FakeProblemCatalogue.drippingTap)]

        model.submit()

        XCTAssertEqual(model.descriptionText, "call me on 917-555-0199 about the tap")
        XCTAssertNotNil(model.rejection)
        XCTAssertEqual(model.path, [.pickProblem(FakeProblemCatalogue.drippingTap)])
        XCTAssertNil(model.completedSubmission)
    }

    func testEditingAfterARejectionAndResubmittingCanSucceed() {
        let (model, _) = makeModel()
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertNotNil(model.rejection)

        model.descriptionText = "drips constantly from the base"
        model.submit()

        XCTAssertNil(model.rejection)
        XCTAssertEqual(model.completedSubmission?.description.text, "drips constantly from the base")
    }

    func testSuccessfulSubmissionClearsThePathForANextCase() {
        let (model, _) = makeModel()
        model.descriptionText = "drips constantly from the base"
        model.path = [.pickProblem(FakeProblemCatalogue.drippingTap), .describeIt(FakeProblemCatalogue.drippingTapSymptoms[0])]

        model.submit()

        XCTAssertEqual(model.path, [])
        XCTAssertNotNil(model.completedSubmission)
    }

    func testAcknowledgingCompletionResetsStateForANewCase() {
        let (model, _) = makeModel()
        model.descriptionText = "drips constantly"
        model.submit()
        XCTAssertNotNil(model.completedSubmission)

        model.acknowledgeCompletion()

        XCTAssertNil(model.completedSubmission)
        XCTAssertEqual(model.descriptionText, "")
        XCTAssertTrue(model.photos.isEmpty)
    }
}
