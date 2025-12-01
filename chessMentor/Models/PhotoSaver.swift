import UIKit
import Photos
import OSLog

private let photoLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                              category: "PhotoSave")

enum PhotoSaver {
    /// Saves `image` to Photos. Requests add-only permission if needed.
    static func saveToLibrary(_ image: UIImage) {
        let proceed: (PHAuthorizationStatus) -> Void = { status in
            guard status == .authorized || status == .limited else {
                photoLog.error("Photo save denied. Status=\(String(describing: status), privacy: .public)")
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    photoLog.info("Saved image to Photos.")
                } else {
                    photoLog.error("Save failed: \(error?.localizedDescription ?? "unknown error", privacy: .public)")
                }
            }
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                proceed(newStatus)
            }
        } else {
            proceed(status)
        }
    }
}
