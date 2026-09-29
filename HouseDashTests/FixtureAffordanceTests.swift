import XCTest
@testable import Features
@testable import HouseDash

final class FixtureAffordanceTests: XCTestCase {
    func testTheFixtureIdentityServiceAcceptsAnEmptyPasswordOnPurpose() async throws {
        let outcome = try await FixtureIdentityService().createAccount(
            identifier: "reviewer@example.com",
            password: "",
            role: .nester
        )
        guard case .accountCreated(let role) = outcome else {
            return XCTFail("the two tap route to the tab root is gone, so no reviewer can reach these screens without a keyboard")
        }
        XCTAssertEqual(role, .nester)
    }

    func testTheFixtureIdentityServiceStillRefusesAnEmptyPasswordOnSignIn() async {
        do {
            _ = try await FixtureIdentityService().signIn(identifier: "dana@example.com", password: "")
            XCTFail("an empty password signed in to an existing account")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .invalidCredentials)
        }
    }

    @MainActor
    func testTheLiveCameraNeverFabricatesAPhotoWhenNoDeviceIsAttached() {
        XCTAssertFalse(LiveCamera().isAvailable, "this suite runs with no capture device attached")
        XCTAssertNil(LiveCamera().capture(sequence: 1))
        XCTAssertNil(UnavailableCamera().capture(sequence: 1))
        XCTAssertFalse(UnavailableCamera().isAvailable)
    }

    func testTheReleaseCatalogueAndCameraAreBothUnavailableRatherThanFixtures() async {
        do {
            _ = try await UnavailableProblemCatalogue().rails(for: .kitchen)
            XCTFail("the release catalogue returned fixture rails")
        } catch {
            XCTAssertEqual(error as? ProblemCatalogueError, .notImplemented)
        }
    }
}
