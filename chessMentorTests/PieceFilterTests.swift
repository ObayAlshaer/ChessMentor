import XCTest
@testable import chessMentor
import CoreGraphics
import UIKit

final class PieceFilterTests: XCTestCase {
    
    let size = CGSize(width: 800, height: 800)
    let S: CGFloat = 100

    // MARK: - Helper
    
    private func p(_ x: CGFloat, _ y: CGFloat, w: CGFloat = 90, h: CGFloat = 90, cls: String, conf: CGFloat = 0.9) -> Prediction {
        Prediction(x: x, y: y, width: w, height: h, class: cls, confidence: conf)
    }
    
    // MARK: - Initialization Tests
    
    func testInitializeWithDefaults() {
        let _ = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        XCTAssertTrue(true)
    }
    
    func testInitializeWithCustomParams() {
        let _ = PieceFilter(
            minConfidence: 0.5,
            minConfidenceKing: 0.3,
            edgeTrimSquares: 0.2,
            minSizeFrac: 0.4,
            maxSizeFrac: 2.0
        )
        XCTAssertTrue(true)
    }
    
    // MARK: - Core Filter Tests

    func testFilter_dropsOffboardAndTiny() {
        let f = PieceFilter(minConfidence: 0.3, minConfidenceKing: 0.25, edgeTrimSquares: 0.15, minSizeFrac: 0.35, maxSizeFrac: 1.6)
        let onBoard = p(4.5*S, 4.5*S, w: 90, h: 90, cls: "w-queen", conf: 0.9)
        let offBoard = p(0.1*S, 0.1*S, w: 90, h: 90, cls: "w-queen", conf: 0.9)
        let tiny = p(4.5*S, 4.5*S, w: 10, h: 10, cls: "w-queen", conf: 0.9)
        let kept = f.apply([onBoard, offBoard, tiny], imageSize: size)
        XCTAssertEqual(kept.count, 1)
        XCTAssertEqual(kept.first?.class, "w-queen")
    }

    func testFilter_keepsLowConfKingButDropsOther() {
        let f = PieceFilter(minConfidence: 0.4, minConfidenceKing: 0.2, edgeTrimSquares: 0.1, minSizeFrac: 0.35, maxSizeFrac: 1.6)
        let king = p(4.5*S, 4.5*S, cls: "w-king", conf: 0.25)
        let pawn = p(3.5*S, 3.5*S, cls: "w-pawn", conf: 0.25)
        let kept = f.apply([king, pawn], imageSize: size)
        XCTAssertEqual(kept.count, 1)
        XCTAssertEqual(kept.first?.class, "w-king")
    }
    
    // MARK: - Empty & Basic Tests
    
    func testFilterEmptyList() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        
        let predictions: [Prediction] = []
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertTrue(filtered.isEmpty)
    }
    
    func testFilterHighConfidence() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-pawn", confidence: 0.95)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertEqual(filtered.count, 1)
    }
    
    func testFilterLowConfidence() {
        let filter = PieceFilter(
            minConfidence: 0.50,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-pawn", confidence: 0.25)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertTrue(filtered.isEmpty)
    }
    
    // MARK: - Size Filter Tests
    
    func testFilterOversizedPieces() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.20
        )
        
        let expectedSize = size.width / 8
        
        let predictions = [
            Prediction(x: 400, y: 400, width: expectedSize, height: expectedSize, class: "w-pawn", confidence: 0.90),
            Prediction(x: 500, y: 400, width: expectedSize * 2, height: expectedSize * 2, class: "w-queen", confidence: 0.90)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.class, "w-pawn")
    }
    
    func testFilterUndersizedPieces() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.40,
            maxSizeFrac: 1.60
        )
        
        let expectedSize = size.width / 8
        
        let predictions = [
            Prediction(x: 400, y: 400, width: expectedSize, height: expectedSize, class: "w-pawn", confidence: 0.90),
            Prediction(x: 500, y: 400, width: expectedSize * 0.2, height: expectedSize * 0.2, class: "w-queen", confidence: 0.90)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.class, "w-pawn")
    }
    
    // MARK: - Edge & Position Tests
    
    func testFilterBoardEdges() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.2,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        
        let predictions = [
            Prediction(x: 10, y: 400, width: 80, height: 80, class: "w-pawn", confidence: 0.90),
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-queen", confidence: 0.90)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertTrue(filtered.contains { $0.class == "w-queen" })
    }
    
    // MARK: - Multiple Predictions Tests
    
    func testFilterMultiplePredictions() {
        let filter = PieceFilter(
            minConfidence: 0.30,
            minConfidenceKing: 0.22,
            edgeTrimSquares: 0.12,
            minSizeFrac: 0.35,
            maxSizeFrac: 1.60
        )
        
        let predictions = [
            Prediction(x: 150, y: 150, width: 80, height: 80, class: "w-rook", confidence: 0.95),
            Prediction(x: 250, y: 150, width: 80, height: 80, class: "w-knight", confidence: 0.90),
            Prediction(x: 350, y: 150, width: 80, height: 80, class: "w-bishop", confidence: 0.85),
            Prediction(x: 450, y: 150, width: 80, height: 80, class: "w-queen", confidence: 0.92),
            Prediction(x: 550, y: 150, width: 80, height: 80, class: "w-king", confidence: 0.88)
        ]
        
        let filtered = filter.apply(predictions, imageSize: size)
        
        XCTAssertGreaterThan(filtered.count, 0)
    }
}
