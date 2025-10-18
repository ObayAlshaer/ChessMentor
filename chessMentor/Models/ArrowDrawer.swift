// ArrowDrawer.swift
import UIKit

struct ArrowDrawer {
    func draw(on image: UIImage, uci: String) -> UIImage {
        guard uci.count >= 4 else { return image }

        let src = String(uci.prefix(2))
        let dst = String(uci.dropFirst(2).prefix(2))

        func center(of square: String, size: CGSize) -> CGPoint {
            let fileChar = square.first!
            let rankChar = square.last!
            let file = Int(fileChar.asciiValue! - Character("a").asciiValue!) // 0..7
            let rank = Int(String(rankChar))!                                  // 1..8
            let sq = size.width / 8.0
            let x = (CGFloat(file) + 0.5) * sq
            let y = (CGFloat(8 - rank) + 0.5) * sq
            return CGPoint(x: x, y: y)
        }

        let size = image.size
        let p1 = center(of: src, size: size)
        let p2 = center(of: dst, size: size)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            let cg = ctx.cgContext
            cg.setLineWidth(6)
            cg.setStrokeColor(UIColor.systemRed.cgColor)
            cg.setLineCap(.round)
            drawArrow(context: cg, from: p1, to: p2, tipLength: 18)
        }
    }

    private func drawArrow(context: CGContext, from start: CGPoint, to end: CGPoint, tipLength: CGFloat) {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        // Arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        let tip1 = CGPoint(x: end.x - tipLength * cos(angle - .pi/6),
                           y: end.y - tipLength * sin(angle - .pi/6))
        let tip2 = CGPoint(x: end.x - tipLength * cos(angle + .pi/6),
                           y: end.y - tipLength * sin(angle + .pi/6))

        context.beginPath()
        context.move(to: end)
        context.addLine(to: tip1)
        context.move(to: end)
        context.addLine(to: tip2)
        context.strokePath()
    }
}
