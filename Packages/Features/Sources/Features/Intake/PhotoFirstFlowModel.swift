import Foundation
import Observation

public enum PhotoFirstRoute: Hashable, Sendable {
    case aFewDetails
}

@MainActor
@Observable
public final class PhotoFirstFlowModel {
    public static let photoLimit = 4

    public var path: [PhotoFirstRoute] = []
    public var photos: [CapturedPhoto] = []
    public var descriptionText: String = ""
    public var rejection: DescriptionRejection?
    public var isSubmitting = false
    public private(set) var completedSubmission: IntakeSubmission?
    public private(set) var announcement: String?

    private var captureCount = 0
    private let camera: PhotoCapture

    public init(camera: PhotoCapture = UnavailableCamera()) {
        self.camera = camera
    }

    public var isCameraAvailable: Bool { camera.isAvailable }

    public var canSubmit: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func capturePhoto() {
        guard photos.count < Self.photoLimit else { return }
        guard let photo = camera.capture(sequence: captureCount + 1) else { return }
        captureCount += 1
        photos.append(photo)
    }

    public func reviewPhotos() {
        guard !photos.isEmpty, path.isEmpty else { return }
        path.append(.aFewDetails)
    }

    public func goBack() {
        rejection = nil
        guard !path.isEmpty else { return }
        path.removeLast()
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
                problem: nil,
                location: "",
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
        descriptionText = ""
        photos = []
        captureCount = 0
    }

    public func acknowledgeAnnouncement() {
        announcement = nil
    }
}
