import XCTest
@testable import chessMentor
import UIKit

final class RoboflowClientScalingTests: XCTestCase {

    // Mock URLProtocol to stub network
    class StubProtocol: URLProtocol {
        static var responseJSON: String = ""
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            let data = Self.responseJSON.data(using: .utf8)!
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {}
    }

    func testScaling_fromServerSpaceToUIImage() async throws {
        // server response: image 1024x1024, one box at (512,512,w=256,h=256)
        StubProtocol.responseJSON = """
        { "predictions":[{ "x":512, "y":512, "width":256, "height":256, "class":"w-queen", "confidence":0.9 }], "image": { "width":1024, "height":1024 } }
        """
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: config)

        let client = RoboflowClient(apiKey: "TEST", modelId: "any/1", confidence: 0.25, overlap: 0.2, session: session)

        // 800x800 blank image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 800, height: 800), true, 1)
        UIColor.white.setFill(); UIBezierPath(rect: CGRect(x: 0, y: 0, width: 800, height: 800)).fill()
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let preds = try await client.detect(on: img)
        XCTAssertEqual(preds.count, 1)
        let p = preds[0]
        // scaled by 800/1024 = 0.78125 → x=400, y=400, w=200, h=200
        XCTAssertEqual(round(p.x), 400)
        XCTAssertEqual(round(p.y), 400)
        XCTAssertEqual(round(p.width), 200)
        XCTAssertEqual(round(p.height), 200)
    }
}
