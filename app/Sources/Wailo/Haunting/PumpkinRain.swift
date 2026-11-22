import AppKit

@MainActor
final class PumpkinRain {
    private enum State {
        case falling
        case landed(windowID: CGWindowID, relativeX: CGFloat, since: TimeInterval)
        case dockIdle(since: TimeInterval)
        case dragging
        case magnetized
    }

    private final class Body {
        let id = UUID()
        let panel: PumpkinPanel
        var center: CGPoint
        var velocity: CGVector
        var state: State = .falling
        var dragSamples: [(CGPoint, TimeInterval)] = []
        var previousWindowCenter: CGPoint?

        init(center: CGPoint, velocity: CGVector, panel: PumpkinPanel) {
            self.center = center; self.velocity = velocity; self.panel = panel
        }
    }

    private let screenFrame: CGRect
    private let visibleFrame: CGRect
    private let reduceMotion: Bool
    private let binRect: () -> CGRect?
    private let bury: (UUID) -> Void
    private var windows: [TrackedWindow] = []
    private var bodies: [Body] = []
    private var physicsTimer: Timer?
    private var spawnTimer: Timer?
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private var stopped = false

    init(screenFrame: CGRect, visibleFrame: CGRect, reduceMotion: Bool,
         binRect: @escaping () -> CGRect?, bury: @escaping (UUID) -> Void) {
        self.screenFrame = screenFrame; self.visibleFrame = visibleFrame
        self.reduceMotion = reduceMotion; self.binRect = binRect; self.bury = bury
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common); physicsTimer = timer
        scheduleSpawn(initial: true)
    }

    func update(windows: [TrackedWindow]) {
        self.windows = windows.filter { $0.frame.intersects(screenFrame) }
        let byID = Dictionary(uniqueKeysWithValues: self.windows.map { ($0.id, $0) })
        let now = ProcessInfo.processInfo.systemUptime
        for body in bodies {
            guard case let .landed(id, relativeX, since) = body.state else { continue }
            guard let window = byID[id],
                  let region = WindowEligibility.titleBarLandingRegion(window: window.frame,
                                                                       visibleFrame: visibleFrame,
                                                                       ownerName: window.ownerName) else {
                body.state = .falling; body.velocity = CGVector(dx: 0, dy: -80); continue
            }
            if window.velocity > 500 {
                let dx = body.previousWindowCenter.map { window.frame.midX - $0.x } ?? 0
                body.state = .falling
                body.velocity = PumpkinPhysics.clampThrowVelocity(CGVector(dx: dx * 12, dy: 180))
                continue
            }
            body.previousWindowCenter = CGPoint(x: window.frame.midX, y: window.frame.midY)
            body.center = CGPoint(x: region.minX + min(max(relativeX, 0), 1) * region.width,
                                  y: region.midY)
            if now - since >= 8 {
                WailoDebugLogger.shared.log(.pumpkinVanished(id: body.id, reason: .idle))
                remove(body, animated: true)
            }
        }
    }

    func remove() {
        stopped = true; physicsTimer?.invalidate(); spawnTimer?.invalidate()
        physicsTimer = nil; spawnTimer = nil
        bodies.forEach { $0.panel.orderOut(nil) }; bodies.removeAll()
    }

    private func scheduleSpawn(initial: Bool = false) {
        guard !stopped else { return }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: initial ? 0.7 : .random(in: 1.6...3.2), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.spawn(); self?.scheduleSpawn() }
        }
    }

    private func spawn() {
        guard bodies.count < 16 else { return }
        let center = CGPoint(x: CGFloat.random(in: screenFrame.minX + 25...screenFrame.maxX - 25),
                             y: visibleFrame.maxY - 18)
        let panel = PumpkinPanel(size: 38)
        let body = Body(center: center,
                        velocity: CGVector(dx: CGFloat.random(in: -30...30), dy: reduceMotion ? -90 : -35),
                        panel: panel)
        panel.onDown = { [weak self, weak body] point in self?.beginDrag(body, at: point) }
        panel.onDrag = { [weak self, weak body] point in self?.drag(body, to: point) }
        panel.onUp = { [weak self, weak body] point in self?.endDrag(body, at: point) }
        bodies.append(body)
        WailoDebugLogger.shared.log(.pumpkinSpawned(id: body.id, point: center))
        position(body); panel.orderFrontRegardless()
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.05, max(0.001, now - lastTick)); lastTick = now
        for body in bodies {
            let pointer = NSEvent.mouseLocation
            body.panel.ignoresMouseEvents = !(isPointer(pointer, over: body) || isDragging(body))
            switch body.state {
            case .falling:
                body.velocity.dy -= 620 * dt
                body.center.x += body.velocity.dx * dt; body.center.y += body.velocity.dy * dt
                if body.center.x < screenFrame.minX + 18 || body.center.x > screenFrame.maxX - 18 {
                    body.velocity.dx *= -0.72
                    body.center.x = min(max(body.center.x, screenFrame.minX + 18), screenFrame.maxX - 18)
                }
                if tryLand(body, now: now) { break }
                if tryBin(body) { break }
                if body.center.y <= visibleFrame.minY + 12 {
                    body.center.y = visibleFrame.minY + 12; body.velocity = .zero; body.state = .dockIdle(since: now)
                }
            case .landed:
                break
            case .dockIdle(let since):
                if tryBin(body) { break }
                if now - since >= 2 {
                    WailoDebugLogger.shared.log(.pumpkinVanished(id: body.id, reason: .dock))
                    remove(body, animated: true)
                }
            case .dragging:
                break
            case .magnetized:
                guard let bin = binRect() else { body.state = .falling; break }
                let target = CGPoint(x: bin.midX, y: bin.midY)
                let dx = target.x - body.center.x, dy = target.y - body.center.y
                body.center.x += dx * min(1, CGFloat(dt * 8)); body.center.y += dy * min(1, CGFloat(dt * 8))
                if hypot(dx, dy) < 8 { buryBody(body) }
            }
            position(body)
        }
    }

    private func tryLand(_ body: Body, now: TimeInterval) -> Bool {
        guard body.velocity.dy <= 0 else { return false }
        for window in windows.sorted(by: { $0.frontOrder < $1.frontOrder }) {
            guard let region = WindowEligibility.titleBarLandingRegion(window: window.frame,
                                                                       visibleFrame: visibleFrame,
                                                                       ownerName: window.ownerName),
                  body.center.x >= region.minX, body.center.x <= region.maxX,
                  body.center.y <= region.maxY + 10, body.center.y >= region.minY - 18 else { continue }
            let relative = (body.center.x - region.minX) / max(1, region.width)
            body.center = CGPoint(x: min(max(body.center.x, region.minX), region.maxX), y: region.midY)
            body.velocity = .zero; body.state = .landed(windowID: window.id, relativeX: relative, since: now)
            WailoDebugLogger.shared.log(.pumpkinLanded(id: body.id, point: body.center, windowID: window.id))
            body.previousWindowCenter = CGPoint(x: window.frame.midX, y: window.frame.midY)
            return true
        }
        return false
    }

    private func tryBin(_ body: Body) -> Bool {
        guard let bin = binRect() else { return false }
        let pumpkinRect = CGRect(x: body.center.x - body.panel.frame.width / 2,
                                 y: body.center.y - body.panel.frame.height / 2,
                                 width: body.panel.frame.width, height: body.panel.frame.height)
        if bin.intersects(pumpkinRect) { buryBody(body); return true }
        if PumpkinPhysics.isInsideMagnetRadius(body.center, bin: bin) {
            body.state = .magnetized; return true
        }
        return false
    }

    private func beginDrag(_ body: Body?, at point: CGPoint) {
        guard let body else { return }
        body.state = .dragging; body.velocity = .zero
        body.dragSamples = [(point, ProcessInfo.processInfo.systemUptime)]
        body.panel.ignoresMouseEvents = false
    }

    private func drag(_ body: Body?, to point: CGPoint) {
        guard let body, isDragging(body) else { return }
        body.center = point; body.dragSamples.append((point, ProcessInfo.processInfo.systemUptime))
        if body.dragSamples.count > 6 { body.dragSamples.removeFirst() }
        position(body)
    }

    private func endDrag(_ body: Body?, at point: CGPoint) {
        guard let body else { return }
        drag(body, to: point)
        let first = body.dragSamples.first ?? (point, ProcessInfo.processInfo.systemUptime)
        let last = body.dragSamples.last ?? first
        let elapsed = max(0.01, last.1 - first.1)
        body.velocity = PumpkinPhysics.clampThrowVelocity(CGVector(dx: (last.0.x - first.0.x) / elapsed,
                                                                    dy: (last.0.y - first.0.y) / elapsed))
        body.dragSamples.removeAll()
        if let bin = binRect(), PumpkinPhysics.isInsideMagnetRadius(point, bin: bin) { body.state = .magnetized }
        else { body.state = .falling }
    }

    private func buryBody(_ body: Body) {
        bury(body.id); remove(body, animated: true)
    }

    private func remove(_ body: Body, animated: Bool) {
        guard let index = bodies.firstIndex(where: { $0 === body }) else { return }
        bodies.remove(at: index)
        if animated {
            body.panel.alphaValue = 0
        }
        body.panel.orderOut(nil)
    }

    private func position(_ body: Body) {
        body.panel.setFrameOrigin(CGPoint(x: body.center.x - body.panel.frame.width / 2,
                                         y: body.center.y - body.panel.frame.height / 2))
    }

    private func isPointer(_ point: CGPoint, over body: Body) -> Bool {
        hypot(point.x - body.center.x, point.y - body.center.y) <= body.panel.frame.width * 0.46
    }

    private func isDragging(_ body: Body) -> Bool {
        if case .dragging = body.state { return true }; return false
    }
}

private final class PumpkinPanel: NSPanel {
    var onDown: ((CGPoint) -> Void)?
    var onDrag: ((CGPoint) -> Void)?
    var onUp: ((CGPoint) -> Void)?

    init(size: CGFloat) {
        super.init(contentRect: CGRect(x: 0, y: 0, width: size, height: size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear; isOpaque = false; hasShadow = false
        ignoresMouseEvents = true; hidesOnDeactivate = false; animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        contentView = PumpkinView(frame: CGRect(x: 0, y: 0, width: size, height: size), panel: self)
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class PumpkinView: NSView {
    weak var pumpkinPanel: PumpkinPanel?
    init(frame: CGRect, panel: PumpkinPanel) { self.pumpkinPanel = panel; super.init(frame: frame); wantsLayer = true }
    required init?(coder: NSCoder) { nil }
    override func draw(_ dirtyRect: NSRect) {
        AssetLoader.shared.image(for: .pumpkin).draw(in: bounds.insetBy(dx: 1, dy: 1))
    }
    override func mouseDown(with event: NSEvent) { pumpkinPanel?.onDown?(NSEvent.mouseLocation) }
    override func mouseDragged(with event: NSEvent) { pumpkinPanel?.onDrag?(NSEvent.mouseLocation) }
    override func mouseUp(with event: NSEvent) { pumpkinPanel?.onUp?(NSEvent.mouseLocation) }
}
