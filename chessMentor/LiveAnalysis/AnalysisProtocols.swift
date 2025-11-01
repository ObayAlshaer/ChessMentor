import CoreMedia
import UIKit

public struct DetectedBoard: Equatable {
    public let fen: String
    public let cropped: UIImage              // 800x800
    public let cropRectInSource: CGRect      // in source image coords
    public let sourcePixelSize: CGSize       // source image size used by cropper
    public init(fen: String, cropped: UIImage, cropRectInSource: CGRect, sourcePixelSize: CGSize) {
        self.fen = fen
        self.cropped = cropped
        self.cropRectInSource = cropRectInSource
        self.sourcePixelSize = sourcePixelSize
    }
}

public struct EngineResult: Equatable {
    public let uci: String
    public let san: String
    public let evaluation: Double?
    public let pv: [String]?
    public init(uci: String, san: String, evaluation: Double?, pv: [String]?) {
        self.uci = uci; self.san = san; self.evaluation = evaluation; self.pv = pv
    }
}

public protocol BoardDetector {
    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard?
}

public protocol BestMoveProvider {
    func bestMove(for fen: String) async throws -> EngineResult
}

/// Data needed to draw the arrow on top of the live preview.
public struct LiveArrow {
    public let sourceSize: CGSize           // full camera frame size used by preview
    public let cropRect: CGRect             // where the board lives in that frame
    public let boardSize: CGSize            // cropped board size (usually 800x800)
    public let p1Cropped: CGPoint           // arrow start in cropped coords
    public let p2Cropped: CGPoint           // arrow end in cropped coords
}
