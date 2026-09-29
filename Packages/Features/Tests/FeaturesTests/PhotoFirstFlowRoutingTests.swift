import XCTest
@testable import Features

@MainActor
final class PhotoFirstFlowRoutingTests: XCTestCase {
    func testReviewingWithNoPhotosDoesNothingBecauseThereIsNothingToReview() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.reviewPhotos()
        XCTAssertEqual(model.path, [])
    }

    func testCapturingThenReviewingAdvancesToAFewDetails() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.reviewPhotos()
        XCTAssertEqual(model.path, [.aFewDetails])
    }

    func testCapturingIsCappedAtFourToMatchTheTwoByTwoGrid() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        for _ in 0..<6 { model.capturePhoto() }
        XCTAssertEqual(model.photos.count, 4)
    }

    func testRejectedSubmissionKeepsPhotosAndText() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.descriptionText = "email me at bob@example.com"

        model.submit()

        XCTAssertNotNil(model.rejection)
        XCTAssertEqual(model.descriptionText, "email me at bob@example.com")
        XCTAssertEqual(model.photos.count, 1)
    }

    func testSuccessfulSubmissionClearsThePathAndRecordsTheDescription() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.reviewPhotos()
        model.descriptionText = "drips constantly from the base"

        model.submit()

        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.completedSubmission?.description.text, "drips constantly from the base")
    }

    func testTheSubmissionCarriesEveryPhotoTheUserCanSeeAndNoOthers() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.capturePhoto()
        model.reviewPhotos()
        model.descriptionText = "drips constantly from the base"

        model.submit()

        XCTAssertEqual(model.completedSubmission?.photos, model.photos)
        XCTAssertEqual(model.completedSubmission?.photos.count, 2)
    }

    func testABlankDescriptionCannotBeSubmittedAndProducesNoCase() {
        for blank in ["", "   ", "\n\t "] {
            let model = PhotoFirstFlowModel(camera: FakeCamera())
            model.capturePhoto()
            model.reviewPhotos()
            model.descriptionText = blank

            XCTAssertFalse(model.canSubmit, "\(blank.debugDescription) must not enable the CTA")
            model.submit()

            XCTAssertNil(model.completedSubmission, "\(blank.debugDescription) produced a case")
            XCTAssertEqual(model.path, [.aFewDetails], "a blocked submission must not navigate")
        }
    }

    func testWithNoCameraTheShutterAddsNothingRatherThanFabricatingAPhoto() {
        let model = PhotoFirstFlowModel(camera: FakeCamera(isAvailable: false))
        model.capturePhoto()
        model.capturePhoto()

        XCTAssertFalse(model.isCameraAvailable)
        XCTAssertTrue(model.photos.isEmpty)
    }

    func testGoingBackFromAFewDetailsClearsAStaleRejectionBanner() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.reviewPhotos()
        model.descriptionText = "email me at bob@example.com"
        model.submit()
        XCTAssertNotNil(model.rejection)

        model.goBack()

        XCTAssertEqual(model.path, [])
        XCTAssertNil(model.rejection, "the banner must not survive back-navigation and reappear stale")
    }
    func testTheRefusalNamesTheBoxOnThePhotoFirstPathToo() {
        let model = PhotoFirstFlowModel(camera: FakeCamera())
        model.capturePhoto()
        model.reviewPhotos()
        model.descriptionText = "call me on 917-555-0199 about the radiator"
        model.submit()

        let rejection = model.rejection
        XCTAssertEqual(
            rejection?.fieldLabels, [PhotoFirstFlowModel.descriptionFieldLabel],
            "the photo-first path mints an empty label set, so its refusal says \(DescriptionRejection.anUnnamedField.debugDescription) where B03's names the box the text was typed into"
        )
        XCTAssertTrue(
            rejection?.summary.contains(PhotoFirstFlowModel.descriptionFieldLabel) == true,
            "the summary a person reads on B07 does not name the one field the screen has: \(rejection?.summary ?? "no rejection at all")"
        )
        XCTAssertNil(model.completedSubmission, "the refused description was submitted anyway")
    }

}
