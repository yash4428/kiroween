import AppKit
import SpriteKit

final class SlimeDripCoordinator {
    private var owner: ObjectIdentifier?

    func acquire(for component: AnyObject) -> Bool {
        guard owner == nil else { return false }
        owner = ObjectIdentifier(component)
        return true
    }

    func release(for component: AnyObject) {
        if owner == ObjectIdentifier(component) { owner = nil }
    }
}

final class SlimeDrips {
    private final class Rim {
        let root = SKNode()
        let line = SKShapeNode()
        var splatteredAt: TimeInterval?
        var lowSpeedSince: TimeInterval?
    }

    private weak var scene: EffectsScene?
    private let screenFrame: CGRect
    private let maxWindows: Int
    private let reduceMotion: Bool
    private let coordinator: SlimeDripCoordinator
    private let root = SKNode()
    private var rims: [CGWindowID: Rim] = [:]
    private var dripTimer: Timer?
    private var stopped = false

    init(
        scene: EffectsScene,
        screenFrame: CGRect,
        maxWindows: Int,
        reduceMotion: Bool,
        coordinator: SlimeDripCoordinator
    ) {
        self.scene = scene
        self.screenFrame = screenFrame
        self.maxWindows = maxWindows
        self.reduceMotion = reduceMotion
        self.coordinator = coordinator
        root.name = "slimeDrips"
        root.zPosition = 60
        scene.add(root, to: .decor)
        scheduleDrip()
    }

    func update(windows: [TrackedWindow]) {
        guard !stopped else { return }
        let selected = windows
            .filter { $0.frame.maxX > screenFrame.minX && $0.frame.minX < screenFrame.maxX &&
                      $0.frame.maxY >= screenFrame.minY && $0.frame.maxY <= screenFrame.maxY + 1 }
            .prefix(maxWindows)
        let selectedIDs = Set(selected.map(\.id))

        let staleIDs = rims.keys.filter { !selectedIDs.contains($0) }
        for id in staleIDs {
            rims.removeValue(forKey: id)?.root.removeFromParent()
        }
        let now = ProcessInfo.processInfo.systemUptime
        for window in selected {
            let rim = rims[window.id] ?? installRim(for: window)
            let local = CoordinateSpace.globalToLocal(window.frame, screenFrame: screenFrame)
            rim.root.position = CGPoint(x: local.minX, y: local.maxY)
            updateRim(rim, window: window, now: now)
        }
        scene?.wake()
    }

    func remove() {
        stopped = true
        dripTimer?.invalidate()
        dripTimer = nil
        coordinator.release(for: self)
        root.children.forEach { $0.removeAllActions() }
        root.removeFromParent()
        rims.removeAll()
        scene?.wake()
    }

    private func installRim(for window: TrackedWindow) -> Rim {
        let rim = Rim()
        rim.root.name = "slime-\(window.id)"
        let local = CoordinateSpace.globalToLocal(window.frame, screenFrame: screenFrame)
        let width = min(local.width, screenFrame.width)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 5, y: 0))
        path.addCurve(to: CGPoint(x: width - 5, y: 0),
                      control1: CGPoint(x: width * 0.30, y: -4),
                      control2: CGPoint(x: width * 0.68, y: 4))
        rim.line.path = path
        rim.line.strokeColor = NSColor(calibratedRed: 0.50, green: 0.94, blue: 0.57, alpha: 0.78)
        rim.line.lineWidth = 7
        rim.line.glowWidth = 3
        rim.line.lineCap = .round
        rim.root.addChild(rim.line)

        for fraction in [0.16, 0.38, 0.64, 0.83] as [CGFloat] {
            let bead = SKShapeNode(circleOfRadius: 4.5)
            bead.fillColor = rim.line.strokeColor
            bead.strokeColor = .clear
            bead.position = CGPoint(x: width * fraction, y: -4)
            rim.root.addChild(bead)
        }
        root.addChild(rim.root)
        rims[window.id] = rim
        return rim
    }

    private func updateRim(_ rim: Rim, window: TrackedWindow, now: TimeInterval) {
        if window.velocity > 900 {
            if rim.splatteredAt == nil { splatter(rim) }
            rim.splatteredAt = now
            rim.lowSpeedSince = nil
            return
        }
        guard rim.splatteredAt != nil else { return }
        if window.velocity < 150 {
            rim.lowSpeedSince = rim.lowSpeedSince ?? now
            if let lowSince = rim.lowSpeedSince, now - lowSince >= 1.0 {
                regrow(rim)
                rim.splatteredAt = nil
                rim.lowSpeedSince = nil
            }
        } else {
            rim.lowSpeedSince = nil
        }
    }

    private func splatter(_ rim: Rim) {
        rim.root.alpha = 0.18
        guard !reduceMotion else { return }
        for index in 0 ..< 7 {
            let drop = SKShapeNode(circleOfRadius: CGFloat.random(in: 2 ... 5))
            drop.fillColor = rim.line.strokeColor
            drop.strokeColor = .clear
            drop.position = CGPoint(x: CGFloat(index) * 12 + 8, y: 0)
            rim.root.addChild(drop)
            drop.run(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -18 ... 18), y: CGFloat.random(in: -34 ... -13), duration: 0.35),
                    .fadeOut(withDuration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func regrow(_ rim: Rim) {
        rim.root.removeAllActions()
        if reduceMotion {
            rim.root.alpha = 1
        } else {
            rim.root.run(.fadeIn(withDuration: 0.5))
        }
    }

    private func scheduleDrip() {
        guard !stopped else { return }
        let delay = TimeInterval.random(in: 6 ... 11)
        dripTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.performDrip()
        }
    }

    private func performDrip() {
        guard !stopped, let scene, let rim = rims.values.randomElement(), coordinator.acquire(for: self) else {
            scheduleDrip()
            return
        }
        let drip = SKShapeNode(rect: CGRect(x: -4, y: -5, width: 8, height: 24), cornerRadius: 4)
        drip.fillColor = NSColor(calibratedRed: 0.50, green: 0.94, blue: 0.57, alpha: 0.8)
        drip.strokeColor = .clear
        drip.position = CGPoint(x: max(18, rim.line.frame.width * CGFloat.random(in: 0.15 ... 0.85)), y: -9)
        drip.yScale = 0.1
        rim.root.addChild(drip)

        let finish = SKAction.run { [weak self, weak drip] in
            guard let self else { return }
            drip?.removeFromParent()
            self.coordinator.release(for: self)
            self.scheduleDrip()
        }
        if reduceMotion {
            drip.run(.sequence([.fadeIn(withDuration: 0.2), .wait(forDuration: 0.2), .fadeOut(withDuration: 0.2), finish]))
        } else {
            drip.run(.sequence([
                .scaleY(to: 1, duration: 0.38),
                .moveBy(x: 0, y: -42, duration: 0.32),
                .group([.scaleY(to: 0.25, duration: 0.25), .fadeOut(withDuration: 0.25)]),
                finish
            ]))
        }
        scene.wake()
    }
}
