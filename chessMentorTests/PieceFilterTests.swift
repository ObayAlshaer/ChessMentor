import XCTest
@testable import chessMentor
import CoreGraphics
import UIKit

final class PieceFilterTests: XCTestCase {
    let size = CGSize(width: 800, height: 800)
    let S: CGFloat = 100

    private func p(_ x: CGFloat, _ y: CGFloat, w: CGFloat = 90, h: CGFloat = 90, cls: String, conf: CGFloat = 0.9) -> Prediction {
        Prediction(x: x, y: y, width: w, height: h, class: cls, confidence: conf)
    }

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
        let king = p(4.5*S, 4.5*S, cls: "w-king", conf: 0.25)   // passes king threshold
        let pawn = p(3.5*S, 3.5*S, cls: "w-pawn", conf: 0.25)   // fails general threshold
        let kept = f.apply([king, pawn], imageSize: size)
        XCTAssertEqual(kept.count, 1)
        XCTAssertEqual(kept.first?.class, "w-king")
    }
}
