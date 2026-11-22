import AppKit

/// Coordinates Wailo's stationary desktop pet, interaction panel, and speech panel.
@MainActor
final class GhostPet {
    enum Mode {
        case hidden
        case parked
        case anchored(globalPoint: CGPoint, generation: Int)
        case dragging(pointerOffset: CGPoint)
    }

    private enum DefaultsKey {
        static let centerX = "wailo.pet.globalCenterX"
        static let centerY = "wailo.pet.globalCenterY"
        static let normalizedX = "wailo.pet.normalizedX"
        static let normalizedY = "wailo.pet.normalizedY"
        static let displayID = "wailo.pet.displayID"
        static let hasPosition = "wailo.pet.hasPosition"
    }

    private static let clickThreshold: CGFloat = 4
    private static let panelSize = GhostView.preferredSize

    private let panel: GhostPanel
    private let ghostView: GhostView
    private let defaults: UserDefaults
    private let bubble: SpeechBubble
    private var screenObserver: NSObjectProtocol?
    private var tickTimer: Timer?
    private var initialPointerDown: CGPoint?
    private var initialPanelOrigin: CGPoint?
    private var lastPointerLocation: CGPoint
    private var lastActivity: Date
    private var hoverInside = false
    private var transitionGeneration = 0

    private(set) var mode: Mode = .hidden
    private(set) var stateMachine: GhostStateMachine

    var onRequestSubmitted: ((String) -> Void)?
    var onPromptCancelled: (() -> Void)?
    var promptSuggestions = [
        "Make a new folder",
        "Open a website in Safari",
        "Check whether this page is a scam"
    ]

    init(
        stateMachine: GhostStateMachine,
        defaults: UserDefaults = .standard,
        bubble: SpeechBubble? = nil
    ) {
        self.stateMachine = stateMachine
        self.defaults = defaults
        self.bubble = bubble ?? SpeechBubble()
        lastPointerLocation = NSEvent.mouseLocation
        lastActivity = Date()

        ghostView = GhostView(frame: CGRect(origin: .zero, size: Self.panelSize))
        panel = GhostPanel(
            contentRect: CGRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanel()
        connectView()
        restoreReachablePosition()
        renderState(animated: false)
        installObservers()
        startTicking()
    }

    deinit {
        tickTimer?.invalidate()
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    var visibleState: GhostState { stateMachine.visible }

    var ghostFrame: CGRect {
        guard panel.isVisible else { return .null }
        return globalBodyFrame(atPanelOrigin: panel.frame.origin)
    }

    var isVisible: Bool {
        if case .hidden = mode { return false }
        return panel.isVisible
    }

    /// Shows the ghost at its persisted reachable location. It never follows the cursor.
    func show(animated: Bool = true) {
        transitionGeneration += 1
        let generation = transitionGeneration
        restoreReachablePosition()
        let destination = panel.frame.origin
        let bodyCenter = CGPoint(x: ghostFrame.midX, y: ghostFrame.midY)
        mode = .anchored(globalPoint: bodyCenter, generation: generation)
        panel.alphaValue = ghostView.reduceMotion && animated ? 0 : 1
        panel.orderFrontRegardless()
        updateBubbleAttachment()

        guard animated else {
            mode = .parked
            panel.alphaValue = 1
            tick()
            return
        }

        if ghostView.reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.24
                panel.animator().alphaValue = 1
            } completionHandler: { [weak self] in
                Task { @MainActor in self?.finishTransition(generation: generation) }
            }
        } else {
            panel.setFrameOrigin(CGPoint(x: destination.x, y: destination.y - 22))
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.34
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrameOrigin(destination)
            } completionHandler: { [weak self] in
                Task { @MainActor in self?.finishTransition(generation: generation) }
            }
        }
    }

    /// Hides the pet with a sink, or a fade when Reduce Motion is enabled.
    func hide(animated: Bool = true) {
        transitionGeneration += 1
        let generation = transitionGeneration
        bubble.hide()
        panel.ignoresMouseEvents = true
        hoverInside = false

        guard animated, panel.isVisible else {
            panel.orderOut(nil)
            panel.alphaValue = 1
            mode = .hidden
            return
        }

        let body = globalBodyFrame(atPanelOrigin: panel.frame.origin)
        mode = .anchored(globalPoint: CGPoint(x: body.midX, y: body.midY), generation: generation)

        if ghostView.reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in self?.finishHide(generation: generation) }
            }
        } else {
            let destination = CGPoint(x: panel.frame.minX, y: panel.frame.minY - 22)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrameOrigin(destination)
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in self?.finishHide(generation: generation) }
            }
        }
    }

    /// Sends one semantic event through the pure state machine and redraws from its result.
    func handle(_ event: GhostEvent, animated: Bool = true) {
        stateMachine.handle(event)
        WailoDebugLogger.shared.log(.ghostStateChanged(stateMachine.visible))
        lastActivity = Date()
        renderState(animated: animated)
    }

    func say(
        _ text: String,
        style: SpeechBubble.Style = .normal,
        actions: [SpeechBubble.Action] = [],
        autoHide: TimeInterval? = nil,
        centerOnScreen: NSScreen? = nil
    ) {
        updateBubbleAttachment()
        bubble.say(text, style: style, actions: actions, autoHide: autoHide, centerOnScreen: centerOnScreen)
    }

    func openPrompt(initialText: String = "") {
        guard panel.isVisible else { return }
        handle(.startListening)
        updateBubbleAttachment()
        bubble.ask(
            prompt: "What would you like to do?",
            suggestions: promptSuggestions,
            initialText: initialText,
            onSubmit: { [weak self] text in
                guard let self else { return }
                self.handle(.cancel)
                self.onRequestSubmitted?(text)
            },
            onCancel: { [weak self] in
                guard let self else { return }
                self.handle(.cancel)
                self.onPromptCancelled?()
            }
        )
    }

    /// Returns true for the currently visible speech or prompt panel.
    func containsBubble(at globalPoint: CGPoint) -> Bool {
        bubble.covers(globalPoint: globalPoint)
    }

    /// Debug-only state preview used by the menu and contest demonstrations.
    func debugShowNextState() {
        let states = GhostState.allCases
        let current = states.firstIndex(of: stateMachine.visible) ?? 0
        stateMachine = GhostStateMachine(visible: states[(current + 1) % states.count])
        renderState(animated: true)
    }

    func hideBubble() {
        bubble.hide()
    }

    /// Returns true only for the visible procedural body, not the transparent panel rectangle.
    func containsGhost(at globalPoint: CGPoint) -> Bool {
        guard panel.isVisible else { return false }
        let local = CGPoint(x: globalPoint.x - panel.frame.minX, y: globalPoint.y - panel.frame.minY)
        return ghostView.bodyContains(local)
    }

    // MARK: - Panel and interaction

    private func configurePanel() {
        // isFloatingPanel resets level, so assign the final level afterward.
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.contentView = ghostView
    }

    private func connectView() {
        ghostView.onPointerDown = { [weak self] point in self?.pointerDown(at: point) }
        ghostView.onPointerDragged = { [weak self] point in self?.pointerDragged(to: point) }
        ghostView.onPointerUp = { [weak self] point in self?.pointerUp(at: point) }
        ghostView.onReduceMotionChanged = { [weak self] _ in
            guard let self else { return }
            self.renderState(animated: false)
        }
    }

    private func pointerDown(at globalPoint: CGPoint) {
        guard panel.isVisible, containsGhost(at: globalPoint) else { return }
        transitionGeneration += 1
        initialPointerDown = globalPoint
        initialPanelOrigin = panel.frame.origin
        let offset = CGPoint(x: globalPoint.x - panel.frame.minX, y: globalPoint.y - panel.frame.minY)
        mode = .dragging(pointerOffset: offset)
        panel.ignoresMouseEvents = false
        noteActivity(pointer: globalPoint)
    }

    private func pointerDragged(to globalPoint: CGPoint) {
        guard case let .dragging(offset) = mode else { return }
        let candidate = CGPoint(x: globalPoint.x - offset.x, y: globalPoint.y - offset.y)
        panel.setFrameOrigin(constrainedPanelOrigin(candidate))
        noteActivity(pointer: globalPoint)
        updateBubbleAttachment()
    }

    private func pointerUp(at globalPoint: CGPoint) {
        guard case .dragging = mode, let down = initialPointerDown else { return }
        let movement = hypot(globalPoint.x - down.x, globalPoint.y - down.y)
        initialPointerDown = nil
        mode = .parked

        if movement < Self.clickThreshold {
            if let initialPanelOrigin { panel.setFrameOrigin(initialPanelOrigin) }
            self.initialPanelOrigin = nil
            updateBubbleAttachment()
            openPrompt()
        } else {
            initialPanelOrigin = nil
            panel.setFrameOrigin(constrainedPanelOrigin(panel.frame.origin))
            persistPosition()
            updateBubbleAttachment()
        }
        noteActivity(pointer: globalPoint)
        tick()
    }

    // MARK: - Position persistence

    private func restoreReachablePosition() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        let desiredOrigin: CGPoint

        if defaults.bool(forKey: DefaultsKey.hasPosition) {
            let savedDisplayID = defaults.string(forKey: DefaultsKey.displayID)
            if let savedScreen = screens.first(where: { displayIdentifier(for: $0) == savedDisplayID }) {
                let nx = clamped(CGFloat(defaults.double(forKey: DefaultsKey.normalizedX)), 0, 1)
                let ny = clamped(CGFloat(defaults.double(forKey: DefaultsKey.normalizedY)), 0, 1)
                let center = CGPoint(
                    x: savedScreen.visibleFrame.minX + nx * savedScreen.visibleFrame.width,
                    y: savedScreen.visibleFrame.minY + ny * savedScreen.visibleFrame.height
                )
                desiredOrigin = panelOrigin(forBodyCenter: center)
            } else {
                let center = CGPoint(
                    x: defaults.double(forKey: DefaultsKey.centerX),
                    y: defaults.double(forKey: DefaultsKey.centerY)
                )
                desiredOrigin = panelOrigin(forBodyCenter: center)
            }
        } else {
            let primary = screens.first(where: { $0.frame.origin == .zero }) ?? screens[0]
            let frame = primary.visibleFrame
            let center = CGPoint(x: frame.minX + frame.width * 0.80, y: frame.minY + frame.height * 0.30)
            desiredOrigin = panelOrigin(forBodyCenter: center)
        }

        panel.setFrameOrigin(constrainedPanelOrigin(desiredOrigin))
        updateBubbleAttachment()
    }

    private func persistPosition() {
        let bodyFrame = globalBodyFrame(atPanelOrigin: panel.frame.origin)
        let bodyCenter = CGPoint(x: bodyFrame.midX, y: bodyFrame.midY)
        guard let screen = containingOrNearestScreen(to: bodyCenter) else { return }
        let visible = screen.visibleFrame
        let normalizedX = visible.width > 0 ? (bodyCenter.x - visible.minX) / visible.width : 0.5
        let normalizedY = visible.height > 0 ? (bodyCenter.y - visible.minY) / visible.height : 0.5

        defaults.set(Double(bodyCenter.x), forKey: DefaultsKey.centerX)
        defaults.set(Double(bodyCenter.y), forKey: DefaultsKey.centerY)
        defaults.set(Double(clamped(normalizedX, 0, 1)), forKey: DefaultsKey.normalizedX)
        defaults.set(Double(clamped(normalizedY, 0, 1)), forKey: DefaultsKey.normalizedY)
        defaults.set(displayIdentifier(for: screen), forKey: DefaultsKey.displayID)
        defaults.set(true, forKey: DefaultsKey.hasPosition)
    }

    private func constrainedPanelOrigin(_ candidate: CGPoint) -> CGPoint {
        let frames = NSScreen.screens.map(\.visibleFrame).filter { !$0.isEmpty }
        guard !frames.isEmpty else { return candidate }
        let localBody = ghostView.bodyBounds
        let candidateBody = localBody.offsetBy(dx: candidate.x, dy: candidate.y)
        if frames.contains(where: { $0.contains(candidateBody) }) {
            return candidate
        }

        var bestOrigin = candidate
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for frame in frames where frame.width >= localBody.width && frame.height >= localBody.height {
            let x = clamped(candidate.x, frame.minX - localBody.minX, frame.maxX - localBody.maxX)
            let y = clamped(candidate.y, frame.minY - localBody.minY, frame.maxY - localBody.maxY)
            let distance = pow(x - candidate.x, 2) + pow(y - candidate.y, 2)
            if distance < bestDistance {
                bestDistance = distance
                bestOrigin = CGPoint(x: x, y: y)
            }
        }
        return bestOrigin
    }

    private func panelOrigin(forBodyCenter center: CGPoint) -> CGPoint {
        let body = ghostView.bodyBounds
        return CGPoint(x: center.x - body.midX, y: center.y - body.midY)
    }

    private func globalBodyFrame(atPanelOrigin origin: CGPoint) -> CGRect {
        ghostView.bodyBounds.offsetBy(dx: origin.x, dy: origin.y)
    }

    private func containingOrNearestScreen(to point: CGPoint) -> NSScreen? {
        let screens = NSScreen.screens
        if let containing = screens.first(where: { $0.visibleFrame.contains(point) }) {
            return containing
        }
        return screens.min {
            distanceSquared(from: point, to: $0.visibleFrame) < distanceSquared(from: point, to: $1.visibleFrame)
        }
    }

    private func displayIdentifier(for screen: NSScreen) -> String {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return number.stringValue
        }
        return "\(screen.localizedName)|\(Int(screen.frame.minX)),\(Int(screen.frame.minY))|\(Int(screen.frame.width))x\(Int(screen.frame.height))"
    }

    // MARK: - Lifecycle, hover, and sleeping

    private func installObservers() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.screensChanged() }
        }
    }

    private func startTicking() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    private func tick() {
        guard panel.isVisible else {
            panel.ignoresMouseEvents = true
            return
        }

        let pointer = NSEvent.mouseLocation
        let pointerMoved = hypot(pointer.x - lastPointerLocation.x, pointer.y - lastPointerLocation.y) > 0.5
        if pointerMoved {
            lastPointerLocation = pointer
            lastActivity = Date()
            if isSleeping {
                handle(.activity)
            }
        }

        let inside = containsGhost(at: pointer)
        switch mode {
        case .dragging:
            panel.ignoresMouseEvents = false
        case .parked:
            panel.ignoresMouseEvents = !inside
        case .anchored, .hidden:
            panel.ignoresMouseEvents = true
        }

        if case .parked = mode, isIdle {
            if inside && !hoverInside {
                hoverInside = true
                if !bubble.isVisible {
                    ghostView.performGiggle()
                    say("hehe", autoHide: 1.35)
                }
            } else if !inside {
                hoverInside = false
            }
        } else if !inside {
            hoverInside = false
        }

        if isIdle, Date().timeIntervalSince(lastActivity) >= sleepThreshold(at: Date()) {
            handle(.idleTooLong)
        }
    }

    private func noteActivity(pointer: CGPoint) {
        lastPointerLocation = pointer
        lastActivity = Date()
        if isSleeping { handle(.activity) }
    }

    private func sleepThreshold(at date: Date) -> TimeInterval {
        let hour = Calendar.current.component(.hour, from: date)
        return (0..<5).contains(hour) ? 60 : 10 * 60
    }

    private func screensChanged() {
        let currentBody = globalBodyFrame(atPanelOrigin: panel.frame.origin)
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        if !visibleFrames.contains(where: { $0.contains(currentBody) }) {
            panel.setFrameOrigin(constrainedPanelOrigin(panel.frame.origin))
            persistPosition()
        }
        updateBubbleAttachment()
        tick()
    }

    private func renderState(animated: Bool) {
        ghostView.apply(state: stateMachine.visible, animated: animated)
        panel.setFrameOrigin(constrainedPanelOrigin(panel.frame.origin))
        if panel.isVisible { persistPosition() }
        updateBubbleAttachment()
    }

    private func updateBubbleAttachment() {
        bubble.follow(
            ghostFrame: globalBodyFrame(atPanelOrigin: panel.frame.origin),
            visibleFrames: NSScreen.screens.map(\.visibleFrame)
        )
    }

    private func finishTransition(generation: Int) {
        guard transitionGeneration == generation else { return }
        guard case let .anchored(_, activeGeneration) = mode, activeGeneration == generation else { return }
        mode = .parked
        panel.alphaValue = 1
        panel.setFrameOrigin(constrainedPanelOrigin(panel.frame.origin))
        persistPosition()
        updateBubbleAttachment()
        tick()
    }

    private func finishHide(generation: Int) {
        guard transitionGeneration == generation else { return }
        panel.orderOut(nil)
        panel.alphaValue = 1
        mode = .hidden
    }

    private var isIdle: Bool {
        if case .idle = stateMachine.visible { return true }
        return false
    }

    private var isSleeping: Bool {
        if case .sleeping = stateMachine.visible { return true }
        return false
    }

    private func distanceSquared(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let nearestX = clamped(point.x, rect.minX, rect.maxX)
        let nearestY = clamped(point.y, rect.minY, rect.maxY)
        return pow(point.x - nearestX, 2) + pow(point.y - nearestY, 2)
    }

    private func clamped(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

private final class GhostPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
