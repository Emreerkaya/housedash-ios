import Features

struct UnavailableProblemCatalogue: ProblemCatalogue {
    func rails(for room: HDRoom) async throws -> [ProblemRail] {
        throw ProblemCatalogueError.notImplemented
    }

    func symptoms(for problem: ProblemSummary) async throws -> [SymptomOption] {
        throw ProblemCatalogueError.notImplemented
    }
}
