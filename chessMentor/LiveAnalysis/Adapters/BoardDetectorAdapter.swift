import CoreMedia
import CoreImage
import UIKit
import OSLog

struct BoardDetectorAdapter: BoardDetector {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                                    category: "LiveBoardDetector")

    // Services
    private let cropper: BoardCropper
    private let roboflow: RoboflowClient
    private let fenBuilder = FenBuilder()
    private let validator = FENValidator()
    private let filter: PieceFilter

    init(roboflowApiKey: String,
         pieceModelId: String = "chessbot-v2/1",
         boardModelId: String = "chessboard-detection-x5kxd/1") {

        self.roboflow = RoboflowClient(apiKey: roboflowApiKey,
                                       modelId: pieceModelId,
                                       confidence: 0.30,
                                       overlap: 0.50)

        self.cropper = BoardCropper(apiKey: roboflowApiKey,
                                    boardModelId: boardModelId,
                                    confidence: 0.25,
                                    overlap: 0.20,
                                    maxLongSide: 1280,
                                    padFrac: 0.03,
                                    enforceSquare: true)

        self.filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
    }

    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard? {
        guard let uiImage = UIImage(pixelBuffer: pixelBuffer) else { return nil }

        // 1) Crop board (internally does RF board-detect)
        let cropped = try cropper.crop(uiImage)  // 800x800

        // 2) Detect pieces (Roboflow) — bridge async -> sync
        let raw = try awaitDetectPieces(on: cropped)
        if raw.isEmpty { return nil }

        // 3) Filter + build FEN
        let preds = filter.apply(raw, imageSize: cropped.size)
        let fen = fenBuilder.fen(from: preds, imageSize: cropped.size)

        let check = validator.isLikelyValid(fen)
        guard check.ok else {
            Self.log.error("Live FEN invalid: \(check.reason ?? "Unknown")")
            return nil
        }
        return DetectedBoard(fen: fen, cropped: cropped)
    }

    // MARK: - Helpers

    private func awaitDetectPieces(on image: UIImage) throws -> [Prediction] {
        var out: Result<[Prediction], Error>!
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                let preds = try await roboflow.detect(on: image)
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

// Convert CVPixelBuffer -> UIImage
private extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let ctx = CIContext(options: nil)
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return nil }
        self.init(cgImage: cg)
    }
}
