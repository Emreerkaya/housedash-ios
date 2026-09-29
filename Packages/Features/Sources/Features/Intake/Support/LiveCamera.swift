import AVFoundation
import Foundation

public final class LiveCamera: NSObject, PhotoCapture, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.housedash.livecamera.session")
    private let stateLock = NSLock()
    private var lastFrameAt: Date?
    private var didConfigure = false

    public override init() {
        super.init()
        configureIfPossible()
    }

    public var isAvailable: Bool {
        guard AVCaptureDevice.default(for: .video) != nil, permission == .authorized else { return false }
        stateLock.lock()
        defer { stateLock.unlock() }
        return didConfigure
    }

    public var permission: CameraPermission {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .authorized
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    public func requestPermission() async -> CameraPermission {
        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
        if granted { configureIfPossible() }
        return granted ? .authorized : .denied
    }

    public func capture(sequence: Int) -> CapturedPhoto? {
        guard isAvailable else { return nil }
        stateLock.lock()
        let frameAt = lastFrameAt
        stateLock.unlock()
        guard let frameAt, Date().timeIntervalSince(frameAt) < 2 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return CapturedPhoto(id: UUID().uuidString, timestampLabel: formatter.string(from: frameAt))
    }

    private func configureIfPossible() {
        guard permission == .authorized, let device = AVCaptureDevice.default(for: .video) else { return }
        queue.async { [weak self] in
            guard let self, self.session.inputs.isEmpty else { return }
            guard let input = try? AVCaptureDeviceInput(device: device) else { return }
            self.session.beginConfiguration()
            if self.session.canAddInput(input) { self.session.addInput(input) }
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.queue)
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.session.startRunning()
            self.stateLock.lock()
            self.didConfigure = true
            self.stateLock.unlock()
        }
    }
}

extension LiveCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        stateLock.lock()
        lastFrameAt = Date()
        stateLock.unlock()
    }
}
