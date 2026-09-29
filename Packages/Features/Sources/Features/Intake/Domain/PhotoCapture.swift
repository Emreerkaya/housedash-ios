import Foundation

public protocol PhotoCapture: Sendable {
    var isAvailable: Bool { get }

    func capture(sequence: Int) -> CapturedPhoto?
}

public struct UnavailableCamera: PhotoCapture {
    public init() {}

    public var isAvailable: Bool { false }

    public func capture(sequence: Int) -> CapturedPhoto? { nil }
}
