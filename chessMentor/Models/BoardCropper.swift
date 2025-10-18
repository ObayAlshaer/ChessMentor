import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import OSLog

private let cropLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "chessmentor",
                             category: "BoardCropper")

final class BoardCropper {
    private let context = CIContext()
    private let outputSize = CGSize(width: 800, height: 800)

    enum CropError: Int, LocalizedError {
        case badImage = 0, noRectangleFound = 1, cantWarp = 2, cantRender = 3
        var errorDescription: String? {
            switch self {
            case .badImage:         return "Could not create CIImage from input."
            case .noRectangleFound: return "No board-like rectangle found by Vision."
            case .cantWarp:         return "Perspective correction failed."
            case .cantRender:       return "Failed to render corrected image."
            }
        }
    }

    func crop(_ image: UIImage) throws -> UIImage {
        let src = image.fixedOrientationUp()
        cropLog.info("Crop start. input=\(Int(src.size.width))x\(Int(src.size.height))")
        guard let cg = src.cgImage else { throw CropError.badImage }
        let ci = CIImage(cgImage: cg)

        // 1) detect rectangle
        let req = VNDetectRectanglesRequest()
        req.minimumConfidence = 0.5
        req.maximumObservations = 5
        req.minimumAspectRatio = 0.70
        req.maximumAspectRatio = 1.30
        req.minimumSize = 0.20

        try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([req])
        guard let r = (req.results as? [VNRectangleObservation])?.first else {
            cropLog.error("No rectangle found"); throw CropError.noRectangleFound
        }

        // 2) convert normalized → pixel coords
        let pts: [CGPoint] = [
            r.topLeft.applying(src.size),
            r.topRight.applying(src.size),
            r.bottomRight.applying(src.size),
            r.bottomLeft.applying(src.size),
        ]

        // 3) Python-like ordering of corners
        let ordered = orderPoints(pts) // [tl, tr, br, bl]
        let tl = ordered[0], tr = ordered[1], br = ordered[2], bl = ordered[3]
        cropLog.debug("TL(\(Int(tl.x)),\(Int(tl.y))) TR(\(Int(tr.x)),\(Int(tr.y))) BR(\(Int(br.x)),\(Int(br.y))) BL(\(Int(bl.x)),\(Int(bl.y)))")

        // 4) CIPerspectiveCorrection with explicit TL/TR/BR/BL → 800x800
        let f = CIFilter.perspectiveCorrection()
        f.inputImage  = ci
        f.topLeft     = br
        f.topRight    = bl
        f.bottomRight = tl
        f.bottomLeft  = tr
        guard let corrected = f.outputImage else { throw CropError.cantWarp }

        guard let correctedCG = context.createCGImage(corrected, from: corrected.extent) else {
            throw CropError.cantRender
        }
        let correctedUI = UIImage(cgImage: correctedCG, scale: 1, orientation: .up)
        let scaled = correctedUI.scaledTo(size: outputSize).flippedHorizontally()
        cropLog.info("Crop success. output=\(Int(scaled.size.width))x\(Int(scaled.size.height))")
        return scaled
    }

    /// Mirrors Python's `order_points` (sum/diff trick) to fix orientation.
    private func orderPoints(_ pts: [CGPoint]) -> [CGPoint] {
        precondition(pts.count == 4)
        // sum = x+y; min→TL, max→BR
        let sums = pts.map { $0.x + $0.y }
        let tl = pts[sums.firstIndex(of: sums.min()!)!]
        let br = pts[sums.firstIndex(of: sums.max()!)!]
        // diff = x - y; min→TR, max→BL  (note: Python uses y - x; equivalent up to sign)
        let diffs = pts.map { $0.y - $0.x }
        let tr = pts[diffs.firstIndex(of: diffs.min()!)!]
        let bl = pts[diffs.firstIndex(of: diffs.max()!)!]
        return [tl, tr, br, bl]
    }
}

private extension CGPoint {
    func applying(_ size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: (1 - y) * size.height)
    }
}

private extension UIImage {
    func fixedOrientationUp() -> UIImage {
        if imageOrientation == .up { return self }
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    func scaledTo(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
private extension UIImage {
    func flippedHorizontally() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: size.width, y: 0)
            ctx.cgContext.scaleBy(x: -1, y: 1)
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
