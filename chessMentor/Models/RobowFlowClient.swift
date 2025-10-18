import Foundation
import UIKit
import OSLog
import CoreGraphics

private let rfLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                           category: "Roboflow")

// Your app-wide model used elsewhere

final class RoboflowClient {

    // Raw response structs from Roboflow (include image size for scaling)
    private struct RFResponse: Decodable {
        let predictions: [RFBox]
        let image: RFImageInfo?
    }
    private struct RFImageInfo: Decodable {
        let width: CGFloat
        let height: CGFloat
    }
    private struct RFBox: Decodable {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let `class`: String
        let confidence: CGFloat?
    }

    private let session: URLSession
    private let apiKey: String
    private let modelId: String
    private let confidence: Double
    private let overlap: Double

    /// Example modelId: "chessbot-v2/1"
    init(apiKey: String,
         modelId: String = "chessbot-v2/1",
         confidence: Double = 0.25,   // permissive like the Python SDK
         overlap: Double = 0.20,      // low NMS so adjacent pieces survive
         session: URLSession = .shared)
    {
        self.apiKey = apiKey
        self.modelId = modelId
        self.confidence = confidence
        self.overlap = overlap
        self.session = session
    }

    private var detectURL: URL {
        var comps = URLComponents(string: "https://detect.roboflow.com/\(modelId)")!
        comps.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "format", value: "json"),
            .init(name: "confidence", value: String(confidence)),
            .init(name: "overlap", value: String(overlap))
            // (Optional extras you can try later)
            // .init(name: "stroke", value: "2"),
            // .init(name: "labels", value: "on")
        ]
        return comps.url!
    }

    /// Detect using multipart/form-data upload, then **scale predictions** to the input image size.
    func detect(on image: UIImage) async throws -> [Prediction] {
        guard let jpeg = image.jpegData(compressionQuality: 0.92) else {
            throw Err.encode("Failed to encode JPEG")
        }

        var req = URLRequest(url: detectURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 30

        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = makeMultipartBody(boundary: boundary,
                                         fieldName: "file",
                                         filename: "image.jpg",
                                         mimeType: "image/jpeg",
                                         data: jpeg)

        rfLog.info("Roboflow request → \(self.detectURL.absoluteString, privacy: .public) (size=\(jpeg.count, privacy: .public) bytes)")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw Err.http(status: -1, body: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
            rfLog.error("Roboflow HTTP \(http.statusCode, privacy: .public) body=\(body, privacy: .public)")
            throw Err.http(status: http.statusCode, body: body)
        }

        // Decode raw response (with server-side image size)
        let raw = try JSONDecoder().decode(RFResponse.self, from: data)

        // Determine scale factors from server's coordinate space → our UIImage size
        let serverW = raw.image?.width ?? CGFloat(800)  // fall back harmlessly
        let serverH = raw.image?.height ?? CGFloat(800)
        let targetW = image.size.width
        let targetH = image.size.height
        let sx = targetW / max(serverW, 1)
        let sy = targetH / max(serverH, 1)

        rfLog.info("Scale RF→UI: server=\(Int(serverW))x\(Int(serverH)) target=\(Int(targetW))x\(Int(targetH))  sx=\(String(format: "%.3f", sx)) sy=\(String(format: "%.3f", sy))")

        // Map to your app's Prediction in the **correct pixel space**
        let scaled: [Prediction] = raw.predictions.map { b in
            Prediction(
                x: b.x * sx,
                y: b.y * sy,
                width: b.width * sx,
                height: b.height * sy,
                class: b.class,
                confidence: b.confidence
            )
        }

        rfLog.info("Roboflow OK. predictions=\(scaled.count, privacy: .public)")
        return scaled
    }

    // MARK: - Multipart helper

    private func makeMultipartBody(boundary: String,
                                   fieldName: String,
                                   filename: String,
                                   mimeType: String,
                                   data: Data) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    // MARK: - Errors

    enum Err: LocalizedError {
        case encode(String)
        case http(status: Int, body: String)

        var errorDescription: String? {
            switch self {
            case .encode(let m): return m
            case .http(let s, let body):
                let snippet = body.count > 300 ? String(body.prefix(300)) + "…" : body
                return "HTTP \(s): \(snippet)"
            }
        }
    }
}
