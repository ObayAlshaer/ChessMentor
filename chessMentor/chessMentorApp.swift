import SwiftUI

/// Entry point for the Chess Mentor SwiftUI application, responsible for initializing the UI
/// and choosing the correct root view depending on whether the app is running in normal mode
/// or driven by UI tests. :contentReference[oaicite:1]{index=1}
@main
struct ChessMentorApp: App {

    /// Determines whether the app is currently running under a UI test scenario.
    /// Uses command-line arguments and environment variables to detect UITEST_MODE.
    /// When enabled, the app will bypass authentication and jump directly to a deterministic UI state. :contentReference[oaicite:2]{index=2}
    private var isUITestMode: Bool {
        let p = ProcessInfo.processInfo
        return p.arguments.contains("UITEST_MODE") || p.environment["UITEST_MODE"] == "1"
    }

    /// Defines the main scene of the app. Displays either:
    /// - `ResultsView` with a mocked camera model for UI testing
    /// - `LoginView` for normal runtime behavior
    /// Uses a `NavigationStack` to support navigation throughout the app. :contentReference[oaicite:3]{index=3}
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isUITestMode {
                    // In UI testing, immediately show a results screen with a known image
                    // so automated tests can run deterministically without interacting
                    // with hardware camera access. :contentReference[oaicite:4]{index=4}
                    ResultsView(camera: makeUITestCamera())
                        .accessibilityIdentifier("results_root")
                } else {
                    // Default runtime: start at the login screen. :contentReference[oaicite:5]{index=5}
                    LoginView()
                }
            }
        }
    }

    // MARK: - Helpers

    /// Creates a camera model suitable for UI tests.
    /// - Sets the camera state to "taken" so views that expect a captured image behave normally.
    /// - Attempts to load a known board test image if it exists in assets.
    /// - Falls back to generating a small gray image to prevent crashes during tests if the asset is missing. :contentReference[oaicite:6]{index=6}
    private func makeUITestCamera() -> CameraModel {
        let cam = CameraModel()
        cam.isTaken = true
        // Use your asset "ui_test_board" if present; otherwise a tiny gray placeholder so it never crashes. :contentReference[oaicite:7]{index=7}
        if let img = UIImage(named: "ui_test_board") {
            cam.capturedPhoto = img
        } else {
            cam.capturedPhoto = UIImage.solidColor(.systemGray, size: CGSize(width: 4, height: 4))
        }
        return cam
    }
}

/// Helper for generating a solid-color UIImage programmatically.
/// Used primarily for UI testing fallback images where an actual asset might not exist. :contentReference[oaicite:8]{index=8}
private extension UIImage {
    /// Creates a plain colored rectangle image of a given size.
    /// This avoids crashes when a placeholder image is required during automated tests. :contentReference[oaicite:9]{index=9}
    static func solidColor(_ color: UIColor, size: CGSize) -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

