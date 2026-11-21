import AppKit
import ApplicationServices

@main
enum WailoMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: Settings!
    private var overlays: OverlayWindowManager!
    private var ghost: GhostPet!
    private var haunting: HauntingController!
    private var finder: AXFinder!
    private var grimoire: GrimoireController!
    private var grimoireWindow: GrimoireWindowController!
    private var seance: SeanceMode!
    private var director: GuidanceDirector!
    private var liveMode: LiveMode!
    private var warning: CursedPageWarning!
    private var mail: GhostMail!
    private var shakeToFind: ShakeToFindController!
    private var roomReader: RoomReader!
    private var menu: MenuBarController!
    private var hotKeys: HotKeys!
    private var vision: VisionService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        requestAccessibilityIfNeeded()

        settings = Settings()
        overlays = OverlayWindowManager()
        ghost = GhostPet(stateMachine: GhostStateMachine())
        finder = AXFinder()
        vision = VisionService()
        grimoire = GrimoireController(finder: finder, ghost: ghost)
        grimoireWindow = GrimoireWindowController(model: grimoire)
        seance = SeanceMode(overlays: overlays, ghost: ghost, finder: finder, grimoire: grimoire, settings: settings)
        director = GuidanceDirector(overlays: overlays, ghost: ghost, settings: settings)
        liveMode = LiveMode(director: director, ghost: ghost)
        warning = CursedPageWarning(overlays: overlays, ghost: ghost, settings: settings, finder: finder)
        mail = GhostMail(overlays: overlays, ghost: ghost, settings: settings)
        shakeToFind = ShakeToFindController(overlays: overlays, ghost: ghost, settings: settings,
                                            isGuideActive: { [weak director] in director?.isRunning ?? false })
        shakeToFind.start()
        roomReader = RoomReader(
            isSuppressed: { [weak self] in (self?.director.isRunning ?? true) || (self?.warning.isVisible ?? true) },
            onOffer: { [weak self] offer in self?.showRoomTip(offer) }
        )
        roomReader.start()

        director.axLookup = { [weak finder] step in finder?.find(step.query, bundleHint: step.bundleHint) }
        director.rememberedLookup = { [weak grimoire] step in grimoire?.rememberedTarget(for: step) }
        director.visionLookup = { [weak self] step, screen in
            guard let self, self.settings.visionFallback else { return nil }
            let label: String
            switch step.query {
            case .smart(let value), .dockItem(let value), .menuBarItem(let value), .menuItem(let value): label = value
            case .element(let keywords, _): label = keywords.joined(separator: " ")
            case .safariAddressBar: label = "Safari address and search field"
            case .none: return nil
            }
            return await self.vision.locate(label: label, instruction: step.instruction, on: screen)?.cocoaRect
        }
        director.startSeance = { [weak seance] step, completion in seance?.begin(step: step, completion: completion) }
        director.frontmostBundleID = { [weak finder] in finder?.frontmostBundleID }
        director.hauntedDockTargetFactory = { [weak self] step in
            guard let self else { return nil }
            let label: String
            if case .dockItem(let value) = step.query { label = value }
            else if let bundle = step.bundleHint {
                label = NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first?.localizedName
                    ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle)?.deletingPathExtension().lastPathComponent
                    ?? bundle
            } else { return nil }
            return HauntedDockTarget(overlays: self.overlays, finder: self.finder, appLabel: label,
                                     bundleID: step.bundleHint, reduceMotion: self.settings.reduceMotion)
        }

        haunting = HauntingController(overlays: overlays, settings: settings)
        haunting.callbacks = HauntingCallbacks(
            ghostRise: { [weak ghost] _ in ghost?.show() },
            ghostSink: { [weak ghost] in ghost?.hide() },
            stopTransientFeatures: { [weak self] in
                self?.director.stop(); self?.seance.stop(); self?.warning.dismiss()
            },
            ghostHitTest: { [weak ghost] point in ghost?.containsGhost(at: point) ?? false }
        )
        director.onStarted = { [weak self] in self?.ensureHaunting() }
        ghost.onRequestSubmitted = { [weak self] text in self?.route(text) }

        menu = MenuBarController(settings: settings, haunting: haunting,
                                 onAction: { [weak self] action in self?.perform(action) },
                                 onSeance: { [weak self] in self?.ensureHaunting(); self?.seance.beginManual() },
                                 onGrimoire: { [weak grimoireWindow] in grimoireWindow?.show() })
        hotKeys = HotKeys { [weak self] action in self?.perform(action) }

        haunting.start()
        scheduleAutoDemo()
    }

    func applicationWillTerminate(_ notification: Notification) {
        liveMode?.cancel(); director?.stop(); seance?.stop(); warning?.stopWatching(); shakeToFind?.stop(); roomReader?.stop()
    }

    private func showRoomTip(_ offer: RoomReader.Offer) {
        let notNow = SpeechBubble.Action("Not now", accessibilityLabel: "Dismiss help suggestion") { [weak ghost] in
            ghost?.hideBubble()
        }
        switch offer.kind {
        case .finder:
            ghost.say("You’ve been in Finder a little while. Would you like help?",
                      actions: [SpeechBubble.Action("Make a new folder") { [weak director] in director?.run(.newFolder) }, notNow])
        case .browser:
            ghost.say("Would you like me to check whether this page looks safe?",
                      actions: [SpeechBubble.Action("Is this page safe?") { [weak self] in self?.checkCurrentPageSafety() }, notNow])
        case .mail:
            ghost.say("Would you like help composing or finding mail?",
                      actions: [SpeechBubble.Action("Help with Mail") { [weak liveMode] in liveMode?.run(task: "Help me compose or find an email in Mail") }, notNow])
        case .systemSettings:
            ghost.say("Would you like help changing a setting?",
                      actions: [SpeechBubble.Action("Help with settings") { [weak liveMode] in liveMode?.run(task: "Help me change a setting in System Settings") }, notNow])
        case .generic(let appName):
            ghost.say("Would you like help with \(appName)?",
                      actions: [SpeechBubble.Action("Ask Wailo") { [weak ghost] in ghost?.openPrompt(initialText: "Help me with \(appName)") }, notNow])
        }
    }

    private func checkCurrentPageSafety() {
        if let url = finder.safariURL(), CursedURL.isCursed(url) {
            warning.trigger()
        } else {
            ghost.say("I don’t see one of the scam warning signs I know. Still avoid sharing bank details if anything feels unusual. 💜",
                      autoHide: 5)
        }
    }

    private func route(_ text: String) {
        let route = TaskRouter.route(text)
        if route != .grimoire && route != .nothing { ensureHaunting() }
        switch route {
        case .newFolder: director.run(.newFolder)
        case .safari: director.run(.safari)
        case .cursed: warning.trigger()
        case .ghostMail: mail.deliver()
        case .grimoire: grimoireWindow.show()
        case .live(let task): liveMode.run(task: task)
        case .nothing: ghost.openPrompt()
        }
    }

    private func perform(_ action: WailoAction) {
        switch action {
        case .toggleHaunting: haunting.toggle()
        case .prompt: ensureHaunting(); ghost.openPrompt()
        case .folderDemo: director.run(.newFolder)
        case .safariDemo: director.run(.safari)
        case .nextStep: director.next()
        case .cursedPage: ensureHaunting(); warning.toggle()
        case .cycleGhost: ensureHaunting(); ghost.debugShowNextState()
        case .ghostMail: ensureHaunting(); mail.deliver()
        case .stopGuidance: liveMode.cancel(); director.stop(); seance.stop()
        }
    }

    private func ensureHaunting() {
        if haunting.phase == .off {
            haunting.start()
            ghost.show(animated: false)
        }
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let key = "wailo.didRequestAccessibility"
        if !UserDefaults.standard.bool(forKey: key) {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    private func scheduleAutoDemo() {
        guard let value = ProcessInfo.processInfo.environment["WAILO_AUTODEMO"],
              ["folder", "safari", "cursed", "prompt"].contains(value) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            guard let self else { return }
            switch value {
            case "folder": self.director.run(.newFolder)
            case "safari": self.director.run(.safari)
            case "cursed": self.warning.trigger()
            case "prompt": self.ghost.openPrompt()
            default: break
            }
        }
    }
}
