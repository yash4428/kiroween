import AppKit
import SpriteKit

@MainActor
final class CursedPageWarning {
    private let overlays: OverlayWindowManager
    private let ghost: GhostPet
    private let settings: Settings
    private let finder: AXFinder
    private var frostNodes: [SKNode] = []
    private var watchTimer: Timer?
    private var detector = CursedURLDetector()
    private(set) var isVisible = false

    init(overlays: OverlayWindowManager, ghost: GhostPet, settings: Settings, finder: AXFinder) {
        self.overlays = overlays; self.ghost = ghost; self.settings = settings; self.finder = finder
        NotificationCenter.default.addObserver(forName: Settings.changed, object: settings, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshWatcher() }
        }
        refreshWatcher()
    }

    func toggle() { isVisible ? dismiss() : trigger() }

    func trigger() {
        guard !isVisible else { return }; isVisible = true
        installFrost(); ghost.handle(.dangerDetected)
        let screen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
        let actions = [
            SpeechBubble.Action("Close this page", accessibilityLabel: "Close the unsafe Safari page") { [weak self] in self?.closeSafariPage() },
            SpeechBubble.Action("I trust it", accessibilityLabel: "Dismiss this warning") { [weak self] in self?.dismiss() }
        ]
        ghost.say("This page feels cursed 👻 Don’t enter your bank details. Call your family first.",
                  style: .warning, actions: actions, centerOnScreen: screen)
        WailoSound.submarine.play(ifEnabled: settings)
    }

    func dismiss() {
        guard isVisible else { return }; isVisible = false
        for node in frostNodes {
            if settings.reduceMotion { node.removeFromParent() }
            else { node.run(.sequence([.fadeOut(withDuration: 0.45), .removeFromParent()])) }
        }
        frostNodes.removeAll(); ghost.handle(.dangerCleared)
        ghost.say("Phew! Stay safe 💜", autoHide: 2.2)
    }

    func startWatching() { refreshWatcher() }
    func stopWatching() { watchTimer?.invalidate(); watchTimer = nil; detector = CursedURLDetector() }

    private func refreshWatcher() {
        watchTimer?.invalidate(); watchTimer = nil
        guard settings.watchSafari else { detector = CursedURLDetector(); return }
        watchTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.watchTick() }
        }
    }

    private func watchTick() {
        guard settings.watchSafari, finder.frontmostBundleID == "com.apple.Safari" else {
            _ = detector.inspect(nil); return
        }
        if detector.inspect(finder.safariURL()) { trigger() }
    }

    private func installFrost() {
        frostNodes.forEach { $0.removeFromParent() }; frostNodes.removeAll()
        for overlay in overlays.overlays {
            let root = SKNode(); root.zPosition = 80
            let tint = SKShapeNode(rectOf: overlay.effectsScene.size)
            tint.position = CGPoint(x: overlay.effectsScene.size.width / 2, y: overlay.effectsScene.size.height / 2)
            tint.fillColor = NSColor(calibratedRed: 0.35, green: 0.72, blue: 1, alpha: 0.13); tint.strokeColor = .clear
            root.addChild(tint)
            for index in 0..<9 {
                let mist = SKShapeNode(ellipseOf: CGSize(width: 150 + index * 13, height: 38 + index % 3 * 8))
                mist.fillColor = NSColor(calibratedRed: 0.68, green: 0.88, blue: 1, alpha: 0.055)
                mist.strokeColor = .clear
                mist.position = CGPoint(x: CGFloat(index) / 8 * overlay.effectsScene.size.width,
                                        y: 28 + CGFloat(index % 3) * 20)
                mist.name = "coldMist"
                root.addChild(mist)
            }
            for edge in 0..<4 {
                let path = CGMutablePath()
                let size = overlay.effectsScene.size
                let start: CGPoint
                switch edge { case 0: start = CGPoint(x: 0, y: 0); case 1: start = CGPoint(x: size.width, y: 0); case 2: start = CGPoint(x: 0, y: size.height); default: start = CGPoint(x: size.width, y: size.height) }
                path.move(to: start)
                for i in 1...11 {
                    let t = CGFloat(i) / 11
                    let x = edge % 2 == 0 ? t * min(150, size.width * 0.18) : size.width - t * min(150, size.width * 0.18)
                    let y = edge < 2 ? t * min(115, size.height * 0.16) : size.height - t * min(115, size.height * 0.16)
                    let p = CGPoint(x: x, y: y); path.addLine(to: p)
                    path.move(to: p); path.addLine(to: CGPoint(x: p.x + (edge % 2 == 0 ? 18 : -18), y: p.y + (edge < 2 ? 7 : -7))); path.move(to: p)
                }
                let crystal = SKShapeNode(path: path); crystal.strokeColor = NSColor(calibratedRed: 0.7, green: 0.92, blue: 1, alpha: 0.9); crystal.lineWidth = 3; crystal.glowWidth = 5
                root.addChild(crystal)
            }
            root.alpha = settings.reduceMotion ? 1 : 0
            overlay.effectsScene.add(root, to: .fx)
            if !settings.reduceMotion { root.run(.fadeIn(withDuration: 0.55)) }
            frostNodes.append(root)
        }
    }

    private func closeSafariPage() {
        let source = "tell application \"Safari\" to close current tab of front window"
        var errorInfo: NSDictionary?
        if NSAppleScript(source: source)?.executeAndReturnError(&errorInfo) != nil, errorInfo == nil {
            dismiss()
        } else {
            ghost.say("I couldn’t close it. Please press ⌘W in Safari, then choose I trust it to dismiss this warning.",
                      style: .warning,
                      actions: [SpeechBubble.Action("I trust it") { [weak self] in self?.dismiss() }],
                      centerOnScreen: NSScreen.screens.first(where: { $0.frame.origin == .zero }))
        }
    }
}
