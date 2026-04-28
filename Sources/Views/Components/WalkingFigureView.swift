import SwiftUI

/// Animated stick-figure that walks continuously using Canvas + TimelineView.
struct WalkingFigureView: View {
    var color: Color = Color.accentColor
    /// Cadence in full cycles per second (≈ 0.9 gives ~108 steps/min).
    var cadence: Double = 0.9

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // phase drives leg swing: 0 → max forward, π → max back
                let phase = sin(t * cadence * 2 * .pi) * 0.40
                draw(ctx, size: size, phase: phase)
            }
        }
    }

    // MARK: - Drawing

    private func draw(_ ctx: GraphicsContext, size: CGSize, phase: Double) {
        let cx   = size.width  / 2
        let shade = GraphicsContext.Shading.color(color)
        let style = StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)

        // — Vertical layout —
        let headR:    CGFloat = 5.5
        let headCY:   CGFloat = headR + 1          // 6.5
        let neckY     = headCY + headR              // 12
        let shoulderY = neckY  + 2                 // 14
        let hipY:     CGFloat = neckY  + 17        // 29
        let legLen:   CGFloat = 15
        let armLen:   CGFloat = 9

        // Head
        var head = Path()
        head.addEllipse(in: CGRect(x: cx - headR, y: headCY - headR,
                                   width: headR * 2, height: headR * 2))
        ctx.stroke(head, with: shade, style: style)

        // Spine
        ctx.stroke(seg(pt(cx, neckY), pt(cx, hipY)), with: shade, style: style)

        // Legs — left leads when phase > 0, right leads when phase < 0
        ctx.stroke(seg(pt(cx, hipY), swingEnd(cx, hipY, angle:  phase, len: legLen)),
                   with: shade, style: style)
        ctx.stroke(seg(pt(cx, hipY), swingEnd(cx, hipY, angle: -phase, len: legLen)),
                   with: shade, style: style)

        // Arms — opposite to same-side leg (natural counterswing)
        let armPhase = phase * 0.65
        ctx.stroke(seg(pt(cx, shoulderY), armEnd(cx, shoulderY, angle: -armPhase, len: armLen)),
                   with: shade, style: style)
        ctx.stroke(seg(pt(cx, shoulderY), armEnd(cx, shoulderY, angle:  armPhase, len: armLen)),
                   with: shade, style: style)
    }

    /// End-point of a leg swinging around the hip/shoulder pivot.
    private func swingEnd(_ cx: CGFloat, _ originY: CGFloat,
                          angle: Double, len: CGFloat) -> CGPoint {
        CGPoint(x: cx + CGFloat(sin(angle)) * len,
                y: originY + CGFloat(cos(angle)) * len)
    }

    /// Arms hang slightly forward; the swing is mostly horizontal.
    private func armEnd(_ cx: CGFloat, _ originY: CGFloat,
                        angle: Double, len: CGFloat) -> CGPoint {
        CGPoint(x: cx + CGFloat(sin(angle)) * len,
                y: originY + len * 0.65)
    }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private func seg(_ a: CGPoint, _ b: CGPoint) -> Path {
        var p = Path(); p.move(to: a); p.addLine(to: b); return p
    }
}
