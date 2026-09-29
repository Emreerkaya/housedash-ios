import XCTest
@testable import Features

final class IntakeCardPhotoResolutionTests: XCTestCase {
    func testAProblemWithNoBundledAssetGetsTheDesignedEmptyStateRatherThanABrokenImage() {
        let problem = FakeProblemCatalogue.drippingTap
        XCTAssertEqual(
            IntakeCard.resolvePhoto(for: problem, in: .module),
            .emptyState,
            "Features ships no bundled photo for '\(problem.id)', so the card must fall back to the designed empty state"
        )
    }

    func testAProblemWhoseIDMatchesABundledAssetResolvesToThatAsset() {
        let problem = ProblemSummary(id: "sample-problem", title: "Sample problem", category: "Test", priceRange: "$1–2")
        XCTAssertEqual(
            IntakeCard.resolvePhoto(for: problem, in: Bundle.module),
            .asset(name: "sample-problem"),
            "a bundled asset named exactly after the problem id must resolve rather than falling through to the empty state"
        )
    }

}
