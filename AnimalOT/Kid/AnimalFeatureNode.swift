import Foundation
import ARKit
import SceneKit

// MARK: - Animal features attached to the face anchor (upgraded look)
//
// Still procedural (runs with zero art assets), but far more appealing: rounded
// soft-shaded ears with inner color, glossy eyes with catch-lights, sculpted
// muzzles, whiskers, the raccoon's signature dark eye-mask, and a full golden
// mane for the lion. The point is liveliness AND charm — it should entice a
// 7-year-old to keep looking, not read as a sticker.

final class AnimalFeatureNode: SCNNode {

    private let config: AnimalMaskConfig

    private let leftEar = SCNNode()
    private let rightEar = SCNNode()
    private let leftEye = SCNNode()      // container scaled on blink
    private let rightEye = SCNNode()
    private let snout = SCNNode()
    private var maneTufts: [SCNNode] = []

    init(config: AnimalMaskConfig) {
        self.config = config
        super.init()
        if let mane = config.maneColor { buildMane(mane) }   // behind everything
        buildEars()
        buildMuzzle()
        if config.kind == .raccoon { buildRaccoonMask() }
        buildEyes()
        buildBrows()
        if config.hasWhiskers { buildWhiskers() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: Materials

    private func mat(_ color: UIColor, roughness: CGFloat = 0.55, metal: CGFloat = 0,
                    emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.roughness.contents = roughness
        m.metalness.contents = metal
        if let e = emission { m.emission.contents = e }
        return m
    }

    private func sphere(_ r: CGFloat, _ color: UIColor, roughness: CGFloat = 0.55) -> SCNNode {
        let g = SCNSphere(radius: r)
        g.segmentCount = 48
        g.firstMaterial = mat(color, roughness: roughness)
        return SCNNode(geometry: g)
    }

    // MARK: Ears

    private func buildEars() {
        for (node, sign) in [(leftEar, Float(-1)), (rightEar, Float(1))] {
            node.childNodes.forEach { $0.removeFromParentNode() }
            let outer: SCNNode
            let inner: SCNNode

            switch config.kind {
            case .lion:
                outer = sphere(0.030, config.earColor)
                outer.scale = SCNVector3(1, 1, 0.5)
                inner = sphere(0.018, config.innerColor)
                inner.position = SCNVector3(0, 0, 0.006)
                node.position = SCNVector3(sign * 0.066, 0.072, 0.005)
                node.eulerAngles = SCNVector3(0, 0, sign * -0.2)

            case .donkey:
                outer = sphere(0.020, config.earColor)
                outer.scale = SCNVector3(1, 2.8, 0.7)
                inner = sphere(0.012, config.innerColor)
                inner.scale = SCNVector3(1, 2.4, 1)
                inner.position = SCNVector3(0, 0, 0.006)
                node.position = SCNVector3(sign * 0.05, 0.105, 0.0)
                node.eulerAngles = SCNVector3(-0.1, 0, sign * 0.18)

            case .raccoon:
                let cone = SCNCone(topRadius: 0.001, bottomRadius: 0.026, height: 0.05)
                cone.firstMaterial = mat(config.earColor)
                outer = SCNNode(geometry: cone)
                inner = sphere(0.013, config.innerColor)
                inner.position = SCNVector3(0, -0.008, 0.006)
                node.position = SCNVector3(sign * 0.06, 0.075, 0.0)
                node.eulerAngles = SCNVector3(0.1, 0, sign * -0.25)

            case .pig:
                outer = sphere(0.026, config.earColor)
                outer.scale = SCNVector3(0.7, 1.1, 0.4)
                inner = sphere(0.014, config.innerColor)
                inner.position = SCNVector3(0, -0.004, 0.006)
                node.position = SCNVector3(sign * 0.055, 0.07, 0.012)
                node.eulerAngles = SCNVector3(0.5, 0, sign * 0.25)
            }

            node.addChildNode(outer)
            node.addChildNode(inner)
            addChildNode(node)
        }
    }

    // MARK: Muzzle / snout

    private func buildMuzzle() {
        snout.childNodes.forEach { $0.removeFromParentNode() }

        switch config.kind {
        case .lion:
            for sign in [Float(-1), Float(1)] {
                let cheek = sphere(0.030, config.snoutColor)
                cheek.scale = SCNVector3(1, 0.85, 0.7)
                cheek.position = SCNVector3(sign * 0.024, -0.028, 0.052)
                snout.addChildNode(cheek)
            }
            let nose = sphere(0.014, config.noseColor, roughness: 0.25)
            nose.scale = SCNVector3(1.3, 0.9, 0.9)
            nose.position = SCNVector3(0, -0.006, 0.072)
            snout.addChildNode(nose)

        case .donkey:
            let muzzle = SCNBox(width: 0.058, height: 0.05, length: 0.06, chamferRadius: 0.022)
            muzzle.firstMaterial = mat(config.snoutColor)
            let m = SCNNode(geometry: muzzle)
            m.position = SCNVector3(0, -0.028, 0.055)
            snout.addChildNode(m)
            for sign in [Float(-1), Float(1)] {
                let nostril = sphere(0.006, config.noseColor, roughness: 0.3)
                nostril.position = SCNVector3(sign * 0.013, -0.022, 0.085)
                snout.addChildNode(nostril)
            }

        case .raccoon:
            let muzzle = sphere(0.022, config.snoutColor)
            muzzle.scale = SCNVector3(0.9, 0.8, 1.1)
            muzzle.position = SCNVector3(0, -0.018, 0.06)
            snout.addChildNode(muzzle)
            let nose = sphere(0.010, config.noseColor, roughness: 0.2)
            nose.position = SCNVector3(0, -0.012, 0.082)
            snout.addChildNode(nose)

        case .pig:
            let disc = SCNCylinder(radius: 0.026, height: 0.02)
            disc.firstMaterial = mat(config.snoutColor)
            let d = SCNNode(geometry: disc)
            d.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            d.position = SCNVector3(0, -0.02, 0.07)
            snout.addChildNode(d)
            for sign in [Float(-1), Float(1)] {
                let hole = sphere(0.005, config.noseColor, roughness: 0.3)
                hole.position = SCNVector3(sign * 0.009, -0.02, 0.082)
                snout.addChildNode(hole)
            }
        }

        snout.position = SCNVector3(0, 0, 0)
        addChildNode(snout)
    }

    /// Raccoon's signature dark mask patches around the eyes.
    private func buildRaccoonMask() {
        for sign in [Float(-1), Float(1)] {
            let patch = sphere(0.026, config.innerColor)
            patch.scale = SCNVector3(1.2, 0.8, 0.3)
            patch.position = SCNVector3(sign * 0.032, 0.024, 0.044)
            patch.eulerAngles = SCNVector3(0, 0, sign * 0.2)
            addChildNode(patch)
        }
    }

    // MARK: Eyes (glossy, with catch-lights)

    private func buildEyes() {
        for (eye, sign) in [(leftEye, Float(-1)), (rightEye, Float(1))] {
            eye.childNodes.forEach { $0.removeFromParentNode() }
            let sclera = sphere(0.0145, .white, roughness: 0.2)
            sclera.scale = SCNVector3(1, 1, 0.6)
            let iris = sphere(0.0092, UIColor(red: 0.20, green: 0.12, blue: 0.06, alpha: 1), roughness: 0.15)
            iris.position = SCNVector3(0, 0, 0.009)
            let pupil = sphere(0.0046, .black, roughness: 0.1)
            pupil.position = SCNVector3(0, 0, 0.013)
            let glint = sphere(0.0026, .white)
            glint.geometry?.firstMaterial?.lightingModel = .constant
            glint.position = SCNVector3(-0.004, 0.004, 0.015)

            eye.addChildNode(sclera)
            eye.addChildNode(iris)
            eye.addChildNode(pupil)
            eye.addChildNode(glint)
            eye.position = SCNVector3(sign * 0.032, 0.024, 0.05)
            addChildNode(eye)
        }
    }

    private func buildBrows() {
        guard config.kind == .lion || config.kind == .donkey else { return }
        for sign in [Float(-1), Float(1)] {
            let brow = SCNBox(width: 0.022, height: 0.005, length: 0.006, chamferRadius: 0.0025)
            brow.firstMaterial = mat(config.innerColor)
            let b = SCNNode(geometry: brow)
            b.position = SCNVector3(sign * 0.032, 0.05, 0.055)
            b.eulerAngles = SCNVector3(0, 0, sign * 0.25)   // cocked, a touch cheeky
            addChildNode(b)
        }
    }

    // MARK: Whiskers

    private func buildWhiskers() {
        let geo = SCNCylinder(radius: 0.0007, height: 0.06)
        geo.firstMaterial = mat(.white, roughness: 0.3)
        for sign in [Float(-1), Float(1)] {
            for tilt in [Float(-0.16), 0, 0.16] {
                let w = SCNNode(geometry: geo.copy() as? SCNGeometry)
                w.position = SCNVector3(sign * 0.042, -0.016, 0.058)
                w.eulerAngles = SCNVector3(0, 0, Float.pi / 2 + sign * tilt)
                addChildNode(w)
            }
        }
    }

    // MARK: Lion mane (the showpiece)

    private func buildMane(_ color: UIColor) {
        let inner = color
        let outer = color.darker(0.18)
        let rings: [(count: Int, radius: Float, z: Float, tuftR: CGFloat, tone: UIColor, scaleY: Float)] = [
            (18, 0.115, -0.03, 0.030, outer, 1.5),
            (16, 0.095, -0.012, 0.026, inner, 1.35)
        ]
        for ring in rings {
            for i in 0..<ring.count {
                let a = (Float(i) / Float(ring.count)) * 2 * .pi
                let tuft = sphere(ring.tuftR, ring.tone, roughness: 0.7)
                tuft.scale = SCNVector3(0.7, ring.scaleY, 0.7)
                tuft.position = SCNVector3(cos(a) * ring.radius, sin(a) * ring.radius - 0.01, ring.z)
                tuft.eulerAngles = SCNVector3(0, 0, a - .pi / 2)
                addChildNode(tuft)
                maneTufts.append(tuft)
            }
        }
    }

    // MARK: Per-frame liveliness

    func update(with faceAnchor: ARFaceAnchor) {
        let blend = faceAnchor.blendShapes

        let jawOpen = blend[.jawOpen]?.floatValue ?? 0
        snout.scale = SCNVector3(1, 1 + jawOpen * 0.5, 1)
        snout.position.y = -jawOpen * 0.018

        let blinkL = blend[.eyeBlinkLeft]?.floatValue ?? 0
        let blinkR = blend[.eyeBlinkRight]?.floatValue ?? 0
        leftEye.scale = SCNVector3(1, max(0.08, 1 - blinkL), 1)
        rightEye.scale = SCNVector3(1, max(0.08, 1 - blinkR), 1)

        let brow = blend[.browInnerUp]?.floatValue ?? 0
        let smile = ((blend[.mouthSmileLeft]?.floatValue ?? 0) + (blend[.mouthSmileRight]?.floatValue ?? 0)) / 2
        let perk = -brow * 0.3 - smile * 0.15
        leftEar.eulerAngles.x = baseEarTiltX + perk
        rightEar.eulerAngles.x = baseEarTiltX + perk
    }

    private var baseEarTiltX: Float {
        switch config.kind {
        case .donkey: return -0.1
        case .raccoon: return 0.1
        case .pig: return 0.5
        case .lion: return 0.0
        }
    }
}

// MARK: - Color helper

private extension UIColor {
    func darker(_ amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(0, r - amount), green: max(0, g - amount),
                       blue: max(0, b - amount), alpha: a)
    }
}
