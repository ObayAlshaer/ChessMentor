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

    // Dynamic overlay (cropped board + arrow)
    @Published var overlayImage: UIImage?

    private var lastAt: TimeInterval = 0
    private let minInterval: TimeInterval = 0.8   // throttle; tune as needed
    private var task: Task<Void, Never>?

    private let drawer = ArrowDrawer()

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
                // 1) Detect board + FEN + get 800x800 cropped board image
                guard let board = try detector.detect(from: pixelBuffer) else {
                    status = "No board found"
                    isAnalyzing = false
                    return
                }
                currentFEN = board.fen
                status = "Analyzing…"

                // 2) Engine best move
                let res = try await engine.bestMove(for: board.fen)
                bestMoveDisplay = res.san.isEmpty ? res.uci : res.san
                evaluationText = res.evaluation.map { String(format: "%+.2f", $0) }
                status = "Live"

                // 3) Draw arrow overlay on the cropped board
                let withArrow = drawer.draw(on: board.cropped, uci: res.uci)
                overlayImage = withArrow
            } catch {
                status = "Error: \(error.localizedDescription)"
            }
            isAnalyzing = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
