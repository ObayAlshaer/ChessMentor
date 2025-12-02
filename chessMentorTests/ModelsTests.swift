//
//  ModelsTests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest
@testable import chessMentor
import UIKit

final class ModelsTests: XCTestCase {
    
    // MARK: - Prediction Tests
    
    func testPredictionInitialization() {
        let prediction = Prediction(
            x: 400,
            y: 400,
            width: 80,
            height: 80,
            class: "w-king",
            confidence: 0.95
        )
        
        XCTAssertEqual(prediction.x, 400)
        XCTAssertEqual(prediction.y, 400)
        XCTAssertEqual(prediction.width, 80)
        XCTAssertEqual(prediction.height, 80)
        XCTAssertEqual(prediction.class, "w-king")
        XCTAssertEqual(prediction.confidence, 0.95)
    }
    
    func testPredictionWithNilConfidence() {
        let prediction = Prediction(
            x: 100,
            y: 200,
            width: 50,
            height: 50,
            class: "b-pawn",
            confidence: nil
        )
        
        XCTAssertNil(prediction.confidence)
    }
    
    func testPredictionEquality() {
        let pred1 = Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.95)
        let pred2 = Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.95)
        
        XCTAssertEqual(pred1, pred2)
    }
    
    func testPredictionInequality() {
        let pred1 = Prediction(x: 400, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.95)
        let pred2 = Prediction(x: 500, y: 400, width: 80, height: 80, class: "w-king", confidence: 0.95)
        
        XCTAssertNotEqual(pred1, pred2)
    }
    
    func testPredictionDecodingFromJSON() throws {
        let json = """
        {
            "x": 450.5,
            "y": 350.2,
            "width": 88.0,
            "height": 88.0,
            "class": "w-queen",
            "confidence": 0.92
        }
        """.data(using: .utf8)!
        
        let prediction = try JSONDecoder().decode(Prediction.self, from: json)
        
        XCTAssertEqual(prediction.x, 450.5)
        XCTAssertEqual(prediction.y, 350.2)
        XCTAssertEqual(prediction.width, 88.0)
        XCTAssertEqual(prediction.height, 88.0)
        XCTAssertEqual(prediction.class, "w-queen")
        XCTAssertEqual(prediction.confidence, 0.92)
    }
    
    func testPredictionDecodingWithoutConfidence() throws {
        let json = """
        {
            "x": 100,
            "y": 200,
            "width": 80,
            "height": 80,
            "class": "b-rook"
        }
        """.data(using: .utf8)!
        
        let prediction = try JSONDecoder().decode(Prediction.self, from: json)
        
        XCTAssertEqual(prediction.class, "b-rook")
        XCTAssertNil(prediction.confidence)
    }
    
    func testPredictionAllPieceClasses() {
        let classes = ["w-king", "w-queen", "w-rook", "w-bishop", "w-knight", "w-pawn",
                       "b-king", "b-queen", "b-rook", "b-bishop", "b-knight", "b-pawn"]
        
        for cls in classes {
            let pred = Prediction(x: 400, y: 400, width: 80, height: 80, class: cls, confidence: 0.9)
            XCTAssertEqual(pred.class, cls)
        }
    }
    
    // MARK: - BestMove Tests
    
    func testBestMoveInitialization() {
        let move = BestMove(
            best_move_uci: "e2e4",
            best_move_san: "e4",
            evaluation: "0.31"
        )
        
        XCTAssertEqual(move.best_move_uci, "e2e4")
        XCTAssertEqual(move.best_move_san, "e4")
        XCTAssertEqual(move.evaluation, "0.31")
    }
    
    func testBestMoveWithNilEvaluation() {
        let move = BestMove(
            best_move_uci: "g1f3",
            best_move_san: "Nf3",
            evaluation: nil
        )
        
        XCTAssertEqual(move.best_move_uci, "g1f3")
        XCTAssertEqual(move.best_move_san, "Nf3")
        XCTAssertNil(move.evaluation)
    }
    
    func testBestMoveEquality() {
        let move1 = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        let move2 = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        
        XCTAssertEqual(move1, move2)
    }
    
    func testBestMoveInequality() {
        let move1 = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        let move2 = BestMove(best_move_uci: "d2d4", best_move_san: "d4", evaluation: "0.31")
        
        XCTAssertNotEqual(move1, move2)
    }
    
    func testBestMoveDecodingFromJSON() throws {
        let json = """
        {
            "best_move_uci": "e2e4",
            "best_move_san": "e4",
            "evaluation": "0.35"
        }
        """.data(using: .utf8)!
        
        let move = try JSONDecoder().decode(BestMove.self, from: json)
        
        XCTAssertEqual(move.best_move_uci, "e2e4")
        XCTAssertEqual(move.best_move_san, "e4")
        XCTAssertEqual(move.evaluation, "0.35")
    }
    
    func testBestMoveDecodingWithNullEvaluation() throws {
        let json = """
        {
            "best_move_uci": "a2a3",
            "best_move_san": "a3",
            "evaluation": null
        }
        """.data(using: .utf8)!
        
        let move = try JSONDecoder().decode(BestMove.self, from: json)
        
        XCTAssertEqual(move.best_move_uci, "a2a3")
        XCTAssertNil(move.evaluation)
    }
    
    func testBestMoveVariousFormats() {
        let moves = [
            ("e2e4", "e4"),
            ("g1f3", "Nf3"),
            ("e1g1", "O-O"),
            ("e1c1", "O-O-O"),
            ("d7d8q", "d8=Q"),
            ("b7a8n", "bxa8=N")
        ]
        
        for (uci, san) in moves {
            let move = BestMove(best_move_uci: uci, best_move_san: san, evaluation: nil)
            XCTAssertEqual(move.best_move_uci, uci)
            XCTAssertEqual(move.best_move_san, san)
        }
    }
    
    // MARK: - AnalysisResult Tests
    
    func testAnalysisResultInitialization() {
        let image = createBlankImage()
        let move = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        
        let result = AnalysisResult(
            cropped: image,
            overlays: nil,
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            bestMove: move,
            finalImage: image
        )
        
        XCTAssertEqual(result.fen, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        XCTAssertEqual(result.bestMove.best_move_uci, "e2e4")
        XCTAssertNil(result.overlays)
    }
    
    func testAnalysisResultWithOverlays() {
        let image = createBlankImage()
        let overlay = createBlankImage(size: CGSize(width: 400, height: 400))
        let move = BestMove(best_move_uci: "d2d4", best_move_san: "d4", evaluation: "0.25")
        
        let result = AnalysisResult(
            cropped: image,
            overlays: overlay,
            fen: "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1",
            bestMove: move,
            finalImage: image
        )
        
        XCTAssertNotNil(result.overlays)
        XCTAssertEqual(result.overlays?.size, CGSize(width: 400, height: 400))
    }
    
    func testAnalysisResultEquality() {
        let image1 = createBlankImage()
        let image2 = createBlankImage()
        let move = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        
        let result1 = AnalysisResult(cropped: image1, overlays: nil, fen: "test-fen", bestMove: move, finalImage: image1)
        let result2 = AnalysisResult(cropped: image2, overlays: nil, fen: "test-fen", bestMove: move, finalImage: image2)
        
        XCTAssertEqual(result1, result2)
    }
    
    func testAnalysisResultInequalityByFen() {
        let image = createBlankImage()
        let move = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        
        let result1 = AnalysisResult(cropped: image, overlays: nil, fen: "fen1", bestMove: move, finalImage: image)
        let result2 = AnalysisResult(cropped: image, overlays: nil, fen: "fen2", bestMove: move, finalImage: image)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    func testAnalysisResultInequalityByMove() {
        let image = createBlankImage()
        let move1 = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        let move2 = BestMove(best_move_uci: "d2d4", best_move_san: "d4", evaluation: "0.31")
        
        let result1 = AnalysisResult(cropped: image, overlays: nil, fen: "test", bestMove: move1, finalImage: image)
        let result2 = AnalysisResult(cropped: image, overlays: nil, fen: "test", bestMove: move2, finalImage: image)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    func testAnalysisResultInequalityByImageSize() {
        let image1 = createBlankImage(size: CGSize(width: 800, height: 800))
        let image2 = createBlankImage(size: CGSize(width: 400, height: 400))
        let move = BestMove(best_move_uci: "e2e4", best_move_san: "e4", evaluation: "0.31")
        
        let result1 = AnalysisResult(cropped: image1, overlays: nil, fen: "test", bestMove: move, finalImage: image1)
        let result2 = AnalysisResult(cropped: image2, overlays: nil, fen: "test", bestMove: move, finalImage: image2)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    // MARK: - Helper
    
    private func createBlankImage(size: CGSize = CGSize(width: 800, height: 800)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
