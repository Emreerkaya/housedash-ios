import DesignSystem
import Foundation
import Observation

@MainActor
@Observable
public final class IntakeFlowModel {
    public let rooms: [HDRoom] = HDRoom.allCases
    public var selectedRoom: HDRoom = .kitchen
    public var rails: [ProblemRail] = []
    public var isLoadingRails = false

    public var path: [IntakeRoute] = []

    public var selectedProblem: ProblemSummary?
    public var symptoms: [SymptomOption] = []
    public var selectedSymptom: SymptomOption?

    public var descriptionText: String = ""
    public var locationText: String = ""
    public var photos: [CapturedPhoto] = []
    public var rejection: DescriptionRejection?
    public var isSubmitting = false
    public private(set) var completedDescription: Description?

    private var captureCount = 0
    private let catalogue: ProblemCatalogue

    public init(catalogue: ProblemCatalogue) {
        self.catalogue = catalogue
    }

    public func loadRails() async {
        isLoadingRails = true
        defer { isLoadingRails = false }
        rails = (try? await catalogue.rails(for: selectedRoom)) ?? []
    }

    public func selectRoom(_ room: HDRoom) async {
        guard room != selectedRoom else { return }
        selectedRoom = room
        await loadRails()
    }

    public func selectProblem(_ problem: ProblemSummary) async {
        selectedProblem = problem
        selectedSymptom = nil
        symptoms = (try? await catalogue.symptoms(for: problem)) ?? []
        path.append(.pickProblem(problem))
    }

    public func selectSymptomForReview(_ symptom: SymptomOption) {
        selectedSymptom = symptom
    }

    public func confirmSymptomSelection() {
        guard let symptom = selectedSymptom else { return }
        rejection = nil
        descriptionText = ""
        locationText = ""
        if symptom.isEscapeHatch {
            path.append(.somethingElse)
        } else {
            path.append(.describeIt(symptom))
        }
    }

    public func goBack() {
        rejection = nil
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func beginPhotoCapture() {
        path.append(.photograph)
    }

    public func finishPhotoCapture() {
        if path.last == .photograph {
            path.removeLast()
        }
    }

    public func capturePhoto() {
        guard photos.count < 3 else { return }
        captureCount += 1
        photos.append(CapturedPhoto(id: UUID().uuidString, timestampLabel: IntakeFixtureClock.label(for: captureCount)))
    }

    public func submit() {
        rejection = nil
        switch Description.of(descriptionText) {
        case .success(let description):
            isSubmitting = true
            defer { isSubmitting = false }
            completedDescription = description
            path = []
        case .failure(.rejected(let rejection)):
            self.rejection = rejection
        }
    }

    public func acknowledgeCompletion() {
        completedDescription = nil
        selectedProblem = nil
        selectedSymptom = nil
        symptoms = []
        descriptionText = ""
        locationText = ""
        photos = []
        captureCount = 0
    }
}

enum IntakeFixtureClock {
    static func label(for index: Int) -> String {
        switch index {
        case 1: "11:24"
        case 2: "11:31"
        default: "11:39"
        }
    }
}
