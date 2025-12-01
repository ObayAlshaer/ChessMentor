import Foundation

struct FENValidator {
    func isLikelyValid(_ fen: String) -> (ok: Bool, reason: String?) {
        let parts = fen.split(separator: " ")
        guard let board = parts.first else { return (false, "Empty FEN") }
        let ranks = board.split(separator: "/")
        guard ranks.count == 8 else { return (false, "FEN must have 8 ranks") }

        var hasWhiteK = false, hasBlackK = false
        for r in ranks {
            var count = 0
            for ch in r {
                if let n = ch.wholeNumberValue { count += n }
                else {
                    count += 1
                    if ch == "K" { hasWhiteK = true }
                    if ch == "k" { hasBlackK = true }
                }
            }
            if count != 8 { return (false, "Rank '\(r)' does not sum to 8 squares") }
        }
        if !hasWhiteK || !hasBlackK {
            return (false, "Missing king(s): white=\(hasWhiteK), black=\(hasBlackK)")
        }
        return (true, nil)
    }
}
