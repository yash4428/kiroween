import AppKit
import SpriteKit

final class NightSkyScene: EffectsScene {
    private let skyRoot = SKNode()
    private let moon = SKShapeNode(circleOfRadius: 31)
    private let moonGlow = SKShapeNode(circleOfRadius: 43)
    private var minuteTimer: Timer?
    private var reduceMotion = false
    private(set) var targetOpacity: CGFloat = 0.85

    override init(size: CGSize) {
        super.init(size: size)
        skyRoot.alpha = 0
        weather.addChild(skyRoot)
        installStaticArtwork()
        installMoon()
        updateMoon()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        minuteTimer?.invalidate()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        startTimers()
    }

    static func moonProgress(date: Date, calendar: Calendar = .current) -> CGFloat? {
        let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        guard let hour = components.hour else { return nil }
        if hour >= 6 && hour < 18 { return nil }

        let minute = CGFloat(components.minute ?? 0)
        let second = CGFloat(components.second ?? 0)
        let nanos = CGFloat(components.nanosecond ?? 0)
        let fractionalHour = CGFloat(hour) + minute / 60 + second / 3_600 + nanos / 3_600_000_000_000
        let elapsed = hour >= 18 ? fractionalHour - 18 : fractionalHour + 6
        return min(1, max(0, elapsed / 12))
    }

    func setNight(opacity: CGFloat, animated: Bool, reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        targetOpacity = min(1, max(0, opacity))
        skyRoot.childNode(withName: "sunriseWarmth")?.removeFromParent()
        startTimers()
        skyRoot.removeAction(forKey: "skyTransition")
        if animated {
            let duration = reduceMotion ? 0.35 : 1.25
            skyRoot.run(.fadeAlpha(to: targetOpacity, duration: duration), withKey: "skyTransition")
        } else {
            skyRoot.alpha = targetOpacity
        }
        updateMoon()
        wake()
    }

    func sunriseAndFade(duration: TimeInterval = 1.1, completion: @escaping () -> Void) {
        skyRoot.removeAction(forKey: "skyTransition")
        let warmth = SKShapeNode(rectOf: size)
        warmth.name = "sunriseWarmth"
        warmth.position = CGPoint(x: size.width / 2, y: size.height / 2)
        warmth.fillColor = NSColor(calibratedRed: 0.96, green: 0.50, blue: 0.30, alpha: 0.22)
        warmth.strokeColor = .clear
        warmth.alpha = 0
        skyRoot.addChild(warmth)
        let action = SKAction.group([
            .fadeOut(withDuration: duration),
            .sequence([
                .run { warmth.run(.fadeAlpha(to: 1, duration: duration * 0.45)) },
                .wait(forDuration: duration * 0.45)
            ])
        ])
        skyRoot.run(.sequence([
            action,
            .run { [weak self, weak warmth] in
                warmth?.removeFromParent()
                self?.stopTimers()
                completion()
            }
        ]), withKey: "skyTransition")
        wake()
    }

    private func installStaticArtwork() {
        let image = Self.staticSkyImage(size: size)
        let node = SKSpriteNode(texture: SKTexture(image: image), size: size)
        node.anchorPoint = .zero
        node.position = .zero
        node.zPosition = -100
        skyRoot.addChild(node)
    }

    private static func staticSkyImage(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let bounds = CGRect(origin: .zero, size: size)
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.10, green: 0.05, blue: 0.24, alpha: 1),
            NSColor(calibratedRed: 0.17, green: 0.08, blue: 0.35, alpha: 1),
            NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.18, alpha: 1)
        ])
        gradient?.draw(in: bounds, angle: -90)

        var random = SeededRandom(seed: UInt64(size.width.rounded()) ^ UInt64(size.height.rounded()))
        for _ in 0 ..< max(55, Int(size.width * size.height / 19_000)) {
            let x = random.next() * size.width
            let y = size.height * (0.24 + random.next() * 0.72)
            let radius = 0.55 + random.next() * 1.45
            NSColor(calibratedWhite: 1, alpha: 0.38 + random.next() * 0.48).setFill()
            NSBezierPath(ovalIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)).fill()
        }

        drawHill(in: bounds, baseline: size.height * 0.10, crest: size.height * 0.27,
                 color: NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.17, alpha: 1), phase: 0.4)
        drawHill(in: bounds, baseline: 0, crest: size.height * 0.17,
                 color: NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.09, alpha: 1), phase: 2.2)

        let treeColor = NSColor(calibratedRed: 0.025, green: 0.025, blue: 0.06, alpha: 0.96)
        for fraction in stride(from: CGFloat(0.05), through: 0.96, by: 0.11) {
            drawTree(at: CGPoint(x: size.width * fraction, y: size.height * (0.06 + 0.025 * sin(fraction * 21))),
                     height: 42 + random.next() * 48, color: treeColor)
        }
        for fraction in stride(from: CGFloat(0.12), through: 0.92, by: 0.17) {
            drawTinyTombstone(at: CGPoint(x: size.width * fraction, y: size.height * 0.055), scale: 0.7 + random.next() * 0.5)
        }
        return image
    }

    private static func drawHill(in bounds: CGRect, baseline: CGFloat, crest: CGFloat, color: NSColor, phase: CGFloat) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.minX, y: baseline))
        let segments = 8
        for index in 0 ... segments {
            let progress = CGFloat(index) / CGFloat(segments)
            let y = baseline + crest * (0.55 + 0.22 * sin(progress * .pi * 3 + phase))
            path.line(to: CGPoint(x: bounds.width * progress, y: y))
        }
        path.line(to: CGPoint(x: bounds.maxX, y: 0))
        path.line(to: .zero)
        path.close()
        color.setFill()
        path.fill()
    }

    private static func drawTree(at base: CGPoint, height: CGFloat, color: NSColor) {
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = max(2, height / 24)
        path.lineCapStyle = .round
        path.move(to: base)
        path.line(to: CGPoint(x: base.x, y: base.y + height))
        for direction in [-1.0, 1.0] {
            let d = CGFloat(direction)
            path.move(to: CGPoint(x: base.x, y: base.y + height * 0.52))
            path.curve(to: CGPoint(x: base.x + d * height * 0.27, y: base.y + height * 0.82),
                       controlPoint1: CGPoint(x: base.x + d * 5, y: base.y + height * 0.64),
                       controlPoint2: CGPoint(x: base.x + d * height * 0.17, y: base.y + height * 0.68))
            path.move(to: CGPoint(x: base.x, y: base.y + height * 0.72))
            path.line(to: CGPoint(x: base.x + d * height * 0.18, y: base.y + height * 0.98))
        }
        path.stroke()
    }

    private static func drawTinyTombstone(at base: CGPoint, scale: CGFloat) {
        let rect = CGRect(x: base.x - 8 * scale, y: base.y, width: 16 * scale, height: 23 * scale)
        let path = NSBezierPath(roundedRect: rect, xRadius: 7 * scale, yRadius: 7 * scale)
        NSColor(calibratedWhite: 0.03, alpha: 0.9).setFill()
        path.fill()
    }

    private func installMoon() {
        moon.fillColor = NSColor(calibratedRed: 1, green: 0.88, blue: 0.60, alpha: 1)
        moon.strokeColor = NSColor(calibratedRed: 1, green: 0.73, blue: 0.38, alpha: 0.8)
        moon.lineWidth = 2
        moon.zPosition = -50
        moonGlow.fillColor = NSColor(calibratedRed: 0.9, green: 0.76, blue: 1, alpha: 0.10)
        moonGlow.strokeColor = .clear
        moonGlow.zPosition = -51
        skyRoot.addChild(moonGlow)
        skyRoot.addChild(moon)
    }

    private func startTimers() {
        guard minuteTimer == nil else { return }
        minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateMoon()
        }
    }

    private func stopTimers() {
        minuteTimer?.invalidate()
        minuteTimer = nil
    }

    private func updateMoon(date: Date = Date()) {
        guard let progress = Self.moonProgress(date: date) else {
            moon.isHidden = true
            moonGlow.isHidden = true
            return
        }
        moon.isHidden = false
        moonGlow.isHidden = false
        let point = CGPoint(
            x: 60 + progress * max(0, size.width - 120),
            y: size.height * (0.70 + 0.12 * sin(progress * .pi))
        )
        moon.position = point
        moonGlow.position = point
        wake()
    }
}

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return CGFloat(Double(state >> 11) / Double(UInt64.max >> 11))
    }
}
