import XCTest
@testable import chessMentor
import CoreGraphics
import UIKit

final class FenBuilderTests: XCTestCase {

    let size = CGSize(width: 800, height: 800)
    let S: CGFloat = 100 // 800/8

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

    func testFenBuilder_initialSkeletonContainsKings() {
        let b = FenBuilder()
        var ps: [Prediction] = []
        // just place both kings and a few pawns
        ps.append(pred("e", 1, "w-king"))
        ps.append(pred("e", 8, "b-king"))
        ps.append(pred("e", 2, "w-pawn"))
        ps.append(pred("e", 7, "b-pawn"))
        let fen = b.fen(from: ps, imageSize: size)
        XCTAssertTrue(fen.contains("K"), "should contain white king")
        XCTAssertTrue(fen.contains("k"), "should contain black king")
        XCTAssertTrue(fen.hasSuffix(" w") || fen.contains(" w "), "side to move should be present")
    }

    func testFenBuilder_collisionKingWins() {
        let b = FenBuilder()
        // both king and queen in e1 → king should win
        let c = center("e", 1)
        let king = Prediction(x: c.x, y: c.y, width: 88, height: 88, class: "w-king", confidence: 0.55)
        let queen = Prediction(x: c.x, y: c.y, width: 88, height: 88, class: "w-queen", confidence: 0.95)
        let fen = b.fen(from: [king, queen], imageSize: size)
        // row 1 must contain 'K' at file e (we can't easily assert exact string, but at least 'K' exists)
        XCTAssertTrue(fen.contains("K"), "king must win collisions")
        XCTAssertFalse(fen.contains("Q") && !fen.contains("K"), "queen must not overwrite king")
    }

    func testFenBuilder_castlingRightsFromPlacement() {
        let b = FenBuilder()
        var ps: [Prediction] = []
        // White K at e1, rooks at a1 and h1 → KQ
        ps.append(pred("e", 1, "w-king"))
        ps.append(pred("a", 1, "w-rook"))
        ps.append(pred("h", 1, "w-rook"))
        // Black k at e8, rooks at a8 and h8 → kq
        ps.append(pred("e", 8, "b-king"))
        ps.append(pred("a", 8, "b-rook"))
        ps.append(pred("h", 8, "b-rook"))
        let fen = b.fen(from: ps, imageSize: size)
        XCTAssertTrue(fen.contains(" KQkq ") || fen.contains(" KQkq-") || fen.contains(" KQkq"), "castling flags should be KQkq for start-like placement: \(fen)")
    }
}
