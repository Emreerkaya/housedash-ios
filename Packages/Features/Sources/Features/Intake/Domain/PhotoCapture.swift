import Foundation

public enum CameraPermission: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
}

public protocol PhotoCapture: Sendable {
    var isAvailable: Bool { get }
    var permission: CameraPermission { get }

    func requestPermission() async -> CameraPermission
    func capture(sequence: Int) -> CapturedPhoto?
    func adopt(libraryIdentifier: String, sequence: Int) -> CapturedPhoto?
}

public extension PhotoCapture {
    var permission: CameraPermission { .authorized }

    func requestPermission() async -> CameraPermission { permission }

    func adopt(libraryIdentifier: String, sequence: Int) -> CapturedPhoto? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return CapturedPhoto(id: libraryIdentifier, timestampLabel: formatter.string(from: Date()))
    }
}

public struct UnavailableCamera: PhotoCapture {
    public init() {}

    public var isAvailable: Bool { false }

    public func capture(sequence: Int) -> CapturedPhoto? { nil }
}
