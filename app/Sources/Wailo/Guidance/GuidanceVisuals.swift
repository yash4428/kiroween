import AppKit
import SpriteKit

@MainActor
protocol GuideVisual: AnyObject { func remove() }

@MainActor
final class GuidanceVisualSet {
    private(set) var visuals: [GuideVisual] = []
    func keep(_ visual: GuideVisual) { visuals.append(visual) }
    func remove() { visuals.forEach { $0.remove() }; visuals.removeAll() }
}

@MainActor
final class FogSpotlight: GuideVisual {
    private let root = SKNode()
    init(scene: EffectsScene, target: CGRect, opacity: CGFloat, reduceMotion: Bool) {
        let bounds = CGRect(origin: .zero, size: scene.size)
        let hole = target.insetBy(dx: -28, dy: -28).intersection(bounds)
        let pieces = [
            CGRect(x: 0, y: 0, width: bounds.width, height: max(0, hole.minY)),
            CGRect(x: 0, y: hole.maxY, width: bounds.width, height: max(0, bounds.maxY - hole.maxY)),
            CGRect(x: 0, y: hole.minY, width: max(0, hole.minX), height: hole.height),
            CGRect(x: hole.maxX, y: hole.minY, width: max(0, bounds.maxX - hole.maxX), height: hole.height)
        ]
        for rect in pieces where rect.width > 0 && rect.height > 0 {
            let node = SKShapeNode(rect: rect)
            node.fillColor = NSColor(calibratedRed: 0.08, green: 0.06, blue: 0.18, alpha: opacity)
            node.strokeColor = .clear
            node.alpha = reduceMotion ? 0 : 1
            root.addChild(node)
            if reduceMotion { node.run(.fadeIn(withDuration: 0.2)) }
        }
        root.zPosition = 10
        scene.add(root, to: .guide)
    }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class SpiderPointer: GuideVisual {
    private let root = SKNode()
    init(scene: EffectsScene, target: CGPoint, reduceMotion: Bool) {
        let thread = SKShapeNode()
        let path = CGMutablePath(); path.move(to: CGPoint(x: target.x, y: scene.size.height)); path.addLine(to: target)
        thread.path = path; thread.strokeColor = NSColor(white: 0.92, alpha: 0.75); thread.lineWidth = 1.5
        let spider = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .spider)))
        spider.size = CGSize(width: 44, height: 44); spider.position = target
        root.addChild(thread); root.addChild(spider); root.zPosition = 30
        scene.add(root, to: .guide)
        if reduceMotion { root.alpha = 0; root.run(.fadeIn(withDuration: 0.22)) }
        else {
            spider.position.y = scene.size.height + 24
            spider.run(.sequence([.move(to: target, duration: 0.85),
                                  .repeatForever(.sequence([.moveBy(x: 4, y: 0, duration: 0.45), .moveBy(x: -8, y: 0, duration: 0.9), .moveBy(x: 4, y: 0, duration: 0.45)]))]))
        }
    }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class PumpkinRing: GuideVisual {
    private let root = SKNode()
    init(scene: EffectsScene, target: CGRect, reduceMotion: Bool) {
        let ring = SKShapeNode(rect: target.insetBy(dx: -9, dy: -9), cornerRadius: 14)
        ring.strokeColor = NSColor(calibratedRed: 1, green: 0.43, blue: 0.08, alpha: 1)
        ring.lineWidth = 5; ring.glowWidth = 7; ring.fillColor = .clear
        let pumpkin = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .pumpkin)))
        pumpkin.size = CGSize(width: 30, height: 30); pumpkin.position = CGPoint(x: target.maxX + 5, y: target.maxY + 5)
        root.addChild(ring); root.addChild(pumpkin); root.zPosition = 25
        scene.add(root, to: .guide)
        if reduceMotion { root.alpha = 0; root.run(.fadeIn(withDuration: 0.2)) }
        else { ring.run(.repeatForever(.sequence([.scale(to: 1.04, duration: 0.55), .scale(to: 1, duration: 0.55)]))) }
    }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class FootprintTrail: GuideVisual {
    private let root = SKNode()
    init(scene: EffectsScene, from: CGPoint, target: CGRect, reduceMotion: Bool) {
        let marks = FootprintPath.marks(from: from, to: target, spacing: 28)
        for (index, mark) in marks.enumerated() {
            let node = SKShapeNode(ellipseOf: CGSize(width: 9, height: 16))
            node.fillColor = NSColor(calibratedRed: 1, green: 0.43, blue: 0.08, alpha: 0.92)
            node.strokeColor = .clear; node.glowWidth = 4; node.position = mark.position
            node.zRotation = mark.rotation; node.xScale = mark.side == .left ? -1 : 1
            node.alpha = reduceMotion ? 0.75 : 0
            root.addChild(node)
            if !reduceMotion { node.run(.sequence([.wait(forDuration: Double(index) * 0.045), .fadeIn(withDuration: 0.12)])) }
        }
        root.zPosition = 20; scene.add(root, to: .guide)
    }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class GhostHandVisual: GuideVisual {
    private let node: SKSpriteNode
    init(scene: EffectsScene, target: CGPoint, action: HandAction, reduceMotion: Bool) {
        node = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .handUp)))
        node.size = CGSize(width: 54, height: 54); node.position = CGPoint(x: target.x + 24, y: target.y - 22)
        node.alpha = 0.72; node.zPosition = 35; scene.add(node, to: .guide)
        guard !reduceMotion else { return }
        let tap = SKAction.sequence([.scale(to: 0.85, duration: 0.18), .scale(to: 1, duration: 0.22), .wait(forDuration: 0.55)])
        switch action {
        case .doubleTap: node.run(.repeatForever(.sequence([tap, tap])))
        case .drag(let destination): node.run(.repeatForever(.sequence([.move(to: destination, duration: 0.8), .move(to: node.position, duration: 0), .wait(forDuration: 0.5)])))
        case .tap: node.run(.repeatForever(tap))
        case .none: break
        }
    }
    func remove() { node.removeAllActions(); node.removeFromParent() }
}

@MainActor
final class CandleProgress: GuideVisual {
    private let root = SKNode()
    private var candles: [SKNode] = []
    init(scene: EffectsScene, count: Int, visibleFrameLocal: CGRect) {
        let width = CGFloat(max(1, count)) * 34 + 24
        let plate = SKShapeNode(rectOf: CGSize(width: width, height: 50), cornerRadius: 22)
        plate.fillColor = NSColor(calibratedWhite: 0.08, alpha: 0.72); plate.strokeColor = NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.7, alpha: 0.8)
        root.addChild(plate)
        for i in 0..<max(1, count) {
            let candle = SKNode(); candle.position = CGPoint(x: CGFloat(i) * 34 - CGFloat(max(0, count - 1)) * 17, y: -4)
            let wax = SKShapeNode(rectOf: CGSize(width: 12, height: 22), cornerRadius: 4); wax.fillColor = .systemPurple; wax.strokeColor = .clear
            let flame = SKShapeNode(circleOfRadius: 5); flame.name = "flame"; flame.position.y = 16; flame.fillColor = .darkGray; flame.strokeColor = .clear
            candle.addChild(wax); candle.addChild(flame); root.addChild(candle); candles.append(candle)
        }
        root.position = CGPoint(x: visibleFrameLocal.midX, y: visibleFrameLocal.minY + 52); root.zPosition = 45
        scene.add(root, to: .guide)
    }
    func setCurrent(_ index: Int) {
        for (i, candle) in candles.enumerated() {
            guard let flame = candle.childNode(withName: "flame") as? SKShapeNode else { continue }
            flame.fillColor = i <= index ? .systemOrange : .darkGray
            flame.glowWidth = i == index ? 7 : 2
        }
    }
    func lightAll() { setCurrent(candles.count - 1) }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class ConfettiBurst: GuideVisual {
    private let root = SKNode()
    init(scene: EffectsScene, at point: CGPoint, reduceMotion: Bool) {
        let sprites: [Sprite] = [.candy, .bat, .pumpkin, .lollipop, .sparkles]
        for i in 0..<(reduceMotion ? 14 : 36) {
            let node = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: sprites[i % sprites.count])))
            node.size = CGSize(width: 24, height: 24); node.position = point; node.zPosition = 60
            root.addChild(node)
            let angle = CGFloat(i) / CGFloat(reduceMotion ? 14 : 36) * .pi * 2
            let distance: CGFloat = reduceMotion ? 36 : CGFloat.random(in: 70...180)
            let destination = CGPoint(x: point.x + cos(angle) * distance, y: point.y + sin(angle) * distance)
            node.run(.sequence([.group([.move(to: destination, duration: reduceMotion ? 0.25 : 1.1), .rotate(byAngle: .pi * 2, duration: 1.1)]), .fadeOut(withDuration: 0.35), .removeFromParent()]))
        }
        scene.add(root, to: .fx)
    }
    func remove() { root.removeAllActions(); root.removeFromParent() }
}

@MainActor
final class DebugTargetVisual: GuideVisual {
    private let node: SKShapeNode
    init(scene: EffectsScene, target: CGRect) {
        node = SKShapeNode(rect: target); node.strokeColor = .systemGreen; node.lineWidth = 2; node.fillColor = .clear; node.zPosition = 100
        scene.add(node, to: .guide)
    }
    func remove() { node.removeFromParent() }
}
