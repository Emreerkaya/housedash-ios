import DesignSystem
@testable import Features

final class FakeProblemCatalogue: ProblemCatalogue, @unchecked Sendable {
    static let drippingTap = ProblemSummary(
        id: "dripping-tap",
        title: "Dripping tap",
        fullTitle: "Dripping tap or faucet",
        category: "Water",
        priceRange: "$90–140"
    )

    static let blockedDrain = ProblemSummary(
        id: "blocked-drain",
        title: "Blocked drain",
        category: "Water",
        priceRange: "$120–180"
    )

    static let drippingTapSymptoms: [SymptomOption] = [
        SymptomOption(
            id: "drips-constantly",
            primary: "Drips constantly",
            secondary: "Worse when the hot tap is on",
            priceRange: "$90–140"
        ),
        SymptomOption(
            id: "drips-when-running",
            primary: "Drips only when running",
            secondary: "Stops when the tap is off",
            priceRange: nil
        ),
        SymptomOption.ownWords(id: "none-of-these", primary: "None of these", secondary: "Describe it yourself")
    ]

    static let symptomWithNoPriceFromTheCatalogue = drippingTapSymptoms[1]

    static let escapeHatch = drippingTapSymptoms[2]

    var railsCallCount = 0
    var symptomsCallCount = 0

    func rails(for room: HDRoom) async throws -> [ProblemRail] {
        railsCallCount += 1
        guard room == .kitchen else { return [] }
        return [ProblemRail(id: "common-in-a-kitchen", heading: "Common in a kitchen", cards: [Self.drippingTap, Self.blockedDrain])]
    }

    func symptoms(for problem: ProblemSummary) async throws -> [SymptomOption] {
        symptomsCallCount += 1
        return problem.id == Self.drippingTap.id
            ? Self.drippingTapSymptoms
            : [SymptomOption.ownWords(id: "none-of-these", primary: "None of these", secondary: "Describe it yourself")]
    }
}
