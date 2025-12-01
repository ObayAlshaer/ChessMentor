import SwiftUI

/// Draws the arrow on top of the camera preview using aspect-fill math
/// to map source-image coordinates into the preview's view coordinates.
struct LiveArrowOverlay: View {
    let arrow: LiveArrow?

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard let a = arrow else { return }

                // Aspect-fill transform: source image -> view
                let viewW = size.width, viewH = size.height
                let imgW = a.sourceSize.width, imgH = a.sourceSize.height
                guard imgW > 1, imgH > 1 else { return }

                let scale = max(viewW / imgW, viewH / imgH)
                let drawnW = imgW * scale
                let drawnH = imgH * scale
                let offX = (viewW - drawnW) * 0.5
                let offY = (viewH - drawnH) * 0.5

                func mapCroppedToView(_ p: CGPoint) -> CGPoint {
                    // Cropped (800x800) -> source space via crop rect
                    let sx = a.cropRect.width  / a.boardSize.width
                    let sy = a.cropRect.height / a.boardSize.height
                    let srcX = a.cropRect.origin.x + p.x * sx
                    let srcY = a.cropRect.origin.y + p.y * sy
                    // Source -> view (aspect fill)
                    return CGPoint(x: offX + srcX * scale, y: offY + srcY * scale)
                }

                let p1 = mapCroppedToView(a.p1Cropped)
                let p2 = mapCroppedToView(a.p2Cropped)

                // Common stroke style (this fixes the `.round` inference error)
                let style = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)

                // Main arrow line
                var shaft = Path()
                shaft.move(to: p1)
                shaft.addLine(to: p2)
                ctx.stroke(shaft, with: .color(.red), style: style)

                // Arrow head
                let tipLen: CGFloat = 18
                let angle = atan2(p2.y - p1.y, p2.x - p1.x)
                let tip1 = CGPoint(x: p2.x - tipLen * cos(angle - .pi/6),
                                   y: p2.y - tipLen * sin(angle - .pi/6))
                let tip2 = CGPoint(x: p2.x - tipLen * cos(angle + .pi/6),
                                   y: p2.y - tipLen * sin(angle + .pi/6))

                var head = Path()
                head.move(to: p2)
                head.addLine(to: tip1)
                head.move(to: p2)
                head.addLine(to: tip2)
                ctx.stroke(head, with: .color(.red), style: style)
            }
        }
        .allowsHitTesting(false)
    }
}
