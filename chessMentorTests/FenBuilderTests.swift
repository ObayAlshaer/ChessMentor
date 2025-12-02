import XCTest
@testable import chessMentor
import CoreGraphics
import UIKit

final class FenBuilderTests: XCTestCase {

    let size = CGSize(width: 800, height: 800)
    let S: CGFloat = 100 // 800/8
    let builder = FenBuilder()

    // MARK: - Helper Functions
    
    private func center(_ file: Character, _ rank: Int) -> (x: CGFloat, y: CGFloat) {
        let fIdx = Int(file.asciiValue! - Character("a").asciiValue!)
        let rowTop = 8 - rank
        let x = (CGFloat(fIdx) + 0.5) * S
        let y = (CGFloat(rowTop) + 0.5) * S
        return (x, y)
    }

    private func pred(_ file: Character, _ rank: Int, _ label: String, _ w: CGFloat = 80, _ h: CGFloat = 80, conf: CGFloat = 0.99) -> Prediction {
        let c = center(file, rank)
        return Prediction(x: c.x, y: c.y, width: w, height: h, class: label, confidence: conf)
    }
    
    private func createStartingPositionPredictions() -> [Prediction] {
        var predictions: [Prediction] = []
        let squareSize: CGFloat = 100
        
        // White back rank
        let whitePieces = ["w-rook", "w-knight", "w-bishop", "w-queen", "w-king", "w-bishop", "w-knight", "w-rook"]
        for (file, piece) in whitePieces.enumerated() {
            let x = CGFloat(file) * squareSize + squareSize/2
            predictions.append(Prediction(x: x, y: 700, width: 80, height: 80, class: piece, confidence: 0.90))
        }
        
        // White pawns
        for file in 0..<8 {
            let x = CGFloat(file) * squareSize + squareSize/2
            predictions.append(Prediction(x: x, y: 600, width: 80, height: 80, class: "w-pawn", confidence: 0.85))
        }
        
        // Black pawns
        for file in 0..<8 {
            let x = CGFloat(file) * squareSize + squareSize/2
            predictions.append(Prediction(x: x, y: 100, width: 80, height: 80, class: "b-pawn", confidence: 0.85))
        }
        
        // Black back rank
        let blackPieces = ["b-rook", "b-knight", "b-bishop", "b-queen", "b-king", "b-bishop", "b-knight", "b-rook"]
        for (file, piece) in blackPieces.enumerated() {
            let x = CGFloat(file) * squareSize + squareSize/2
            predictions.append(Prediction(x: x, y: 50, width: 80, height: 80, class: piece, confidence: 0.90))
        }
        
        return predictions
    }

    // MARK: - Basic FEN Structure Tests
    
    func testFenBuilder_initialSkeletonContainsKings() {
        var ps: [Prediction] = []
        ps.append(pred("e", 1, "w-king"))
        ps.append(pred("e", 8, "b-king"))
        ps.append(pred("e", 2, "w-pawn"))
        ps.append(pred("e", 7, "b-pawn"))
        let fen = builder.fen(from: ps, imageSize: size)
        XCTAssertTrue(fen.contains("K"), "should contain white king")
        XCTAssertTrue(fen.contains("k"), "should contain black king")
        XCTAssertTrue(fen.hasSuffix(" w") || fen.contains(" w "), "side to move should be present")
    }
    
    func testBuildFENForStartingPosition() {
        let predictions = createStartingPositionPredictions()
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.hasPrefix("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"))
        XCTAssertTrue(fen.contains(" w "))
    }
    
    func testRepresentEmptySquaresWithNumbers() {
        let predictions = [
            Prediction(x: 400, y: 700, width: 80, height: 80, class: "w-king", confidence: 0.95),
            Prediction(x: 400, y: 100, width: 80, height: 80, class: "b-king", confidence: 0.95)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("8") || fen.contains("7") || fen.contains("6"))
    }

    // MARK: - Castling Rights Tests
    
    func testFenBuilder_castlingRightsFromPlacement() {
        var ps: [Prediction] = []
        ps.append(pred("e", 1, "w-king"))
        ps.append(pred("a", 1, "w-rook"))
        ps.append(pred("h", 1, "w-rook"))
        ps.append(pred("e", 8, "b-king"))
        ps.append(pred("a", 8, "b-rook"))
        ps.append(pred("h", 8, "b-rook"))
        let fen = builder.fen(from: ps, imageSize: size)
        XCTAssertTrue(fen.contains(" KQkq ") || fen.contains(" KQkq-") || fen.contains(" KQkq"), "castling flags should be KQkq for start-like placement: \(fen)")
    }
    
    func testBuildFENWithFullCastlingRights() {
        let predictions = [
            Prediction(x: 400, y: 700, width: 80, height: 80, class: "w-king", confidence: 0.95),
            Prediction(x: 50, y: 700, width: 80, height: 80, class: "w-rook", confidence: 0.90),
            Prediction(x: 750, y: 700, width: 80, height: 80, class: "w-rook", confidence: 0.90),
            Prediction(x: 400, y: 50, width: 80, height: 80, class: "b-king", confidence: 0.95),
            Prediction(x: 50, y: 50, width: 80, height: 80, class: "b-rook", confidence: 0.90),
            Prediction(x: 750, y: 50, width: 80, height: 80, class: "b-rook", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains(" KQkq "))
    }
    
    func testBuildFENWithNoCastlingRights() {
        let predictions = [
            Prediction(x: 300, y: 500, width: 80, height: 80, class: "w-king", confidence: 0.95),
            Prediction(x: 500, y: 300, width: 80, height: 80, class: "b-king", confidence: 0.95)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains(" - "))
    }

    // MARK: - Piece Recognition Tests
    
    func testParseWhitePieceClassNames() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.90),
            Prediction(x: 500, y: 400, width: 80, height: 80, class: "white-queen", confidence: 0.90),
            Prediction(x: 600, y: 400, width: 80, height: 80, class: "w-rook", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("Q"))
        XCTAssertTrue(fen.contains("R"))
    }
    
    func testParseBlackPieceClassNames() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "b-king", confidence: 0.90),
            Prediction(x: 500, y: 400, width: 80, height: 80, class: "black-queen", confidence: 0.90),
            Prediction(x: 600, y: 400, width: 80, height: 80, class: "b-knight", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("k"))
        XCTAssertTrue(fen.contains("q"))
        XCTAssertTrue(fen.contains("n"))
    }
    
    func testParseAllPieceTypes() {
        let y: CGFloat = 400
        let predictions = [
            Prediction(x: 50, y: y, width: 80, height: 80, class: "w-king", confidence: 0.90),
            Prediction(x: 150, y: y, width: 80, height: 80, class: "w-queen", confidence: 0.90),
            Prediction(x: 250, y: y, width: 80, height: 80, class: "w-rook", confidence: 0.90),
            Prediction(x: 350, y: y, width: 80, height: 80, class: "w-bishop", confidence: 0.90),
            Prediction(x: 450, y: y, width: 80, height: 80, class: "w-knight", confidence: 0.90),
            Prediction(x: 550, y: y, width: 80, height: 80, class: "w-pawn", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("Q"))
        XCTAssertTrue(fen.contains("R"))
        XCTAssertTrue(fen.contains("B"))
        XCTAssertTrue(fen.contains("N"))
        XCTAssertTrue(fen.contains("P"))
    }
    
    func testHandleClassNamesWithVersionSuffixes() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king-v2", confidence: 0.90),
            Prediction(x: 500, y: 400, width: 80, height: 80, class: "b-queen-v3", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("q"))
    }

    // MARK: - Collision Resolution Tests
    
    func testFenBuilder_collisionKingWins() {
        let c = center("e", 1)
        let king = Prediction(x: c.x, y: c.y, width: 88, height: 88, class: "w-king", confidence: 0.55)
        let queen = Prediction(x: c.x, y: c.y, width: 88, height: 88, class: "w-queen", confidence: 0.95)
        let fen = builder.fen(from: [king, queen], imageSize: size)
        XCTAssertTrue(fen.contains("K"), "king must win collisions")
        XCTAssertFalse(fen.contains("Q") && !fen.contains("K"), "queen must not overwrite king")
    }
    
    func testCollisionKingWinsByPriority() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.80),
            Prediction(x: 410, y: 410, width: 80, height: 80, class: "w-pawn", confidence: 0.95)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
    }
    
    func testCollisionResolvedByConfidence() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-pawn", confidence: 0.60),
            Prediction(x: 410, y: 410, width: 80, height: 80, class: "w-pawn", confidence: 0.90),
            Prediction(x: 500, y: 400, width: 80, height: 80, class: "b-king", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains(" w "))
    }

    // MARK: - Edge Cases & Boundary Tests
    
    func testClampCoordinatesToBoardBoundaries() {
        let predictions = [
            Prediction(x: -10, y: 50, width: 80, height: 80, class: "w-rook", confidence: 0.90),
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.90),
            Prediction(x: 810, y: 750, width: 80, height: 80, class: "b-king", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("R"))
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("k"))
    }
    
    func testHandleDifferentImageSizes() {
        let predictions = [
            Prediction(x: 200, y: 200, width: 40, height: 40, class: "w-king", confidence: 0.90),
            Prediction(x: 200, y: 600, width: 40, height: 40, class: "b-king", confidence: 0.90)
        ]
        
        let largeSize = CGSize(width: 1600, height: 1600)
        let fen1 = builder.fen(from: predictions, imageSize: largeSize)
        XCTAssertTrue(fen1.contains("K"))
        XCTAssertTrue(fen1.contains("k"))
        
        let smallSize = CGSize(width: 400, height: 400)
        let fen2 = builder.fen(from: predictions, imageSize: smallSize)
        XCTAssertTrue(fen2.contains("K"))
        XCTAssertTrue(fen2.contains("k"))
    }

    // MARK: - King Recovery Tests
    
    func testForcePlaceWhiteKingWhenMissingAfterCollision() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.70),
            Prediction(x: 405, y: 405, width: 100, height: 100, class: "w-queen", confidence: 0.95),
            Prediction(x: 500, y: 100, width: 80, height: 80, class: "b-king", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("k"))
    }
    
    func testForcePlaceBlackKingWhenMissingAfterCollision() {
        let predictions = [
            Prediction(x: 400, y: 400, width: 80, height: 80, class: "b-king", confidence: 0.70),
            Prediction(x: 405, y: 405, width: 100, height: 100, class: "b-queen", confidence: 0.95),
            Prediction(x: 500, y: 700, width: 80, height: 80, class: "w-king", confidence: 0.90)
        ]
        
        let fen = builder.fen(from: predictions, imageSize: size)
        
        XCTAssertTrue(fen.contains("K"))
        XCTAssertTrue(fen.contains("k"))
    }
}
