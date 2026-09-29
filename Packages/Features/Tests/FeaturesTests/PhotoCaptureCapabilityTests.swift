import XCTest
@testable import Features

final class PhotoCaptureCapabilityTests: XCTestCase {
    func testUnavailableCameraStillLetsALibraryPhotoBeAdopted() {
        let camera = UnavailableCamera()
        XCTAssertFalse(camera.isAvailable)
        XCTAssertNotNil(camera.adopt(libraryIdentifier: "library-1", sequence: 1))
    }

    func testUnavailableCameraDefaultsToAuthorizedPermissionSoItNeverShowsASettingsPrompt() {
        XCTAssertEqual(UnavailableCamera().permission, .authorized)
    }

    func testRequestingPermissionWithNoOverrideReturnsTheCurrentPermission() async {
        let camera = UnavailableCamera()
        let result = await camera.requestPermission()
        XCTAssertEqual(result, camera.permission)
    }

    @MainActor
    func testLiveCameraOnThisMachineHasNoVideoDeviceSoItNeverFabricatesAPhoto() {
        let camera = LiveCamera()

        XCTAssertFalse(camera.isAvailable, "this suite runs with no capture device attached")
        XCTAssertNil(camera.capture(sequence: 1), "with no device, capture must add nothing rather than fabricate a photo")
    }

    @MainActor
    func testLiveCameraStillLetsALibraryPhotoBeAdoptedWithNoDevice() {
        let camera = LiveCamera()
        XCTAssertNotNil(camera.adopt(libraryIdentifier: "library-1", sequence: 1))
    }
}
