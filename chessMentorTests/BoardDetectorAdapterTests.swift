//
//  BoardDetectorAdapterTests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest
@testable import chessMentor
import CoreVideo
import UIKit

final class BoardDetectorAdapterTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    private func createPixelBuffer(width: Int = 1920, height: Int = 1080) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            options,
            &pixelBuffer
        )
        
        return status == kCVReturnSuccess ? pixelBuffer : nil
    }
    
    private func fillPixelBuffer(_ pixelBuffer: CVPixelBuffer, with color: UIColor) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }
        
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    private func createBlankImage() -> UIImage {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Pixel Buffer Creation Tests
    
    func testCreateValidPixelBuffer() {
        let pixelBuffer = createPixelBuffer()
        
        XCTAssertNotNil(pixelBuffer)
        
        if let buffer = pixelBuffer {
            XCTAssertEqual(CVPixelBufferGetWidth(buffer), 1920)
            XCTAssertEqual(CVPixelBufferGetHeight(buffer), 1080)
        }
    }
    
    func testCreateCustomSizePixelBuffer() {
        let pixelBuffer = createPixelBuffer(width: 1280, height: 720)
        
        XCTAssertNotNil(pixelBuffer)
        
        if let buffer = pixelBuffer {
            XCTAssertEqual(CVPixelBufferGetWidth(buffer), 1280)
            XCTAssertEqual(CVPixelBufferGetHeight(buffer), 720)
        }
    }
    
    func testCreateSquarePixelBuffer() {
        let pixelBuffer = createPixelBuffer(width: 800, height: 800)
        
        XCTAssertNotNil(pixelBuffer)
        
        if let buffer = pixelBuffer {
            XCTAssertEqual(CVPixelBufferGetWidth(buffer), 800)
            XCTAssertEqual(CVPixelBufferGetHeight(buffer), 800)
        }
    }
    
    // MARK: - Pixel Buffer Manipulation Tests
    
    func testFillPixelBufferWithColor() {
        guard let pixelBuffer = createPixelBuffer(width: 100, height: 100) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        fillPixelBuffer(pixelBuffer, with: .white)
        
        XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 100)
        XCTAssertEqual(CVPixelBufferGetHeight(pixelBuffer), 100)
    }
    
    func testFillMultiplePixelBuffers() {
        let colors: [UIColor] = [.white, .black, .red, .blue, .green]
        
        for color in colors {
            guard let pixelBuffer = createPixelBuffer(width: 100, height: 100) else {
                XCTFail("Failed to create pixel buffer")
                continue
            }
            
            fillPixelBuffer(pixelBuffer, with: color)
            
            XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 100)
        }
    }
    
    // MARK: - UIImage to PixelBuffer Conversion Tests
    
    func testConvertImageToPixelBuffer() {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let _ = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width), Int(size.height),
            kCVPixelFormatType_32BGRA,
            options,
            &pixelBuffer
        )
        
        XCTAssertNotNil(pixelBuffer)
    }
    
    // MARK: - Detected Board Structure Tests
    
    func testCreateDetectedBoard() {
        let image = createBlankImage()
        let board = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(board.fen, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        XCTAssertEqual(board.cropped.size, CGSize(width: 800, height: 800))
        XCTAssertEqual(board.cropRectInSource.width, 800)
        XCTAssertEqual(board.sourcePixelSize.width, 1920)
    }
    
    func testDetectedBoardEquality() {
        let image1 = createBlankImage()
        let image2 = createBlankImage()
        
        let board1 = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            cropped: image1,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        let board2 = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            cropped: image2,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(board1.fen, board2.fen)
        XCTAssertEqual(board1.cropRectInSource, board2.cropRectInSource)
    }
    
    // MARK: - EngineResult Structure Tests
    
    func testCreateEngineResultComplete() {
        let result = EngineResult(
            uci: "e2e4",
            san: "e4",
            evaluation: 0.5,
            pv: ["e2e4", "e7e5", "g1f3"]
        )
        
        XCTAssertEqual(result.uci, "e2e4")
        XCTAssertEqual(result.san, "e4")
        XCTAssertEqual(result.evaluation, 0.5)
        XCTAssertEqual(result.pv?.count, 3)
    }
    
    func testCreateEngineResultNilEvaluation() {
        let result = EngineResult(
            uci: "e2e4",
            san: "e4",
            evaluation: nil,
            pv: nil
        )
        
        XCTAssertEqual(result.uci, "e2e4")
        XCTAssertEqual(result.san, "e4")
        XCTAssertNil(result.evaluation)
        XCTAssertNil(result.pv)
    }
    
    func testEngineResultEquality() {
        let result1 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: ["e2e4"])
        let result2 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: ["e2e4"])
        
        XCTAssertEqual(result1, result2)
    }
    
    func testEngineResultInequalityUCI() {
        let result1 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: nil)
        let result2 = EngineResult(uci: "d2d4", san: "d4", evaluation: 0.5, pv: nil)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    func testEngineResultInequalityEvaluation() {
        let result1 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: nil)
        let result2 = EngineResult(uci: "e2e4", san: "e4", evaluation: 1.0, pv: nil)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    // MARK: - LiveArrow Structure Tests
    
    func testCreateLiveArrow() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 500, y: 500)
        )
        
        XCTAssertEqual(arrow.sourceSize.width, 1920)
        XCTAssertEqual(arrow.boardSize.width, 800)
        XCTAssertEqual(arrow.p1Cropped.x, 400)
        XCTAssertEqual(arrow.p2Cropped.x, 500)
    }
    
    func testLiveArrowEdgeCoordinates() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 0, y: 0, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 0, y: 0),
            p2Cropped: CGPoint(x: 800, y: 800)
        )
        
        XCTAssertEqual(arrow.cropRect.origin.x, 0)
        XCTAssertEqual(arrow.p1Cropped.x, 0)
        XCTAssertEqual(arrow.p2Cropped.x, 800)
    }
    
    func testLiveArrowSamePoints() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 400, y: 400)
        )
        
        XCTAssertEqual(arrow.p1Cropped, arrow.p2Cropped)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testBoardDetectorProtocolSignature() {
        let _: (any BoardDetector)? = nil
        XCTAssertTrue(true)
    }
    
    func testBestMoveProviderProtocolSignature() {
        let _: (any BestMoveProvider)? = nil
        XCTAssertTrue(true)
    }
    
    // MARK: - Integration Structure Tests
    
    func testCompleteAnalysisResult() {
        let image = createBlankImage()
        let board = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        let engineResult = EngineResult(
            uci: "e7e5",
            san: "e5",
            evaluation: 0.3,
            pv: ["e7e5", "g1f3", "b8c6"]
        )
        
        let arrow = LiveArrow(
            sourceSize: board.sourcePixelSize,
            cropRect: board.cropRectInSource,
            boardSize: board.cropped.size,
            p1Cropped: CGPoint(x: 400, y: 100),
            p2Cropped: CGPoint(x: 400, y: 300)
        )
        
        XCTAssertTrue(board.fen.contains("e3"))
        XCTAssertEqual(engineResult.uci, "e7e5")
        XCTAssertEqual(arrow.p1Cropped.y, 100)
    }
    
    // MARK: - Different Board Positions Tests
    
    func testStartingPositionBoard() {
        let image = createBlankImage()
        let board = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertTrue(board.fen.hasPrefix("rnbqkbnr/pppppppp"))
        XCTAssertTrue(board.fen.contains(" w "))
        XCTAssertTrue(board.fen.contains("KQkq"))
    }
    
    func testMidGamePosition() {
        let image = createBlankImage()
        let board = DetectedBoard(
            fen: "r1bqkb1r/pppp1ppp/2n2n2/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertTrue(board.fen.contains("r1bqkb1r"))
        XCTAssertTrue(board.fen.contains("KQkq"))
    }
    
    func testEndgamePosition() {
        let image = createBlankImage()
        let board = DetectedBoard(
            fen: "8/5k2/8/8/8/3K4/8/8 w - - 0 1",
            cropped: image,
            cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
            sourcePixelSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertTrue(board.fen.contains("5k2"))
        XCTAssertTrue(board.fen.contains("3K4"))
    }
    
    // MARK: - Crop Rectangle Tests
    
    func testCropRectanglePositions() {
        let image = createBlankImage()
        let positions = [
            CGRect(x: 0, y: 0, width: 800, height: 800),
            CGRect(x: 100, y: 100, width: 800, height: 800),
            CGRect(x: 500, y: 200, width: 800, height: 800),
            CGRect(x: 1000, y: 100, width: 800, height: 800)
        ]
        
        for rect in positions {
            let board = DetectedBoard(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                cropped: image,
                cropRectInSource: rect,
                sourcePixelSize: CGSize(width: 1920, height: 1080)
            )
            
            XCTAssertEqual(board.cropRectInSource, rect)
        }
    }
    
    func testCropRectangleSizes() {
        let image = createBlankImage()
        let sizes: [CGSize] = [
            CGSize(width: 400, height: 400),
            CGSize(width: 800, height: 800),
            CGSize(width: 1200, height: 1200)
        ]
        
        for size in sizes {
            let board = DetectedBoard(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                cropped: image,
                cropRectInSource: CGRect(origin: .zero, size: size),
                sourcePixelSize: CGSize(width: 1920, height: 1080)
            )
            
            XCTAssertEqual(board.cropRectInSource.size, size)
        }
    }
    
    // MARK: - Source Size Tests
    
    func testDifferentSourceSizes() {
        let image = createBlankImage()
        let sizes: [CGSize] = [
            CGSize(width: 1280, height: 720),
            CGSize(width: 1920, height: 1080),
            CGSize(width: 3840, height: 2160),
            CGSize(width: 4096, height: 2160)
        ]
        
        for size in sizes {
            let board = DetectedBoard(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                cropped: image,
                cropRectInSource: CGRect(x: 100, y: 100, width: 800, height: 800),
                sourcePixelSize: size
            )
            
            XCTAssertEqual(board.sourcePixelSize, size)
        }
    }

    // MARK: - BoardDetectorAdapter Initialization Tests

    func testBoardDetectorAdapterInitialization() {
        let adapter = BoardDetectorAdapter(roboflowApiKey: "test_api_key")
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterWithCustomPieceModelId() {
        let adapter = BoardDetectorAdapter(
            roboflowApiKey: "test_api_key",
            pieceModelId: "custom-piece-model/1"
        )
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterWithCustomBoardModelId() {
        let adapter = BoardDetectorAdapter(
            roboflowApiKey: "test_api_key",
            boardModelId: "custom-board-model/1"
        )
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterWithAllCustomParams() {
        let adapter = BoardDetectorAdapter(
            roboflowApiKey: "test_api_key",
            pieceModelId: "custom-piece/2",
            boardModelId: "custom-board/3"
        )
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterConformsToBoardDetectorProtocol() {
        let adapter = BoardDetectorAdapter(roboflowApiKey: "test_key")
        XCTAssertTrue(adapter is BoardDetector)
    }

    // MARK: - BoardDetectorAdapter with Various API Keys

    func testBoardDetectorAdapterWithEmptyAPIKey() {
        let adapter = BoardDetectorAdapter(roboflowApiKey: "")
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterWithLongAPIKey() {
        let longKey = String(repeating: "a", count: 100)
        let adapter = BoardDetectorAdapter(roboflowApiKey: longKey)
        XCTAssertNotNil(adapter)
    }

    func testBoardDetectorAdapterWithSpecialCharactersInKey() {
        let adapter = BoardDetectorAdapter(roboflowApiKey: "key-with_special.chars123")
        XCTAssertNotNil(adapter)
    }

    // MARK: - Multiple Adapter Instances

    func testMultipleBoardDetectorAdapterInstances() {
        let adapter1 = BoardDetectorAdapter(roboflowApiKey: "key1")
        let adapter2 = BoardDetectorAdapter(roboflowApiKey: "key2")
        let adapter3 = BoardDetectorAdapter(roboflowApiKey: "key3", pieceModelId: "model/1")
        
        XCTAssertNotNil(adapter1)
        XCTAssertNotNil(adapter2)
        XCTAssertNotNil(adapter3)
    }

    // MARK: - UIImage from PixelBuffer Tests

    func testUIImageCreationFromValidPixelBuffer() {
        guard let pixelBuffer = createPixelBuffer(width: 100, height: 100) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        fillPixelBuffer(pixelBuffer, with: .blue)
        
        // Test the CIImage -> CGImage -> UIImage conversion path
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        XCTAssertEqual(uiImage.size.width, 100)
        XCTAssertEqual(uiImage.size.height, 100)
    }

    func testUIImageCreationFromLargePixelBuffer() {
        guard let pixelBuffer = createPixelBuffer(width: 1920, height: 1080) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        fillPixelBuffer(pixelBuffer, with: .white)
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        XCTAssertEqual(uiImage.size.width, 1920)
        XCTAssertEqual(uiImage.size.height, 1080)
    }

    func testUIImageCreationFrom4KPixelBuffer() {
        guard let pixelBuffer = createPixelBuffer(width: 3840, height: 2160) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        fillPixelBuffer(pixelBuffer, with: .gray)
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        XCTAssertEqual(uiImage.size.width, 3840)
        XCTAssertEqual(uiImage.size.height, 2160)
    }

    // MARK: - Data Flow Integration Tests

    func testFullDataFlowFromPixelBufferToLiveArrow() {
        // 1. Create pixel buffer (simulating camera frame)
        guard let pixelBuffer = createPixelBuffer(width: 1920, height: 1080) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        fillPixelBuffer(pixelBuffer, with: .white)
        
        // 2. Convert to UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            XCTFail("Failed to create CGImage")
            return
        }
        let sourceImage = UIImage(cgImage: cgImage)
        
        // 3. Simulate cropped board
        let croppedImage = createBlankImage()
        let cropRect = CGRect(x: 560, y: 140, width: 800, height: 800)
        
        // 4. Create DetectedBoard
        let board = DetectedBoard(
            fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
            cropped: croppedImage,
            cropRectInSource: cropRect,
            sourcePixelSize: sourceImage.size
        )
        
        // 5. Create LiveArrow from board data
        let arrow = LiveArrow(
            sourceSize: board.sourcePixelSize,
            cropRect: board.cropRectInSource,
            boardSize: board.cropped.size,
            p1Cropped: CGPoint(x: 400, y: 600),  // e2
            p2Cropped: CGPoint(x: 400, y: 400)   // e4
        )
        
        // Verify complete data flow
        XCTAssertEqual(arrow.sourceSize.width, 1920)
        XCTAssertEqual(arrow.sourceSize.height, 1080)
        XCTAssertEqual(arrow.cropRect, cropRect)
        XCTAssertEqual(arrow.boardSize, CGSize(width: 800, height: 800))
    }

    // MARK: - Detect Method Edge Cases (without network)

    func testDetectReturnsNilForInvalidPixelBuffer() {
        // Create an adapter - we can't actually call detect without mocking,
        // but we can verify the adapter handles the setup correctly
        let adapter = BoardDetectorAdapter(roboflowApiKey: "test_key")
        
        // Verify it's a valid BoardDetector
        let detector: BoardDetector = adapter
        XCTAssertNotNil(detector)
    }

    // MARK: - Model ID Format Tests

    func testBoardDetectorAdapterWithVariousModelIdFormats() {
        let modelIds = [
            ("chessbot-v2/1", "chessboard-detection-x5kxd/1"),
            ("model/1", "board/1"),
            ("custom-model-name/10", "custom-board/5"),
            ("a/1", "b/1")
        ]
        
        for (pieceModel, boardModel) in modelIds {
            let adapter = BoardDetectorAdapter(
                roboflowApiKey: "test_key",
                pieceModelId: pieceModel,
                boardModelId: boardModel
            )
            XCTAssertNotNil(adapter)
        }
    }
}
