import AppKit
import QuartzCore

/// Layer-backed, procedurally drawn view for Wailo's ghost.
@MainActor
final class GhostView: NSView {
    static let preferredSize = CGSize(width: 220, height: 220)

    private let ghostContainer = CALayer()
    private let logoLayer = CALayer()
    private let bodyLayer = CAShapeLayer()
    private let frostLayer = CAShapeLayer()
    private let leftEye = CAShapeLayer()
    private let rightEye = CAShapeLayer()
    private let mouthLayer = CAShapeLayer()
    private let leftBlush = CAShapeLayer()
    private let rightBlush = CAShapeLayer()
    private let accessoryLayer = CALayer()
    private let effectLayer = CALayer()

    private var state: GhostState?
    private var usesKiroLogo = false
    private var blinkTimer: Timer?
    private var yawnTimer: Timer?
    private var stateGeneration = 0
    private var workspaceObserver: NSObjectProtocol?
    private(set) var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    /// Called after the live Reduce Motion setting changes.
    var onReduceMotionChanged: ((Bool) -> Void)?
    var onPointerDown: ((CGPoint) -> Void)?
    var onPointerDragged: ((CGPoint) -> Void)?
    var onPointerUp: ((CGPoint) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureLayers()
        configureAccessibility()
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshReduceMotion() }
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        blinkTimer?.invalidate()
        yawnTimer?.invalidate()
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
    }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        onPointerDown?(NSEvent.mouseLocation)
    }

    override func mouseDragged(with event: NSEvent) {
        onPointerDragged?(NSEvent.mouseLocation)
    }

    override func mouseUp(with event: NSEvent) {
        onPointerUp?(NSEvent.mouseLocation)
    }

    /// Conservative body bounds in view coordinates, including the danger puff.
    var bodyBounds: CGRect {
        let scale: CGFloat = isDanger ? 1.5 : 1
        return Self.baseBodyBounds.scaled(around: CGPoint(x: bounds.midX, y: bounds.midY), by: scale)
            .insetBy(dx: -5, dy: -5)
    }

    func bodyContains(_ point: CGPoint) -> Bool {
        let scale: CGFloat = isDanger ? 1.5 : 1
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let unscaled = CGPoint(
            x: center.x + (point.x - center.x) / scale,
            y: center.y + (point.y - center.y) / scale
        )
        let generousPath = Self.ghostPath.copy(
            strokingWithWidth: 10,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 2
        )
        return Self.ghostPath.contains(unscaled) || generousPath.contains(unscaled)
    }

    func apply(state newState: GhostState, animated: Bool = true) {
        stateGeneration += 1
        state = newState
        blinkTimer?.invalidate()
        yawnTimer?.invalidate()
        removeSemanticEffects()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        resetAppearance()
        configureAppearance(for: newState)
        CATransaction.commit()

        installMotion(for: newState, animated: animated && !reduceMotion)
        scheduleIdleLifeIfNeeded()
        setAccessibilityValue(accessibilityDescription(for: newState))
        needsDisplay = true
    }

    func performGiggle() {
        guard !reduceMotion else {
            flashBody()
            return
        }
        let hop = CAKeyframeAnimation(keyPath: "transform.translation.y")
        hop.values = [0, 8, 0, 5, 0]
        hop.keyTimes = [0, 0.2, 0.45, 0.68, 1]
        hop.duration = 0.55
        hop.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ghostContainer.add(hop, forKey: "giggle")
    }

    // MARK: - Drawing

    private static let baseBodyBounds = CGRect(x: 48, y: 38, width: 124, height: 132)

    private static let ghostPath: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 48, y: 54))
        path.addLine(to: CGPoint(x: 48, y: 111))
        path.addCurve(
            to: CGPoint(x: 110, y: 170),
            control1: CGPoint(x: 48, y: 148),
            control2: CGPoint(x: 73, y: 170)
        )
        path.addCurve(
            to: CGPoint(x: 172, y: 111),
            control1: CGPoint(x: 147, y: 170),
            control2: CGPoint(x: 172, y: 148)
        )
        path.addLine(to: CGPoint(x: 172, y: 54))
        path.addCurve(to: CGPoint(x: 151, y: 39), control1: CGPoint(x: 169, y: 42), control2: CGPoint(x: 160, y: 37))
        path.addCurve(to: CGPoint(x: 132, y: 51), control1: CGPoint(x: 144, y: 41), control2: CGPoint(x: 139, y: 48))
        path.addCurve(to: CGPoint(x: 110, y: 38), control1: CGPoint(x: 124, y: 47), control2: CGPoint(x: 118, y: 38))
        path.addCurve(to: CGPoint(x: 88, y: 51), control1: CGPoint(x: 102, y: 38), control2: CGPoint(x: 96, y: 47))
        path.addCurve(to: CGPoint(x: 69, y: 39), control1: CGPoint(x: 81, y: 48), control2: CGPoint(x: 76, y: 41))
        path.addCurve(to: CGPoint(x: 48, y: 54), control1: CGPoint(x: 60, y: 37), control2: CGPoint(x: 51, y: 42))
        path.closeSubpath()
        return path
    }()

    private func configureLayers() {
        wantsLayer = true
        layer = CALayer()
        layer?.frame = bounds
        layer?.masksToBounds = false

        ghostContainer.frame = bounds
        ghostContainer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ghostContainer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer?.addSublayer(ghostContainer)

        bodyLayer.path = Self.ghostPath
        bodyLayer.fillColor = NSColor(calibratedWhite: 1, alpha: 0.98).cgColor
        bodyLayer.strokeColor = NSColor(calibratedRed: 0.48, green: 0.34, blue: 0.72, alpha: 0.95).cgColor
        bodyLayer.lineWidth = 3
        bodyLayer.lineJoin = .round
        bodyLayer.shadowColor = NSColor(calibratedRed: 0.58, green: 0.43, blue: 0.85, alpha: 1).cgColor
        bodyLayer.shadowOpacity = 0.5
        bodyLayer.shadowRadius = 12
        ghostContainer.addSublayer(bodyLayer)

        frostLayer.path = Self.ghostPath
        frostLayer.fillColor = NSColor.clear.cgColor
        frostLayer.strokeColor = NSColor(calibratedRed: 0.64, green: 0.94, blue: 1, alpha: 0.95).cgColor
        frostLayer.lineWidth = 7
        frostLayer.lineDashPattern = [3, 6]
        frostLayer.isHidden = true
        ghostContainer.addSublayer(frostLayer)

        [leftEye, rightEye].forEach {
            $0.fillColor = NSColor(calibratedWhite: 0.12, alpha: 1).cgColor
            ghostContainer.addSublayer($0)
        }
        leftEye.path = CGPath(ellipseIn: CGRect(x: 76, y: 100, width: 15, height: 30), transform: nil)
        rightEye.path = CGPath(ellipseIn: CGRect(x: 129, y: 100, width: 15, height: 30), transform: nil)

        mouthLayer.fillColor = nil
        mouthLayer.strokeColor = NSColor(calibratedWhite: 0.14, alpha: 1).cgColor
        mouthLayer.lineWidth = 4
        mouthLayer.lineCap = .round
        ghostContainer.addSublayer(mouthLayer)

        leftBlush.path = CGPath(ellipseIn: CGRect(x: 65, y: 88, width: 18, height: 8), transform: nil)
        rightBlush.path = CGPath(ellipseIn: CGRect(x: 137, y: 88, width: 18, height: 8), transform: nil)
        [leftBlush, rightBlush].forEach {
            $0.fillColor = NSColor(calibratedRed: 1, green: 0.55, blue: 0.66, alpha: 0.42).cgColor
            ghostContainer.addSublayer($0)
        }

        effectLayer.frame = bounds
        effectLayer.masksToBounds = false
        layer?.addSublayer(effectLayer)
        accessoryLayer.frame = bounds
        accessoryLayer.masksToBounds = false
        layer?.addSublayer(accessoryLayer)

        // Haunting v2 uses a mouthless, eye-led mascot. A provided Kiro logo takes precedence.
        mouthLayer.isHidden = true
        leftBlush.isHidden = true
        rightBlush.isHidden = true
        if let logo = AssetLoader.shared.optionalImage(named: "kiro-logo.png") {
            usesKiroLogo = true
            logoLayer.contents = logo
            logoLayer.contentsGravity = .resizeAspect
            logoLayer.frame = Self.baseBodyBounds.insetBy(dx: -10, dy: -10)
            logoLayer.shadowColor = NSColor.systemPurple.cgColor
            logoLayer.shadowOpacity = 0.8
            logoLayer.shadowRadius = 18
            ghostContainer.addSublayer(logoLayer)
            [bodyLayer, frostLayer, leftEye, rightEye].forEach { $0.isHidden = true }
        }
    }

    private func configureAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Wailo ghost assistant")
        setAccessibilityHelp("Click to ask for help, or drag to move Wailo.")
    }

    private func resetAppearance() {
        ghostContainer.transform = CATransform3DMakeRotation(0.07, 0, 0, 1)
        ghostContainer.opacity = 1
        bodyLayer.fillColor = NSColor(calibratedWhite: 1, alpha: 0.98).cgColor
        bodyLayer.strokeColor = NSColor(calibratedRed: 0.48, green: 0.34, blue: 0.72, alpha: 0.95).cgColor
        bodyLayer.shadowColor = NSColor(calibratedRed: 0.58, green: 0.43, blue: 0.85, alpha: 1).cgColor
        bodyLayer.shadowOpacity = 0.5
        bodyLayer.shadowRadius = 12
        frostLayer.isHidden = true
        setEyes(.open)
        setMouth(.smile)
        leftBlush.opacity = 1
        rightBlush.opacity = 1
    }

    private func configureAppearance(for state: GhostState) {
        switch state {
        case .idle:
            break
        case .listening:
            setGlow(NSColor(calibratedRed: 0.62, green: 0.38, blue: 0.96, alpha: 1), radius: 22)
            addText("👂", frame: CGRect(x: 155, y: 119, width: 48, height: 48), size: 34)
            addWisps(color: NSColor.cyan)
        case .planning:
            setEyes(.wide)
            setMouth(.focused)
            addCauldron()
            addPlanningCandles()
        case .searching:
            setMouth(.focused)
            addText("🏮", frame: CGRect(x: 153, y: 62, width: 54, height: 54), size: 38)
            addSearchBeam()
        case .searchingHard:
            setEyes(.wide)
            setGlow(NSColor(calibratedRed: 0.68, green: 0.36, blue: 1, alpha: 1), radius: 25)
            addText("🔮", frame: CGRect(x: 147, y: 49, width: 66, height: 66), size: 48)
            addCrystalAura()
        case .found:
            setEyes(.delighted)
            setMouth(.delighted)
            addSparkles()
        case .waitingForClick:
            setMouth(.encouraging)
            addText("☝️", frame: CGRect(x: 153, y: 75, width: 62, height: 62), size: 44)
        case .wrongClick:
            setEyes(.sad)
            setMouth(.frown)
            addText("?", frame: CGRect(x: 164, y: 131, width: 36, height: 44), size: 34, color: .systemOrange)
        case .seance:
            setEyes(.sad)
            setGlow(NSColor(calibratedRed: 0.65, green: 0.30, blue: 0.92, alpha: 1), radius: 28)
            addText("🕯️", frame: CGRect(x: 155, y: 55, width: 54, height: 62), size: 40)
            addSeanceCircle()
        case .success:
            setEyes(.delighted)
            setMouth(.delighted)
            addText("🕯️", frame: CGRect(x: 157, y: 61, width: 52, height: 58), size: 40)
            addSparkles()
        case .danger:
            ghostContainer.transform = CATransform3DMakeScale(1.5, 1.5, 1)
            setEyes(.sad)
            setMouth(.alarm)
            bodyLayer.fillColor = NSColor(calibratedWhite: 1, alpha: 0.98).cgColor
            setGlow(NSColor(calibratedRed: 0.62, green: 0.38, blue: 0.96, alpha: 1), radius: 20)
            frostLayer.isHidden = false
            addIceSpikes()
            addText("⚠️", frame: CGRect(x: 161, y: 129, width: 52, height: 52), size: 40)
        case .sleeping:
            setEyes(.closed)
            setMouth(.sleeping)
            leftBlush.opacity = 0.45
            rightBlush.opacity = 0.45
            addText("💤", frame: CGRect(x: 147, y: 128, width: 68, height: 54), size: 38)
            ghostContainer.transform = CATransform3DMakeRotation(-0.10, 0, 0, 1)
        }
        if usesKiroLogo {
            logoLayer.isHidden = false
            bodyLayer.isHidden = true
            frostLayer.isHidden = true
            leftEye.isHidden = true
            rightEye.isHidden = true
        }
    }

    private func installMotion(for state: GhostState, animated: Bool) {
        switch state {
        case .idle:
            if animated { addIdleBob() }
        case .listening:
            if animated { animateWisps() }
        case .planning:
            animateNamedSublayers(prefix: "bubble", verticalDistance: 12, duration: 1.0, moving: animated)
            animateNamedSublayers(prefix: "planCandle", verticalDistance: 9, duration: 1.2, moving: animated)
        case .searching:
            if animated { addBeamSweep() }
        case .searchingHard:
            pulseNamedSublayers(prefix: "crystal", duration: 1.1, moving: animated)
        case .found:
            animateSparkles(moving: animated)
        case .waitingForClick:
            if animated { addNudge() }
        case .wrongClick:
            if animated { addHeadShake() }
        case .seance:
            pulseNamedSublayers(prefix: "seance", duration: 1.4, moving: animated)
        case .success:
            animateSparkles(moving: animated)
            performGiggle()
        case .danger:
            pulseNamedSublayers(prefix: "ice", duration: 0.9, moving: animated)
        case .sleeping:
            break
        }
    }

    // MARK: - Face

    private enum EyeExpression { case open, closed, delighted, sad, wide }
    private enum MouthExpression { case smile, delighted, focused, encouraging, frown, alarm, sleeping }

    private func setEyes(_ expression: EyeExpression) {
        let leftRect: CGRect
        let rightRect: CGRect
        switch expression {
        case .open:
            leftRect = CGRect(x: 76, y: 100, width: 15, height: 30)
            rightRect = CGRect(x: 129, y: 100, width: 15, height: 30)
        case .wide:
            leftRect = CGRect(x: 73, y: 96, width: 20, height: 38)
            rightRect = CGRect(x: 127, y: 96, width: 20, height: 38)
        case .closed:
            leftRect = CGRect(x: 75, y: 112, width: 18, height: 3)
            rightRect = CGRect(x: 127, y: 112, width: 18, height: 3)
        case .delighted:
            leftRect = CGRect(x: 75, y: 106, width: 18, height: 11)
            rightRect = CGRect(x: 127, y: 106, width: 18, height: 11)
        case .sad:
            leftRect = CGRect(x: 75, y: 104, width: 17, height: 13)
            rightRect = CGRect(x: 128, y: 104, width: 17, height: 13)
        }
        leftEye.path = roundedEyePath(leftRect, expression: expression, mirrored: false)
        rightEye.path = roundedEyePath(rightRect, expression: expression, mirrored: true)
    }

    private func roundedEyePath(_ rect: CGRect, expression: EyeExpression, mirrored: Bool) -> CGPath {
        switch expression {
        case .sad:
            let p = CGMutablePath()
            let startY = mirrored ? rect.minY : rect.maxY
            let endY = mirrored ? rect.maxY : rect.minY
            p.move(to: CGPoint(x: rect.minX, y: startY))
            p.addLine(to: CGPoint(x: rect.maxX, y: endY))
            return p.copy(strokingWithWidth: 4, lineCap: .round, lineJoin: .round, miterLimit: 2)
        case .delighted:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY))
            return p.copy(strokingWithWidth: 4, lineCap: .round, lineJoin: .round, miterLimit: 2)
        default:
            return CGPath(roundedRect: rect, cornerWidth: rect.height / 2, cornerHeight: rect.height / 2, transform: nil)
        }
    }

    private func setMouth(_ expression: MouthExpression) {
        let p = CGMutablePath()
        mouthLayer.fillColor = nil
        mouthLayer.lineWidth = 4
        switch expression {
        case .smile, .encouraging:
            p.move(to: CGPoint(x: 96, y: 91))
            p.addQuadCurve(to: CGPoint(x: 124, y: 91), control: CGPoint(x: 110, y: 77))
        case .delighted:
            p.move(to: CGPoint(x: 94, y: 92))
            p.addQuadCurve(to: CGPoint(x: 126, y: 92), control: CGPoint(x: 110, y: 72))
        case .focused:
            p.move(to: CGPoint(x: 101, y: 85))
            p.addLine(to: CGPoint(x: 119, y: 85))
        case .frown:
            p.move(to: CGPoint(x: 96, y: 80))
            p.addQuadCurve(to: CGPoint(x: 124, y: 80), control: CGPoint(x: 110, y: 94))
        case .alarm:
            mouthLayer.fillColor = NSColor(calibratedWhite: 0.13, alpha: 1).cgColor
            p.addEllipse(in: CGRect(x: 100, y: 76, width: 20, height: 25))
        case .sleeping:
            p.move(to: CGPoint(x: 103, y: 84))
            p.addQuadCurve(to: CGPoint(x: 117, y: 84), control: CGPoint(x: 110, y: 80))
        }
        mouthLayer.path = p
    }

    // MARK: - Semantic accessories

    @discardableResult
    private func addText(
        _ text: String,
        frame: CGRect,
        size: CGFloat,
        color: NSColor = .labelColor,
        name: String? = nil
    ) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = name
        textLayer.string = text
        textLayer.frame = frame
        textLayer.fontSize = size
        textLayer.foregroundColor = color.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = window?.backingScaleFactor ?? NSScreen.screens.first?.backingScaleFactor ?? 2
        accessoryLayer.addSublayer(textLayer)
        return textLayer
    }

    private func addWisps(color: NSColor) {
        for index in 0..<3 {
            let wisp = CAShapeLayer()
            wisp.name = "wisp\(index)"
            let path = CGMutablePath()
            let y = CGFloat(76 + index * 22)
            path.move(to: CGPoint(x: 15, y: y))
            path.addCurve(to: CGPoint(x: 51, y: y + 3), control1: CGPoint(x: 27, y: y + 12), control2: CGPoint(x: 38, y: y - 8))
            wisp.path = path
            wisp.fillColor = nil
            wisp.strokeColor = color.withAlphaComponent(0.75).cgColor
            wisp.lineWidth = 3
            wisp.lineCap = .round
            effectLayer.addSublayer(wisp)
        }
    }

    private func addCauldron() {
        let pot = CAShapeLayer()
        pot.name = "cauldron"
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 75, y: 22, width: 70, height: 18))
        path.addCurve(to: CGPoint(x: 84, y: 8), control1: CGPoint(x: 143, y: 24), control2: CGPoint(x: 136, y: 8))
        path.addLine(to: CGPoint(x: 136, y: 8))
        path.closeSubpath()
        pot.path = path
        pot.fillColor = NSColor(calibratedRed: 0.17, green: 0.12, blue: 0.22, alpha: 1).cgColor
        pot.strokeColor = NSColor(calibratedRed: 0.60, green: 0.38, blue: 0.75, alpha: 1).cgColor
        pot.lineWidth = 3
        accessoryLayer.addSublayer(pot)

        for index in 0..<4 {
            let bubble = CAShapeLayer()
            bubble.name = "bubble\(index)"
            let diameter = CGFloat(5 + (index % 2) * 3)
            bubble.path = CGPath(ellipseIn: CGRect(x: 90 + CGFloat(index * 12), y: 37 + CGFloat(index % 2) * 5, width: diameter, height: diameter), transform: nil)
            bubble.fillColor = NSColor(calibratedRed: 0.45, green: 0.93, blue: 0.63, alpha: 0.85).cgColor
            accessoryLayer.addSublayer(bubble)
        }
    }

    private func addPlanningCandles() {
        for index in 0..<3 {
            let candle = addText(
                "🕯️",
                frame: CGRect(x: 25 + CGFloat(index * 31), y: 156 + CGFloat(index % 2) * 7, width: 34, height: 43),
                size: 27,
                name: "planCandle\(index)"
            )
            candle.opacity = Float(0.55 + Double(index) * 0.2)
        }
    }

    private func addSearchBeam() {
        let beam = CAShapeLayer()
        beam.name = "searchBeam"
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 177, y: 91))
        path.addLine(to: CGPoint(x: 217, y: 52))
        path.addLine(to: CGPoint(x: 217, y: 119))
        path.closeSubpath()
        beam.path = path
        beam.fillColor = NSColor(calibratedRed: 1, green: 0.85, blue: 0.34, alpha: 0.24).cgColor
        beam.strokeColor = NSColor(calibratedRed: 1, green: 0.82, blue: 0.25, alpha: 0.55).cgColor
        beam.lineWidth = 2
        effectLayer.addSublayer(beam)
    }

    private func addCrystalAura() {
        for index in 0..<3 {
            let ring = CAShapeLayer()
            ring.name = "crystal\(index)"
            let inset = CGFloat(index * 6)
            ring.path = CGPath(ellipseIn: CGRect(x: 145 - inset, y: 47 - inset, width: 70 + inset * 2, height: 70 + inset * 2), transform: nil)
            ring.fillColor = nil
            ring.strokeColor = NSColor(calibratedRed: 0.72, green: 0.42, blue: 1, alpha: 0.5 - CGFloat(index) * 0.11).cgColor
            ring.lineWidth = 2
            effectLayer.addSublayer(ring)
        }
    }

    private func addSparkles() {
        let locations = [CGPoint(x: 45, y: 151), CGPoint(x: 171, y: 158), CGPoint(x: 185, y: 112), CGPoint(x: 36, y: 97)]
        for (index, point) in locations.enumerated() {
            addText("✦", frame: CGRect(x: point.x - 14, y: point.y - 14, width: 28, height: 28), size: 25, color: .systemYellow, name: "sparkle\(index)")
        }
    }

    private func addSeanceCircle() {
        let ring = CAShapeLayer()
        ring.name = "seanceRing"
        ring.path = CGPath(ellipseIn: CGRect(x: 25, y: 18, width: 170, height: 34), transform: nil)
        ring.fillColor = NSColor(calibratedRed: 0.53, green: 0.25, blue: 0.80, alpha: 0.13).cgColor
        ring.strokeColor = NSColor(calibratedRed: 0.75, green: 0.47, blue: 1, alpha: 0.72).cgColor
        ring.lineWidth = 3
        effectLayer.addSublayer(ring)
    }

    private func addIceSpikes() {
        let spikePath = CGMutablePath()
        let points: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: 43, y: 130), CGPoint(x: 24, y: 141), CGPoint(x: 47, y: 119)),
            (CGPoint(x: 75, y: 171), CGPoint(x: 68, y: 196), CGPoint(x: 91, y: 168)),
            (CGPoint(x: 146, y: 169), CGPoint(x: 158, y: 194), CGPoint(x: 158, y: 161)),
            (CGPoint(x: 171, y: 111), CGPoint(x: 199, y: 118), CGPoint(x: 170, y: 96))
        ]
        for (a, b, c) in points {
            spikePath.move(to: a)
            spikePath.addLine(to: b)
            spikePath.addLine(to: c)
            spikePath.closeSubpath()
        }
        let spikes = CAShapeLayer()
        spikes.name = "iceSpikes"
        spikes.path = spikePath
        spikes.fillColor = NSColor(calibratedRed: 0.61, green: 0.91, blue: 1, alpha: 0.82).cgColor
        effectLayer.addSublayer(spikes)
    }

    // MARK: - Animation

    private func addIdleBob() {
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.fromValue = -2
        bob.toValue = 3
        bob.duration = 2.1
        bob.autoreverses = true
        bob.repeatCount = .infinity
        bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ghostContainer.add(bob, forKey: "idleBob")
    }

    private func animateWisps() {
        for layer in effectLayer.sublayers ?? [] where layer.name?.hasPrefix("wisp") == true {
            let move = CABasicAnimation(keyPath: "transform.translation.x")
            move.fromValue = -8
            move.toValue = 8
            move.duration = 1.25
            move.autoreverses = true
            move.repeatCount = .infinity
            layer.add(move, forKey: "inward")
        }
    }

    private func addBeamSweep() {
        guard let beam = effectLayer.sublayers?.first(where: { $0.name == "searchBeam" }) else { return }
        beam.anchorPoint = CGPoint(x: 0, y: 0.5)
        let sweep = CABasicAnimation(keyPath: "transform.rotation.z")
        sweep.fromValue = -0.14
        sweep.toValue = 0.14
        sweep.duration = 1.25
        sweep.autoreverses = true
        sweep.repeatCount = .infinity
        sweep.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        beam.add(sweep, forKey: "sweep")
    }

    private func addNudge() {
        guard let pointer = accessoryLayer.sublayers?.last else { return }
        let nudge = CABasicAnimation(keyPath: "transform.translation.x")
        nudge.fromValue = -4
        nudge.toValue = 4
        nudge.duration = 0.45
        nudge.autoreverses = true
        nudge.repeatCount = 2
        pointer.add(nudge, forKey: "nudge")
    }

    private func addHeadShake() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -7, 7, -5, 5, 0]
        shake.duration = 0.48
        shake.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ghostContainer.add(shake, forKey: "headShake")
    }

    private func animateSparkles(moving: Bool) {
        for layer in accessoryLayer.sublayers ?? [] where layer.name?.hasPrefix("sparkle") == true {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = moving ? 0.25 : 0.65
            fade.toValue = 1
            fade.duration = 0.7
            fade.autoreverses = true
            fade.repeatCount = moving ? 3 : 1
            layer.add(fade, forKey: "sparkle")
        }
    }

    private func animateNamedSublayers(prefix: String, verticalDistance: CGFloat, duration: TimeInterval, moving: Bool) {
        for layer in accessoryLayer.sublayers ?? [] where layer.name?.hasPrefix(prefix) == true {
            let animation = CABasicAnimation(keyPath: moving ? "transform.translation.y" : "opacity")
            animation.fromValue = moving ? 0 : 0.45
            animation.toValue = moving ? verticalDistance : 1
            animation.duration = duration
            animation.autoreverses = true
            animation.repeatCount = .infinity
            layer.add(animation, forKey: "semantic")
        }
    }

    private func pulseNamedSublayers(prefix: String, duration: TimeInterval, moving: Bool) {
        let allLayers = (effectLayer.sublayers ?? []) + (accessoryLayer.sublayers ?? [])
        for layer in allLayers where layer.name?.hasPrefix(prefix) == true {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.35
            pulse.toValue = 1
            pulse.duration = duration
            pulse.autoreverses = true
            pulse.repeatCount = moving ? .infinity : 1
            layer.add(pulse, forKey: "pulse")
        }
    }

    private func scheduleIdleLifeIfNeeded() {
        guard isIdle else { return }
        scheduleBlink()
        scheduleYawn()
    }

    private func scheduleBlink() {
        let generation = stateGeneration
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...7), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.stateGeneration == generation, self.isIdle else { return }
                let blink = CABasicAnimation(keyPath: self.reduceMotion ? "opacity" : "transform.scale.y")
                blink.fromValue = 1
                blink.toValue = self.reduceMotion ? 0.35 : 0.08
                blink.duration = 0.10
                blink.autoreverses = true
                self.leftEye.add(blink, forKey: "blink")
                self.rightEye.add(blink, forKey: "blink")
                self.scheduleBlink()
            }
        }
    }

    private func scheduleYawn() {
        let generation = stateGeneration
        yawnTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 40...65), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.stateGeneration == generation, self.isIdle else { return }
                self.setEyes(.wide)
                if self.reduceMotion {
                    self.flashBody()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                    guard let self, self.stateGeneration == generation, self.isIdle else { return }
                    self.setEyes(.open)
                    self.scheduleYawn()
                }
            }
        }
    }

    private func flashBody() {
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.68
        fade.toValue = 1
        fade.duration = 0.22
        bodyLayer.add(fade, forKey: "gentleFade")
    }

    private func setGlow(_ color: NSColor, radius: CGFloat) {
        bodyLayer.shadowColor = color.cgColor
        bodyLayer.shadowOpacity = 0.92
        bodyLayer.shadowRadius = radius
    }

    private func removeSemanticEffects() {
        ghostContainer.removeAllAnimations()
        bodyLayer.removeAllAnimations()
        leftEye.removeAllAnimations()
        rightEye.removeAllAnimations()
        accessoryLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        effectLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func refreshReduceMotion() {
        let updated = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard updated != reduceMotion else { return }
        reduceMotion = updated
        if let state { apply(state: state, animated: true) }
        onReduceMotionChanged?(updated)
    }

    private var isIdle: Bool {
        guard let state else { return false }
        if case .idle = state { return true }
        return false
    }

    private var isDanger: Bool {
        guard let state else { return false }
        if case .danger = state { return true }
        return false
    }

    private func accessibilityDescription(for state: GhostState) -> String {
        switch state {
        case .idle: return "Ready"
        case .listening: return "Listening"
        case .planning: return "Planning"
        case .searching: return "Searching with a lantern"
        case .searchingHard: return "Using the crystal ball with permission"
        case .found: return "Found the target"
        case .waitingForClick: return "Waiting for your click"
        case .wrongClick: return "That was not the expected click"
        case .seance: return "Waiting for you to show the target"
        case .success: return "Task complete"
        case .danger: return "Danger warning"
        case .sleeping: return "Sleeping"
        }
    }
}

private extension CGRect {
    func scaled(around center: CGPoint, by scale: CGFloat) -> CGRect {
        CGRect(
            x: center.x + (minX - center.x) * scale,
            y: center.y + (minY - center.y) * scale,
            width: width * scale,
            height: height * scale
        )
    }
}
