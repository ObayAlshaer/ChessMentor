import XCTest
@testable import chessMentor
import UIKit

final class ArrowDrawerTests: XCTestCase {
    
    var drawer: ArrowDrawer!
    
    override func setUp() {
        super.setUp()
        drawer = ArrowDrawer()
    }
    
    override func tearDown() {
        drawer = nil
        super.tearDown()
    }
    
    // MARK: - Helper Functions
    
    private func createTestImage(size: CGSize = CGSize(width: 800, height: 800)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Draw a simple chessboard pattern
            UIColor.lightGray.setFill()
            for row in 0..<8 {
                for col in 0..<8 where (row + col) % 2 == 1 {
                    let squareSize = size.width / 8
                    let rect = CGRect(x: CGFloat(col) * squareSize,
                                    y: CGFloat(row) * squareSize,
                                    width: squareSize,
                                    height: squareSize)
                    ctx.fill(rect)
                }
            }
        }
    }
    
    // MARK: - Basic Arrow Drawing Tests
    
    func testDrawArrowFromE2ToE4() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e2e4")
        
        XCTAssertEqual(result.size, image.size)
        XCTAssertEqual(result.scale, image.scale)
    }
    
    func testDrawArrowFromG1ToF3() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "g1f3")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testDrawArrowFromE7ToE5() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e7e5")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testDrawDiagonalArrow() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "b1c3")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testDrawLongDiagonalArrow() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "a1h8")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - Edge Cases
    
    func testInvalidUCITooShort() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e2e")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testEmptyUCIString() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testUCIWithPromotion() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e7e8q")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - Corner Tests
    
    func testArrowFromA1() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "a1a3")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowFromA8() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "a8c8")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowFromH1() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "h1h3")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowFromH8() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "h8f8")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - All Files Tests
    
    func testArrowsFromAllFiles() {
        let image = createTestImage()
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        
        for file in files {
            let uci = "\(file)2\(file)4"
            let result = drawer.draw(on: image, uci: uci)
            XCTAssertEqual(result.size, image.size, "Failed for file \(file)")
        }
    }
    
    // MARK: - All Ranks Tests
    
    func testArrowsFromAllRanks() {
        let image = createTestImage()
        
        for rank in 1...8 {
            let uci = "e\(rank)e\((rank % 8) + 1)"
            let result = drawer.draw(on: image, uci: uci)
            XCTAssertEqual(result.size, image.size, "Failed for rank \(rank)")
        }
    }
    
    // MARK: - Different Image Sizes
    
    func testArrowOnSmallImage() {
        let image = createTestImage(size: CGSize(width: 400, height: 400))
        let result = drawer.draw(on: image, uci: "e2e4")
        
        XCTAssertEqual(result.size, CGSize(width: 400, height: 400))
    }
    
    func testArrowOnLargeImage() {
        let image = createTestImage(size: CGSize(width: 1600, height: 1600))
        let result = drawer.draw(on: image, uci: "e2e4")
        
        XCTAssertEqual(result.size, CGSize(width: 1600, height: 1600))
    }
    
    func testArrowOnRectangularImage() {
        let image = createTestImage(size: CGSize(width: 800, height: 1000))
        let result = drawer.draw(on: image, uci: "e2e4")
        
        XCTAssertEqual(result.size, CGSize(width: 800, height: 1000))
    }
    
    // MARK: - Knight Moves
    
    func testKnightMove() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "g1f3")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testAllKnightMovesFromE4() {
        let image = createTestImage()
        let knightMoves = ["e4d6", "e4f6", "e4g5", "e4g3", "e4f2", "e4d2", "e4c3", "e4c5"]
        
        for uci in knightMoves {
            let result = drawer.draw(on: image, uci: uci)
            XCTAssertEqual(result.size, image.size, "Failed for knight move \(uci)")
        }
    }
    
    // MARK: - Same Square Move
    
    func testMoveToSameSquare() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e4e4")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - Multiple Arrows
    
    func testMultipleArrowsSequentially() {
        var image = createTestImage()
        
        image = drawer.draw(on: image, uci: "e2e4")
        XCTAssertEqual(image.size, CGSize(width: 800, height: 800))
        
        image = drawer.draw(on: image, uci: "g1f3")
        XCTAssertEqual(image.size, CGSize(width: 800, height: 800))
        
        image = drawer.draw(on: image, uci: "d7d5")
        XCTAssertEqual(image.size, CGSize(width: 800, height: 800))
    }
    
    // MARK: - Castling Moves
    
    func testKingsideCastling() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e1g1")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testQueensideCastling() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e1c1")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - Arrow Directions
    
    func testArrowMovingUp() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e4e8")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowMovingDown() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "e8e1")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowMovingLeft() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "h4a4")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    func testArrowMovingRight() {
        let image = createTestImage()
        let result = drawer.draw(on: image, uci: "a4h4")
        
        XCTAssertEqual(result.size, image.size)
    }
    
    // MARK: - Common Opening Moves
    
    func testCommonOpeningMoves() {
        let image = createTestImage()
        let openingMoves = [
            "e2e4",  // King's pawn
            "d2d4",  // Queen's pawn
            "c2c4",  // English opening
            "g1f3",  // Knight development
            "e7e5",  // Black response
            "c7c5",  // Sicilian defense
        ]
        
        for uci in openingMoves {
            let result = drawer.draw(on: image, uci: uci)
            XCTAssertEqual(result.size, image.size, "Failed for opening move \(uci)")
        }
    }
}
