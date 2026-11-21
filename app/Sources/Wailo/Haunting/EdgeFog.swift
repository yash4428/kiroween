import AppKit
import SpriteKit

final class EdgeFog {
    private weak var scene: EffectsScene?
    private let root = SKNode()
    private var emitters: [SKEmitterNode] = []

    init(scene: EffectsScene, opacity: CGFloat, reduceMotion: Bool, animated: Bool = true) {
        self.scene = scene
        root.name = "edgeFog"
        root.zPosition = 20
        scene.add(root, to: .weather)
        installVignette(size: scene.size, opacity: opacity)
        if !animated {
            root.removeFromParent()
        } else if reduceMotion {
            root.alpha = 0
            root.run(.sequence([.fadeIn(withDuration: 0.35), .wait(forDuration: 1.7),
                                .fadeOut(withDuration: 0.35), .removeFromParent()]))
        } else {
            installFiniteFog(size: scene.size, opacity: opacity)
            root.run(.sequence([.wait(forDuration: 2.35), .fadeOut(withDuration: 0.4), .removeFromParent()]))
        }
        scene.wake()
    }

    func update(opacity: CGFloat) {
        root.childNode(withName: "vignette")?.alpha = opacity
        emitters.forEach { $0.particleAlpha = opacity * 0.45 }
        scene?.wake()
    }

    func remove() {
        emitters.forEach { $0.removeAllActions(); $0.removeFromParent() }
        emitters.removeAll()
        root.removeAllActions()
        root.removeFromParent()
        scene?.wake()
    }

    private func installVignette(size: CGSize, opacity: CGFloat) {
        let vignette = SKNode()
        vignette.name = "vignette"
        vignette.alpha = opacity
        let depth = max(70, min(size.width, size.height) * 0.11)
        let color = NSColor(calibratedRed: 0.16, green: 0.11, blue: 0.27, alpha: 0.72)
        let rects = [
            CGRect(x: 0, y: 0, width: size.width, height: depth),
            CGRect(x: 0, y: size.height - depth, width: size.width, height: depth),
            CGRect(x: 0, y: depth, width: depth, height: max(0, size.height - depth * 2)),
            CGRect(x: size.width - depth, y: depth, width: depth, height: max(0, size.height - depth * 2))
        ]
        for rect in rects {
            let edge = SKShapeNode(rect: rect)
            edge.fillColor = color
            edge.strokeColor = .clear
            vignette.addChild(edge)
        }
        root.addChild(vignette)
    }

    private func installFiniteFog(size: CGSize, opacity: CGFloat) {
        let specs: [(CGPoint, CGVector, CGFloat)] = [
            (CGPoint(x: size.width / 2, y: 6), CGVector(dx: 0, dy: 22), 0),
            (CGPoint(x: size.width / 2, y: size.height - 6), CGVector(dx: 0, dy: -22), .pi),
            (CGPoint(x: 6, y: size.height / 2), CGVector(dx: 22, dy: 0), -.pi / 2),
            (CGPoint(x: size.width - 6, y: size.height / 2), CGVector(dx: -22, dy: 0), .pi / 2)
        ]
        let texture = SKTexture(image: Self.fogParticleImage())
        for (position, velocity, angle) in specs {
            let emitter = SKEmitterNode()
            emitter.position = position
            emitter.particleTexture = texture
            emitter.particleBirthRate = 35
            emitter.numParticlesToEmit = 25
            emitter.particleLifetime = 1.1
            emitter.particleLifetimeRange = 0.3
            emitter.particleAlpha = opacity * 0.45
            emitter.particleAlphaSpeed = -0.16
            emitter.particleScale = 0.8
            emitter.particleScaleRange = 0.5
            emitter.particleScaleSpeed = 0.18
            emitter.particleSpeed = hypot(velocity.dx, velocity.dy)
            emitter.emissionAngle = angle
            emitter.emissionAngleRange = .pi / 2.5
            emitter.particlePositionRange = angle == 0 || angle == .pi
                ? CGVector(dx: size.width, dy: 8)
                : CGVector(dx: 8, dy: size.height)
            root.addChild(emitter)
            emitters.append(emitter)
            emitter.run(.sequence([
                .wait(forDuration: 0.7),
                .run { [weak emitter] in emitter?.particleBirthRate = 0 },
                .wait(forDuration: 1.5),
                .removeFromParent()
            ]))
        }
    }

    private static func fogParticleImage() -> NSImage {
        let image = NSImage(size: CGSize(width: 44, height: 44))
        image.lockFocus()
        NSColor(calibratedWhite: 0.92, alpha: 0.25).setFill()
        NSBezierPath(ovalIn: CGRect(x: 2, y: 6, width: 40, height: 32)).fill()
        image.unlockFocus()
        return image
    }
}
