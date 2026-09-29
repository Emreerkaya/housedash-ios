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

    func testACueWordDoesNotDisableDetection() {
        XCTAssertEqual(rejectionSignals("ref 917-555-0199"), [.phoneNumber])
    }

    func testTheArmsThatRefusedSomethingTheServerAcceptsAreEachPinnedOnTheirOwn() {
        XCTAssertNil(
            rejectionSignals("boiler serial 1234567890"),
            "a bare digit run with no grouping and no cue is a gap the server leaves open, not a signal"
        )
        XCTAssertNil(
            rejectionSignals("the part number is 0141-445-2266-01 on the label"),
            "a four digit leading group and a two digit last group is not a phone shape on the server"
        )
        XCTAssertNil(
            rejectionSignals("bob@example..com is a typo"),
            "an empty domain label is not a domain on the server"
        )
        XCTAssertNil(
            rejectionSignals("the mycash.app/bob directory is where the manual lives"),
            "the server requires a word boundary before a payment brand"
        )
        XCTAssertNil(
            rejectionSignals("the code stamped is A250$bobsmith on the casing"),
            "the server requires a cashtag not to follow a letter or digit"
        )
    }

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

    func testARejectedDescriptionNamesEveryKindItFoundAndQuotesNoneOfThem() {
        let original = "call me on 917-555-0199 or bob@example.com, or just pay me at $bobsmith"
        guard case .failure(.rejected(let rejection)) = Description.of(original) else {
            return XCTFail("'\(original)' carries all three kinds and was accepted")
        }
        XCTAssertEqual(
            rejection.signals, [.emailAddress, .phoneNumber, .paymentHandle],
            "a description carrying all three kinds reports \(rejection.signals.map(\.rawValue))"
        )
        XCTAssertEqual(
            rejection.summary,
            "This looks like it includes an email address, a phone number, and a payment link or handle. Every job is coordinated and paid through HouseDash, so contact details and payment links can't go in a description \u{2014} remove that part and you're set.",
            "the three-kind branch of the summary reads: \(rejection.summary)"
        )
        for quoted in ["917", "555", "0199", "bob@example.com", "bobsmith"] {
            XCTAssertFalse(
                rejection.summary.contains(quoted),
                "the summary quotes '\(quoted)' back at the person who typed it"
            )
        }
    }

    func testEmptyDescriptionIsNotRejectedByTheContactFilterItself() {
        XCTAssertNil(rejectionSignals(""))
    }

}
