import XCTest
@testable import chessMentor

final class StockfishServiceTests: XCTestCase {

    // Simple URLProtocol stub to intercept network calls.
    final class StubProtocol: URLProtocol {
        static var status = 200
        static var body = #"{"best_move_uci":"e2e4","best_move_san":"e4","evaluation":"0.31"}"# // <- eval as STRING

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let data = Self.body.data(using: .utf8)!
            let resp = HTTPURLResponse(
                url: request.url!,
                statusCode: Self.status,
                httpVersion: nil,
                headerFields: ["Content-Type":"application/json"]
            )!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: config)
    }

    func testBestMoveDecode_success() async throws {
        // Given a good JSON body (snake_case; evaluation as STRING)
        StubProtocol.status = 200
        StubProtocol.body = #"{"best_move_uci":"e2e4","best_move_san":"e4","evaluation":"0.31"}"#

        let svc = StockfishService(session: makeSession())

        // When
        let bm = try await svc.bestMove(for: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - - 0 1")

        // Then
        XCTAssertEqual(bm.best_move_uci, "e2e4")
        XCTAssertEqual(bm.best_move_san, "e4")
        // If your BestMove.evaluation is a String, you can optionally parse/ignore it in tests.
        // Here we just make sure it exists in the raw payload:
        // (No assertion on evaluation to keep this test model-agnostic.)
    }

    func testBestMove_httpErrorBubbles() async {
        // Given a non-200 with some body
        StubProtocol.status = 500
        StubProtocol.body = #"{"error":"boom"}"#

        let svc = StockfishService(session: makeSession())

        do {
            _ = try await svc.bestMove(for: "8/8/8/8/8/8/8/8 w - - 0 1")
            XCTFail("Expected error")
        } catch {
            // Your StockfishService.Err.http(status:body:) should surface here.
            // We just assert we got *an* error.
            XCTAssertTrue(true)
        }
    }
}
