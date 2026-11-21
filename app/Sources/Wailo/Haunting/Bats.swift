import AppKit
import SpriteKit

final class BatColony {
    typealias RandomInterval = (ClosedRange<TimeInterval>) -> TimeInterval

    private weak var scene: EffectsScene?
    private let root = SKNode()
    private let booLevel: BooLevel
    private let reduceMotion: Bool
    private let randomInterval: RandomInterval
    private var flightTimer: Timer?
    private var stopped = false

    init(
        scene: EffectsScene,
        booLevel: BooLevel,
        reduceMotion: Bool,
        randomInterval: @escaping RandomInterval = { Double.random(in: $0) }
    ) {
        self.scene = scene
        self.booLevel = booLevel
        self.reduceMotion = reduceMotion
        self.randomInterval = randomInterval
        root.name = "batColony"
        root.zPosition = 45
        scene.add(root, to: .decor)
        installBats(count: booLevel == .cozy ? 3 : 5)
        scheduleFlight()
    }

    func remove() {
        stopped = true
        flightTimer?.invalidate()
        flightTimer = nil
        root.removeAllActions()
        root.children.forEach { $0.removeAllActions() }
        root.removeFromParent()
        scene?.wake()
    }

    private func installBats(count: Int) {
        guard let scene else { return }
        let texture = SKTexture(image: AssetLoader.shared.image(for: .bat))
        let usableWidth = max(180, scene.size.width - 180)
        for index in 0 ..< count {
            let bat = SKSpriteNode(texture: texture, size: CGSize(width: 37, height: 37))
            bat.name = "bat"
            bat.position = CGPoint(
                x: 90 + usableWidth * CGFloat(index + 1) / CGFloat(count + 1),
                y: scene.size.height - 34 - CGFloat(index % 2) * 8
            )
            bat.zRotation = index.isMultiple(of: 2) ? -0.09 : 0.08
            root.addChild(bat)
        }
        scene.wake()
    }

    private func scheduleFlight() {
        guard !stopped else { return }
        flightTimer?.invalidate()
        let delay = max(0.1, randomInterval(booLevel.batFlightInterval))
        flightTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.flyOneBat()
        }
    }

    private func flyOneBat() {
        guard !stopped, let scene, let bat = root.children.randomElement() else { return }
        let perch = bat.position
        if reduceMotion {
            bat.run(.sequence([
                .fadeAlpha(to: 0.38, duration: 0.35),
                .fadeIn(withDuration: 0.35),
                .run { [weak self] in self?.scheduleFlight() }
            ]))
        } else {
            let destination = CGPoint(
                x: CGFloat.random(in: 70 ... max(71, scene.size.width - 70)),
                y: CGFloat.random(in: scene.size.height * 0.48 ... scene.size.height * 0.79)
            )
            let out = CGMutablePath()
            out.move(to: perch)
            out.addCurve(
                to: destination,
                control1: CGPoint(x: perch.x + 70, y: perch.y - 95),
                control2: CGPoint(x: destination.x - 90, y: destination.y + 55)
            )
            let back = CGMutablePath()
            back.move(to: destination)
            back.addCurve(
                to: perch,
                control1: CGPoint(x: destination.x + 80, y: destination.y - 30),
                control2: CGPoint(x: perch.x - 60, y: perch.y - 80)
            )
            bat.run(.sequence([
                .follow(out, asOffset: false, orientToPath: true, duration: 2.2),
                .follow(back, asOffset: false, orientToPath: true, duration: 2.0),
                .rotate(toAngle: 0, duration: 0.15),
                .run { [weak self] in self?.scheduleFlight() }
            ]))
        }
        scene.wake()
    }
}
