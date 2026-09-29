@testable import Features

struct FakeCamera: PhotoCapture {
    var isAvailable: Bool = true

    func capture(sequence: Int) -> CapturedPhoto? {
        guard isAvailable else { return nil }
        return CapturedPhoto(id: "photo-\(sequence)", timestampLabel: "11:0\(sequence)")
    }
}
