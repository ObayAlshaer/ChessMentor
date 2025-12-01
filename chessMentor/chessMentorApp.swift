import SwiftUI

@main
struct ChessMentorApp: App {
    private var isUITestMode: Bool {
        let p = ProcessInfo.processInfo
        return p.arguments.contains("UITEST_MODE") || p.environment["UITEST_MODE"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isUITestMode {
                    // 🚀 In UI tests: show ResultsView immediately with a known image.
                    ResultsView(camera: makeUITestCamera())
                        .accessibilityIdentifier("results_root")
                } else {
                    // Normal app flow
                    LoginView()
                }
            }
        }
    }

    // MARK: - Helpers

    private func makeUITestCamera() -> CameraModel {
        let cam = CameraModel()
        cam.isTaken = true
        // Use your asset "ui_test_board" if present; otherwise a tiny gray placeholder so it never crashes.
        if let img = UIImage(named: "ui_test_board") {
            cam.capturedPhoto = img
        } else {
            cam.capturedPhoto = UIImage.solidColor(.systemGray, size: CGSize(width: 4, height: 4))
        }
        return cam
    }
}

private extension UIImage {
    static func solidColor(_ color: UIColor, size: CGSize) -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
