import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import Features
@testable import HouseDash

final class FixtureProblemCatalogueTests: XCTestCase {
    private static func parsePriceRange(_ text: String) throws -> (low: Int, high: Int) {
        let digitsAndDash = text.filter { $0.isNumber || $0 == "–" }
        let parts = digitsAndDash.split(separator: "–")
        guard
            parts.count == 2,
            let low = Int(parts[0]),
            let high = Int(parts[1])
        else {
            throw XCTSkip("'\(text)' is not a parseable band, so this test cannot measure it")
        }
        return (low, high)
    }

    private static let idsThatMustNotAppearInKitchen: Set<String> = ["running-toilet", "sticking-door"]

    func testEveryProblemAppearsExactlyOnceAcrossTheWholeCatalogue() {
        let ids = FixtureProblemCatalogue.entries.map(\.problem.id)
        XCTAssertEqual(
            ids.count, Set(ids).count,
            "the catalogue lists \(ids.count) entries but only \(Set(ids).count) distinct ids, so some problem is duplicated"
        )
    }

    func testRunningToiletAndStickingDoorNoLongerSitUnderKitchen() {
        let kitchenIDs = Set(
            FixtureProblemCatalogue.entries.filter { $0.room == .kitchen }.map(\.problem.id)
        )
        let stillMisfiled = kitchenIDs.intersection(Self.idsThatMustNotAppearInKitchen)
        XCTAssertTrue(
            stillMisfiled.isEmpty,
            "\(stillMisfiled.sorted()) still sit under Kitchen; neither is a kitchen problem"
        )
    }

    func testRunningToiletResolvesToBathroomAndStickingDoorToBedroom() {
        let byID = Dictionary(uniqueKeysWithValues: FixtureProblemCatalogue.entries.map { ($0.problem.id, $0.room) })
        XCTAssertEqual(byID["running-toilet"], .bathroom, "a running toilet is a bathroom problem")
        XCTAssertEqual(byID["sticking-door"], .bedroom, "a sticking door was filed under Kitchen and must move somewhere that is not Kitchen")
    }

    func testEveryPriceBandIsOrderedLowToHigh() throws {
        for entry in FixtureProblemCatalogue.entries {
            let band = try Self.parsePriceRange(entry.problem.priceRange)
            XCTAssertLessThan(
                band.low, band.high,
                "'\(entry.problem.id)' has an unordered price band \(entry.problem.priceRange)"
            )
        }
    }

    func testEveryCardInTheUnder100RailActuallyToppedOutAtOrUnder100() throws {
        for entry in FixtureProblemCatalogue.entries where entry.band == .under100 {
            let band = try Self.parsePriceRange(entry.problem.priceRange)
            XCTAssertLessThanOrEqual(
                band.high, 100,
                "'\(entry.problem.id)' sits in the Under $100 rail but its band tops out at $\(band.high)"
            )
        }
    }

    func testEveryRoomTheChipsOfferHasAtLeastOneEntry() {
        for room in HDRoom.allCases {
            let count = FixtureProblemCatalogue.entries.filter { $0.room == room }.count
            XCTAssertGreaterThan(count, 0, "\(room.label) has no problems filed under it at all")
        }
    }

    func testTheRoomFilterReturnsDifferentContentPerRoomRatherThanGatingEverythingBehindKitchen() async throws {
        let catalogue = FixtureProblemCatalogue()
        var idsByRoom: [HDRoom: Set<String>] = [:]
        for room in HDRoom.allCases {
            let rails = try await catalogue.rails(for: room)
            idsByRoom[room] = Set(rails.flatMap(\.cards).map(\.id))
        }

        for room in HDRoom.allCases where room != .kitchen {
            XCTAssertFalse(
                idsByRoom[room, default: []].isEmpty,
                "\(room.label) shows no curated content; the chip selects, the content does not change"
            )
            XCTAssertNotEqual(
                idsByRoom[room], idsByRoom[.kitchen],
                "\(room.label) returns the same cards Kitchen does"
            )
        }
    }

    func testNeitherRunningToiletNorStickingDoorReachesTheScreenViaTheKitchenChip() async throws {
        let catalogue = FixtureProblemCatalogue()
        let kitchenCardIDs = try await catalogue.rails(for: .kitchen).flatMap(\.cards).map(\.id)
        for forbidden in Self.idsThatMustNotAppearInKitchen {
            XCTAssertFalse(
                kitchenCardIDs.contains(forbidden),
                "'\(forbidden)' reaches the Kitchen chip's rails"
            )
        }
    }

    #if canImport(UIKit)
    @MainActor
    func testEveryCardTheRealCatalogueShipsRendersSomethingRatherThanCollapsingToNothing() async throws {
        let catalogue = FixtureProblemCatalogue()
        for room in HDRoom.allCases {
            let rails = try await catalogue.rails(for: room)
            for card in rails.flatMap(\.cards) {
                let size = UIHostingController(rootView: IntakeCard(problem: card, action: {}))
                    .sizeThatFits(in: CGSize(width: 353, height: CGFloat.infinity))
                XCTAssertGreaterThan(
                    size.height, IntakeCard.photoHeight,
                    "'\(card.id)' rendered at \(size.height)pt, no taller than its photo slot, so its title and price drew nothing"
                )
            }
        }
    }
    #endif
}
