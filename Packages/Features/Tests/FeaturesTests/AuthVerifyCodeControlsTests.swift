import XCTest
import DesignSystem
@testable import Features

final class AuthVerifyCodeControlsTests: XCTestCase {
    func testSubmitIsDisabledUntilAllSixDigitsAreEntered() {
        XCTAssertFalse(A06VerifyCodeScreen.canSubmit(codeCount: 0, banner: nil))
        XCTAssertFalse(A06VerifyCodeScreen.canSubmit(codeCount: 5, banner: nil))
        XCTAssertTrue(A06VerifyCodeScreen.canSubmit(codeCount: 6, banner: nil))
    }

    func testSubmitStaysEnabledOnAWrongCodeSoTheUserCanRetry() {
        XCTAssertTrue(A06VerifyCodeScreen.canSubmit(codeCount: 6, banner: .wrongCode))
    }

    func testSubmitIsDisabledOnceTheCodeHasExpired() {
        XCTAssertFalse(A06VerifyCodeScreen.canSubmit(codeCount: 6, banner: .codeExpired))
        XCTAssertNotNil(A06VerifyCodeScreen.disabledReason(codeCount: 6, banner: .codeExpired))
    }

    func testSubmitIsDisabledAfterTooManyAttempts() {
        XCTAssertFalse(A06VerifyCodeScreen.canSubmit(codeCount: 6, banner: .tooManyAttempts))
        XCTAssertNotNil(A06VerifyCodeScreen.disabledReason(codeCount: 6, banner: .tooManyAttempts))
    }

    func testEveryDisabledSubmitCarriesAReason() {
        let bannersDisablingSubmit: [OTPBannerState?] = [.codeExpired, .tooManyAttempts]
        for banner in bannersDisablingSubmit {
            XCTAssertNotNil(
                A06VerifyCodeScreen.disabledReason(codeCount: 6, banner: banner),
                "\(String(describing: banner)) disables submit and must say why"
            )
        }
    }

    func testAnEnabledSubmitCarriesNoReason() {
        XCTAssertNil(A06VerifyCodeScreen.disabledReason(codeCount: 6, banner: nil))
        XCTAssertNil(A06VerifyCodeScreen.disabledReason(codeCount: 6, banner: .wrongCode))
    }

    func testCodeEntrySanitizesNonDigitsAndClampsToSixCharacters() {
        XCTAssertEqual(HDCodeEntryField.sanitize("1a2b3c4d5e6f7g"), "123456")
        XCTAssertEqual(HDCodeEntryField.sanitize("12"), "12")
        XCTAssertEqual(HDCodeEntryField.sanitize(""), "")
    }

    func testCodeEntryAcceptsAWholePastedSixDigitStringInOneShot() {
        XCTAssertEqual(HDCodeEntryField.sanitize("482913"), "482913")
    }

    func testCodeEntryDropsAnyPastedCharactersPastTheSixthDigit() {
        XCTAssertEqual(HDCodeEntryField.sanitize("4829131234"), "482913")
    }
}
