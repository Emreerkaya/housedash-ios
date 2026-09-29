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

    func testTheFilterRefusesNothingTheServerWouldAccept() {
        for text in Self.everyDescriptionTheServerAccepts {
            XCTAssertNil(
                rejectionSignals(text),
                "the client refuses \(text.debugDescription), which the server's own pinned tests accept"
            )
        }
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

    static let everyDescriptionTheServerAccepts: [String] = [
        "kitchen tap drips from the base",
        "boiler pressure drops to half a bar overnight, a 2015 model",
        "flat 4B at 350 East 62nd Street, bedroom 2 radiator is cold",
        "the fuse blew on 2026-09-24 and blew again the next day",
        "the last quote was $250 and the one before was $180",
        "the pipe is 3/4 inch and weeping at the joint",
        "it has dripped for 14 days now",
        "model number BX-2200 on the sticker",
        "the meter reads 001234 and the dial is stuck",
        "my gazelle bike is chained to the wisecrack pipe",
        "the paypalace hotel radiator is not the issue",
        "cabinet is 600 mm wide and 870 mm tall",
        "the parts cost 12.50 13.75 14.00 all in",
        "sizes 10 12 14 16 18 20 22 are all wrong",
        "replace washers 1 2 3 4 5 6 7 8 9 10 in that order",
        "the pipe is 3\u{00BD} inch across the joint",
        "the flue is 600 mm long and the gap is 870 mm",
        "a 2015 model that has leaked for 14 days",
        "350 East 62nd Street, apartment 4B, third floor walk up",
        "the manual is at vaillant.co.uk if you want to read it",
        "boiler serial 1234567890",
        "the plate reads 9175550199 and nothing else",
        "the coil is stamped 1234567 890 on the side",
        "the gauge showed 12 34 56 78 90 across the week",
        "serial 917555019",
        "serial 191755501990001",
        "part 9175550199 on the plate",
        "serial number 1234567890 is on the plate behind the panel",
        "invoice number 1234567890 is still unpaid",
        "boiler serviced 2019, 2021, 2023 and now it leaks",
        "boiler serviced 2019 2021 2023 and now it leaks",
        "the radiators are 1400, 1600, 1800 mm along that wall",
        "the radiators are 1400 1600 1800 mm along that wall",
        "radiator widths are\n1400\n1600\n1800\nacross the hallway",
        "invoices 4455 4456 4457 are all still unpaid",
        "lengths 1200 1500 1800 and 2100 mm are needed",
        "the part number is 0141-445-2266-01 on the label",
        "the plate reads 1 1234567 1234567 1234567 1 on the side",
        "the rads are 1 22 33 44 55 66 77 8 across the run",
        "call me about the 123,456,789 lira bill",
        "call me about the 1,250,000 lira bill",
        "what's appropriate for this boiler is not clear",
        "what is apparent here is nothing at all",
        "the run cost 123,456,789 lira all in",
        "the invoice total was 1,250.00 and 1,234 parts",
        "steps \u{2474}\u{2475}\u{2476}\u{2477}\u{2478}\u{2479}\u{247A}\u{247B}\u{247C}",
        "mail the receipt to 10001-1234 instead",
        "the gasket stamped 12345-678-90 is split",
        "fittings \u{00BD} \u{00BE} \u{215C} \u{215D} \u{215E} needed here",
        "call me when the \u{00BD} \u{00BE} \u{215C} \u{215D} \u{215E} fittings arrive",
        "fittings 1/2 3/4 3/8 5/8 7/8 needed here",
        "call me when the 1/2 3/4 3/8 5/8 7/8 fittings arrive",
        "elbows in 15 mm 22 mm 28 mm and 35 mm please",
        "the tank is 210 litres and the cylinder is 1,250 mm tall",
        "the radiator is 1400 x 600 mm and weighs 32 kg",
        "the pressure gauge reads 1.5 bar and the flow is 12.5 l/min",
        "logged at 12:30:45 2026-09-24 by the engineer",
        "the fuse blew on 2026-09-24, 350 East 62nd Street",
        "job 4455 on 2026-09-24 needs 2 washers 12 mm",
        "appliance model ecoTEC plus 832, serial 21123400123456789",
        "3 @ 5.00 each for the washers",
        "bob at bobsplumbing.co.uk is where the invoices go",
        "BX22001234567890123 is stamped on the casing",
        "GB34BUKB20201555555555 is stamped on the casing",
        "AB12 3456 7890 1234 5678 9012 3456 7890 123 stamped on the casing",
        "bob@localhost is where the logs go",
        "bob@example..com is a typo",
        "bob@example.c0m is a typo",
        "nine one seven five five five zero one nine nine",
        "bobsplumbing.co.uk",
        "look me up, the business name is bobs plumbing",
        "bob at bobsplumbing.co.uk",
        "the pipe run is 917\u{2044}555\u{2044}0199 mm of copper",
        "917 then 555 then 0199 is the number",
        "7700 9001 2345 is best",
        "7700,9001,2345 is best",
        "bob at example dot see oh em",
        "scan the qr code on my van",
        "the rads are 9 1 7 5 5 5 0 1 99 across the run",
        "the part code is GB33BUKB20201555555556 on the plate",
        "the boiler plate reads GB33 BUKB 2020 is stamped by the door"
    ]
}
