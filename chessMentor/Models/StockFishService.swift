import Foundation
import OSLog

private let sfLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                           category: "Stockfish")


final class StockfishService {
    private let session: URLSession
    private let endpoint = URL(string: "https://stockfish-api-jzrn.onrender.com/get-best-move")!

    init(session: URLSession = .shared) { self.session = session }

    enum Err: LocalizedError {
        case http(status: Int, body: String)
        case decode(String)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case .http(let status, let body):
                let snippet = body.count > 300 ? String(body.prefix(300)) + "…" : body
                return "HTTP \(status): \(snippet)"
            case .decode(let msg):
                return "Decode failed: \(msg)"
            case .transport(let msg):
                return "Transport error: \(msg)"
            }
        }
    }

    func bestMove(for fen: String) async throws -> BestMove {
        sfLog.info("Engine request (FEN) = \(fen, privacy: .public)")

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        struct Payload: Encodable { let fen: String }
        do {
            req.httpBody = try JSONEncoder().encode(Payload(fen: fen))
        } catch {
            throw Err.transport("Could not encode JSON: \(error.localizedDescription)")
        }

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                sfLog.error("No HTTPURLResponse")
                throw Err.transport("No HTTP response")
            }

            if !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
                sfLog.error("Engine HTTP \(http.statusCode, privacy: .public) body=\(body, privacy: .public)")
                throw Err.http(status: http.statusCode, body: body)
            }

            do {
                let best = try JSONDecoder().decode(BestMove.self, from: data)
                sfLog.info("Engine OK: UCI \(best.best_move_uci, privacy: .public) / SAN \(best.best_move_san, privacy: .public)")
                return best
            } catch {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
                sfLog.error("Engine decode failed: \(error.localizedDescription, privacy: .public) body=\(body, privacy: .public)")
                throw Err.decode(error.localizedDescription)
            }
        } catch {
            if let e = error as? Err { throw e }
            sfLog.error("Engine transport error: \(error.localizedDescription, privacy: .public)")
            throw Err.transport(error.localizedDescription)
        }
    }
}
