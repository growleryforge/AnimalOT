import SwiftUI

// MARK: - A drawn chocolate-chip cookie (nicer than a flat emoji)
//
// Scales to its frame. Glows + a dashed "halo" when it's ready to be pounced, so
// "now!" is unmistakable.

struct CookieView: View {
    var glow: Bool = false

    // Fixed chip layout (unit coordinates 0...1), so it looks hand-placed.
    private let chips: [CGPoint] = [
        CGPoint(x: 0.32, y: 0.30), CGPoint(x: 0.64, y: 0.26),
        CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.28, y: 0.62),
        CGPoint(x: 0.70, y: 0.60), CGPoint(x: 0.46, y: 0.74),
        CGPoint(x: 0.74, y: 0.42)
    ]

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                if glow {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.86, blue: 0.4))
                        .blur(radius: s * 0.18)
                        .opacity(0.8)
                        .scaleEffect(1.25)
                }

                Canvas { ctx, size in
                    let r = min(size.width, size.height) / 2
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let body = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))

                    // Dough with a soft radial bake.
                    ctx.fill(body, with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.91, green: 0.73, blue: 0.45),
                            Color(red: 0.78, green: 0.55, blue: 0.30)
                        ]),
                        center: CGPoint(x: c.x - r * 0.2, y: c.y - r * 0.25),
                        startRadius: r * 0.1, endRadius: r * 1.05))

                    // Darker baked rim.
                    ctx.stroke(body, with: .color(Color(red: 0.55, green: 0.36, blue: 0.18)),
                               lineWidth: r * 0.07)

                    // Chocolate chips.
                    for chip in chips {
                        let cr = r * 0.16
                        let p = CGPoint(x: chip.x * size.width, y: chip.y * size.height)
                        let chipRect = CGRect(x: p.x - cr, y: p.y - cr, width: cr * 2, height: cr * 2)
                        ctx.fill(Path(ellipseIn: chipRect),
                                 with: .color(Color(red: 0.30, green: 0.18, blue: 0.10)))
                        // tiny shine on each chip
                        let hr = cr * 0.4
                        let hRect = CGRect(x: p.x - cr * 0.5, y: p.y - cr * 0.6, width: hr, height: hr)
                        ctx.fill(Path(ellipseIn: hRect), with: .color(.white.opacity(0.35)))
                    }
                }
                .frame(width: s, height: s)

                if glow {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: s * 0.04, dash: [s * 0.10, s * 0.07]))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: s * 1.18, height: s * 1.18)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
