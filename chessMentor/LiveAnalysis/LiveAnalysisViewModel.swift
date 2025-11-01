import Foundation
import CoreMedia
import QuartzCore
import UIKit

@MainActor
final class LiveAnalysisViewModel: ObservableObject {
    private let detector: BoardDetector
    private let engine: BestMoveProvider

    @Published var currentFEN: String?
    @Published var bestMoveDisplay: String?
    @Published var evaluationText: String?
    @Published var status: String = "Searching for board…"
    @Published var isAnalyzing: Bool = false

    // Overlay data for drawing on the live preview
    @Published var liveArrow: LiveArrow?

    private var lastAt: TimeInterval = 0
    private let minInterval: TimeInterval = 0.8
    private var task: Task<Void, Never>?

    init(detector: BoardDetector, engine: BestMoveProvider) {
        self.detector = detector
        self.engine = engine
    }

    func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        guard !isAnalyzing, (now - lastAt) >= minInterval else { return }
        lastAt = now
        isAnalyzing = true

        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                guard let board = try detector.detect(from: pixelBuffer) else {
                    status = "No board found"
                    isAnalyzing = false
                    liveArrow = nil
                    return
                }
                currentFEN = board.fen
                status = "Analyzing…"

                let res = try await engine.bestMove(for: board.fen)
                bestMoveDisplay = res.san.isEmpty ? res.uci : res.san
                evaluationText = res.evaluation.map { String(format: "%+.2f", $0) }
                status = "Live"

                // Compute arrow centers in CROPPED (800x800) coords
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
                status = "Error: \(error.localizedDescription)"
                liveArrow = nil
            }
            isAnalyzing = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    private func centers(forUCI uci: String, boardSize: CGSize) -> (CGPoint, CGPoint)? {
        guard uci.count >= 4 else { return nil }
        let src = String(uci.prefix(2))
        let dst = String(uci.dropFirst(2).prefix(2))

        func center(of square: String, size: CGSize) -> CGPoint {
            let fileChar = square.first!
            let rankChar = square.last!
            let file = Int(fileChar.asciiValue! - Character("a").asciiValue!) // 0..7
            let rank = Int(String(rankChar))!                                  // 1..8
            let sq = size.width / 8.0
            let x = (CGFloat(file) + 0.5) * sq
            let y = (CGFloat(8 - rank) + 0.5) * sq
            return CGPoint(x: x, y: y)
        }

        return (center(of: src, size: boardSize),
                center(of: dst, size: boardSize))
    }
}
