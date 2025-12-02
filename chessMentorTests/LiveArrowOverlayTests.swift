//
//  LiveArrowOverlayTests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest
@testable import chessMentor
import SwiftUI

@MainActor
final class LiveArrowOverlayTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    private func createTestArrow() -> LiveArrow {
        LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 560, y: 140, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 600),
            p2Cropped: CGPoint(x: 400, y: 400)
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitializeWithNilArrow() {
        let overlay = LiveArrowOverlay(arrow: nil)
        
        XCTAssertNil(overlay.arrow)
    }
    
    func testInitializeWithValidArrow() {
        let arrow = createTestArrow()
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertNotNil(overlay.arrow)
    }
    
    // MARK: - Arrow Creation Tests
    
    func testArrowWithDifferentSourceSizes() {
        let sourceSizes: [CGSize] = [
            CGSize(width: 1280, height: 720),
            CGSize(width: 1920, height: 1080),
            CGSize(width: 3840, height: 2160)
        ]
        
        for size in sourceSizes {
            let arrow = LiveArrow(
                sourceSize: size,
                cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
                boardSize: CGSize(width: 800, height: 800),
                p1Cropped: CGPoint(x: 400, y: 400),
                p2Cropped: CGPoint(x: 500, y: 500)
            )
            let overlay = LiveArrowOverlay(arrow: arrow)
            
            XCTAssertEqual(overlay.arrow?.sourceSize, size)
        }
    }
    
    func testArrowWithDifferentCropRects() {
        let cropRects = [
            CGRect(x: 0, y: 0, width: 800, height: 800),
            CGRect(x: 100, y: 100, width: 800, height: 800),
            CGRect(x: 560, y: 140, width: 800, height: 800)
        ]
        
        for rect in cropRects {
            let arrow = LiveArrow(
                sourceSize: CGSize(width: 1920, height: 1080),
                cropRect: rect,
                boardSize: CGSize(width: 800, height: 800),
                p1Cropped: CGPoint(x: 400, y: 400),
                p2Cropped: CGPoint(x: 500, y: 500)
            )
            let overlay = LiveArrowOverlay(arrow: arrow)
            
            XCTAssertEqual(overlay.arrow?.cropRect, rect)
        }
    }
    
    // MARK: - Coordinate Mapping Tests
    
    func testArrowE2ToE4() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 560, y: 140, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 600),
            p2Cropped: CGPoint(x: 400, y: 400)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.x, 400)
        XCTAssertEqual(overlay.arrow?.p2Cropped.x, 400)
    }
    
    func testArrowA1ToH8() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 560, y: 140, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 50, y: 750),
            p2Cropped: CGPoint(x: 750, y: 50)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.x, 50)
        XCTAssertEqual(overlay.arrow?.p2Cropped.x, 750)
    }
    
    func testArrowCenterToCorner() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 0, y: 0)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped, CGPoint(x: 400, y: 400))
        XCTAssertEqual(overlay.arrow?.p2Cropped, CGPoint(x: 0, y: 0))
    }
    
    // MARK: - Edge Case Tests
    
    func testArrowSameStartEnd() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 400, y: 400)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped, overlay.arrow?.p2Cropped)
    }
    
    func testArrowAtTopEdge() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 0),
            p2Cropped: CGPoint(x: 500, y: 0)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.y, 0)
        XCTAssertEqual(overlay.arrow?.p2Cropped.y, 0)
    }
    
    func testArrowAtBottomEdge() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 800),
            p2Cropped: CGPoint(x: 500, y: 800)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.y, 800)
        XCTAssertEqual(overlay.arrow?.p2Cropped.y, 800)
    }
    
    func testArrowAtLeftEdge() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 0, y: 400),
            p2Cropped: CGPoint(x: 0, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.x, 0)
        XCTAssertEqual(overlay.arrow?.p2Cropped.x, 0)
    }
    
    func testArrowAtRightEdge() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 800, y: 400),
            p2Cropped: CGPoint(x: 800, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(overlay.arrow?.p1Cropped.x, 800)
        XCTAssertEqual(overlay.arrow?.p2Cropped.x, 800)
    }
    
    // MARK: - Direction Tests
    
    func testArrowPointingUp() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 600),
            p2Cropped: CGPoint(x: 400, y: 200)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertLessThan(dy, 0)
    }
    
    func testArrowPointingDown() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 200),
            p2Cropped: CGPoint(x: 400, y: 600)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertGreaterThan(dy, 0)
    }
    
    func testArrowPointingLeft() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 600, y: 400),
            p2Cropped: CGPoint(x: 200, y: 400)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        XCTAssertLessThan(dx, 0)
    }
    
    func testArrowPointingRight() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 200, y: 400),
            p2Cropped: CGPoint(x: 600, y: 400)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        XCTAssertGreaterThan(dx, 0)
    }
    
    // MARK: - Diagonal Arrow Tests
    
    func testArrowDiagonalNE() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 200, y: 600),
            p2Cropped: CGPoint(x: 600, y: 200)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertTrue(dx > 0 && dy < 0)
    }
    
    func testArrowDiagonalSE() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 200, y: 200),
            p2Cropped: CGPoint(x: 600, y: 600)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertTrue(dx > 0 && dy > 0)
    }
    
    func testArrowDiagonalSW() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 600, y: 200),
            p2Cropped: CGPoint(x: 200, y: 600)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertTrue(dx < 0 && dy > 0)
    }
    
    func testArrowDiagonalNW() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 600, y: 600),
            p2Cropped: CGPoint(x: 200, y: 200)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        XCTAssertTrue(dx < 0 && dy < 0)
    }
    
    // MARK: - Knight Move Tests
    
    func testKnightMove2R1U() {
        let squareSize: CGFloat = 100
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 400 + 2*squareSize, y: 400 - squareSize)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = abs(overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x)
        let dy = abs(overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y)
        XCTAssertEqual(dx, 200)
        XCTAssertEqual(dy, 100)
    }
    
    func testKnightMove1L2D() {
        let squareSize: CGFloat = 100
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 400 - squareSize, y: 400 + 2*squareSize)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = abs(overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x)
        let dy = abs(overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y)
        XCTAssertEqual(dx, 100)
        XCTAssertEqual(dy, 200)
    }
    
    // MARK: - Aspect Ratio Tests
    
    func testArrowLandscapeSource() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 560, y: 140, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 500, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let aspectRatio = arrow.sourceSize.width / arrow.sourceSize.height
        XCTAssertGreaterThan(aspectRatio, 1)
        XCTAssertNotNil(overlay.arrow)
    }
    
    func testArrowPortraitSource() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1080, height: 1920),
            cropRect: CGRect(x: 140, y: 560, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 500, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let aspectRatio = arrow.sourceSize.width / arrow.sourceSize.height
        XCTAssertLessThan(aspectRatio, 1)
        XCTAssertNotNil(overlay.arrow)
    }
    
    func testArrowSquareSource() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1000, height: 1000),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 500, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertEqual(arrow.sourceSize.width, arrow.sourceSize.height)
        XCTAssertNotNil(overlay.arrow)
    }
    
    // MARK: - Arrow Length Tests
    
    func testVeryShortArrow() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 400, y: 400),
            p2Cropped: CGPoint(x: 405, y: 405)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        let length = sqrt(dx*dx + dy*dy)
        XCTAssertLessThan(length, 10)
    }
    
    func testVeryLongArrow() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 0, y: 0),
            p2Cropped: CGPoint(x: 800, y: 800)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        let length = sqrt(dx*dx + dy*dy)
        XCTAssertGreaterThan(length, 1000)
    }
    
    func testMediumLengthArrow() {
        let arrow = LiveArrow(
            sourceSize: CGSize(width: 1920, height: 1080),
            cropRect: CGRect(x: 100, y: 100, width: 800, height: 800),
            boardSize: CGSize(width: 800, height: 800),
            p1Cropped: CGPoint(x: 300, y: 300),
            p2Cropped: CGPoint(x: 500, y: 500)
        )
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        let dx = overlay.arrow!.p2Cropped.x - overlay.arrow!.p1Cropped.x
        let dy = overlay.arrow!.p2Cropped.y - overlay.arrow!.p1Cropped.y
        let length = sqrt(dx*dx + dy*dy)
        XCTAssertTrue(length > 200 && length < 400)
    }
    
    // MARK: - View Property Tests
    
    func testOverlayDisablesHitTesting() {
        let arrow = createTestArrow()
        let overlay = LiveArrowOverlay(arrow: arrow)
        
        XCTAssertNotNil(overlay.arrow)
    }
}
