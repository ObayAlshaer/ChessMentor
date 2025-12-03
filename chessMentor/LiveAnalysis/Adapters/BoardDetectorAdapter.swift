import CoreMedia
import CoreImage
import UIKit
import OSLog

/// Adapter responsible for orchestrating the end-to-end chessboard detection process:
/// 1. Crop the board from the input image
/// 2. Detect individual pieces using a Roboflow model
/// 3. Filter noisy predictions
/// 4. Convert predictions to FEN
/// 5. Validate the resulting chess position
///
/// Implements the `BoardDetector` protocol so this can be swapped in production,
/// testing, or mocked environments. :contentReference[oaicite:1]{index=1}
struct BoardDetectorAdapter: BoardDetector {

    /// Logger instance used for debugging runtime board detection events. :contentReference[oaicite:2]{index=2}
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
        category: "LiveBoardDetector"
    )

    /// Crops the original image to an isolated chessboard region based on ML detection. :contentReference[oaicite:3]{index=3}
    private let cropper: BoardCropper

    /// Roboflow client used for piece-level object detection on an image. :contentReference[oaicite:4]{index=4}
    private let roboflow: RoboflowClient

    /// Builds FEN strings from filtered piece predictions. :contentReference[oaicite:5]{index=5}
    private let fenBuilder = FenBuilder()

    /// Performs structural validity checks on generated FEN (e.g., both kings exist). :contentReference[oaicite:6]{index=6}
    private let validator = FENValidator()

    /// Applies heuristics to remove low-confidence or invalid piece detections. :contentReference[oaicite:7]{index=7}
    private let filter: PieceFilter

    /// Initializes Roboflow clients for both piece detection and board cropping.
    /// Uses provided API key and model identifiers, and applies predefined confidence,
    /// overlap, and sizing configuration values for consistent detection performance. :contentReference[oaicite:8]{index=8}
    init(
        roboflowApiKey: String,
        pieceModelId: String = "chessbot-v2/1",
        boardModelId: String = "chessboard-detection-x5kxd/1"
    ) {

        // ML model for detecting individual chess pieces within a cropped board image
        self.roboflow = RoboflowClient(
            apiKey: roboflowApiKey,
            modelId: pieceModelId,
            confidence: 0.30,
            overlap: 0.50
        )

        // ML model for identifying the chessboard region to crop from source image
        self.cropper = BoardCropper(
            apiKey: roboflowApiKey,
            boardModelId: boardModelId,
            confidence: 0.25,
            overlap: 0.20,
            maxLongSide: 1280,
            padFrac: 0.03,
            enforceSquare: true
        )

        // Heuristic post-processing to clean noisy ML detections
        self.filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
    }

    /// Primary detection pipeline.
    ///
    /// - Converts a CVPixelBuffer (camera frame) to UIImage
    /// - Crops the board region from the source
    /// - Detects raw piece predictions using ML
    /// - Filters predictions and constructs a candidate FEN string
    /// - Validates the FEN; returns `nil` for unlikely/invalid positions
    ///
    /// Throws on Roboflow network/processing errors. :contentReference[oaicite:9]{index=9}
    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard? {
        guard let uiImage = UIImage(pixelBuffer: pixelBuffer) else { return nil }

        // 1) Detect and crop the chessboard, keeping track of scaling so we can map
        //    predictions back into original image coordinates. :contentReference[oaicite:10]{index=10}
        let r = try cropper.cropWithRect(uiImage) // returns 800x800 + cropRect + sourceSize

        // 2) Detect raw predictions of chess pieces on the cropped 800×800 image. :contentReference[oaicite:11]{index=11}
        let raw = try awaitDetectPieces(on: r.cropped)
        if raw.isEmpty { return nil }

        // 3) Clean up detections and build a FEN representation. :contentReference[oaicite:12]{index=12}
        let preds = filter.apply(raw, imageSize: r.cropped.size)
        let fen = fenBuilder.fen(from: preds, imageSize: r.cropped.size)

        // Validate board structure (e.g., king count, square occupancy sanity). :contentReference[oaicite:13]{index=13}
        let check = validator.isLikelyValid(fen)
        guard check.ok else { return nil }

        // Construct object containing final FEN string and metadata about crop mapping. :contentReference[oaicite:14]{index=14}
        return DetectedBoard(
            fen: fen,
            cropped: r.cropped,
            cropRectInSource: r.rectInSource,
            sourcePixelSize: r.sourceSize
        )
    }

    /// Executes Roboflow piece detection using an async API, but exposes a synchronous
    /// interface by blocking with a semaphore. Useful when caller cannot be async.
    ///
    /// Wraps `roboflow.detect(on:)` using `Task` and bridging back to synchronous code. :contentReference[oaicite:15]{index=15}
    private func awaitDetectPieces(on image: UIImage) throws -> [Prediction] {
        var out: Result<[Prediction], Error>!
        let sem = DispatchSemaphore(value: 0)

        // Launch asynchronous detection task, then block until completion. :contentReference[oaicite:16]{index=16}
        Task {
            do { out = .success(try await roboflow.detect(on: image)) }
            catch { out = .failure(error) }
            sem.signal()
        }

        // Block thread until detection completes
        sem.wait()

        // Convert Result to thrown or returned value. :contentReference[oaicite:17]{index=17}
        switch out! {
        case .success(let p): return p
        case .failure(let e): throw e
        }
    }
}

// MARK: - CVPixelBuffer Conversion

/// Converts a camera pixel buffer (`CVPixelBuffer`) into a standard UIImage using Core Image.
/// Used to feed live camera frames into ML detection routines. :contentReference[oaicite:18]{index=18}
private extension UIImage {
    /// Initializes a UIImage from a CVPixelBuffer by rendering it through a Core Image context. :contentReference[oaicite:19]{index=19}
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let ctx = CIContext(options: nil)
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return nil }
        self.init(cgImage: cg)
    }
}

