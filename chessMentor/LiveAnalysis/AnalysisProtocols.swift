import CoreMedia
import UIKit

public struct DetectedBoard: Equatable {
    public let fen: String
    public let cropped: UIImage   // 800x800 board image used for overlay
    public init(fen: String, cropped: UIImage) {
        self.fen = fen
        self.cropped = cropped
    }
}

public struct EngineResult: Equatable {
    public let uci: String        // needed for ArrowDrawer
    public let san: String        // nice to display
    public let evaluation: Double?
    public let pv: [String]?
    public init(uci: String, san: String, evaluation: Double?, pv: [String]?) {
        self.uci = uci
        self.san = san
        self.evaluation = evaluation
        self.pv = pv
    }
}

public protocol BoardDetector {
    /// Return (FEN + cropped board image) if detected; nil when no board/confidence too low.
    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard?
}

public protocol BestMoveProvider {
    /// Return best move (both UCI and SAN).
    func bestMove(for fen: String) async throws -> EngineResult
}
