import DesignSystem
import Foundation
import Observation

public struct IntakeSubmission: Sendable, Equatable {
    public let description: Description
    public let problem: ProblemSummary?
    public let location: Location
    public let photos: [CapturedPhoto]

    public init(description: Description, problem: ProblemSummary?, location: Location, photos: [CapturedPhoto]) {
        self.description = description
        self.problem = problem
        self.location = location
        self.photos = photos
    }
}

enum DescribedRoute: Equatable {
    case symptom(ProblemSummary, SymptomOption)
    case ownWords

    var problem: ProblemSummary? {
        switch self {
        case .symptom(let problem, _): problem
        case .ownWords: nil
        }
    }
}

@MainActor
@Observable
public final class IntakeFlowModel {
    public static let photoLimit = 3
    public static let descriptionFieldLabel = "What is it doing?"
    public static let locationFieldLabel = "Where"
    public static let nothingIsPickedYet = "Pick what it is doing first."
    public static let theProblemThisOptionBelongsToIsGone =
        "That option belongs to a problem that is no longer picked, so go back and choose the problem again."

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

    private var describedRoute: DescribedRoute?
    private var captureCount = 0
    private let catalogue: ProblemCatalogue
    private let camera: PhotoCapture

    public private(set) var cameraPermission: CameraPermission

    public init(catalogue: ProblemCatalogue, camera: PhotoCapture = UnavailableCamera()) {
        self.catalogue = catalogue
        self.camera = camera
        self.cameraPermission = camera.permission
    }

    public var isCameraAvailable: Bool { camera.isAvailable }

    public func requestCameraPermissionIfNeeded() async {
        guard cameraPermission == .notDetermined else { return }
        cameraPermission = await camera.requestPermission()
    }

    public var canConfirmSymptom: Bool {
        guard let symptom = selectedSymptom else { return false }
        return route(for: symptom) != nil
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
        guard let symptom = selectedSymptom else {
            announcement = Self.nothingIsPickedYet
            return
        }
        guard let route = route(for: symptom) else {
            announcement = Self.theProblemThisOptionBelongsToIsGone
            return
        }
        rejection = nil
        if route != describedRoute {
            descriptionText = ""
            locationText = ""
            photos = []
            captureCount = 0
            describedRoute = route
        }
        switch route {
        case .ownWords:
            path.append(.somethingElse)
        case .symptom(_, let symptom):
            path.append(.describeIt(symptom))
        }
    }

    private func route(for symptom: SymptomOption) -> DescribedRoute? {
        switch symptom.kind {
        case .ownWords:
            return .ownWords
        case .symptom:
            guard let problem = selectedProblem else { return nil }
            return .symptom(problem, symptom)
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
        guard cameraPermission != .notDetermined else {
            Task { await requestCameraPermissionIfNeeded() }
            return
        }
        guard let photo = camera.capture(sequence: captureCount + 1) else { return }
        captureCount += 1
        photos.append(photo)
    }

    public func adoptLibraryPhoto(identifier: String) {
        guard photos.count < Self.photoLimit else { return }
        guard let photo = camera.adopt(libraryIdentifier: identifier, sequence: captureCount + 1) else { return }
        captureCount += 1
        photos.append(photo)
    }

    public func submit() {
        rejection = nil
        guard canSubmit else { return }
        let typedLocation = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        let refusals = [
            (Self.descriptionFieldLabel, DescriptionFilter.signals(in: descriptionText)),
            (Self.locationFieldLabel, DescriptionFilter.signals(in: typedLocation))
        ].filter { !$0.1.isEmpty }
        guard refusals.isEmpty else {
            let rejection = DescriptionRejection(
                signals: ContactSignalKind.allCases.filter { kind in
                    refusals.contains { $0.1.contains(kind) }
                },
                fieldLabels: refusals.map(\.0)
            )
            self.rejection = rejection
            announcement = rejection.summary
            return
        }
        guard
            case .success(let description) = Description.of(descriptionText),
            case .success(let location) = Location.of(typedLocation)
        else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        completedSubmission = IntakeSubmission(
            description: description,
            problem: describedRoute?.problem,
            location: location,
            photos: photos
        )
        announcement = "Case ready"
        path = []
    }

    public func acknowledgeCompletion() {
        completedSubmission = nil
        announcement = nil
        selectedProblem = nil
        selectedSymptom = nil
        describedRoute = nil
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
