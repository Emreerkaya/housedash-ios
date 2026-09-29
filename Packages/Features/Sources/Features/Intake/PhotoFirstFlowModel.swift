import Foundation
import Observation

public enum PhotoFirstRoute: Hashable, Sendable {
    case aFewDetails
}

@MainActor
@Observable
public final class PhotoFirstFlowModel {
    public var path: [PhotoFirstRoute] = []
    public var photos: [CapturedPhoto] = []
    public var descriptionText: String = ""
    public var rejection: DescriptionRejection?
    public var isSubmitting = false
    public private(set) var completedDescription: Description?

    private var captureCount = 0

    public init() {}

    public func capturePhoto() {
        guard photos.count < 4 else { return }
        captureCount += 1
        photos.append(
            CapturedPhoto(id: UUID().uuidString, timestampLabel: PhotoFirstFixtureClock.label(for: captureCount))
        )
    }

    public func reviewPhotos() {
        guard !photos.isEmpty, path.isEmpty else { return }
        path.append(.aFewDetails)
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
        descriptionText = ""
        photos = []
        captureCount = 0
    }
}

enum PhotoFirstFixtureClock {
    static func label(for index: Int) -> String {
        switch index {
        case 1: "9:38"
        case 2: "9:39"
        case 3: "9:41"
        default: "9:4\(2 + index - 4)"
        }
    }
}
