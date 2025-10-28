import Foundation

struct StockfishBestMoveProvider: BestMoveProvider {
    private let service = StockfishService()

    func bestMove(for fen: String) async throws -> EngineResult {
        let r = try await service.bestMove(for: fen)
        let eval = Double(r.evaluation ?? "")
        return EngineResult(uci: r.best_move_uci,
                            san: r.best_move_san,
                            evaluation: eval,
                            pv: nil)
    }
}
