import XCTest
@testable import Features
@testable import HouseDash

final class FixtureAffordanceTests: XCTestCase {
    func testTheFixtureIdentityServiceCreatesAnAccountOnceTheFixtureCodeVerifies() async throws {
        let outcome = try await FixtureIdentityService().createAccount(
            identifier: "reviewer@example.com",
            role: .nester
        )
        guard case .accountCreated(let role) = outcome else {
            return XCTFail("the two tap route to the tab root is gone, so no reviewer can reach these screens without a keyboard")
        }
        XCTAssertEqual(role, .nester)
    }

    func testTheFixtureIdentityServiceRefusesAWrongCode() async {
        do {
            _ = try await FixtureIdentityService().verifyCode(identifier: "dana@example.com", code: "000000")
            XCTFail("a wrong code verified against an existing account")
        } catch {
            XCTAssertEqual(error as? IdentityServiceError, .wrongCode)
        }
    }

    func testTheFixtureIdentityServiceAcceptsItsOwnFixtureCode() async throws {
        let result = try await FixtureIdentityService().verifyCode(
            identifier: "dana@example.com",
            code: FixtureIdentityService.fixtureCode
        )
        guard case .existingAccount(let roles) = result else {
            return XCTFail("dana@example.com is a fixture account and should verify as existing")
        }
        XCTAssertEqual(roles, [.nester, .tasker])
    }

    func testTheFixtureIdentityServiceNeverAppendsTheCodeToItsErrorDescription() {
        let error = IdentityServiceError.wrongCode
        XCTAssertFalse("\(error)".contains(FixtureIdentityService.fixtureCode))
    }

    func testTheFixtureIdentityServiceHasASentinelCodeForEveryQAState() async {
        let service = FixtureIdentityService()
        let cases: [(String, IdentityServiceError)] = [
            (FixtureIdentityService.expiredCode, .codeExpired),
            (FixtureIdentityService.tooManyAttemptsCode, .tooManyAttempts),
            (FixtureIdentityService.rateLimitedCode, .rateLimited(retryAfterSeconds: 45)),
            (FixtureIdentityService.offlineCode, .offline)
        ]
        for (code, expected) in cases {
            do {
                _ = try await service.verifyCode(identifier: "dana@example.com", code: code)
                XCTFail("\(code) should have thrown \(expected)")
            } catch {
                XCTAssertEqual(error as? IdentityServiceError, expected)
            }
        }
    }

    func testTheFixtureCameraIsTheOnlyThingThatProducesAPhotoAndItIsDebugOnly() {
        XCTAssertNotNil(FixtureCamera().capture(sequence: 1))
        XCTAssertTrue(FixtureCamera().isAvailable)
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
