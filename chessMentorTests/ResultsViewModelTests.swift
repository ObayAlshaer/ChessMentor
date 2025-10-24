import XCTest
import Combine
import UIKit
@testable import chessMentor

// MARK: - Mocks
class MockCropper: BoardCropper {
    let image: UIImage
    init(image: UIImage) {
        self.image = image
        // Use any dummy values; we override crop() so it won't hit the network.
        super.init(
            apiKey: "TEST",
            boardModelId: "chessboard-detection-x5kxd/1",
            confidence: 0.25,
            overlap: 0.20,
            maxLongSide: 1280,
            padFrac: 0.03,
            enforceSquare: true
        )
    }
    override func crop(_ image: UIImage) throws -> UIImage { self.image }
}

class MockRoboflow: RoboflowClient {
    let predictions: [Prediction]
    init(predictions: [Prediction]) { self.predictions = predictions; super.init(apiKey: "TEST") }
    override func detect(on image: UIImage) async throws -> [Prediction] { predictions }
}

class MockEngine: StockfishService {
    let move: BestMove
    init(move: BestMove) { self.move = move; super.init(session: .shared) }
    override func bestMove(for fen: String) async throws -> BestMove { move }
}

// MARK: - Helpers
private func blankImage(_ size: CGSize = .init(width: 800, height: 800)) -> UIImage {
    let r = UIGraphicsImageRenderer(size: size)
    return r.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}
private func center(_ file: Character, _ rank: Int) -> (CGFloat, CGFloat) {
    let S: CGFloat = 100
    let f = Int(file.asciiValue! - Character("a").asciiValue!)
    let rowTop = 8 - rank
    return ( (CGFloat(f) + 0.5) * S, (CGFloat(rowTop) + 0.5) * S )
}
private func piece(_ file: Character, _ rank: Int, _ cls: String, conf: CGFloat = 0.95) -> Prediction {
    let (x, y) = center(file, rank)
    return Prediction(x: x, y: y, width: 88, height: 88, class: cls, confidence: conf)
}

// MARK: - Tests
final class ResultsViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    @MainActor
    func testPipeline_Succeeds_AndProducesFenAndMove() {
        let board = blankImage()

        let preds: [Prediction] = [
            piece("e", 1, "w-king", conf: 0.40),
            piece("e", 8, "b-king", conf: 0.40),
            piece("e", 2, "w-pawn"),
            piece("d", 7, "b-pawn"),
            // off-board false positive (center outside trimmed interior)
            Prediction(x: -50, y: -50, width: 40, height: 40, class: "w-queen", confidence: 0.99)
        ]

        let vm = ResultsViewModel(
            cropper: MockCropper(image: board),
            roboflow: MockRoboflow(predictions: preds),
            engine: MockEngine(move: BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")),
            drawer: ArrowDrawer(),
            saveDebugImages: false
        )

        let exp = expectation(description: "pipeline done")

        vm.$phase
            .dropFirst()
            .receive(on: RunLoop.main) // ensure Combine delivery on main
            .sink { phase in
                switch phase {
                case .done(let result):
                    XCTAssertFalse(result.fen.isEmpty)
                    XCTAssertTrue(result.fen.contains("K"))
                    XCTAssertTrue(result.fen.contains("k"))
                    XCTAssertEqual(result.bestMove.best_move_uci, "e2e4")
                    XCTAssertNotNil(result.finalImage.pngData())
                    exp.fulfill()
                case .failed(let msg):
                    XCTFail("Pipeline failed: \(msg)")
                    exp.fulfill()
                default: break
                }
            }
            .store(in: &cancellables)

        vm.run(with: UIImage())
        wait(for: [exp], timeout: 3.0)
    }

    @MainActor
    func testPipeline_FailsOnInvalidFen_MissingBlackKing() {
        let board = blankImage()
        let preds = [ piece("e", 1, "w-king") ] // missing black king → invalid FEN

        let vm = ResultsViewModel(
            cropper: MockCropper(image: board),
            roboflow: MockRoboflow(predictions: preds),
            engine: MockEngine(move: BestMove(best_move_uci: "a2a3", best_move_san: "a3", evaluation: "0.0")),
            drawer: ArrowDrawer(),
            saveDebugImages: false
        )

        let exp = expectation(description: "pipeline failed")

        vm.$phase
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { phase in
                if case .failed(let msg) = phase {
                    XCTAssertTrue(msg.lowercased().contains("king"), "Expected missing king reason, got: \(msg)")
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        vm.run(with: UIImage())
        wait(for: [exp], timeout: 3.0)
    }
}
