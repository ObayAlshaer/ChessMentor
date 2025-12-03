import CoreMedia
import UIKit

/// Represents the output of a successful chessboard detection pipeline.
/// Contains FEN, a cropped board image, and information needed to map
/// cropped coordinates back to the original camera/source frame. :contentReference[oaicite:1]{index=1}
public struct DetectedBoard: Equatable {

    /// FEN string describing the detected chess position. :contentReference[oaicite:2]{index=2}
    public let fen: String

    /// Cropped 800×800 image of the board used for piece detection and visualization. :contentReference[oaicite:3]{index=3}
    public let cropped: UIImage              // 800x800

    /// Location of the cropped board region in the original camera frame (used for drawing overlays). :contentReference[oaicite:4]{index=4}
    public let cropRectInSource: CGRect      // in source image coords

    /// Full resolution of the source image from which the board was extracted. :contentReference[oaicite:5]{index=5}
    public let sourcePixelSize: CGSize       // source image size used by cropper

    /// Initializes a detected board result with mapping metadata for UI overlays and analysis. :contentReference[oaicite:6]{index=6}
    public init(
        fen: String,
        cropped: UIImage,
        cropRectInSource: CGRect,
        sourcePixelSize: CGSize
    ) {
        self.fen = fen
        self.cropped = cropped
        self.cropRectInSource = cropRectInSource
        self.sourcePixelSize = sourcePixelSize
    }
}

/// Represents the output of a chess engine evaluation request (Stockfish or similar).
/// Includes best move in both UCI and SAN formats plus optional evaluation score
/// and principal variation (PV). :contentReference[oaicite:7]{index=7}
public struct EngineResult: Equatable {

    /// Best move in UCI notation (e.g., "e2e4"). :contentReference[oaicite:8]{index=8}
    public let uci: String

    /// Best move in SAN notation (e.g., "Nf3"). :contentReference[oaicite:9]{index=9}
    public let san: String

    /// Numerical evaluation of the position from the engine (positive for white, negative for black). :contentReference[oaicite:10]{index=10}
    public let evaluation: Double?

    /// Optional principal variation (engine's suggested continuation sequence). :contentReference[oaicite:11]{index=11}
    public let pv: [String]?

    /// Initializes a result wrapper for engine output data. :contentReference[oaicite:12]{index=12}
    public init(
        uci: String,
        san: String,
        evaluation: Double?,
        pv: [String]?
    ) {
        self.uci = uci
        self.san = san
        self.evaluation = evaluation
        self.pv = pv
    }
}

/// Protocol defining a component capable of detecting chessboard positions
/// from camera pixel buffers. Returns optional `DetectedBoard` to allow
/// early exit when no valid board is found. :contentReference[oaicite:13]{index=13}
public protocol BoardDetector {
    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard?
}

/// Protocol defining a chess engine query service.
/// Consumes a FEN string and produces a best move result asynchronously. :contentReference[oaicite:14]{index=14}
public protocol BestMoveProvider {
    func bestMove(for fen: String) async throws -> EngineResult
}

/// Container for all data needed to draw a move arrow overlay on top of
/// a live camera preview. Includes mapping between cropped and full-frame
/// coordinates and endpoints of the arrow. :contentReference[oaicite:15]{index=15}
public struct LiveArrow {

    /// Full camera frame resolution being displayed. :contentReference[oaicite:16]{index=16}
    public let sourceSize: CGSize           // full camera frame size used by preview

    /// Rectangle where the detected board is located in the full camera frame. :contentReference[oaicite:17]{index=17}
    public let cropRect: CGRect             // where the board lives in that frame

    /// Pixel size of the cropped board image (typically a square like 800×800). :contentReference[oaicite:18]{index=18}
    public let boardSize: CGSize            // cropped board size (usually 800x800)

    /// Starting point of arrow (piece location) in cropped image coordinate system. :contentReference[oaicite:19]{index=19}
    public let p1Cropped: CGPoint           // arrow start in cropped coords

    /// Ending point of arrow (destination square) in cropped image coordinate system. :contentReference[oaicite:20]{index=20}
    public let p2Cropped: CGPoint           // arrow end in cropped coords
}

