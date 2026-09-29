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

    func testAPhoneNumberTypedIntoWhereIsRefusedTheSameWayOneTypedIntoTheDescriptionIs() async {
        let contactDetail = "917-555-0199 ask for Bob, or bob@example.com"

        let (inTheDescription, _) = makeModel()
        await reachDescribeIt(inTheDescription)
        inTheDescription.descriptionText = contactDetail
        inTheDescription.submit()

        let (inWhere, _) = makeModel()
        await reachDescribeIt(inWhere)
        inWhere.descriptionText = "The tap drips from the base."
        inWhere.locationText = contactDetail
        inWhere.submit()

        XCTAssertEqual(
            inWhere.rejection?.signals, inTheDescription.rejection?.signals,
            "the same string reports \(String(describing: inWhere.rejection?.signals)) in Where and \(String(describing: inTheDescription.rejection?.signals)) in the description"
        )
        XCTAssertNil(
            inWhere.completedSubmission,
            "Where carried \(String(describing: inWhere.completedSubmission?.location)) into the submitted case unfiltered"
        )
        XCTAssertEqual(inWhere.rejection?.fieldLabels, [IntakeFlowModel.locationFieldLabel])
        XCTAssertEqual(inTheDescription.rejection?.fieldLabels, [IntakeFlowModel.descriptionFieldLabel])
    }

    func testWhereStillTakesAPlaceNameWithDigitsInIt() async {
        let (model, _) = makeModel()
        await reachDescribeIt(model)
        model.descriptionText = "The tap drips from the base."
        for place in ["Greenwich Village", "Flat 4, 221B Baker Street", "350 East 62nd Street", "Apartment 12, second floor"] {
            model.locationText = place
            model.submit()
            XCTAssertNil(model.rejection, "'\(place)' is refused, so the filter is now refusing addresses")
            XCTAssertEqual(model.completedSubmission?.location, place)
            model.acknowledgeCompletion()
            await reachDescribeIt(model)
            model.descriptionText = "The tap drips from the base."
        }
    }

    func testASubmissionCarriesOnlyPhotosTakenForTheProblemItNames() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.capturePhoto()
        XCTAssertEqual(model.photos.map(\.id), ["photo-1"], "the camera fixture took no photo, so this test is vacuous")
        model.goBack()

        model.selectSymptomForReview(FakeProblemCatalogue.symptomWithNoPriceFromTheCatalogue)
        model.confirmSymptomSelection()
        model.descriptionText = "The tap drips from the base."
        model.submit()

        XCTAssertEqual(
            model.completedSubmission?.photos, [],
            "the case names \(String(describing: model.completedSubmission?.problem?.title)) and carries \(String(describing: model.completedSubmission?.photos.map(\.id))), taken against a different symptom"
        )
    }

    func testASubmissionKeepsThePhotosTakenForTheSymptomItStillNames() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.capturePhoto()
        model.goBack()
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
        model.descriptionText = "The tap drips from the base."
        model.submit()

        XCTAssertEqual(
            model.completedSubmission?.photos.map(\.id), ["photo-1"],
            "going back and choosing the same symptom again threw away a photo that still belongs to it"
        )
    }

    func testASymptomTheCatalogueGaveNoPriceForIsStillASymptom() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        let symptom = FakeProblemCatalogue.symptomWithNoPriceFromTheCatalogue
        XCTAssertNil(symptom.priceRange, "this symptom has a price, so the case it stands for cannot arise")
        XCTAssertFalse(symptom.isEscapeHatch, "a symptom with no price from the catalogue is being read as the escape hatch")

        model.selectSymptomForReview(symptom)
        model.confirmSymptomSelection()
        XCTAssertEqual(
            model.path.last, .describeIt(symptom),
            "a missing price sent an ordinary symptom to \(String(describing: model.path.last)) instead of its own screen"
        )

        model.capturePhoto()
        model.descriptionText = "The tap drips from the base."
        model.submit()
        XCTAssertEqual(
            model.completedSubmission?.problem, FakeProblemCatalogue.drippingTap,
            "a missing price detached the case from its catalogue problem"
        )
        XCTAssertEqual(
            model.completedSubmission?.photos.map(\.id), ["photo-1"],
            "a missing price threw away the captured photo"
        )
    }

    func testTheEscapeHatchIsTheOnlyThingThatSubmitsWithNoProblem() async {
        let (model, _) = makeModel()
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.escapeHatch)
        model.confirmSymptomSelection()
        XCTAssertEqual(model.path.last, .somethingElse)
        model.descriptionText = "The radiator never gets hot."
        model.submit()
        XCTAssertNil(model.completedSubmission?.problem)
    }

    func testARealSymptomWithNoProblemBehindItDoesNotBecomeTheEscapeHatch() {
        let (model, _) = makeModel()
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]
        model.symptoms = FakeProblemCatalogue.drippingTapSymptoms
        model.photos = [CapturedPhoto(id: "photo-1", timestampLabel: "09:41")]
        XCTAssertNil(model.selectedProblem, "this test needs the problem missing, and it is not")
        XCTAssertFalse(symptom.isEscapeHatch, "this test needs a real symptom, and it has the escape hatch")

        model.selectSymptomForReview(symptom)
        model.confirmSymptomSelection()

        XCTAssertEqual(
            model.path, [],
            "a real symptom with no problem behind it navigated to \(model.path), and the only screen it can reach that way is the escape hatch's, which has no photo strip and submits problem: nil"
        )
        XCTAssertEqual(
            model.photos.map(\.id), ["photo-1"],
            "the refused transition still threw away the captured photos on its way to nowhere"
        )
    }

    func testTheEscapeHatchStillRoutesWithNoProblemBehindIt() {
        let (model, _) = makeModel()
        model.symptoms = FakeProblemCatalogue.drippingTapSymptoms
        model.selectSymptomForReview(FakeProblemCatalogue.escapeHatch)
        model.confirmSymptomSelection()
        XCTAssertEqual(
            model.path, [.somethingElse],
            "the escape hatch needs no problem behind it and the refusal above is now swallowing it too"
        )
    }

    private func reachDescribeIt(_ model: IntakeFlowModel) async {
        await model.selectProblem(FakeProblemCatalogue.drippingTap)
        model.selectSymptomForReview(FakeProblemCatalogue.drippingTapSymptoms[0])
        model.confirmSymptomSelection()
    }
}
