import XCTest
@testable import chessMentor
import CoreVideo
import UIKit

// MARK: - Mock BoardDetector

class MockBoardDetector: BoardDetector {
    var shouldReturnNil = false
    var shouldThrow = false
    var mockBoard: DetectedBoard?
    var detectCallCount = 0
    
    func detect(from pixelBuffer: CVPixelBuffer) throws -> DetectedBoard? {
        detectCallCount += 1
        if shouldThrow {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if shouldReturnNil { return nil }
        return mockBoard
    }
}

// MARK: - Mock BestMoveProvider

class MockBestMoveProvider: BestMoveProvider {
    var mockResult: EngineResult?
    var shouldThrow = false
    var bestMoveCallCount = 0
    var lastFenReceived: String?
    
    func bestMove(for fen: String) async throws -> EngineResult {
        bestMoveCallCount += 1
        lastFenReceived = fen
        if shouldThrow {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Engine error"])
        }
        return mockResult ?? EngineResult(uci: "e2e4", san: "e4", evaluation: 0.3, pv: nil)
    }
}

// MARK: - Tests

final class LiveAnalysisViewModelTests: XCTestCase {
    
    var mockDetector: MockBoardDetector!
    var mockEngine: MockBestMoveProvider!
    
    override func setUp() {
        super.setUp()
        mockDetector = MockBoardDetector()
        mockEngine = MockBestMoveProvider()
    }
    
    override func tearDown() {
        mockDetector = nil
        mockEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testViewModelInitialization() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        
        XCTAssertNotNil(vm)
        XCTAssertNil(vm.liveArrow)
        XCTAssertNil(vm.bestMoveDisplay)
        XCTAssertNil(vm.evaluationText)
        XCTAssertFalse(vm.isAnalyzing)
    }
    
    @MainActor
    func testInitialStatusIsNotEmpty() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        XCTAssertFalse(vm.status.isEmpty)
    }
    
    @MainActor
    func testInitialLiveArrowIsNil() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        XCTAssertNil(vm.liveArrow)
    }
    
    @MainActor
    func testInitialBestMoveDisplayIsNil() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        XCTAssertNil(vm.bestMoveDisplay)
    }
    
    @MainActor
    func testInitialEvaluationTextIsNil() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        XCTAssertNil(vm.evaluationText)
    }
    
    @MainActor
    func testInitialIsAnalyzingIsFalse() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        XCTAssertFalse(vm.isAnalyzing)
    }
    
    // MARK: - Cancel Tests
    
    @MainActor
    func testCancelSetsIsAnalyzingToFalse() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        
        vm.cancel()
        
        XCTAssertFalse(vm.isAnalyzing)
    }
    
    @MainActor
    func testCancelCanBeCalledMultipleTimes() {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        
        vm.cancel()
        vm.cancel()
        vm.cancel()
        
        XCTAssertFalse(vm.isAnalyzing)
    }
    
    // MARK: - Handle Frame Tests
    
    @MainActor
    func testHandleFrameWithNilDetectionResult() async {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        mockDetector.shouldReturnNil = true
        
        guard let pixelBuffer = createTestPixelBuffer() else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        vm.handleFrame(pixelBuffer)
        
        // Give async code time to execute
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When detection returns nil, no engine call should be made
        XCTAssertEqual(mockEngine.bestMoveCallCount, 0)
    }
    
    @MainActor
    func testHandleFrameCallsDetector() async {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        mockDetector.shouldReturnNil = true
        
        guard let pixelBuffer = createTestPixelBuffer() else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        vm.handleFrame(pixelBuffer)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertGreaterThanOrEqual(mockDetector.detectCallCount, 1)
    }
    
    @MainActor
    func testHandleFrameWithValidDetection() async {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        
        let image = createBlankImage()
        mockDetector.mockBoard = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        mockDetector.shouldReturnNil = false
        
        mockEngine.mockResult = EngineResult(uci: "e7e5", san: "e5", evaluation: 0.1, pv: nil)
        
        guard let pixelBuffer = createTestPixelBuffer() else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        vm.handleFrame(pixelBuffer)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Detector should have been called
        XCTAssertGreaterThanOrEqual(mockDetector.detectCallCount, 1)
    }
    
    @MainActor
    func testHandleFrameWhenAlreadyAnalyzing() async {
        let vm = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        mockDetector.shouldReturnNil = true
        
        guard let pixelBuffer = createTestPixelBuffer() else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        // Call handleFrame multiple times rapidly
        vm.handleFrame(pixelBuffer)
        vm.handleFrame(pixelBuffer)
        vm.handleFrame(pixelBuffer)
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Should handle gracefully without crashing
        XCTAssertNotNil(vm)
    }
    
    // MARK: - Multiple Instances Test
    
    @MainActor
    func testMultipleViewModelInstances() {
        let vm1 = LiveAnalysisViewModel(detector: mockDetector, engine: mockEngine)
        let vm2 = LiveAnalysisViewModel(detector: MockBoardDetector(), engine: MockBestMoveProvider())
        let vm3 = LiveAnalysisViewModel(detector: MockBoardDetector(), engine: MockBestMoveProvider())
        
        XCTAssertNotNil(vm1)
        XCTAssertNotNil(vm2)
        XCTAssertNotNil(vm3)
    }
    
    // MARK: - Helpers
    
    private func createTestPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            1920, 1080,
            kCVPixelFormatType_32BGRA,
            options,
            &pixelBuffer
        )
        
        return pixelBuffer
    }
    
    private func createBlankImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 800))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 800, height: 800)))
        }
    }
}
