import AppKit
import SpriteKit

@MainActor
final class GuidanceDirector {
    typealias AXLookup = (GuideStep) -> CGRect?
    typealias CocoaLookup = (GuideStep) -> CGRect?
    typealias VisionLookup = (GuideStep, NSScreen) async -> CGRect?
    typealias SeanceStarter = (GuideStep, @escaping () -> Void) -> Void

    let overlays: OverlayWindowManager
    let ghost: GhostPet
    let settings: Settings

    var axLookup: AXLookup?
    var rememberedLookup: CocoaLookup?
    var visionLookup: VisionLookup?
    var startSeance: SeanceStarter?
    var frontmostBundleID: (() -> String?)?
    var hauntedDockTargetFactory: ((GuideStep) -> HauntedDockTarget?)?
    var onStarted: (() -> Void)?
    var onStopped: (() -> Void)?

    private(set) var script: DemoScript?
    private(set) var index = 0
    private(set) var isRunning = false
    private var generation = 0
    private var searchStarted = Date()
    private var searchTimer: Timer?
    private var clickTimer: Timer?
    private var footprintTimer: Timer?
    private var returnGlobalMonitor: Any?
    private var returnLocalMonitor: Any?
    private var previousMouseDown = false
    private var currentTarget: CGRect?
    private var currentOverlay: ScreenOverlay?
    private var visuals = GuidanceVisualSet()
    private var candles: CandleProgress?
    private var firstTargetPresented = false
    private var visionAttempted = false
    private var hauntedDockTarget: HauntedDockTarget?

    init(overlays: OverlayWindowManager, ghost: GhostPet, settings: Settings) {
        self.overlays = overlays; self.ghost = ghost; self.settings = settings
    }

    func run(_ script: DemoScript) {
        stop(showIdle: false)
        generation += 1
        let active = generation
        self.script = script; index = 0; isRunning = true; firstTargetPresented = false
        ghost.handle(.startPlanning)
        ghost.say("Let me brew a plan… 🕯️")
        onStarted?()
        installCandles(count: script.steps.count, overlay: overlays.primaryOverlay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.generation == active, self.isRunning else { return }
            self.beginStep()
        }
    }

    func next() {
        guard isRunning else { return }
        stepComplete()
    }

    func stop() { stop(showIdle: true) }

    private func stop(showIdle: Bool) {
        generation += 1; isRunning = false
        invalidateStepWork(); visuals.remove(); candles?.remove(); candles = nil
        currentOverlay = nil; currentTarget = nil; script = nil
        overlays.setGuiding(false, on: nil)
        if showIdle { ghost.handle(.cancel); ghost.hideBubble() }
        onStopped?()
    }

    private func beginStep() {
        guard let script, script.steps.indices.contains(index) else { return }
        invalidateStepWork(); visuals.remove(); currentTarget = nil; visionAttempted = false
        candles?.setCurrent(index)
        let step = script.steps[index]
        hauntedDockTarget = hauntedDockTargetFactory?(step)
        ghost.handle(.startSearching)
        if step.advance == .returnKeyOrNext || step.query == .none {
            ghost.handle(.targetFound); ghost.handle(.awaitClick)
            ghost.say(step.instruction)
            installReturnMonitor()
            return
        }
        searchStarted = Date()
        let active = generation
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.generation == active else { return }
                self.searchTick(step)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, self.generation == active else { return }
            self.searchTick(step)
        }
    }

    private func searchTick(_ step: GuideStep) {
        if let bundle = step.bundleHint, !isDockQuery(step.query) {
            if frontmostBundleID?() != bundle {
                searchStarted = Date()
                return
            }
            hauntedDockTarget?.remove(); hauntedDockTarget = nil
        }
        let elapsed = Date().timeIntervalSince(searchStarted)
        if elapsed < 0.7 { return }
        if let remembered = rememberedLookup?(step) { present(cocoaTarget: remembered, step: step); return }
        if let axRect = axLookup?(step) {
            let frames = NSScreen.screens.map(\.frame)
            guard frames.contains(where: { $0.origin == .zero }) else { return }
            present(cocoaTarget: CoordinateSpace.axToCocoa(axRect, screenFrames: frames), step: step)
            return
        }
        if elapsed >= 1.6, settings.visionFallback, !visionAttempted, let visionLookup,
           let screen = screenForSearch(step) {
            visionAttempted = true; ghost.handle(.escalateSearch)
            let active = generation
            Task { @MainActor [weak self] in
                guard let self else { return }
                let result = await visionLookup(step, screen)
                guard self.generation == active, self.isRunning else { return }
                if let result { self.present(cocoaTarget: result, step: step) }
                else { self.ghost.handle(.startSearching) }
            }
        }
        if elapsed >= 3.6 { enterSeance(step) }
    }

    private func isDockQuery(_ query: TargetQuery) -> Bool {
        if case .dockItem = query { return true }
        return false
    }

    private func screenForSearch(_ step: GuideStep) -> NSScreen? {
        if let hint = step.bundleHint,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: hint).first,
           app.isActive { return NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.screens.first }
        return NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.screens.first
    }

    private func present(cocoaTarget: CGRect, step: GuideStep) {
        searchTimer?.invalidate(); searchTimer = nil
        let center = CGPoint(x: cocoaTarget.midX, y: cocoaTarget.midY)
        guard let overlay = overlays.overlay(containing: center) else { enterSeance(step); return }
        currentTarget = cocoaTarget; currentOverlay = overlay
        overlays.setGuiding(true, on: overlay)
        visuals.remove()
        let local = CoordinateSpace.globalToLocal(cocoaTarget, screenFrame: overlay.screen.frame)
        let pointer = CoordinateSpace.globalToLocal(NSEvent.mouseLocation, screenFrame: overlay.screen.frame)
        let dim: CGFloat = settings.booLevel == .cozy ? 0.35 : (settings.booLevel == .spooky ? 0.55 : 0.60)
        visuals.keep(FogSpotlight(scene: overlay.effectsScene, target: local, opacity: dim, reduceMotion: settings.reduceMotion))
        if !firstTargetPresented {
            visuals.keep(SpiderPointer(scene: overlay.effectsScene, target: CGPoint(x: local.midX, y: local.midY), reduceMotion: settings.reduceMotion))
            firstTargetPresented = true
        } else {
            visuals.keep(PumpkinRing(scene: overlay.effectsScene, target: local, reduceMotion: settings.reduceMotion))
        }
        visuals.keep(FootprintTrail(scene: overlay.effectsScene, from: pointer, target: local, reduceMotion: settings.reduceMotion))
        visuals.keep(GhostHandVisual(scene: overlay.effectsScene, target: CGPoint(x: local.midX, y: local.midY), action: step.action, reduceMotion: settings.reduceMotion))
        if settings.showTargetFrames { visuals.keep(DebugTargetVisual(scene: overlay.effectsScene, target: local)) }
        ghost.handle(.targetFound); ghost.say(step.instruction)
        let active = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.generation == active else { return }
            self.ghost.handle(.awaitClick); self.startClickPolling(); self.startFootprintReplay(step: step)
        }
    }

    private func startClickPolling() {
        clickTimer?.invalidate(); previousMouseDown = NSEvent.pressedMouseButtons & 1 != 0
        let active = generation
        clickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.generation == active else { return }
                let down = NSEvent.pressedMouseButtons & 1 != 0
                defer { self.previousMouseDown = down }
                guard down && !self.previousMouseDown, let target = self.currentTarget else { return }
                let point = NSEvent.mouseLocation
                if self.ghost.containsGhost(at: point) || self.ghost.containsBubble(at: point) { return }
                let accepted = target.insetBy(dx: -10, dy: -10)
                if point.x >= accepted.minX, point.x <= accepted.maxX,
                   point.y >= accepted.minY, point.y <= accepted.maxY { self.stepComplete() }
                else { self.wrongClick() }
            }
        }
    }

    private func startFootprintReplay(step: GuideStep) {
        footprintTimer?.invalidate()
        let active = generation
        footprintTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.generation == active,
                      let overlay = self.currentOverlay, let target = self.currentTarget else { return }
                let localTarget = CoordinateSpace.globalToLocal(target, screenFrame: overlay.screen.frame)
                let localPointer = CoordinateSpace.globalToLocal(NSEvent.mouseLocation, screenFrame: overlay.screen.frame)
                self.visuals.keep(FootprintTrail(scene: overlay.effectsScene, from: localPointer, target: localTarget, reduceMotion: self.settings.reduceMotion))
            }
        }
    }

    private func wrongClick() {
        guard let script, script.steps.indices.contains(index) else { return }
        ghost.handle(.clickedWrong); ghost.say("Boo… not there 🙂")
        let active = generation, instruction = script.steps[index].instruction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self, self.generation == active, self.isRunning else { return }
            self.ghost.handle(.wrongClickRecovered); self.ghost.say(instruction)
        }
    }

    private func enterSeance(_ step: GuideStep) {
        searchTimer?.invalidate(); searchTimer = nil
        ghost.handle(.cannotFind)
        if let startSeance {
            startSeance(step) { [weak self] in self?.stepComplete() }
        } else {
            ghost.say("The spirits can’t see it… choose Next, or show me with Séance.", style: .warning,
                      actions: [SpeechBubble.Action("Next step") { [weak self] in self?.next() }])
        }
    }

    private func stepComplete() {
        guard isRunning, let script else { return }
        invalidateStepWork(); visuals.remove()
        let isLast = index == script.steps.count - 1
        ghost.handle(.stepDone(last: isLast))
        if isLast { finish() }
        else {
            index += 1
            let active = generation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                guard let self, self.generation == active else { return }
                self.beginStep()
            }
        }
    }

    private func finish() {
        candles?.lightAll()
        if let overlay = currentOverlay ?? overlays.primaryOverlay {
            let global = currentTarget.map { CGPoint(x: $0.midX, y: $0.midY) }
                ?? CGPoint(x: ghost.ghostFrame.midX, y: ghost.ghostFrame.midY)
            let local = CoordinateSpace.globalToLocal(global, screenFrame: overlay.screen.frame)
            visuals.keep(ConfettiBurst(scene: overlay.effectsScene, at: local, reduceMotion: settings.reduceMotion))
        }
        ghost.say("You did it! 🎉🍬", style: .celebratory)
        isRunning = false; overlays.setGuiding(false, on: nil)
        let active = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self, self.generation == active, !self.isRunning else { return }
            self.visuals.remove(); self.candles?.remove(); self.candles = nil
            self.ghost.handle(.activity); self.ghost.hideBubble(); self.onStopped?()
        }
    }

    private func installCandles(count: Int, overlay: ScreenOverlay?) {
        candles?.remove(); guard let overlay else { return }
        let visibleLocal = CoordinateSpace.globalToLocal(overlay.screen.visibleFrame, screenFrame: overlay.screen.frame)
        let progress = CandleProgress(scene: overlay.effectsScene, count: count, visibleFrameLocal: visibleLocal)
        candles = progress; progress.setCurrent(0)
    }

    private func installReturnMonitor() {
        returnLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 36 { Task { @MainActor in self?.next() } }
            return event
        }
        if AXIsProcessTrusted() {
            returnGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 36 { Task { @MainActor in self?.next() } }
            }
        }
    }

    private func invalidateStepWork() {
        searchTimer?.invalidate(); searchTimer = nil
        clickTimer?.invalidate(); clickTimer = nil
        footprintTimer?.invalidate(); footprintTimer = nil
        hauntedDockTarget?.remove(); hauntedDockTarget = nil
        if let returnGlobalMonitor { NSEvent.removeMonitor(returnGlobalMonitor); self.returnGlobalMonitor = nil }
        if let returnLocalMonitor { NSEvent.removeMonitor(returnLocalMonitor); self.returnLocalMonitor = nil }
    }
}
