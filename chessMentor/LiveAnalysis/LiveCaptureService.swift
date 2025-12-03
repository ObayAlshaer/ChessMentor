import AVFoundation
import CoreMedia

/// Handles camera capture setup and frame delivery using AVCaptureSession.
/// Produces BGRA pixel buffers via callback so analysis can run elsewhere. :contentReference[oaicite:44]{index=44}
final class LiveCaptureService: NSObject, ObservableObject {

    /// Shared capture session driving video input and output. :contentReference[oaicite:45]{index=45}
    let session = AVCaptureSession()

    /// Queue used for sample buffer processing to avoid blocking main UI thread. :contentReference[oaicite:46]{index=46}
    private let queue = DispatchQueue(label: "camera.frames.queue")

    /// Video data output responsible for delivering pixel buffers. :contentReference[oaicite:47]{index=47}
    private let videoOutput = AVCaptureVideoDataOutput()

    /// Callback invoked for each BGRA frame received from camera pipeline. :contentReference[oaicite:48]{index=48}
    var onFrame: ((CVPixelBuffer) -> Void)?

    /// Public entry point to start camera capture. Handles authorization logic. :contentReference[oaicite:49]{index=49}
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            // Ask user for camera permission, then configure session on approval. :contentReference[oaicite:50]{index=50}
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                guard ok else { return }
                self?.configureAndStart()
            }
        default:
            // No access: do nothing. Caller can show UI explaining permission issues. :contentReference[oaicite:51]{index=51}
            break
        }
    }

    /// Stops capture session if running. Safe to call regardless of state. :contentReference[oaicite:52]{index=52}
    func stop() {
        if session.isRunning { session.stopRunning() }
    }

    /// Configures capture inputs/outputs and starts session.
    /// Removes existing inputs, attaches back camera, sets output pixel format,
    /// and ensures portrait orientation for video stream. :contentReference[oaicite:53]{index=53}
    private func configureAndStart() {
        guard !session.isRunning else { return }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        // Input configuration: remove existing inputs and add default back camera if possible. :contentReference[oaicite:54]{index=54}
        session.inputs.forEach { session.removeInput($0) }
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { session.commitConfiguration(); return }
        session.addInput(input)

        // Output configuration: remove old output, set BGRA pixel format, attach delegate for frame delivery. :contentReference[oaicite:55]{index=55}
        if session.outputs.contains(videoOutput) { session.removeOutput(videoOutput) }
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(videoOutput) else { session.commitConfiguration(); return }
        session.addOutput(videoOutput)

        // Ensure portrait orientation on supported connections. :contentReference[oaicite:56]{index=56}
        if let c = videoOutput.connection(with: .video), c.isVideoOrientationSupported {
            c.videoOrientation = .portrait
        }

        session.commitConfiguration()
        session.startRunning()
    }
}

/// Receives video sample buffers and forwards their pixel buffers through `onFrame` callback. :contentReference[oaicite:57]{index=57}
extension LiveCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        /// Extract pixel buffer from CMSampleBuffer and deliver to callback if available. :contentReference[oaicite:58]{index=58}
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrame?(pb)
    }
}
