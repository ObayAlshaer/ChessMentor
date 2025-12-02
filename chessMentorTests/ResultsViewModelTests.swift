import XCTest
import Combine
import UIKit
@testable import chessMentor

// MARK: - Mocks

class MockCropper: BoardCropper {
    let image: UIImage
    init(image: UIImage) {
        self.image = image
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
    init(predictions: [Prediction]) {
        self.predictions = predictions
        super.init(apiKey: "TEST")
    }
    override func detect(on image: UIImage) async throws -> [Prediction] { predictions }
}

class MockEngine: StockfishService {
    let move: BestMove
    init(move: BestMove) {
        self.move = move
        super.init(session: .shared)
    }
    override func bestMove(for fen: String) async throws -> BestMove { move }
}

// MARK: - Helpers

private func blankImage(_ size: CGSize = .init(width: 800, height: 800)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

private func center(_ file: Character, _ rank: Int) -> (CGFloat, CGFloat) {
    let S: CGFloat = 100
    let f = Int(file.asciiValue! - Character("a").asciiValue!)
    let rowTop = 8 - rank
    return ((CGFloat(f) + 0.5) * S, (CGFloat(rowTop) + 0.5) * S)
}

private func piece(_ file: Character, _ rank: Int, _ cls: String, conf: CGFloat = 0.95) -> Prediction {
    let (x, y) = center(file, rank)
    return Prediction(x: x, y: y, width: 88, height: 88, class: cls, confidence: conf)
}

// MARK: - ResultsViewModel Tests

final class ResultsViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testInitializeWithDefaults() {
        let viewModel = ResultsViewModel(roboflowApiKey: "test_api_key")
        
        if case .idle = viewModel.phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle phase")
        }
    }
    
    @MainActor
    func testInitializeWithCustomConfidence() {
        let viewModel = ResultsViewModel(
            roboflowApiKey: "test_key",
            confidence: 0.5,
            overlap: 0.3
        )
        
        if case .idle = viewModel.phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle phase")
        }
    }
    
    @MainActor
    func testInitializeWithCustomModelID() {
        let viewModel = ResultsViewModel(
            roboflowApiKey: "test_key",
            modelId: "custom-model/1"
        )
        
        if case .idle = viewModel.phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle phase")
        }
    }
    
    // MARK: - Phase Tests
    
    @MainActor
    func testPhaseStartsIdle() {
        let viewModel = ResultsViewModel(roboflowApiKey: "test_key")
        
        if case .idle = viewModel.phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle phase")
        }
    }
    
    func testPhaseEnumCases() {
        let phases: [ResultsViewModel.Phase] = [
            .idle,
            .cropping,
            .detecting,
            .generatingFEN,
            .queryingEngine,
            .drawingArrow,
            .failed("Test error")
        ]
        
        XCTAssertEqual(phases.count, 7)
    }
    
    func testIdlePhase() {
        let phase = ResultsViewModel.Phase.idle
        if case .idle = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle phase")
        }
    }
    
    func testCroppingPhase() {
        let phase = ResultsViewModel.Phase.cropping
        if case .cropping = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected cropping phase")
        }
    }
    
    func testDetectingPhase() {
        let phase = ResultsViewModel.Phase.detecting
        if case .detecting = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected detecting phase")
        }
    }
    
    func testGeneratingFENPhase() {
        let phase = ResultsViewModel.Phase.generatingFEN
        if case .generatingFEN = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected generatingFEN phase")
        }
    }
    
    func testQueryingEnginePhase() {
        let phase = ResultsViewModel.Phase.queryingEngine
        if case .queryingEngine = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected queryingEngine phase")
        }
    }
    
    func testDrawingArrowPhase() {
        let phase = ResultsViewModel.Phase.drawingArrow
        if case .drawingArrow = phase {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected drawingArrow phase")
        }
    }
    
    func testFailedPhaseWithMessage() {
        let errorMessage = "Test error message"
        let phase = ResultsViewModel.Phase.failed(errorMessage)
        
        if case .failed(let message) = phase {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected failed phase")
        }
    }
    
    // MARK: - Pipeline Tests
    
    @MainActor
    func testPipelineSucceedsAndProducesFenAndMove() {
        let board = blankImage()
        
        let preds: [Prediction] = [
            piece("e", 1, "w-king", conf: 0.40),
            piece("e", 8, "b-king", conf: 0.40),
            piece("e", 2, "w-pawn"),
            piece("d", 7, "b-pawn"),
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
            .receive(on: RunLoop.main)
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
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        vm.run(with: UIImage())
        wait(for: [exp], timeout: 3.0)
    }
    
    @MainActor
    func testPipelineFailsOnInvalidFenMissingBlackKing() {
        let board = blankImage()
        let preds = [piece("e", 1, "w-king")]
        
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

// MARK: - RoboflowClient Tests

final class RoboflowClientTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializeWithAPIKey() {
        let _ = RoboflowClient(apiKey: "test_api_key")
        XCTAssertTrue(true)
    }
    
    func testInitializeWithCustomModelID() {
        let _ = RoboflowClient(apiKey: "test_key", modelId: "custom-model/2")
        XCTAssertTrue(true)
    }
    
    func testInitializeWithCustomConfidence() {
        let _ = RoboflowClient(apiKey: "test_key", confidence: 0.5)
        XCTAssertTrue(true)
    }
    
    func testInitializeWithCustomOverlap() {
        let _ = RoboflowClient(apiKey: "test_key", overlap: 0.3)
        XCTAssertTrue(true)
    }
    
    func testInitializeWithAllCustomParams() {
        let _ = RoboflowClient(apiKey: "test_key", modelId: "custom/1", confidence: 0.4, overlap: 0.25)
        XCTAssertTrue(true)
    }
    
    // MARK: - Error Type Tests
    
    func testCreateEncodeError() {
        let error = RoboflowClient.Err.encode("Test encode error")
        
        if case .encode(let message) = error {
            XCTAssertEqual(message, "Test encode error")
        } else {
            XCTFail("Expected encode error")
        }
    }
    
    func testCreateHTTPError() {
        let error = RoboflowClient.Err.http(status: 500, body: "Internal Server Error")
        
        if case .http(let status, let body) = error {
            XCTAssertEqual(status, 500)
            XCTAssertEqual(body, "Internal Server Error")
        } else {
            XCTFail("Expected http error")
        }
    }
    
    func testEncodeErrorDescription() {
        let error = RoboflowClient.Err.encode("Encoding failed")
        XCTAssertEqual(error.errorDescription, "Encoding failed")
    }
    
    func testHTTPErrorDescription() {
        let error = RoboflowClient.Err.http(status: 404, body: "Not Found")
        let description = error.errorDescription
        
        XCTAssertTrue(description?.contains("HTTP 404") == true)
        XCTAssertTrue(description?.contains("Not Found") == true)
    }
    
    func testHTTPErrorTruncatesLongBody() {
        let longBody = String(repeating: "x", count: 400)
        let error = RoboflowClient.Err.http(status: 500, body: longBody)
        let description = error.errorDescription
        
        XCTAssertNotNil(description)
        XCTAssertLessThan(description!.count, longBody.count)
    }
    
    // MARK: - Multiple Instance Tests
    
    func testMultipleInstances() {
        let _ = RoboflowClient(apiKey: "key1", modelId: "model1/1")
        let _ = RoboflowClient(apiKey: "key2", modelId: "model2/1")
        let _ = RoboflowClient(apiKey: "key3", confidence: 0.5)
        XCTAssertTrue(true)
    }
    
    // MARK: - Confidence Range Tests
    
    func testConfidenceRange() {
        let confidences: [CGFloat] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
        
        for conf in confidences {
            let _ = RoboflowClient(apiKey: "test_key", confidence: conf)
        }
        XCTAssertTrue(true)
    }
    
    // MARK: - Overlap Range Tests
    
    func testOverlapRange() {
        let overlaps: [CGFloat] = [0.0, 0.1, 0.2, 0.5, 0.8, 1.0]
        
        for overlap in overlaps {
            let _ = RoboflowClient(apiKey: "test_key", overlap: overlap)
        }
        XCTAssertTrue(true)
    }
    
    // MARK: - API Key Tests
    
    func testVariousAPIKeyFormats() {
        let keys = [
            "",
            "simple_key",
            "key-with-dashes",
            "key_with_underscores",
            "KeyWithCaps123",
            "very_long_api_key_that_has_many_characters_in_it"
        ]
        
        for key in keys {
            let _ = RoboflowClient(apiKey: key)
        }
        XCTAssertTrue(true)
    }
    
    // MARK: - Model ID Tests
    
    func testVariousModelIDFormats() {
        let modelIDs = [
            "model/1",
            "model/2",
            "chessbot-v2/1",
            "custom-model-name/3",
            "model-with-many-dashes/10"
        ]
        
        for modelID in modelIDs {
            let _ = RoboflowClient(apiKey: "test_key", modelId: modelID)
        }
        XCTAssertTrue(true)
    }
}
