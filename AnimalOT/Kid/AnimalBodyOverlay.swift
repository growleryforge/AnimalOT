import SwiftUI

// MARK: - Animal features pinned to his live body
//
// Draws ears on his head, a snout on his nose, paws on hands/feet, and a tail from
// his hips — positioned from the Vision joints, tinted to the move's theme. Kept
// generic (rounded ears etc.) so any animal works without per-animal art. The
// point is that HE, on screen, becomes the animal while he moves.

struct AnimalBodyOverlay: View {
    let points: [String: CGPoint]     // normalized top-left
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            func pt(_ key: String) -> CGPoint? {
                guard let p = points[key] else { return nil }
                return CGPoint(x: p.x * s.width, y: p.y * s.height)
            }

            // Head center + scale.
            let earL = pt("leftEar"); let earR = pt("rightEar")
            let eyeL = pt("leftEye"); let eyeR = pt("rightEye")
            let nose = pt("nose")
            let head = nose ?? midpoint(earL, earR) ?? midpoint(eyeL, eyeR)
            let headW = spread(earL, earR) ?? (spread(eyeL, eyeR).map { $0 * 2.2 }) ?? (s.width * 0.14)

            ZStack {
                // Ears
                if let head {
                    ear(at: CGPoint(x: head.x - headW * 0.5, y: head.y - headW * 0.7), size: headW * 0.55)
                    ear(at: CGPoint(x: head.x + headW * 0.5, y: head.y - headW * 0.7), size: headW * 0.55)
                }
                // Snout
                if let nose {
                    Circle().fill(color.opacity(0.9))
                        .frame(width: headW * 0.35, height: headW * 0.35)
                        .overlay(Circle().fill(.black.opacity(0.6))
                            .frame(width: headW * 0.16, height: headW * 0.16))
                        .position(nose)
                }
                // Paws
                paw(pt("leftWrist"), headW)
                paw(pt("rightWrist"), headW)
                paw(pt("leftAnkle"), headW)
                paw(pt("rightAnkle"), headW)

                // Tail from the hips.
                if let root = pt("root") ?? midpoint(pt("leftHip"), pt("rightHip")) {
                    Capsule()
                        .fill(color)
                        .frame(width: headW * 0.28, height: headW * 1.4)
                        .rotationEffect(.degrees(35))
                        .position(x: root.x - headW * 0.4, y: root.y + headW * 0.6)
                        .opacity(0.92)
                }
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.08), value: points.count)
    }

    private func ear(at p: CGPoint, size: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(color)
                .frame(width: size, height: size * 1.3)
            Ellipse().fill(color.opacity(0.45))
                .frame(width: size * 0.5, height: size * 0.8)
        }
        .position(p)
    }

    @ViewBuilder
    private func paw(_ p: CGPoint?, _ headW: CGFloat) -> some View {
        if let p {
            Circle().fill(color.opacity(0.85))
                .frame(width: headW * 0.4, height: headW * 0.4)
                .position(p)
        }
    }

    private func midpoint(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
        guard let a, let b else { return a ?? b }
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func spread(_ a: CGPoint?, _ b: CGPoint?) -> CGFloat? {
        guard let a, let b else { return nil }
        return abs(hypot(a.x - b.x, a.y - b.y))
    }
}
