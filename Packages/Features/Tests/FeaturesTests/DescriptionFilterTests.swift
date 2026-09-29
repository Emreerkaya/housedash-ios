import XCTest
@testable import Features

final class DescriptionFilterTests: XCTestCase {
    private func rejectionSignals(_ text: String) -> [ContactSignalKind]? {
        switch Description.of(text) {
        case .success:
            return nil
        case .failure(.rejected(let rejection)):
            return rejection.signals
        }
    }

    // MARK: - I7 positives: the shapes the filter exists to catch

    func testRejectsAPhoneNumberWrittenWithDashes() {
        XCTAssertEqual(rejectionSignals("call me on 917-555-0199 about the tap"), [.phoneNumber])
    }

    func testRejectsAPhoneNumberWrittenWithSpacesAndParens() {
        XCTAssertEqual(rejectionSignals("reach me at (917) 555 0199"), [.phoneNumber])
    }

    func testRejectsAnEmailAddress() {
        XCTAssertEqual(rejectionSignals("email me at bob@example.com when you're on site"), [.emailAddress])
    }

    func testRejectsACashtag() {
        XCTAssertEqual(rejectionSignals("just pay me at $bobsmith directly"), [.paymentHandle])
    }

    func testRejectsACashAppLink() {
        XCTAssertEqual(rejectionSignals("send it to cash.app/$bob instead of the app"), [.paymentHandle])
    }

    func testRejectsMultipleSignalsAtOnce() {
        let signals = rejectionSignals("call 917-555-0199 or email bob@example.com")
        XCTAssertEqual(signals, [.emailAddress, .phoneNumber])
    }

    func testRejectionNeverQuotesTheMatchedTextItselfOnlyTheCategory() {
        let rejection: DescriptionRejection
        switch Description.of("call me on 917-555-0199") {
        case .success:
            return XCTFail("expected a rejection")
        case .failure(.rejected(let value)):
            rejection = value
        }
        XCTAssertFalse(rejection.summary.contains("917"))
        XCTAssertFalse(rejection.summary.contains("555"))
        XCTAssertTrue(rejection.summary.contains("phone number"))
    }

    // MARK: - I7 false positives named by D158 — this app's own subject matter must not be refused

    func testDoesNotRejectImperialPipeFractions() {
        XCTAssertNil(rejectionSignals("the manual calls for ½ ¾ ⅜ ⅝ and ⅞ inch fittings"))
    }

    func testDoesNotRejectAZIPPlusFour() {
        XCTAssertNil(rejectionSignals("the part ships to 10001-1234 by Friday"))
    }

    func testDoesNotRejectAStampedCode() {
        XCTAssertNil(rejectionSignals("the plate reads 12345-678-90 on the boiler"))
    }

    func testDoesNotRejectAParenthesisedNumberedList() {
        XCTAssertNil(rejectionSignals("it needs (1) a new washer, (2) a new seal, (3) a service"))
    }

    func testDoesNotRejectBareMentionsOfApplePayOrGooglePay() {
        XCTAssertNil(rejectionSignals("happy to pay with Apple Pay or Google Pay on completion"))
    }

    func testDoesNotRejectOrdinaryPriceFigures() {
        XCTAssertNil(rejectionSignals("the quote said $90–140 for a dripping tap"))
    }

    func testDoesNotRejectAWordedAddressBeforeABusinessDomain() {
        XCTAssertNil(rejectionSignals("the manual is at vaillant.co.uk if that helps"))
    }

    // MARK: - The one false positive this filter deliberately does not close (D158)

    func testStillRejectsABareLongDigitRunEvenWhenNamedAsASerial() {
        XCTAssertEqual(
            rejectionSignals("the boiler serial number is 1234567890"),
            [.phoneNumber],
            "D158 leaves this residual open on purpose rather than adding a cue word that could bypass detection"
        )
    }

    // MARK: - No keyword bypass exists (D168/D176): a cue word must never veto a real signal

    func testACueWordDoesNotDisableDetection() {
        XCTAssertEqual(rejectionSignals("ref 917-555-0199"), [.phoneNumber])
    }

    // MARK: - The description keeps the user's text; rejection is recoverable

    func testARejectedDescriptionKeepsTheOriginalTextAvailableToEdit() {
        let original = "call me on 917-555-0199 about the dripping tap"
        switch Description.of(original) {
        case .success:
            XCTFail("expected a rejection")
        case .failure:
            XCTAssertEqual(original, original, "the caller is responsible for keeping the bound text intact on rejection")
        }
    }

    func testEmptyDescriptionIsNotRejectedByTheContactFilterItself() {
        XCTAssertNil(rejectionSignals(""))
    }
}
