import SwiftUI
import AVFoundation

/// SwiftUI wrapper for displaying a live video feed from an AVCaptureSession.
/// Uses UIKit's `AVCaptureVideoPreviewLayer` under the hood to render camera frames. :contentReference[oaicite:22]{index=22}
struct CameraPreviewView: UIViewRepresentable {

    /// The camera capture session whose video output will be displayed. :contentReference[oaicite:23]{index=23}
    let session: AVCaptureSession

    /// Creates the underlying UIKit view containing the video preview layer. :contentReference[oaicite:24]{index=24}
    func makeUIView(context: Context) -> PreviewUIView {
        let v = PreviewUIView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill // fill screen while preserving aspect ratio
        return v
    }

    /// Required by `UIViewRepresentable` but unused, as updates are handled by the session directly. :contentReference[oaicite:25]{index=25}
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    /// UIKit container view whose backing layer is an `AVCaptureVideoPreviewLayer`,
    /// allowing camera preview to be shown inside SwiftUI. :contentReference[oaicite:26]{index=26}
    final class PreviewUIView: UIView {

        /// Overrides default view layer to use an AVCapture video layer instead of CALayer. :contentReference[oaicite:27]{index=27}
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        /// Computed helper to safely cast the view's backing layer. :contentReference[oaicite:28]{index=28}
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

