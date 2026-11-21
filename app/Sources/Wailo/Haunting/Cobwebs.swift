import AppKit
import SpriteKit

final class Cobwebs {
    private weak var scene: EffectsScene?
    private let root = SKNode()

    init(scene: EffectsScene, reduceMotion: Bool, animated: Bool = true) {
        self.scene = scene
        root.name = "cobwebs"
        root.zPosition = 35
        scene.add(root, to: .decor)

        let inset: CGFloat = 8
        let topInset: CGFloat = 28
        let corners: [(CGPoint, CGFloat)] = [
            (CGPoint(x: inset, y: inset), 0),
            (CGPoint(x: scene.size.width - inset, y: inset), .pi / 2),
            (CGPoint(x: scene.size.width - inset, y: scene.size.height - topInset), .pi),
            (CGPoint(x: inset, y: scene.size.height - topInset), -.pi / 2)
        ]
        for (point, rotation) in corners {
            let web = Self.makeWeb(radius: min(105, min(scene.size.width, scene.size.height) * 0.13))
            web.position = point
            web.zRotation = rotation
            root.addChild(web)
            if !animated {
                web.alpha = 1
            } else if reduceMotion {
                web.alpha = 0
                web.run(.fadeIn(withDuration: 0.4))
            } else {
                web.setScale(0.02)
                web.alpha = 0
                web.run(.group([
                    .scale(to: 1, duration: 0.65),
                    .fadeIn(withDuration: 0.4)
                ]))
            }
        }
        scene.wake()
    }

    func remove() {
        root.removeAllActions()
        root.removeFromParent()
        scene?.wake()
    }

    private static func makeWeb(radius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        for spoke in 0 ..< 6 {
            let angle = CGFloat(spoke) / 5 * (.pi / 2)
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: cos(angle) * radius, y: sin(angle) * radius))
        }
        for ring in 1 ... 5 {
            let ringRadius = radius * CGFloat(ring) / 5
            var previous = CGPoint.zero
            for spoke in 0 ..< 6 {
                let angle = CGFloat(spoke) / 5 * (.pi / 2)
                let point = CGPoint(x: cos(angle) * ringRadius, y: sin(angle) * ringRadius)
                if spoke > 0 {
                    let sag = CGPoint(
                        x: (previous.x + point.x) / 2 - sin(angle) * ringRadius * 0.045,
                        y: (previous.y + point.y) / 2 - cos(angle) * ringRadius * 0.045
                    )
                    path.move(to: previous)
                    path.addQuadCurve(to: point, control: sag)
                }
                previous = point
            }
        }
        let node = SKShapeNode(path: path)
        node.strokeColor = NSColor(calibratedRed: 0.84, green: 0.79, blue: 0.95, alpha: 0.58)
        node.lineWidth = 1.15
        node.glowWidth = 0.5
        node.lineCap = .round
        return node
    }
}
