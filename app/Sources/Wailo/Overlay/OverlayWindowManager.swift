import AppKit
import SpriteKit

final class PassThroughWindow: NSPanel {
    init(frame: CGRect, level windowLevel: NSWindow.Level) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = false
        level = windowLevel
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = false
        hidesOnDeactivate = false
        animationBehavior = .none
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

enum EffectsLayer: String, CaseIterable {
    case weather, decor, guide, cursorLayer, fx
}

/// A scene that sleeps when finite effects have settled. Calling `add` or `wake` starts one full
/// grace interval before the next idle check is allowed to pause the backing view.
class EffectsScene: SKScene {
    let weather = SKNode()
    let decor = SKNode()
    let guide = SKNode()
    let cursorLayer = SKNode()
    let fx = SKNode()

    private var wakeDeadline: TimeInterval = 0
    private var nextIdleCheck: TimeInterval = 0
    private let idleCheckInterval: TimeInterval = 0.35

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = .zero

        for (node, name) in [
            (weather, EffectsLayer.weather.rawValue),
            (decor, EffectsLayer.decor.rawValue),
            (guide, EffectsLayer.guide.rawValue),
            (cursorLayer, EffectsLayer.cursorLayer.rawValue),
            (fx, EffectsLayer.fx.rawValue)
        ] {
            node.name = name
            addChild(node)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layer(_ layer: EffectsLayer) -> SKNode {
        switch layer {
        case .weather: weather
        case .decor: decor
        case .guide: guide
        case .cursorLayer: cursorLayer
        case .fx: fx
        }
    }

    func add(_ node: SKNode, to targetLayer: EffectsLayer = .fx) {
        layer(targetLayer).addChild(node)
        wake()
    }

    func wake() {
        let now = CACurrentMediaTime()
        wakeDeadline = now + idleCheckInterval
        nextIdleCheck = wakeDeadline
        view?.isPaused = false
    }

    override func didMove(to view: SKView) {
        wake()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let now = CACurrentMediaTime()
        guard now >= wakeDeadline, now >= nextIdleCheck else { return }
        nextIdleCheck = now + idleCheckInterval
        if !containsActiveWork(self) {
            view?.isPaused = true
        }
    }

    private func containsActiveWork(_ node: SKNode) -> Bool {
        if node.hasActions() { return true }
        if let emitter = node as? SKEmitterNode, emitter.particleBirthRate > 0 { return true }
        return node.children.contains { child in
            self.containsActiveWork(child)
        }
    }
}

final class ScreenOverlay {
    let screen: NSScreen
    let displayID: CGDirectDisplayID
    let ambienceWindow: PassThroughWindow
    let decorWindow: PassThroughWindow
    let effectsWindow: PassThroughWindow
    let ambienceView: SKView
    let decorView: SKView
    let effectsView: SKView
    let ambienceScene: NightSkyScene
    let decorScene: EffectsScene
    let effectsScene: EffectsScene

    init(screen: NSScreen) {
        self.screen = screen
        displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map { CGDirectDisplayID($0.uint32Value) } ?? 0

        let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        ambienceWindow = PassThroughWindow(frame: screen.frame, level: desktopLevel)
        decorWindow = PassThroughWindow(frame: screen.frame, level: .statusBar)
        effectsWindow = PassThroughWindow(
            frame: screen.frame,
            level: NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        )

        ambienceScene = NightSkyScene(size: screen.frame.size)
        decorScene = EffectsScene(size: screen.frame.size)
        effectsScene = EffectsScene(size: screen.frame.size)

        ambienceView = Self.makeView(frame: CGRect(origin: .zero, size: screen.frame.size), scene: ambienceScene, fps: 20)
        decorView = Self.makeView(frame: CGRect(origin: .zero, size: screen.frame.size), scene: decorScene, fps: 30)
        effectsView = Self.makeView(frame: CGRect(origin: .zero, size: screen.frame.size), scene: effectsScene, fps: 30)

        ambienceWindow.contentView = ambienceView
        decorWindow.contentView = decorView
        effectsWindow.contentView = effectsView
    }

    func show() {
        ambienceWindow.orderFrontRegardless()
        decorWindow.orderFrontRegardless()
        effectsWindow.orderFrontRegardless()
    }

    func hide() {
        ambienceWindow.orderOut(nil)
        decorWindow.orderOut(nil)
        effectsWindow.orderOut(nil)
    }

    func setGuiding(_ guiding: Bool) {
        effectsView.preferredFramesPerSecond = guiding ? 60 : 30
        if guiding { effectsScene.wake() }
    }

    private static func makeView(frame: CGRect, scene: SKScene, fps: Int) -> SKView {
        let view = SKView(frame: frame)
        view.allowsTransparency = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.preferredFramesPerSecond = fps
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.presentScene(scene)
        return view
    }
}

/// Owns exactly one ambience/decor/effects set per display and recreates those sets after display
/// changes. Clients reinstall semantic state through `onRebuild`; no intro is replayed here.
final class OverlayWindowManager {
    private(set) var overlays: [ScreenOverlay] = []
    var onRebuild: (() -> Void)?
    private(set) var windowsVisible = false

    private let notificationCenter: NotificationCenter
    private var screenObserver: NSObjectProtocol?
    private var rebuildQueued = false

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        rebuild()
        screenObserver = notificationCenter.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleRebuild()
        }
    }

    deinit {
        if let screenObserver { notificationCenter.removeObserver(screenObserver) }
    }

    var primaryOverlay: ScreenOverlay? {
        overlays.first(where: { $0.screen.frame.origin == .zero })
    }

    func overlay(containing globalPoint: CGPoint) -> ScreenOverlay? {
        guard !overlays.isEmpty else { return nil }
        let frames = overlays.map { $0.screen.frame }
        let index = CoordinateSpace.screenIndex(containing: globalPoint, screenFrames: frames)
        guard overlays.indices.contains(index) else { return primaryOverlay ?? overlays.first }
        return overlays[index]
    }

    func show() {
        windowsVisible = true
        overlays.forEach { $0.show() }
    }

    func hide() {
        windowsVisible = false
        overlays.forEach { $0.hide() }
    }

    func setGuiding(_ guiding: Bool, on target: ScreenOverlay?) {
        overlays.forEach { $0.setGuiding(guiding && $0 === target) }
    }

    func rebuild() {
        let screens = NSScreen.screens
        guard !screens.isEmpty, screens.contains(where: { $0.frame.origin == .zero }) else {
            scheduleRebuild()
            return
        }

        let wasVisible = windowsVisible
        overlays.forEach { $0.hide() }
        overlays = screens.map(ScreenOverlay.init)
        if wasVisible { overlays.forEach { $0.show() } }
        onRebuild?()
    }

    private func scheduleRebuild() {
        guard !rebuildQueued else { return }
        rebuildQueued = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.rebuildQueued = false
            self.rebuild()
        }
    }
}
