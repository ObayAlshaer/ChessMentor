import SwiftUI
import UIKit
import OSLog

private let vmLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                           category: "Analysis")

@MainActor
final class ResultsViewModel: ObservableObject {
    
    enum Phase {
        case idle
        case cropping
        case detecting
        case generatingFEN
        case queryingEngine
        case drawingArrow
        case done(AnalysisResult)
        case failed(String)
    }

    @Published var phase: Phase = .idle

    // Services
    private let cropper: BoardCropper
    private let roboflow: RoboflowClient
    private let fenBuilder = FenBuilder()
    private let engine: StockfishService        // ← no default here
    private let drawer: ArrowDrawer 
    private let saveDebugImages: Bool           // ← no default here


    /// Tune confidence/overlap here if you want (0.25–0.35 is a good start for confidence)
    init(roboflowApiKey: String,
         modelId: String = "chessbot-v2/1",
         confidence: Double = 0.30,
         overlap: Double = 0.50) {
        self.roboflow = RoboflowClient(apiKey: roboflowApiKey,
                                       modelId: modelId,
                                       confidence: confidence,
                                       overlap: overlap)
        // 👇 new: board detector cropper (tweak thresholds if you like)
        self.cropper = BoardCropper(apiKey: roboflowApiKey,
                                    boardModelId: "chessboard-detection-x5kxd/1",
                                    confidence: 0.25,
                                    overlap: 0.20,
                                    maxLongSide: 1280,
                                    padFrac: 0.03,
                                    enforceSquare: true)
        self.engine = StockfishService()        // ← assign here
        self.drawer = ArrowDrawer()             // ← assign here
        self.saveDebugImages = true             // ← assign here
    }
    #if DEBUG
    /// Testing initializer (DI for mocks)
    init(cropper: BoardCropper,
         roboflow: RoboflowClient,
         engine: StockfishService,
         drawer: ArrowDrawer,
         saveDebugImages: Bool = false) {

        self.cropper = cropper
        self.roboflow = roboflow
        self.engine  = engine
        self.drawer  = drawer
        self.saveDebugImages = saveDebugImages
    }
    #endif


    func run(with image: UIImage) {
        Task {
            do {
                vmLog.info("Analysis start")

                // 1) Crop
                phase = .cropping
                let cropped = try cropper.crop(image)
                PhotoSaver.saveToLibrary(cropped) // save exact payload we send to Roboflow
                vmLog.info("Saved cropped board to Photos.")

                // 2) Detect
                phase = .detecting
                let raw = try await roboflow.detect(on: cropped)
                vmLog.info("Raw detections: \(raw.count, privacy: .public)")

                // 🔎 NEW: filter out off-board / tiny / huge / low-conf boxes
                let filter = PieceFilter(
                    minConfidence: 0.30,
                    minConfidenceKing: 0.22,
                    edgeTrimSquares: 0.12,    // tighten to 0.20 if side UI still leaks in
                    minSizeFrac: 0.35,
                    maxSizeFrac: 1.60
                )
                let preds = filter.apply(raw, imageSize: cropped.size)
                vmLog.info("Filtered detections: \(preds.count, privacy: .public)")

                // (optional) save both previews to Photos to compare
                if let rawPreview = drawDetectionPreview(on: cropped, predictions: raw) {
                    PhotoSaver.saveToLibrary(rawPreview)   // "raw"
                }
                if let filteredPreview = drawDetectionPreview(on: cropped, predictions: preds) {
                    PhotoSaver.saveToLibrary(filteredPreview) // "filtered"
                }

                // class breakdown (of FILTERED)
                let grouped = Dictionary(grouping: preds, by: { $0.class })
                    .map { "\($0.key): \($0.value.count)" }
                    .sorted()
                vmLog.info("Class breakdown (filtered) → \(grouped.joined(separator: ", "), privacy: .public)")


                // 3) FEN
                phase = .generatingFEN
                let fen = fenBuilder.fen(from: preds, imageSize: cropped.size)
                vmLog.debug("FEN \(fen, privacy: .public)")

                // quick validity check (board must contain both kings)
                let check = FENValidator().isLikelyValid(fen)
                guard check.ok else {
                    vmLog.error("Invalid FEN: \(check.reason ?? "Unknown")")
                    phase = .failed("""
                    Board detection looks incomplete (\(check.reason ?? "invalid FEN")).
                    Try a clearer photo with the full board visible.
                    """)
                    return
                }

                // 4) Engine
                phase = .queryingEngine
                let best = try await engine.bestMove(for: fen)
                vmLog.info("Engine OK: UCI \(best.best_move_uci, privacy: .public) / SAN \(best.best_move_san, privacy: .public)")

                // 5) Arrow
                phase = .drawingArrow
                let final = drawer.draw(on: cropped, uci: best.best_move_uci)

                // Optional: save final image w/ arrow
                // PhotoSaver.saveToLibrary(final)

                // 6) Done
                let overlays = drawDetections(on: cropped, predictions: preds) // optional overlay image
                phase = .done(.init(cropped: cropped,
                                    overlays: overlays,
                                    fen: fen,
                                    bestMove: best,
                                    finalImage: final))
                vmLog.info("Analysis done")
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                vmLog.error("Analysis failed: \(msg, privacy: .public)")
                phase = .failed(msg)
            }
        }
    }

    // MARK: - Helpers

    /// Simple boxes-only overlay (used inside UI if you want to show it)
    private func drawDetections(on image: UIImage, predictions: [Prediction]) -> UIImage? {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            let cg = ctx.cgContext
            cg.setLineWidth(2)
            cg.setStrokeColor(UIColor.systemGreen.cgColor)
            for p in predictions {
                let rect = CGRect(x: p.x - p.width/2,
                                  y: p.y - p.height/2,
                                  width: p.width, height: p.height)
                cg.stroke(rect)
            }
        }
    }

    /// DEBUG preview: grid + boxes + labels (+ confidence)
    private func drawDetectionPreview(on image: UIImage, predictions: [Prediction]) -> UIImage? {
        let size = image.size
        let SQUARE = size.width / 8
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            let cg = ctx.cgContext

            // 8×8 grid
            cg.setLineWidth(1)
            cg.setStrokeColor(UIColor.systemGray.withAlphaComponent(0.6).cgColor)
            for i in 1..<8 {
                let x = CGFloat(i) * SQUARE
                let y = CGFloat(i) * SQUARE
                cg.move(to: CGPoint(x: x, y: 0));              cg.addLine(to: CGPoint(x: x, y: size.height))
                cg.move(to: CGPoint(x: 0, y: y));              cg.addLine(to: CGPoint(x: size.width, y: y))
            }
            cg.strokePath()

            // boxes
            cg.setLineWidth(2)
            cg.setStrokeColor(UIColor.systemGreen.cgColor)

            for p in predictions {
                let rect = CGRect(x: p.x - p.width/2,
                                  y: p.y - p.height/2,
                                  width: p.width, height: p.height)
                cg.stroke(rect)

                // label
                let label: String
                if let c = p.confidence {
                    label = "\(p.class)  \(String(format: "%.2f", Double(c)))"
                } else {
                    label = p.class
                }

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.65)
                ]
                let ns = label as NSString
                let sz = ns.size(withAttributes: attrs)
                let labelRect = CGRect(x: rect.minX,
                                       y: max(0, rect.minY - sz.height - 2),
                                       width: sz.width, height: sz.height)
                ns.draw(in: labelRect, withAttributes: attrs)
            }
        }
    }
}

// MARK: - AnalysisResult (defined in Models.swift)
