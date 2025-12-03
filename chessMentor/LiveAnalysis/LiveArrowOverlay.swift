import SwiftUI

/// SwiftUI view that draws a visual arrow on top of the camera preview,
/// mapping cropped board coordinates into the rendered screen using aspect-fill math. :contentReference[oaicite:31]{index=31}
struct LiveArrowOverlay: View {
    /// Data describing arrow endpoints and coordinate transforms. Nil means nothing to draw. :contentReference[oaicite:32]{index=32}
    let arrow: LiveArrow?

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard let a = arrow else { return }

                // Establish aspect-fill transform from camera source space to preview view space. :contentReference[oaicite:33]{index=33}
                let viewW = size.width, viewH = size.height
                let imgW = a.sourceSize.width, imgH = a.sourceSize.height
                guard imgW > 1, imgH > 1 else { return }

                let scale = max(viewW / imgW, viewH / imgH)
                let drawnW = imgW * scale
                let drawnH = imgH * scale
                let offX = (viewW - drawnW) * 0.5
                let offY = (viewH - drawnH) * 0.5

                /// Converts a point from cropped board coordinates into screen coordinates. :contentReference[oaicite:34]{index=34}
                func mapCroppedToView(_ p: CGPoint) -> CGPoint {
                    // Convert cropped (800×800) space into original source image coordinates. :contentReference[oaicite:35]{index=35}
                    let sx = a.cropRect.width  / a.boardSize.width
                    let sy = a.cropRect.height / a.boardSize.height
                    let srcX = a.cropRect.origin.x + p.x * sx
                    let srcY = a.cropRect.origin.y + p.y * sy

                    // Convert source coordinates to on-screen coordinates using aspect fill. :contentReference[oaicite:36]{index=36}
                    return CGPoint(x: offX + srcX * scale, y: offY + srcY * scale)
                }

                // Final screen points for arrow start/end. :contentReference[oaicite:37]{index=37}
                let p1 = mapCroppedToView(a.p1Cropped)
                let p2 = mapCroppedToView(a.p2Cropped)

                // Shared stroke style to ensure rounded line caps and joins. :contentReference[oaicite:38]{index=38}
                let style = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)

                // Main arrow shaft. :contentReference[oaicite:39]{index=39}
                var shaft = Path()
                shaft.move(to: p1)
                shaft.addLine(to: p2)
                ctx.stroke(shaft, with: .color(.red), style: style)

                // Arrowhead calculation based on angle between p1 and p2. :contentReference[oaicite:40]{index=40}
                let tipLen: CGFloat = 18
                let angle = atan2(p2.y - p1.y, p2.x - p1.x)
                let tip1 = CGPoint(x: p2.x - tipLen * cos(angle - .pi/6),
                                   y: p2.y - tipLen * sin(angle - .pi/6))
                let tip2 = CGPoint(x: p2.x - tipLen * cos(angle + .pi/6),
                                   y: p2.y - tipLen * sin(angle + .pi/6))

                // Draw arrowhead lines. :contentReference[oaicite:41]{index=41}
                var head = Path()
                head.move(to: p2)
                head.addLine(to: tip1)
                head.move(to: p2)
                head.addLine(to: tip2)
                ctx.stroke(head, with: .color(.red), style: style)
            }
        }
        .allowsHitTesting(false) // Overlay is visual only; do not block gestures. :contentReference[oaicite:42]{index=42}
    }
}
