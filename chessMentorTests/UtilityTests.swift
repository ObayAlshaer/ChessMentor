import XCTest
@testable import chessMentor
import UIKit
import CoreGraphics

// MARK: - Prediction Tests

final class PredictionStructTests: XCTestCase {
    
    func testCreatePredictionWithAllFields() {
        let prediction = Prediction(
            x: 400,
            y: 300,
            width: 80,
            height: 80,
            class: "w-king",
            confidence: 0.95
        )
        
        XCTAssertEqual(prediction.x, 400)
        XCTAssertEqual(prediction.y, 300)
        XCTAssertEqual(prediction.width, 80)
        XCTAssertEqual(prediction.height, 80)
        XCTAssertEqual(prediction.class, "w-king")
        XCTAssertEqual(prediction.confidence, 0.95)
    }
    
    func testPredictionWithMinimalConfidence() {
        let prediction = Prediction(
            x: 100,
            y: 100,
            width: 50,
            height: 50,
            class: "w-pawn",
            confidence: 0.01
        )
        
        XCTAssertEqual(prediction.confidence, 0.01)
    }
    
    func testPredictionWithMaximumConfidence() {
        let prediction = Prediction(
            x: 100,
            y: 100,
            width: 50,
            height: 50,
            class: "w-king",
            confidence: 1.0
        )
        
        XCTAssertEqual(prediction.confidence, 1.0)
    }
    
    func testPredictionAtOrigin() {
        let prediction = Prediction(
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            class: "b-queen",
            confidence: 0.85
        )
        
        XCTAssertEqual(prediction.x, 0)
        XCTAssertEqual(prediction.y, 0)
    }
    
    func testPredictionWithFractionalCoordinates() {
        let prediction = Prediction(
            x: 123.456,
            y: 789.012,
            width: 80.5,
            height: 79.8,
            class: "w-knight",
            confidence: 0.88
        )
        
        XCTAssertEqual(prediction.x, 123.456, accuracy: 0.001)
        XCTAssertEqual(prediction.y, 789.012, accuracy: 0.001)
    }
    
    func testPredictionsForAllPieceTypes() {
        let pieces = ["w-king", "w-queen", "w-rook", "w-bishop", "w-knight", "w-pawn",
                     "b-king", "b-queen", "b-rook", "b-bishop", "b-knight", "b-pawn"]
        
        for piece in pieces {
            let prediction = Prediction(
                x: 400,
                y: 400,
                width: 80,
                height: 80,
                class: piece,
                confidence: 0.90
            )
            
            XCTAssertEqual(prediction.class, piece)
        }
    }
    
    func testCalculatePredictionBoundingBox() {
        let prediction = Prediction(
            x: 400,
            y: 300,
            width: 100,
            height: 80,
            class: "w-queen",
            confidence: 0.90
        )
        
        let minX = prediction.x - prediction.width / 2
        let minY = prediction.y - prediction.height / 2
        let maxX = prediction.x + prediction.width / 2
        let maxY = prediction.y + prediction.height / 2
        
        XCTAssertEqual(minX, 350)
        XCTAssertEqual(minY, 260)
        XCTAssertEqual(maxX, 450)
        XCTAssertEqual(maxY, 340)
    }
    
    func testCalculatePredictionArea() {
        let prediction = Prediction(
            x: 400,
            y: 300,
            width: 100,
            height: 80,
            class: "w-rook",
            confidence: 0.85
        )
        
        let area = prediction.width * prediction.height
        XCTAssertEqual(area, 8000)
    }
}

// MARK: - Chess Coordinate Tests

final class ChessCoordinateTests: XCTestCase {
    
    func testConvertFileNumbersToLetters() {
        let files = [0: "a", 1: "b", 2: "c", 3: "d", 4: "e", 5: "f", 6: "g", 7: "h"]
        
        for (number, letter) in files {
            let computed = Character(UnicodeScalar(97 + number)!)
            XCTAssertEqual(String(computed), letter)
        }
    }
    
    func testConvertRankNumbers() {
        for rank in 1...8 {
            let row = 8 - rank
            XCTAssertGreaterThanOrEqual(row, 0)
            XCTAssertLessThan(row, 8)
        }
    }
    
    func testAll64SquaresAreUnique() {
        var squares = Set<String>()
        
        for file in 0..<8 {
            for rank in 1...8 {
                let fileChar = Character(UnicodeScalar(97 + file)!)
                let square = "\(fileChar)\(rank)"
                squares.insert(square)
            }
        }
        
        XCTAssertEqual(squares.count, 64)
    }
    
    func testCornerSquaresHaveCorrectNames() {
        let corners = ["a1", "a8", "h1", "h8"]
        XCTAssertEqual(corners.count, 4)
        XCTAssertTrue(corners.contains("a1"))
        XCTAssertTrue(corners.contains("h8"))
    }
    
    func testCenterSquaresHaveCorrectNames() {
        let center = ["d4", "d5", "e4", "e5"]
        XCTAssertEqual(center.count, 4)
        XCTAssertTrue(center.contains("e4"))
        XCTAssertTrue(center.contains("d5"))
    }
}

// MARK: - UCI Move Format Tests

final class UCIMoveFormatTests: XCTestCase {
    
    func testValidUCIMoveFormat() {
        let moves = ["e2e4", "g1f3", "a7a8q", "e1g1"]
        
        for move in moves {
            XCTAssertGreaterThanOrEqual(move.count, 4)
            XCTAssertLessThanOrEqual(move.count, 5)
        }
    }
    
    func testExtractSourceSquareFromUCI() {
        let uci = "e2e4"
        let source = String(uci.prefix(2))
        
        XCTAssertEqual(source, "e2")
    }
    
    func testExtractDestinationSquareFromUCI() {
        let uci = "e2e4"
        let destination = String(uci.dropFirst(2).prefix(2))
        
        XCTAssertEqual(destination, "e4")
    }
    
    func testExtractPromotionPieceFromUCI() {
        let uci = "e7e8q"
        
        if uci.count == 5 {
            let promotion = uci.last
            XCTAssertEqual(promotion, "q")
        }
    }
    
    func testAllValidUCIMoves() {
        let validMoves = [
            "e2e4",   // Pawn push
            "g1f3",   // Knight move
            "e1g1",   // Castling
            "a7a8q",  // Promotion to queen
            "h7h8n",  // Promotion to knight
        ]
        
        for move in validMoves {
            XCTAssertGreaterThanOrEqual(move.count, 4)
            XCTAssertLessThanOrEqual(move.count, 5)
        }
    }
}

// MARK: - Image Processing Tests

final class ImageProcessingTests: XCTestCase {
    
    func testCreateBlankImage() {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        
        XCTAssertEqual(image.size, size)
        XCTAssertGreaterThan(image.scale, 0)
    }
    
    func testCreateImagesOfDifferentSizes() {
        let sizes = [
            CGSize(width: 400, height: 400),
            CGSize(width: 800, height: 800),
            CGSize(width: 1600, height: 1600)
        ]
        
        for size in sizes {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            
            XCTAssertEqual(image.size, size)
        }
    }
    
    func testImageScaleFactors() {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        
        XCTAssertGreaterThanOrEqual(image.scale, 1.0)
    }
}

// MARK: - CGRect Utility Tests

final class CGRectUtilityTests: XCTestCase {
    
    func testCreateCGRect() {
        let rect = CGRect(x: 100, y: 100, width: 800, height: 800)
        
        XCTAssertEqual(rect.origin.x, 100)
        XCTAssertEqual(rect.origin.y, 100)
        XCTAssertEqual(rect.size.width, 800)
        XCTAssertEqual(rect.size.height, 800)
    }
    
    func testCalculateCGRectCenter() {
        let rect = CGRect(x: 100, y: 100, width: 800, height: 800)
        
        let centerX = rect.midX
        let centerY = rect.midY
        
        XCTAssertEqual(centerX, 500)
        XCTAssertEqual(centerY, 500)
    }
    
    func testCheckIfPointIsInsideRectangle() {
        let rect = CGRect(x: 0, y: 0, width: 800, height: 800)
        
        let inside = CGPoint(x: 400, y: 400)
        let outside = CGPoint(x: 900, y: 900)
        
        XCTAssertTrue(rect.contains(inside))
        XCTAssertFalse(rect.contains(outside))
    }
    
    func testCalculateRectangleArea() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 80)
        let area = rect.width * rect.height
        
        XCTAssertEqual(area, 8000)
    }
    
    func testInsetRectangle() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inset = rect.insetBy(dx: 10, dy: 10)
        
        XCTAssertEqual(inset.width, 80)
        XCTAssertEqual(inset.height, 80)
        XCTAssertEqual(inset.origin.x, 10)
        XCTAssertEqual(inset.origin.y, 10)
    }
    
    func testRectangleIntersection() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 50, y: 50, width: 100, height: 100)
        
        XCTAssertTrue(rect1.intersects(rect2))
        
        let intersection = rect1.intersection(rect2)
        XCTAssertFalse(intersection.isNull)
    }
}

// MARK: - Mathematical Utility Tests

final class MathematicalUtilityTests: XCTestCase {
    
    func testCalculateAngleBetweenPoints() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 100, y: 100)
        
        let angle = atan2(p2.y - p1.y, p2.x - p1.x)
        
        XCTAssertEqual(angle, 0.785, accuracy: 0.01)
    }
    
    func testCalculateDistanceBetweenPoints() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 3, y: 4)
        
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let distance = sqrt(dx*dx + dy*dy)
        
        XCTAssertEqual(distance, 5)
    }
    
    func testClampValue() {
        func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
            return max(minValue, min(maxValue, value))
        }
        
        XCTAssertEqual(clamp(5, min: 0, max: 10), 5)
        XCTAssertEqual(clamp(-5, min: 0, max: 10), 0)
        XCTAssertEqual(clamp(15, min: 0, max: 10), 10)
    }
    
    func testLinearInterpolation() {
        func lerp(from: CGFloat, to: CGFloat, t: CGFloat) -> CGFloat {
            return from + (to - from) * t
        }
        
        XCTAssertEqual(lerp(from: 0, to: 100, t: 0.5), 50)
        XCTAssertEqual(lerp(from: 0, to: 100, t: 0.0), 0)
        XCTAssertEqual(lerp(from: 0, to: 100, t: 1.0), 100)
    }
}

// MARK: - Aspect Ratio Tests

final class AspectRatioTests: XCTestCase {
    
    func testCalculateAspectRatio16By9() {
        let width: CGFloat = 1920
        let height: CGFloat = 1080
        let ratio = width / height
        
        XCTAssertEqual(ratio, 16.0/9.0, accuracy: 0.01)
    }
    
    func testCalculateAspectRatio4By3() {
        let width: CGFloat = 1024
        let height: CGFloat = 768
        let ratio = width / height
        
        XCTAssertEqual(ratio, 4.0/3.0, accuracy: 0.01)
    }
    
    func testCalculateAspectRatio1By1() {
        let width: CGFloat = 800
        let height: CGFloat = 800
        let ratio = width / height
        
        XCTAssertEqual(ratio, 1.0)
    }
    
    func testDetectLandscapeOrientation() {
        let size = CGSize(width: 1920, height: 1080)
        let isLandscape = size.width > size.height
        
        XCTAssertTrue(isLandscape)
    }
    
    func testDetectPortraitOrientation() {
        let size = CGSize(width: 1080, height: 1920)
        let isPortrait = size.height > size.width
        
        XCTAssertTrue(isPortrait)
    }
}
