import Foundation
import CoreGraphics
import UIKit
import OSLog

private let fenLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                            category: "FenBuilder")

/// Builds a FEN string from Roboflow predictions on an 800x800 cropped board image
struct FenBuilder {

    /// Create a FEN from raw predictions and the cropped image size.
    /// - Note: Coordinates are interpreted like the Python version:
    ///         file = Int(x / (W/8)), rank = 7 - Int(y / (H/8)), origin at top-left.
    func fen(from predictions: [Prediction], imageSize: CGSize) -> String {
        let SQUARE: CGFloat = imageSize.width / 8.0

        // MARK: - helpers

        // Robust parser for class labels like "w-king", "white-king", "b-queen-v2"
        func parseClass(_ cls: String) -> (color: String, piece: String)? {
            let tokens = cls.split(separator: "-").map { $0.lowercased() }
            // color first (remember its index so piece parser doesn’t reuse "b" as bishop)
            var color: String?
            var colorIdx: Int?
            for (i, t) in tokens.enumerated() {
                if t == "w" || t == "white" { color = "w"; colorIdx = i; break }
                if t == "b" || t == "black" { color = "b"; colorIdx = i; break }
            }
            // piece next (prefer full words, then single-letter aliases)
            var piece: String?
            for (i, t) in tokens.enumerated() where i != colorIdx {
                switch t {
                case "king":   piece = "k"
                case "queen":  piece = "q"
                case "rook":   piece = "r"
                case "bishop": piece = "b"
                case "knight": piece = "n"
                case "pawn":   piece = "p"
                default: break
                }
                if piece != nil { break }
            }
            if piece == nil {
                for (i, t) in tokens.enumerated() where i != colorIdx {
                    switch t {
                    case "k","q","r","b","n","p": piece = t
                    default: break
                    }
                    if piece != nil { break }
                }
            }
            guard let c = color, let p = piece else { return nil }
            return (c, p)
        }

        // Always clamp coordinates to the 0...7 grid so near-edge boxes aren't lost
        func square(forX x: CGFloat, y: CGFloat) -> String {
            let file = max(0, min(7, Int(x / SQUARE)))
            let row  = max(0, min(7, Int(y / SQUARE)))   // 0 (top) ... 7 (bottom)
            let fileChar = Character(UnicodeScalar(97 + file)!) // 'a'..'h'
            let rank = 7 - row                                 // ranks 8..1
            return "\(fileChar)\(rank + 1)"
        }

        // Piece priority when multiple predictions land in the same square
        @inline(__always)
        func priority(_ p: String) -> Int {
            switch p { case "k": return 5
                      case "q": return 4
                      case "r": return 3
                      case "b","n": return 2
                      case "p": return 1
                      default: return 0 }
        }

        struct Cand {
            let fenChar: Character  // 'K','Q','R','B','N','P' or lowercase
            let piece: String       // "k","q","r","b","n","p"
            let conf: CGFloat       // confidence (0...1) if available
            let area: CGFloat       // bbox area as fallback tiebreaker
            let raw: String         // original class string
        }

        // MARK: - 1) group predictions per square + remember king targets
        var bySquare: [String: [Cand]] = [:]
        var whiteKingTarget: String?
        var blackKingTarget: String?

        for p in predictions {
            guard let parsed = parseClass(p.class) else { continue }
            let sq = square(forX: p.x, y: p.y)

            var ch = Character(parsed.piece)           // 'k','q',...
            if parsed.color == "w" {                   // uppercase for white
                ch = Character(String(ch).uppercased())
            }

            let conf = p.confidence ?? 0
            let area = p.width * p.height
            let cand = Cand(fenChar: ch, piece: parsed.piece, conf: conf, area: area, raw: p.class)
            bySquare[sq, default: []].append(cand)

            if parsed.piece == "k" {
                if parsed.color == "w" {
                    whiteKingTarget = sq
                    fenLog.info("w-king center (\(Int(p.x)),\(Int(p.y))) → \(sq)")
                } else {
                    blackKingTarget = sq
                    fenLog.info("b-king center (\(Int(p.x)),\(Int(p.y))) → \(sq)")
                }
            }
        }

        // MARK: - 2) choose best candidate per square (king > ... > pawn, then confidence, then area)
        var pieceMap: [String: Character] = [:]
        for (sq, cands) in bySquare {
            let best = cands.max { a, b in
                if priority(a.piece) != priority(b.piece) {
                    return priority(a.piece) < priority(b.piece)
                }
                if a.conf != b.conf { return a.conf < b.conf }
                return a.area < b.area
            }!
            if cands.count > 1 {
                let desc = cands
                    .map { "\($0.raw)[\($0.piece) c:\(String(format: "%.3f", Double($0.conf))) a:\(Int($0.area))]" }
                    .joined(separator: " | ")
                fenLog.debug("Collision @\(sq): \(desc).  → chose \(best.raw) → \(best.fenChar)")
            }
            pieceMap[sq] = best.fenChar
        }

        // MARK: - 3) force-place kings if detected but missing after collisions
        let boardBefore = boardString(from: pieceMap)
        let hasWhiteK = boardBefore.contains("K")
        let hasBlackk = boardBefore.contains("k")
        if !hasWhiteK, let sq = whiteKingTarget {
            fenLog.error("White king detected but missing; forcing K at \(sq).")
            pieceMap[sq] = "K"
        }
        if !hasBlackk, let sq = blackKingTarget {
            fenLog.error("Black king detected but missing; forcing k at \(sq).")
            pieceMap[sq] = "k"
        }

        // MARK: - 4) build board rows 8→1
        let board = boardString(from: pieceMap)

        // MARK: - 5) compute castling rights only if on starting squares (avoids invalid FEN)
        let castling = castlingRights(from: pieceMap)

        // Final FEN (side-to-move defaults to White; ep field '-')
        let fen = "\(board) w \(castling) - 0 1"

        // Sanity log checking only the board portion (not 'KQkq')
        let boardHasK = board.contains("K")
        let boardHask = board.contains("k")
        if !boardHasK || !boardHask {
            fenLog.error("FEN board missing king(s) → white=\(boardHasK), black=\(boardHask). FEN=\(fen, privacy: .public)")
        } else {
            fenLog.info("FEN OK (both kings present on board).")
        }
        return fen
    }

    // MARK: - helpers

    private func boardString(from pieceMap: [String: Character]) -> String {
        var rows: [String] = []
        for rank in (1...8).reversed() { // 8→1
            var row = ""
            var empty = 0
            for file in 0..<8 {
                let fileChar = Character(UnicodeScalar(97 + file)!) // 'a'..'h'
                let key = "\(fileChar)\(rank)"
                if let ch = pieceMap[key] {
                    if empty > 0 { row.append(String(empty)); empty = 0 }
                    row.append(ch)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { row.append(String(empty)) }
            rows.append(row)
        }
        return rows.joined(separator: "/")
    }

    /// Determine castling rights from piece placement only.
    /// Includes 'K' if K at e1 and R at h1; 'Q' if K at e1 and R at a1; similarly 'k','q' for black.
    private func castlingRights(from pieceMap: [String: Character]) -> String {
        var rights = ""

        // White
        if pieceMap["e1"] == "K" {
            if pieceMap["h1"] == "R" { rights.append("K") }
            if pieceMap["a1"] == "R" { rights.append("Q") }
        }
        // Black
        if pieceMap["e8"] == "k" {
            if pieceMap["h8"] == "r" { rights.append("k") }
            if pieceMap["a8"] == "r" { rights.append("q") }
        }

        return rights.isEmpty ? "-" : rights
    }
}
