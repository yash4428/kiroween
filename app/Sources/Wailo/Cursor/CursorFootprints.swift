import AppKit
import SpriteKit

struct AmbientFootprintMark: Equatable {
    enum Side: Equatable { case left, right }
    let point: CGPoint
    let angle: CGFloat
    let side: Side
}

/// Pure accumulated-distance sampler used by the permission-free ambient cursor trail.
struct FootprintPathSampler {
    typealias Spacing = () -> CGFloat

    private var previousPoint: CGPoint?
    private var distanceUntilMark: CGFloat
    private var nextSide: AmbientFootprintMark.Side = .left
    private let spacing: Spacing

    init(spacing: @escaping Spacing = { CGFloat.random(in: 22 ... 26) }) {
        self.spacing = spacing
        distanceUntilMark = max(1, spacing())
    }

    mutating func reset(at point: CGPoint? = nil) {
        previousPoint = point
        distanceUntilMark = max(1, spacing())
        nextSide = .left
    }

    mutating func consume(
        point: CGPoint,
        excluded: (CGPoint) -> Bool
    ) -> [AmbientFootprintMark] {
        guard point.x.isFinite, point.y.isFinite else { return [] }
        guard let start = previousPoint else {
            previousPoint = point
            return []
        }
        previousPoint = point

        let dx = point.x - start.x
        let dy = point.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.000_001, length.isFinite else { return [] }
        let unit = CGVector(dx: dx / length, dy: dy / length)
        let angle = atan2(dy, dx)
        var traveled: CGFloat = 0
        var marks: [AmbientFootprintMark] = []

        while traveled + distanceUntilMark <= length {
            traveled += distanceUntilMark
            let center = CGPoint(x: start.x + unit.dx * traveled, y: start.y + unit.dy * traveled)
            let lateral: CGFloat = nextSide == .left ? 5.5 : -5.5
            let markPoint = CGPoint(x: center.x - unit.dy * lateral, y: center.y + unit.dx * lateral)
            if !excluded(markPoint) {
                marks.append(AmbientFootprintMark(point: markPoint, angle: angle, side: nextSide))
                nextSide = nextSide == .left ? .right : .left
            }
            distanceUntilMark = max(1, spacing())
        }
        distanceUntilMark -= length - traveled
        return marks
    }
}

final class CursorFootprints {
    private let overlays: OverlayWindowManager
    private let reduceMotion: () -> Bool
    private let ghostHitTest: (CGPoint) -> Bool
    private var sampler = FootprintPathSampler()
    private var timer: Timer?
    private var lastPoint: CGPoint?
    private var lastMovementTime = ProcessInfo.processInfo.systemUptime
    private var currentInterval: TimeInterval = 1.0 / 15.0
    private(set) var isRunning = false

    init(
        overlays: OverlayWindowManager,
        reduceMotion: @escaping () -> Bool,
        ghostHitTest: @escaping (CGPoint) -> Bool = { _ in false }
    ) {
        self.overlays = overlays
        self.reduceMotion = reduceMotion
        self.ghostHitTest = ghostHitTest
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let point = NSEvent.mouseLocation
        lastPoint = point
        sampler.reset(at: point)
        lastMovementTime = ProcessInfo.processInfo.systemUptime
        schedule(interval: 1.0 / 30.0)
    }

    func stop(removeExisting: Bool = false) {
        isRunning = false
        timer?.invalidate()
        timer = nil
        lastPoint = nil
        sampler.reset()
        if removeExisting {
            overlays.overlays.forEach { overlay in
                overlay.effectsScene.cursorLayer.removeAllChildren()
                overlay.effectsScene.wake()
            }
        }
    }

    private func schedule(interval: TimeInterval) {
        timer?.invalidate()
        currentInterval = interval
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.sample() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func sample() {
        guard isRunning else { return }
        let point = NSEvent.mouseLocation
        let now = ProcessInfo.processInfo.systemUptime
        if let lastPoint, hypot(point.x - lastPoint.x, point.y - lastPoint.y) > 0.25 {
            lastMovementTime = now
        }
        lastPoint = point

        let marks = sampler.consume(point: point, excluded: ghostHitTest)
        marks.forEach(render)

        let desired = now - lastMovementTime < 0.28 ? 1.0 / 60.0 : 1.0 / 15.0
        if abs(desired - currentInterval) > 0.001 { schedule(interval: desired) }
    }

    private func render(_ mark: AmbientFootprintMark) {
        guard let overlay = overlays.overlay(containing: mark.point) else { return }
        let local = CoordinateSpace.globalToLocal(mark.point, screenFrame: overlay.screen.frame)
        let node = Self.footprintNode(side: mark.side)
        node.position = local
        node.zRotation = mark.angle - .pi / 2
        node.alpha = 0.88
        overlay.effectsScene.add(node, to: .cursorLayer)

        let duration = TimeInterval.random(in: 1.0 ... 1.4)
        if reduceMotion() {
            node.run(.sequence([.wait(forDuration: duration * 0.20), .fadeOut(withDuration: duration * 0.80), .removeFromParent()]))
        } else {
            node.setScale(0.88)
            node.run(.sequence([
                .group([.scale(to: 1, duration: 0.12), .fadeAlpha(to: 0.95, duration: 0.12)]),
                .fadeOut(withDuration: duration - 0.12),
                .removeFromParent()
            ]))
        }
    }

    private static func footprintNode(side: AmbientFootprintMark.Side) -> SKNode {
        let root = SKNode()
        let color = NSColor(calibratedRed: 0.76, green: 0.61, blue: 1.0, alpha: 0.82)
        let solePath = CGMutablePath()
        solePath.addEllipse(in: CGRect(x: -4.4, y: -8, width: 8.8, height: 17))
        let sole = SKShapeNode(path: solePath)
        sole.fillColor = color
        sole.strokeColor = .clear
        sole.glowWidth = 2
        root.addChild(sole)

        for index in 0 ..< 4 {
            let toe = SKShapeNode(circleOfRadius: 1.65 - CGFloat(index) * 0.12)
            toe.fillColor = color
            toe.strokeColor = .clear
            toe.position = CGPoint(x: -4.1 + CGFloat(index) * 2.65, y: 10 + abs(CGFloat(index) - 1.5) * -0.7)
            root.addChild(toe)
        }
        root.xScale = side == .left ? 1 : -1
        return root
    }
}
