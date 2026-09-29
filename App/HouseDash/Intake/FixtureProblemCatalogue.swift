#if DEBUG
import Features

struct FixtureProblemCatalogue: ProblemCatalogue {
    enum RailBand: String, CaseIterable, Sendable {
        case common
        case under100
        case seasonal

        func heading(for room: HDRoom) -> String {
            switch self {
            case .common:
                room == .outdoors ? "Common outdoors" : "Common in a \(room.label.lowercased())"
            case .under100:
                "Under $100"
            case .seasonal:
                "Worth doing before winter"
            }
        }
    }

    struct Entry: Sendable {
        let room: HDRoom
        let band: RailBand
        let problem: ProblemSummary
    }

    static let drippingTap = ProblemSummary(
        id: "dripping-tap",
        title: "Dripping tap",
        fullTitle: "Dripping tap or faucet",
        category: "Water",
        priceRange: "$90–140"
    )

    static let entries: [Entry] = [
        Entry(room: .kitchen, band: .common, problem: drippingTap),
        Entry(
            room: .kitchen,
            band: .common,
            problem: ProblemSummary(id: "blocked-drain", title: "Blocked drain", category: "Water", priceRange: "$120–180")
        ),
        Entry(
            room: .kitchen,
            band: .common,
            problem: ProblemSummary(
                id: "dishwasher-wont-drain",
                title: "Dishwasher won't drain",
                category: "Appliance",
                priceRange: "$140–220"
            )
        ),
        Entry(
            room: .kitchen,
            band: .common,
            problem: ProblemSummary(
                id: "loose-cabinet-door",
                title: "Loose cabinet door",
                category: "Carpentry",
                priceRange: "$70–110"
            )
        ),
        Entry(
            room: .kitchen,
            band: .seasonal,
            problem: ProblemSummary(
                id: "service-the-boiler",
                title: "Service the boiler",
                category: "Heating",
                priceRange: "$140–200"
            )
        ),

        Entry(
            room: .bathroom,
            band: .under100,
            problem: ProblemSummary(id: "running-toilet", title: "Running toilet", category: "Water", priceRange: "$70–95")
        ),
        Entry(
            room: .bathroom,
            band: .under100,
            problem: ProblemSummary(
                id: "silicone-reseal",
                title: "Silicone reseal",
                category: "Water",
                priceRange: "$80–100"
            )
        ),

        Entry(
            room: .bedroom,
            band: .under100,
            problem: ProblemSummary(id: "sticking-door", title: "Sticking door", category: "Carpentry", priceRange: "$60–90")
        ),
        Entry(
            room: .bedroom,
            band: .under100,
            problem: ProblemSummary(id: "blown-socket", title: "Blown socket", category: "Electrical", priceRange: "$75–95")
        ),
        Entry(
            room: .bedroom,
            band: .seasonal,
            problem: ProblemSummary(
                id: "bleed-radiators",
                title: "Bleed radiators",
                category: "Heating",
                priceRange: "$60–90"
            )
        ),

        Entry(
            room: .outdoors,
            band: .seasonal,
            problem: ProblemSummary(
                id: "draught-seal-a-door",
                title: "Draught-seal a door",
                category: "Carpentry",
                priceRange: "$90–130"
            )
        ),
        Entry(
            room: .outdoors,
            band: .seasonal,
            problem: ProblemSummary(
                id: "clear-the-gutters",
                title: "Clear the gutters",
                category: "Exterior",
                priceRange: "$120–190"
            )
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
        RailBand.allCases.compactMap { band in
            let cards = Self.entries.filter { $0.room == room && $0.band == band }.map(\.problem)
            guard !cards.isEmpty else { return nil }
            return ProblemRail(id: "\(room.rawValue)-\(band.rawValue)", heading: band.heading(for: room), cards: cards)
        }
    }

    func symptoms(for problem: ProblemSummary) async throws -> [SymptomOption] {
        problem.id == Self.drippingTap.id ? Self.drippingTapSymptoms : Self.escapeHatchOnly
    }
}
#endif
