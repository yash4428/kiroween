import AppKit
import SpriteKit

protocol HauntingScheduledToken: AnyObject {
    func cancel()
}

protocol HauntingScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, _ action: @escaping () -> Void) -> HauntingScheduledToken
}

final class DispatchHauntingScheduler: HauntingScheduling {
    private final class Token: HauntingScheduledToken {
        private var item: DispatchWorkItem?
        init(item: DispatchWorkItem) { self.item = item }
        func cancel() { item?.cancel(); item = nil }
    }

    func schedule(after delay: TimeInterval, _ action: @escaping () -> Void) -> HauntingScheduledToken {
        let item = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        return Token(item: item)
    }
}

/// Protocol-neutral hooks let the later Pet, Guidance, Safety, and Séance features join the
/// transition without making the foundation depend on any of their types.
struct HauntingCallbacks {
    var ghostRise: (CGPoint) -> Void = { _ in }
    var ghostSink: () -> Void = {}
    var stopTransientFeatures: () -> Void = {}
    var ghostHitTest: (CGPoint) -> Bool = { _ in false }
}

@MainActor
final class HauntingController {
    enum Phase: Equatable {
        case off
        case starting(Int)
        case on
        case stopping(Int)
    }

    private enum Beat: Int, CaseIterable {
        case dim, fog, sky, webs, bats, tombstone, windowDecor, ghost
    }

    @MainActor
    private final class VisualSet {
        let overlay: ScreenOverlay
        var fog: EdgeFog?
        var webs: Cobwebs?
        var bats: BatColony?
        var tombstone: TombstoneTrash?
        var slime: SlimeDrips?
        var pumpkins: PumpkinRain?

        init(overlay: ScreenOverlay) { self.overlay = overlay }

        func removeAll() {
            fog?.remove(); fog = nil
            webs?.remove(); webs = nil
            bats?.remove(); bats = nil
            tombstone?.remove(); tombstone = nil
            slime?.remove(); slime = nil
            pumpkins?.remove(); pumpkins = nil
        }
    }

    private(set) var phase: Phase = .off
    var callbacks: HauntingCallbacks {
        didSet { rebuildFootprintsIfNeeded() }
    }

    let overlays: OverlayWindowManager
    let settings: Settings

    private let scheduler: HauntingScheduling
    private let windowTracker: WindowTracker
    private let dockLocator: DockLocator
    private let notificationCenter: NotificationCenter
    private let workspaceNotificationCenter: NotificationCenter
    private let dripCoordinator = SlimeDripCoordinator()

    private var generation = 0
    private var scheduled: [HauntingScheduledToken] = []
    private var settingsObserver: NSObjectProtocol?
    private var motionObserver: NSObjectProtocol?
    private var trackerToken: UUID?
    private var visualSets: [ObjectIdentifier: VisualSet] = [:]
    private var completedBeats = Set<Beat>()
    private var appliedSettings: Settings.Snapshot
    private var appliedReduceMotion: Bool
    private var footprints: CursorFootprints?
    private var lightningTimer: Timer?
    private var tombstoneGlobalFrame: CGRect?
    private var activeTombstone: TombstoneTrash? {
        visualSets.values.compactMap(\.tombstone).first
    }

    init(
        overlays: OverlayWindowManager,
        settings: Settings,
        scheduler: HauntingScheduling = DispatchHauntingScheduler(),
        windowTracker: WindowTracker = WindowTracker(),
        dockLocator: DockLocator = DockLocator(),
        callbacks: HauntingCallbacks = HauntingCallbacks(),
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        self.overlays = overlays
        self.settings = settings
        self.scheduler = scheduler
        self.windowTracker = windowTracker
        self.dockLocator = dockLocator
        self.callbacks = callbacks
        self.notificationCenter = notificationCenter
        self.workspaceNotificationCenter = workspaceNotificationCenter
        appliedSettings = settings.snapshot
        appliedReduceMotion = settings.reduceMotion

        overlays.onRebuild = { [weak self] in self?.reinstallAfterScreenChange() }
        settingsObserver = notificationCenter.addObserver(
            forName: Settings.changed,
            object: settings,
            queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.applySettingsChange() } }
        motionObserver = workspaceNotificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.applySettingsChange() } }
    }

    deinit {
        scheduled.forEach { $0.cancel() }
        lightningTimer?.invalidate()
        if let trackerToken { windowTracker.unsubscribe(trackerToken) }
        if let settingsObserver { notificationCenter.removeObserver(settingsObserver) }
        if let motionObserver { workspaceNotificationCenter.removeObserver(motionObserver) }
    }

    func toggle() {
        switch phase {
        case .off, .stopping: start()
        case .starting, .on: stop()
        }
    }

    func start() {
        guard phase == .off || isStopping else { return }
        generation += 1
        let currentGeneration = generation
        cancelScheduledWork()
        completedBeats.removeAll()
        phase = .starting(currentGeneration)
        appliedSettings = settings.snapshot
        appliedReduceMotion = settings.reduceMotion
        ensureVisualSets()
        overlays.show()
        configureFootprints()
        installTimeline(generation: currentGeneration)
    }

    func stop() {
        guard phase != .off else { return }
        generation += 1
        let currentGeneration = generation
        cancelScheduledWork()
        phase = .stopping(currentGeneration)
        callbacks.stopTransientFeatures()
        callbacks.ghostSink()
        footprints?.stop(removeExisting: true)
        stopLightning()
        stopWindowTracking()

        visualSets.values.forEach { visual in
            visual.bats?.remove(); visual.bats = nil
            visual.slime?.remove(); visual.slime = nil
            visual.pumpkins?.remove(); visual.pumpkins = nil
            visual.webs?.remove(); visual.webs = nil
            visual.tombstone?.remove(); visual.tombstone = nil
            visual.fog?.remove(); visual.fog = nil
        }

        let scenes = overlays.overlays.map(\.ambienceScene)
        guard !scenes.isEmpty else {
            finishStop(generation: currentGeneration)
            return
        }
        var remaining = scenes.count
        for scene in scenes {
            scene.sunriseAndFade { [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                remaining -= 1
                if remaining == 0 { self.finishStop(generation: currentGeneration) }
            }
        }
        scheduled.append(scheduler.schedule(after: 1.5) { [weak self] in
            self?.finishStop(generation: currentGeneration)
        })
    }

    private var isStopping: Bool {
        if case .stopping = phase { return true }
        return false
    }

    private func installTimeline(generation: Int) {
        let timeline: [(TimeInterval, Beat)] = [
            (0.0, .dim),
            (0.25, .fog),
            (0.60, .sky),
            (1.20, .webs),
            (1.60, .bats),
            (1.90, .tombstone),
            (2.20, .windowDecor),
            (2.60, .ghost)
        ]
        for (delay, beat) in timeline {
            scheduled.append(scheduler.schedule(after: delay) { [weak self] in
                guard let self, self.generation == generation,
                      case .starting(generation) = self.phase else { return }
                self.completedBeats.insert(beat)
                self.apply(beat: beat, animated: true)
                if beat == .ghost { self.phase = .on }
            })
        }
    }

    private func apply(beat: Beat, animated: Bool) {
        switch beat {
        case .dim:
            performOpeningDim(animated: animated)
        case .fog:
            visualSets.values.forEach { visual in
                visual.fog?.remove()
                visual.fog = EdgeFog(
                    scene: visual.overlay.decorScene,
                    opacity: settings.booLevel.fogOpacity,
                    reduceMotion: settings.reduceMotion,
                    animated: animated
                )
            }
        case .sky:
            overlays.overlays.forEach {
                $0.ambienceScene.setNight(
                    opacity: settings.booLevel.skyOpacity,
                    animated: animated,
                    reduceMotion: settings.reduceMotion
                )
            }
        case .webs:
            visualSets.values.forEach { visual in
                visual.webs?.remove()
                visual.webs = Cobwebs(
                    scene: visual.overlay.decorScene,
                    reduceMotion: settings.reduceMotion,
                    animated: animated
                )
            }
        case .bats:
            rebuildBats()
            configureLightning()
        case .tombstone:
            installTombstone()
        case .windowDecor:
            rebuildWindowDecorations()
        case .ghost:
            if animated { callbacks.ghostRise(ghostRisePoint()) }
        }
    }

    private func performOpeningDim(animated: Bool) {
        for overlay in overlays.overlays {
            let veil = SKShapeNode(rectOf: overlay.ambienceScene.size)
            veil.position = CGPoint(x: overlay.ambienceScene.size.width / 2, y: overlay.ambienceScene.size.height / 2)
            veil.fillColor = .black
            veil.strokeColor = .clear
            veil.alpha = 0
            overlay.ambienceScene.add(veil, to: .fx)

            guard animated else { veil.removeFromParent(); continue }
            if settings.booLevel.allowsBrightnessFlicker && !settings.reduceMotion {
                veil.run(.sequence([
                    .fadeAlpha(to: 0.24, duration: 0.08), .fadeOut(withDuration: 0.08),
                    .fadeAlpha(to: 0.16, duration: 0.07), .fadeOut(withDuration: 0.12),
                    .removeFromParent()
                ]))
            } else {
                veil.run(.sequence([
                    .fadeAlpha(to: 0.18, duration: 0.16),
                    .fadeOut(withDuration: 0.28),
                    .removeFromParent()
                ]))
            }
            overlay.ambienceScene.wake()
        }
    }

    private func ensureVisualSets() {
        let activeKeys = Set(overlays.overlays.map { ObjectIdentifier($0) })
        let staleKeys = visualSets.keys.filter { !activeKeys.contains($0) }
        for key in staleKeys {
            visualSets.removeValue(forKey: key)?.removeAll()
        }
        for overlay in overlays.overlays {
            let key = ObjectIdentifier(overlay)
            if visualSets[key] == nil { visualSets[key] = VisualSet(overlay: overlay) }
        }
    }

    private func reinstallAfterScreenChange() {
        guard phase != .off else { return }
        visualSets.values.forEach { $0.removeAll() }
        visualSets.removeAll()
        stopWindowTracking()
        stopLightning()
        ensureVisualSets()
        for beat in Beat.allCases where completedBeats.contains(beat) && beat != .dim && beat != .ghost {
            apply(beat: beat, animated: false)
        }
        configureFootprints()
    }

    private func installTombstone() {
        visualSets.values.forEach { $0.tombstone?.remove(); $0.tombstone = nil }
        let frames = overlays.overlays.map { $0.screen.frame }
        let located = dockLocator.locateTrash(screenFrames: frames)
        tombstoneGlobalFrame = located?.frame
        let targetOverlay: ScreenOverlay?
        if let located {
            targetOverlay = overlays.overlay(containing: CGPoint(x: located.frame.midX, y: located.frame.midY))
        } else {
            targetOverlay = overlays.primaryOverlay
        }
        guard let overlay = targetOverlay, let visual = visualSets[ObjectIdentifier(overlay)] else { return }
        visual.tombstone = TombstoneTrash(
            scene: overlay.decorScene,
            screenFrame: overlay.screen.frame,
            visibleFrame: overlay.screen.visibleFrame,
            location: located
        )
    }

    private func ghostRisePoint() -> CGPoint {
        if let tombstoneGlobalFrame {
            return CGPoint(x: tombstoneGlobalFrame.midX, y: tombstoneGlobalFrame.maxY + 42)
        }
        guard let frame = overlays.primaryOverlay?.screen.visibleFrame else { return .zero }
        return CGPoint(x: frame.maxX - 72, y: frame.minY + 90)
    }

    private func rebuildBats() {
        visualSets.values.forEach { visual in
            visual.bats?.remove()
            visual.bats = settings.bats
                ? BatColony(scene: visual.overlay.decorScene, booLevel: settings.booLevel, reduceMotion: settings.reduceMotion)
                : nil
        }
    }

    private func rebuildWindowDecorations() {
        visualSets.values.forEach { visual in
            visual.slime?.remove(); visual.slime = nil
            visual.pumpkins?.remove(); visual.pumpkins = nil
            if settings.slime {
                visual.slime = SlimeDrips(
                    scene: visual.overlay.decorScene,
                    screenFrame: visual.overlay.screen.frame,
                    maxWindows: settings.booLevel.trackedWindowLimit,
                    reduceMotion: settings.reduceMotion,
                    coordinator: dripCoordinator
                )
            }
            if settings.booLevel.showsPumpkins {
                visual.pumpkins = PumpkinRain(
                    screenFrame: visual.overlay.screen.frame,
                    visibleFrame: visual.overlay.screen.visibleFrame,
                    reduceMotion: settings.reduceMotion,
                    binRect: { [weak self] in self?.activeTombstone?.binRect },
                    bury: { [weak self] id in self?.activeTombstone?.bury(pumpkinID: id) }
                )
            }
        }
        configureWindowTracking()
    }

    private func configureWindowTracking() {
        let needsTracking = visualSets.values.contains { $0.slime != nil || $0.pumpkins != nil }
        if needsTracking, trackerToken == nil {
            trackerToken = windowTracker.subscribe { [weak self] windows in
                Task { @MainActor in
                    self?.visualSets.values.forEach {
                        $0.slime?.update(windows: windows)
                        $0.pumpkins?.update(windows: windows)
                    }
                }
            }
        } else if !needsTracking {
            stopWindowTracking()
        }
    }

    private func stopWindowTracking() {
        if let trackerToken {
            windowTracker.unsubscribe(trackerToken)
            self.trackerToken = nil
        }
    }

    private func configureFootprints() {
        if footprints == nil {
            footprints = CursorFootprints(
                overlays: overlays,
                reduceMotion: { [weak self] in self?.settings.reduceMotion ?? true },
                ghostHitTest: { [weak self] point in self?.callbacks.ghostHitTest(point) ?? false }
            )
        }
        if settings.cursorFootprints, phase != .off {
            footprints?.start()
        } else {
            footprints?.stop(removeExisting: !settings.cursorFootprints)
        }
    }

    private func rebuildFootprintsIfNeeded() {
        footprints?.stop()
        footprints = nil
        if phase != .off { configureFootprints() }
    }

    private func configureLightning() {
        stopLightning()
        guard settings.booLevel.showsLightning, phase != .off else { return }
        scheduleLightning()
    }

    private func scheduleLightning() {
        guard settings.booLevel.showsLightning, phase != .off else { return }
        lightningTimer = Timer.scheduledTimer(withTimeInterval: .random(in: 18 ... 35), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.flashLightning() }
        }
    }

    private func flashLightning() {
        for overlay in overlays.overlays {
            let flash = SKShapeNode(rectOf: overlay.ambienceScene.size)
            flash.position = CGPoint(x: overlay.ambienceScene.size.width / 2, y: overlay.ambienceScene.size.height / 2)
            flash.fillColor = NSColor(calibratedRed: 0.78, green: 0.76, blue: 1, alpha: 1)
            flash.strokeColor = .clear
            flash.alpha = 0
            overlay.ambienceScene.add(flash, to: .fx)
            let peak: CGFloat = settings.reduceMotion ? 0.10 : 0.18
            flash.run(.sequence([
                .fadeAlpha(to: peak, duration: 0.10),
                .fadeOut(withDuration: 0.28),
                .removeFromParent()
            ]))
        }
        scheduleLightning()
    }

    private func stopLightning() {
        lightningTimer?.invalidate()
        lightningTimer = nil
    }

    private func applySettingsChange() {
        let next = settings.snapshot
        let nextReduceMotion = settings.reduceMotion
        guard next != appliedSettings || nextReduceMotion != appliedReduceMotion else { return }
        let previous = appliedSettings
        let motionChanged = nextReduceMotion != appliedReduceMotion
        appliedSettings = next
        appliedReduceMotion = nextReduceMotion
        guard phase != .off else { return }

        if (next.booLevel != previous.booLevel || motionChanged), completedBeats.contains(.sky) {
            overlays.overlays.forEach {
                $0.ambienceScene.setNight(opacity: next.booLevel.skyOpacity, animated: false, reduceMotion: nextReduceMotion)
            }
        }
        if next.booLevel != previous.booLevel, completedBeats.contains(.fog) {
            visualSets.values.forEach { $0.fog?.update(opacity: next.booLevel.fogOpacity) }
        }
        if motionChanged, completedBeats.contains(.fog) {
            visualSets.values.forEach { visual in
                visual.fog?.remove()
                visual.fog = EdgeFog(
                    scene: visual.overlay.decorScene,
                    opacity: next.booLevel.fogOpacity,
                    reduceMotion: nextReduceMotion,
                    animated: false
                )
            }
        }
        if motionChanged, completedBeats.contains(.webs) {
            visualSets.values.forEach { visual in
                visual.webs?.remove()
                visual.webs = Cobwebs(
                    scene: visual.overlay.decorScene,
                    reduceMotion: nextReduceMotion,
                    animated: false
                )
            }
        }
        if completedBeats.contains(.bats),
           next.bats != previous.bats || next.booLevel != previous.booLevel || motionChanged {
            rebuildBats()
        }
        if completedBeats.contains(.windowDecor),
           next.slime != previous.slime || next.booLevel != previous.booLevel || motionChanged {
            rebuildWindowDecorations()
        }
        if next.cursorFootprints != previous.cursorFootprints || motionChanged { configureFootprints() }
        if completedBeats.contains(.bats), next.booLevel != previous.booLevel { configureLightning() }
    }

    private func finishStop(generation expected: Int) {
        guard generation == expected, case .stopping(expected) = phase else { return }
        visualSets.values.forEach { $0.removeAll() }
        visualSets.removeAll()
        completedBeats.removeAll()
        overlays.hide()
        phase = .off
    }

    private func cancelScheduledWork() {
        scheduled.forEach { $0.cancel() }
        scheduled.removeAll()
    }
}
