import DesignSystem
import Foundation
import Observation

public struct IntakeSubmission: Sendable, Equatable {
    public let description: Description
    public let problem: ProblemSummary?
    public let location: String
    public let photos: [CapturedPhoto]

    public init(description: Description, problem: ProblemSummary?, location: String, photos: [CapturedPhoto]) {
        self.description = description
        self.problem = problem
        self.location = location
        self.photos = photos
    }
}

@MainActor
@Observable
public final class IntakeFlowModel {
    public static let photoLimit = 3

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
    public private(set) var completedSubmission: IntakeSubmission?
    public private(set) var announcement: String?

    private var describedSymptom: SymptomOption?
    private var captureCount = 0
    private let catalogue: ProblemCatalogue
    private let camera: PhotoCapture

    public init(catalogue: ProblemCatalogue, camera: PhotoCapture = UnavailableCamera()) {
        self.catalogue = catalogue
        self.camera = camera
    }

    public var isCameraAvailable: Bool { camera.isAvailable }

    public var canConfirmSymptom: Bool {
        selectedSymptom != nil
    }

    public var canSubmit: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        if symptom != describedSymptom {
            descriptionText = ""
            locationText = ""
            describedSymptom = symptom
        }
        if symptom.isEscapeHatch {
            photos = []
            captureCount = 0
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
        guard photos.count < Self.photoLimit else { return }
        guard let photo = camera.capture(sequence: captureCount + 1) else { return }
        captureCount += 1
        photos.append(photo)
    }

    public func submit() {
        rejection = nil
        guard canSubmit else { return }
        switch Description.of(descriptionText) {
        case .success(let description):
            isSubmitting = true
            defer { isSubmitting = false }
            completedSubmission = IntakeSubmission(
                description: description,
                problem: describedSymptom?.isEscapeHatch == true ? nil : selectedProblem,
                location: locationText.trimmingCharacters(in: .whitespacesAndNewlines),
                photos: photos
            )
            announcement = "Case ready"
            path = []
        case .failure(.rejected(let rejection)):
            self.rejection = rejection
            announcement = rejection.summary
        }
    }

    public func acknowledgeCompletion() {
        completedSubmission = nil
        announcement = nil
        selectedProblem = nil
        selectedSymptom = nil
        describedSymptom = nil
        symptoms = []
        descriptionText = ""
        locationText = ""
        photos = []
        captureCount = 0
    }

    public func acknowledgeAnnouncement() {
        announcement = nil
    }
}
