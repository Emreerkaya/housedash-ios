public enum IntakeRoute: Hashable, Sendable {
    case pickProblem(ProblemSummary)
    case describeIt(SymptomOption)
    case somethingElse
    case photograph
}
