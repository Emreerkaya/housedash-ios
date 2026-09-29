#if DEBUG
import Features
import Foundation

struct FixtureCamera: PhotoCapture {
    private static let cannedTimestamps = ["11:24", "11:31", "11:39", "11:47"]

    var isAvailable: Bool { true }

    func capture(sequence: Int) -> CapturedPhoto? {
        let index = max(0, min(sequence - 1, Self.cannedTimestamps.count - 1))
        return CapturedPhoto(id: UUID().uuidString, timestampLabel: Self.cannedTimestamps[index])
    }
}
#endif
