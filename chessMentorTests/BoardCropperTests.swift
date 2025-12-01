import XCTest
@testable import chessMentor
import UIKit
import Foundation

// MARK: - URLProtocol stub for Roboflow

private final class RFStubProtocol: URLProtocol {
    static var statusCode: Int = 200
    static var responseBody: String = #"{"predictions":[],"image":{"width":800,"height":800}}"#

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests (BoardCropper uses URLSession.shared)
        true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let data = Self.responseBody.data(using: .utf8)!
        let resp = HTTPURLResponse(
            url: request.url ?? URL(string: "https://detect.roboflow.com")!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type":"application/json"]
        )!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

// MARK: - Test helpers

private func blankImage(_ size: CGSize) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

/// Convenience for a single prediction JSON
private func predictionJSON(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                            conf: CGFloat = 0.9,
                            imgW: CGFloat = 800, imgH: CGFloat = 800) -> String {
    return """
    {"predictions":[{"x":\(x),"y":\(y),"width":\(w),"height":\(h),"class":"board","confidence":\(conf)}],
     "image":{"width":\(imgW),"height":\(imgH)}}
    """
}

// MARK: - Tests

final class BoardCropperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(RFStubProtocol.self)
        // default OK body (empty preds) — tests will override per-case
        RFStubProtocol.statusCode = 200
        RFStubProtocol.responseBody = #"{"predictions":[],"image":{"width":800,"height":800}}"#
    }

    override func tearDown() {
        URLProtocol.unregisterClass(RFStubProtocol.self)
        super.tearDown()
    }

    /// Basic success path: centered square detection, should return 800×800 image.
    func testCrop_Succeeds_WithCenteredSquare() throws {
        // Source 800×800 so server "image" size matches → no scaling needed.
        let src = blankImage(CGSize(width: 800, height: 800))
        RFStubProtocol.responseBody = predictionJSON(x: 400, y: 400, w: 600, h: 600, conf: 0.95)

        let cropper = BoardCropper(apiKey: "TEST",
                                   boardModelId: "chessboard-detection-x5kxd/1",
                                   confidence: 0.25,
                                   overlap: 0.20,
                                   maxLongSide: 1280,
                                   padFrac: 0.05,
                                   enforceSquare: true)

        let out = try cropper.crop(src)
        XCTAssertEqual(Int(out.size.width), 800)
        XCTAssertEqual(Int(out.size.height), 800)
    }

    /// Non-square detection should be expanded to square when enforceSquare = true.
    func testCrop_ExpandsToSquare_WhenRectNonSquare() throws {
        let src = blankImage(CGSize(width: 800, height: 800))
        // Tall rectangle
        RFStubProtocol.responseBody = predictionJSON(x: 400, y: 400, w: 300, h: 600, conf: 0.92)

        let cropper = BoardCropper(apiKey: "TEST",
                                   boardModelId: "chessboard-detection-x5kxd/1",
                                   confidence: 0.25,
                                   overlap: 0.20,
                                   padFrac: 0.00,        // make the math simpler
                                   enforceSquare: true)

        let out = try cropper.crop(src)
        XCTAssertEqual(Int(out.size.width), 800)
        XCTAssertEqual(Int(out.size.height), 800, "Output must be square after expansion")
    }

    /// Detection near the edge should be clamped safely and still succeed.
    func testCrop_ClampsRect_AtImageBounds() throws {
        let src = blankImage(CGSize(width: 800, height: 800))
        // Box close to top-left; with padding it would run out of bounds → clamp should handle it.
        RFStubProtocol.responseBody = predictionJSON(x: 60, y: 60, w: 120, h: 120, conf: 0.90)

        let cropper = BoardCropper(apiKey: "TEST",
                                   padFrac: 0.10,       // force padding beyond bounds
                                   enforceSquare: true)

        let out = try cropper.crop(src)
        XCTAssertEqual(Int(out.size.width), 800)
        XCTAssertEqual(Int(out.size.height), 800)
        // No throw == clamp worked.
    }

    /// No predictions from Roboflow ⇒ CropError.noDetection
    func testCrop_NoDetection_Throws() {
        let src = blankImage(CGSize(width: 800, height: 800))
        RFStubProtocol.responseBody = #"{"predictions":[],"image":{"width":800,"height":800}}"#

        let cropper = BoardCropper(apiKey: "TEST")

        do {
            _ = try cropper.crop(src)
            XCTFail("Expected noDetection error")
        } catch let e as BoardCropper.CropError {
            XCTAssertEqual(e, .noDetection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Server reports a different image size (RF will rescale coords). Crop must still succeed.
    func testCrop_WithServerScaling_Succeeds() throws {
        // Source is 1600×1600; BoardCropper downscales to <= maxLongSide (defaults to 1280),
        // but we control the server "image" size via stub to 800×800. RoboflowClient scales to the UI image size.
        let src = blankImage(CGSize(width: 1600, height: 1600))
        RFStubProtocol.responseBody = predictionJSON(x: 400, y: 400, w: 600, h: 600,
                                                     conf: 0.95, imgW: 800, imgH: 800)

        let cropper = BoardCropper(apiKey: "TEST") // uses defaults: maxLongSide 1280, enforceSquare true

        let out = try cropper.crop(src)
        XCTAssertEqual(Int(out.size.width), 800)
        XCTAssertEqual(Int(out.size.height), 800)
    }

    /// If the clamped rect would be too small (<=2 px after clamp), treat as noDetection.
    func testCrop_TooSmallAfterClamp_ThrowsNoDetection() {
        // Small source makes math simple; server "image" matches it.
        let src = blankImage(CGSize(width: 100, height: 100))

        // Tiny detection near the top-left corner.
        // No padding + no square expansion => rect remains ~1x1 after clamp.
        RFStubProtocol.responseBody = predictionJSON(
            x: 0.5, y: 0.5,   // very close to (0,0)
            w: 1.0, h: 1.0,
            conf: 0.99,
            imgW: 100, imgH: 100
        )

        // Disable the two expansions that prevented the error before.
        let cropper = BoardCropper(
            apiKey: "TEST",
            padFrac: 0.0,
            enforceSquare: false
        )

        do {
            _ = try cropper.crop(src)
            XCTFail("Expected noDetection error for too-small rect")
        } catch let e as BoardCropper.CropError {
            XCTAssertEqual(e, .noDetection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}
