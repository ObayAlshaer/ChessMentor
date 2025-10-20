import CoreGraphics
import UIKit
import OSLog

private let filtLog = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
    category: "PieceFilter"
)

/// Filters raw Roboflow detections so only plausible on-board pieces remain.
struct PieceFilter {
    /// Minimum confidence for non-king pieces
    var minConfidence: CGFloat = 0.30
    /// Minimum confidence for kings (slightly relaxed; kings are critical)
    var minConfidenceKing: CGFloat = 0.22

    /// Trim this many squares from each edge when defining the board interior.
    /// e.g. 0.15 → keep centers inside [0.15..7.85] on both axes.
    var edgeTrimSquares: CGFloat = 0.15

    /// Allowed size range relative to one square (width/height in [min..max]).
    var minSizeFrac: CGFloat = 0.35
    var maxSizeFrac: CGFloat = 1.60

    func apply(_ preds: [Prediction], imageSize: CGSize) -> [Prediction] {
        let square = imageSize.width / 8.0
        let inset  = edgeTrimSquares * square
        let inner  = CGRect(x: inset, y: inset,
                            width: imageSize.width  - inset*2,
                            height: imageSize.height - inset*2)

        var kept: [Prediction] = []
        var dropped = 0

        for p in preds {
            let conf = p.confidence ?? 0
            let isKing = p.class.contains("-king")

            // 1) confidence
            if conf < (isKing ? minConfidenceKing : minConfidence) { dropped += 1; continue }

            // 2) center must be inside trimmed board area
            let center = CGPoint(x: p.x, y: p.y)
            if !inner.contains(center) { dropped += 1; continue }

            // 3) piece must be roughly one-square sized
            let wf = p.width  / square
            let hf = p.height / square
            let mn = min(wf, hf), mx = max(wf, hf)
            if mn < minSizeFrac || mx > maxSizeFrac { dropped += 1; continue }

            kept.append(p)
        }

        filtLog.info("Filter: kept \(kept.count, privacy: .public) / \(preds.count, privacy: .public) (dropped \(dropped, privacy: .public))")
        return kept
    }
}
