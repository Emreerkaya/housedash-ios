#if DEBUG
import Features

struct FixtureProblemCatalogue: ProblemCatalogue {
    private static let drippingTap = ProblemSummary(
        id: "dripping-tap",
        title: "Dripping tap",
        fullTitle: "Dripping tap or faucet",
        category: "Water",
        priceRange: "$90–140"
    )

    private static let kitchenRails: [ProblemRail] = [
        ProblemRail(
            id: "common-in-a-kitchen",
            heading: "Common in a kitchen",
            cards: [
                drippingTap,
                ProblemSummary(id: "blocked-drain", title: "Blocked drain", category: "Water", priceRange: "$120–180"),
                ProblemSummary(
                    id: "dishwasher-wont-drain",
                    title: "Dishwasher won't drain",
                    category: "Appliance",
                    priceRange: "$140–220"
                ),
                ProblemSummary(
                    id: "loose-cabinet-door",
                    title: "Loose cabinet door",
                    category: "Carpentry",
                    priceRange: "$70–110"
                )
            ]
        ),
        ProblemRail(
            id: "under-100",
            heading: "Under $100",
            cards: [
                ProblemSummary(id: "running-toilet", title: "Running toilet", category: "Water", priceRange: "$70–95"),
                ProblemSummary(id: "sticking-door", title: "Sticking door", category: "Carpentry", priceRange: "$60–90"),
                ProblemSummary(
                    id: "silicone-reseal",
                    title: "Silicone reseal",
                    category: "Water",
                    priceRange: "$80–100"
                ),
                ProblemSummary(id: "blown-socket", title: "Blown socket", category: "Electrical", priceRange: "$75–95")
            ]
        ),
        ProblemRail(
            id: "worth-doing-before-winter",
            heading: "Worth doing before winter",
            cards: [
                ProblemSummary(
                    id: "bleed-radiators",
                    title: "Bleed radiators",
                    category: "Heating",
                    priceRange: "$60–90"
                ),
                ProblemSummary(
                    id: "draught-seal-a-door",
                    title: "Draught-seal a door",
                    category: "Carpentry",
                    priceRange: "$90–130"
                ),
                ProblemSummary(
                    id: "clear-the-gutters",
                    title: "Clear the gutters",
                    category: "Exterior",
                    priceRange: "$120–190"
                ),
                ProblemSummary(
                    id: "service-the-boiler",
                    title: "Service the boiler",
                    category: "Heating",
                    priceRange: "$140–200"
                )
            ]
        )
    ]

    private static let drippingTapSymptoms: [SymptomOption] = [
        SymptomOption(
            id: "drips-constantly",
            primary: "Drips constantly",
            secondary: "Worse when the hot tap is on",
            priceRange: "$90–140"
        ),
        SymptomOption(
            id: "drips-only-when-running",
            primary: "Drips only when running",
            secondary: "Usually a washer",
            priceRange: "$70–110"
        ),
        SymptomOption(
            id: "water-pools-at-the-base",
            primary: "Water pools at the base",
            secondary: "Seal or cartridge",
            priceRange: "$110–170"
        ),
        SymptomOption(
            id: "handle-is-stiff-or-loose",
            primary: "Handle is stiff or loose",
            secondary: "Cartridge",
            priceRange: "$80–130"
        ),
        SymptomOption.ownWords(id: "none-of-these", primary: "None of these", secondary: "Describe it yourself")
    ]

    private static let escapeHatchOnly: [SymptomOption] = [
        SymptomOption.ownWords(id: "none-of-these", primary: "None of these", secondary: "Describe it yourself")
    ]

    func rails(for room: HDRoom) async throws -> [ProblemRail] {
        room == .kitchen ? Self.kitchenRails : []
    }

    func symptoms(for problem: ProblemSummary) async throws -> [SymptomOption] {
        problem.id == Self.drippingTap.id ? Self.drippingTapSymptoms : Self.escapeHatchOnly
    }
}
#endif
