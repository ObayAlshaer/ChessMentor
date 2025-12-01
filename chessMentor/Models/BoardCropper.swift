import Foundation
import UIKit
import OSLog

private let cropLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                             category: "BoardCropperRF")

/// Crops the board using a Roboflow board-detection model (no Vision, no warp).
class BoardCropper {

    enum CropError: LocalizedError {
        case badImage
        case noDetection

        var errorDescription: String? {
            switch self {
            case .badImage:   return "Could not create an image from input."
            case .noDetection:return "No chessboard detected."
            }
        }
    }

    // MARK: config
    private let rf: RoboflowClient
    private let boardModelId: String
    private let outputSize = CGSize(width: 800, height: 800)
    private let maxLongSide: CGFloat
    private let padFrac: CGFloat
    private let enforceSquare: Bool

    init(apiKey: String,
         boardModelId: String = "chessboard-detection-x5kxd/1",
         confidence: Double = 0.25,
         overlap: Double = 0.20,
         maxLongSide: CGFloat = 1280,
         padFrac: CGFloat = 0.05,
         enforceSquare: Bool = true)
    {
        self.boardModelId = boardModelId
        self.maxLongSide = maxLongSide
        self.padFrac = padFrac
        self.enforceSquare = enforceSquare
        self.rf = RoboflowClient(apiKey: apiKey,
                                 modelId: boardModelId,
                                 confidence: confidence,
                                 overlap: overlap)
    }

    /// Original behavior (used by the photo flow)
    func crop(_ image: UIImage) throws -> UIImage {
        let r = try cropWithRect(image)
        return r.cropped
    }

    /// NEW: also returns the crop rect in the (possibly downscaled) source coordinates,
    /// plus the source size, so you can map back to the full camera frame.
    struct CropResult {
        let cropped: UIImage            // 800x800
        let rectInSource: CGRect        // where that 800x800 came from (in `src.size` coords)
        let sourceSize: CGSize          // size of `src` (after fixedOrientation+downscale)
    }

    func cropWithRect(_ image: UIImage) throws -> CropResult {
        // 1) Canonicalize (EXIF/rotation) and lightly downscale
        let src = image.fixedOrientationUp().downscaledIfNeeded(maxLongSide: maxLongSide)
        cropLog.info("RF crop start. input=\(Int(src.size.width))x\(Int(src.size.height)) model=\(self.boardModelId, privacy: .public)")

        // 2) Detect board on THIS SAME image (RF returns coords in this image space)
        let preds = try awaitDetect(on: src)
        guard let best = preds.max(by: { ($0.confidence ?? 0) < ($1.confidence ?? 0) }) else {
            cropLog.error("No detections from Roboflow.")
            throw CropError.noDetection
        }

        // 3) Build padded rect
        var rect = CGRect(x: best.x - best.width/2,
                          y: best.y - best.height/2,
                          width: best.width,
                          height: best.height)

        let padW = rect.width * padFrac
        let padH = rect.height * padFrac
        rect = rect.insetBy(dx: -padW, dy: -padH)

        // 4) Expand to square if requested (centered)
        if enforceSquare {
            let side = max(rect.width, rect.height)
            let cx = rect.midX, cy = rect.midY
            rect = CGRect(x: cx - side/2, y: cy - side/2, width: side, height: side)
        }

        // 5) Clamp
        rect = rect.clamped(to: CGRect(origin: .zero, size: src.size))
        guard rect.width > 2, rect.height > 2 else {
            cropLog.error("Crop rect too small after clamp: \(NSCoder.string(for: rect))")
            throw CropError.noDetection
        }

        // 6) Render crop and scale to 800×800
        let cropped = UIGraphicsImageRenderer(size: rect.size).image { _ in
            src.draw(in: CGRect(x: -rect.origin.x,
                                y: -rect.origin.y,
                                width: src.size.width,
                                height: src.size.height))
        }
        let scaled = cropped.resized(to: outputSize)

        cropLog.info("RF crop success. output=\(Int(scaled.size.width))x\(Int(scaled.size.height))")
        return CropResult(cropped: scaled, rectInSource: rect, sourceSize: src.size)
    }

    // MARK: - Private

    private func awaitDetect(on image: UIImage) throws -> [Prediction] {
        var out: Result<[Prediction], Error>!
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                let preds = try await rf.detect(on: image)
                out = .success(preds)
            } catch {
                out = .failure(error)
            }
            sem.signal()
        }
        sem.wait()
        switch out! {
        case .success(let p): return p
        case .failure(let e): throw e
        }
    }
}

// MARK: - Helpers (unchanged)

private extension CGRect {
    func clamped(to bounds: CGRect) -> CGRect {
        var r = self
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        r.size.width  = min(r.width,  bounds.width)
        r.size.height = min(r.height, bounds.height)
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        return r
    }
}

private extension UIImage {
    func fixedOrientationUp() -> UIImage {
        if imageOrientation == .up { return self }
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    func downscaledIfNeeded(maxLongSide: CGFloat) -> UIImage {
        let longSide = max(size.width, size.height)
        guard longSide > maxLongSide, longSide > 0 else { return self }
        let scale = maxLongSide / longSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return resized(to: newSize)
    }
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
