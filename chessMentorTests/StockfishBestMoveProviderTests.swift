//
//  StockfishBestMoveProviderTests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest
@testable import chessMentor

final class StockfishBestMoveProviderTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testProviderInitialization() {
        let provider = StockfishBestMoveProvider()
        XCTAssertNotNil(provider)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testConformsToBestMoveProvider() {
        let provider = StockfishBestMoveProvider()
        XCTAssertTrue(provider is BestMoveProvider)
    }
    
    // ADD THIS TEST
    func testMultipleProviderInstances() {
        let provider1 = StockfishBestMoveProvider()
        let provider2 = StockfishBestMoveProvider()
        let provider3 = StockfishBestMoveProvider()
        
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNotNil(provider3)
    }
    
    // MARK: - EngineResult Structure Tests
    
    func testEngineResultCreation() {
        let result = EngineResult(
            uci: "e2e4",
            san: "e4",
            evaluation: 0.31,
            pv: ["e2e4", "e7e5", "g1f3"]
        )
        
        XCTAssertEqual(result.uci, "e2e4")
        XCTAssertEqual(result.san, "e4")
        XCTAssertEqual(result.evaluation, 0.31)
        XCTAssertEqual(result.pv?.count, 3)
    }
    
    func testEngineResultWithNilValues() {
        let result = EngineResult(
            uci: "d2d4",
            san: "d4",
            evaluation: nil,
            pv: nil
        )
        
        XCTAssertEqual(result.uci, "d2d4")
        XCTAssertEqual(result.san, "d4")
        XCTAssertNil(result.evaluation)
        XCTAssertNil(result.pv)
    }
    
    func testEngineResultEquality() {
        let result1 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: nil)
        let result2 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: nil)
        
        XCTAssertEqual(result1, result2)
    }
    
    func testEngineResultInequality() {
        let result1 = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.5, pv: nil)
        let result2 = EngineResult(uci: "d2d4", san: "d4", evaluation: 0.5, pv: nil)
        
        XCTAssertNotEqual(result1, result2)
    }
    
    // MARK: - Evaluation Conversion Tests
    
    func testEvaluationStringToDouble() {
        let testCases: [(String?, Double?)] = [
            ("0.31", 0.31),
            ("-0.5", -0.5),
            ("1.25", 1.25),
            ("0.0", 0.0),
            (nil, nil),
            ("invalid", nil)
        ]
        
        for (input, expected) in testCases {
            let converted = input.flatMap { Double($0) }
            XCTAssertEqual(converted, expected, "Failed for input: \(String(describing: input))")
        }
    }
    
    // MARK: - Various Move Formats Tests
    
    func testVariousMoveFormats() {
        let moves: [(uci: String, san: String)] = [
            ("e2e4", "e4"),
            ("g1f3", "Nf3"),
            ("f1c4", "Bc4"),
            ("e1g1", "O-O"),
            ("e1c1", "O-O-O"),
            ("d7d8q", "d8=Q"),
            ("e5d6", "exd6"),
            ("g4f3", "gxf3")
        ]
        
        for (uci, san) in moves {
            let result = EngineResult(uci: uci, san: san, evaluation: nil, pv: nil)
            XCTAssertEqual(result.uci, uci)
            XCTAssertEqual(result.san, san)
        }
    }
    
    // MARK: - Principal Variation Tests
    
    func testPVWithMultipleMoves() {
        let pv = ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5"]
        let result = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.3, pv: pv)
        
        XCTAssertEqual(result.pv?.count, 5)
        XCTAssertEqual(result.pv?.first, "e2e4")
        XCTAssertEqual(result.pv?.last, "f1b5")
    }
    
    func testEmptyPV() {
        let result = EngineResult(uci: "e2e4", san: "e4", evaluation: 0.3, pv: [])
        
        XCTAssertNotNil(result.pv)
        XCTAssertEqual(result.pv?.count, 0)
    }
}
