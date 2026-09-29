import XCTest
@testable import Features

@MainActor
final class PhotoFirstFlowRoutingTests: XCTestCase {
    func testReviewingWithNoPhotosDoesNothingBecauseThereIsNothingToReview() {
        let model = PhotoFirstFlowModel()
        model.reviewPhotos()
        XCTAssertEqual(model.path, [])
    }

    func testCapturingThenReviewingAdvancesToAFewDetails() {
        let model = PhotoFirstFlowModel()
        model.capturePhoto()
        model.reviewPhotos()
        XCTAssertEqual(model.path, [.aFewDetails])
    }

    func testCapturingIsCappedAtFourToMatchTheTwoByTwoGrid() {
        let model = PhotoFirstFlowModel()
        for _ in 0..<6 { model.capturePhoto() }
        XCTAssertEqual(model.photos.count, 4)
    }

    func testRejectedSubmissionKeepsPhotosAndText() {
        let model = PhotoFirstFlowModel()
        model.capturePhoto()
        model.descriptionText = "email me at bob@example.com"

        model.submit()

        XCTAssertNotNil(model.rejection)
        XCTAssertEqual(model.descriptionText, "email me at bob@example.com")
        XCTAssertEqual(model.photos.count, 1)
    }

    func testSuccessfulSubmissionClearsThePathAndRecordsTheDescription() {
        let model = PhotoFirstFlowModel()
        model.capturePhoto()
        model.reviewPhotos()
        model.descriptionText = "drips constantly from the base"

        model.submit()

        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.completedDescription?.text, "drips constantly from the base")
    }
}
