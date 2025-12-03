import Foundation
import CoreMedia
import QuartzCore
import UIKit

/// View model for live, on-camera chessboard analysis.
/// Handles frame throttling, board detection, engine queries, UI status updates,
/// and arrow overlay data computation. Must run on the main actor because it updates @Published properties. :contentReference[oaicite:1]{index=1}
@MainActor
final class LiveAnalysisViewModel: ObservableObject {

    /// Component responsible for detecting a chessboard and computing a FEN from camera frames. :contentReference[oaicite:2]{index=2}
    private let detector: BoardDetector

    /// Component that queries a chess engine to compute a best move given a FEN. :contentReference[oaicite:3]{index=3}
    private let engine: BestMoveProvider

    /// Latest detected FEN string from the camera, if any. :contentReference[oaicite:4]{index=4}
    @Published var currentFEN: String?

    /// UI-friendly representation of best move (SAN preferred, falling back to UCI). :contentReference[oaicite:5]{index=5}
    @Published var bestMoveDisplay: String?

    /// Engine evaluation formatted as a display string such as "+1.23". :contentReference[oaicite:6]{index=6}
    @Published var evaluationText: String?

    /// Human-readable processing state (e.g. "Searching", "Live", errors). :contentReference[oaicite:7]{index=7}
    @Published var status: String = "Searching for board…"

    /// Whether a frame is currently being analyzed to prevent overlapping detection tasks. :contentReference[oaicite:8]{index=8}
    @Published var isAnalyzing: Bool = false

    /// Arrow overlay data for drawing a move indicator on live preview. Nil when no arrow should be shown. :contentReference[oaicite:9]{index=9}
    @Published var liveArrow: LiveArrow?

    /// Timestamp of last processed frame to enforce throttling. :contentReference[oaicite:10]{index=10}
    private var lastAt: TimeInterval = 0

    /// Minimum time interval between frame analyses. Prevents overwhelming CPU/engine. :contentReference[oaicite:11]{index=11}
    private let minInterval: TimeInterval = 0.8

    /// Handle to the currently running analysis task (for cancellation). :contentReference[oaicite:12]{index=12}
    private var task: Task<Void, Never>?

    /// Initializes live analyzer with required board detection and engine components. :contentReference[oaicite:13]{index=13}
    init(detector: BoardDetector, engine: BestMoveProvider) {
        self.detector = detector
        self.engine = engine
    }

    /// Ingests a camera frame (pixel buffer), throttles processing, launches async board detection
    /// and best-move analysis, and publishes UI state updates. :contentReference[oaicite:14]{index=14}
    func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()

        // Throttle: skip if we are already analyzing or too soon since last frame. :contentReference[oaicite:15]{index=15}
        guard !isAnalyzing, (now - lastAt) >= minInterval else { return }
        lastAt = now
        isAnalyzing = true

        // Cancel previous task so we don't accumulate stale analysis loops. :contentReference[oaicite:16]{index=16}
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                // Attempt board detection from camera frame. :contentReference[oaicite:17]{index=17}
                guard let board = try detector.detect(from: pixelBuffer) else {
                    status = "No board found"
                    isAnalyzing = false
                    liveArrow = nil
                    return
                }

                currentFEN = board.fen
                status = "Analyzing…"

                // Request best move from engine given detected FEN. :contentReference[oaicite:18]{index=18}
                let res = try await engine.bestMove(for: board.fen)

                // Prefer SAN for display; fallback to UCI (empty SAN typically means no SAN available). :contentReference[oaicite:19]{index=19}
                bestMoveDisplay = res.san.isEmpty ? res.uci : res.san

                // Convert evaluation number to formatted text like "+0.45". :contentReference[oaicite:20]{index=20}
                evaluationText = res.evaluation.map { String(format: "%+.2f", $0) }

                status = "Live"

                // Compute arrow endpoints in cropped board coordinates (typically 800×800). :contentReference[oaicite:21]{index=21}
                if let (p1, p2) = centers(forUCI: res.uci, boardSize: board.cropped.size) {
                    liveArrow = LiveArrow(
                        sourceSize: board.sourcePixelSize,
                        cropRect: board.cropRectInSource,
                        boardSize: board.cropped.size,
                        p1Cropped: p1,
                        p2Cropped: p2
                    )
                } else {
                    liveArrow = nil
                }
            } catch {
                // Catch errors from detection or engine request and display message. :contentReference[oaicite:22]{index=22}
                status = "Error: \(error.localizedDescription)"
                liveArrow = nil
            }
            isAnalyzing = false
        }
    }

    /// Cancels ongoing analysis task, useful when view disappears or app stops camera. :contentReference[oaicite:23]{index=23}
    func cancel() {
        task?.cancel()
        task = nil
    }

    /// Converts a UCI move into a pair of geometric center points for arrow drawing.
    /// Each square is mapped to the center of an 8×8 grid within a given board size. :contentReference[oaicite:24]{index=24}
    private func centers(forUCI uci: String, boardSize: CGSize) -> (CGPoint, CGPoint)? {
        guard uci.count >= 4 else { return nil }

        // Source square (e.g. "e2") and destination square (e.g. "e4"). :contentReference[oaicite:25]{index=25}
        let src = String(uci.prefix(2))
        let dst = String(uci.dropFirst(2).prefix(2))

        /// Computes the visual center of a chess square (0–7 file, 1–8 rank). :contentReference[oaicite:26]{index=26}
        func center(of square: String, size: CGSize) -> CGPoint {
            let fileChar = square.first!
            let rankChar = square.last!

            // Convert file letter a–h to 0–7 integer. :contentReference[oaicite:27]{index=27}
            let file = Int(fileChar.asciiValue! - Character("a").asciiValue!) // 0..7

            // Convert rank character 1–8 directly to Int. :contentReference[oaicite:28]{index=28}
            let rank = Int(String(rankChar))!                                  // 1..8

            // Compute square size and translate to center XY point. :contentReference[oaicite:29]{index=29}
            let sq = size.width / 8.0
            let x = (CGFloat(file) + 0.5) * sq
            let y = (CGFloat(8 - rank) + 0.5) * sq
            return CGPoint(x: x, y: y)
        }

        return (center(of: src, size: boardSize),
                center(of: dst, size: boardSize))
    }
}

