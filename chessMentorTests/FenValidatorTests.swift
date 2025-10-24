import XCTest
@testable import chessMentor

final class FENValidatorTests: XCTestCase {

    var validator: FENValidator!

    override func setUp() {
        super.setUp()
        validator = FENValidator()
    }

    // MARK: - Helpers

    private func assertValid(_ fen: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let res = validator.isLikelyValid(fen)
        XCTAssertTrue(res.ok, "Expected valid, got: \(res.reason ?? "nil")", file: file, line: line)
    }

    private func assertInvalid(_ fen: String, reasonContains expected: String,
                               file: StaticString = #filePath, line: UInt = #line) {
        let res = validator.isLikelyValid(fen)
        XCTAssertFalse(res.ok, "Expected invalid", file: file, line: line)
        XCTAssertTrue(res.reason?.contains(expected) ?? false,
                      "Reason mismatch. got: \(res.reason ?? "nil")",
                      file: file, line: line)
    }

    // MARK: - Tests

    func testValid_StartPosition() {
        assertValid("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }

    func testValid_KingsOnlyCentered() {
        assertValid("4k3/8/8/8/8/8/8/4K3 w - - 0 1")
    }

    func testInvalid_NotEightRanks() {
        // Only 7 ranks
        assertInvalid("8/8/8/8/8/8/8 w - - 0 1", reasonContains: "8 ranks")
    }

    func testInvalid_RankSumTooMany() {
        // First rank sums to 9 (contains '9')
        assertInvalid("9/8/8/8/8/8/8/7 w - - 0 1", reasonContains: "sum to 8")
    }

    func testInvalid_RankSumTooFew() {
        // First rank sums to 7
        assertInvalid("7/8/8/8/8/8/8/8 w - - 0 1", reasonContains: "sum to 8")
    }

    func testInvalid_MissingWhiteKing() {
        assertInvalid("4k3/8/8/8/8/8/8/8 w - - 0 1", reasonContains: "Missing king")
    }

    func testInvalid_MissingBlackKing() {
        assertInvalid("8/8/8/8/8/8/8/4K3 w - - 0 1", reasonContains: "Missing king")
    }

    func testInvalid_EmptyFEN() {
        assertInvalid("", reasonContains: "Empty FEN")
    }

    func testValid_IgnoresOtherFields() {
        // Validator only checks the board part; extra fields are ignored.
        assertValid("4k3/8/8/8/8/8/8/4K3 b KQ - 12 34")
    }
}
