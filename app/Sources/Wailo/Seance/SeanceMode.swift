import AppKit
import SpriteKit

@MainActor
final class SeanceMode {
    private let overlays: OverlayWindowManager
    private let ghost: GhostPet
    private let finder: AXFinder
    private let grimoire: GrimoireController
    private let settings: Settings
    private var timer: Timer?
    private var node: SKNode?
    private weak var nodeOverlay: ScreenOverlay?
    private var step: GuideStep?
    private var completion: (() -> Void)?
    private var previousDown = false

    init(overlays: OverlayWindowManager, ghost: GhostPet, finder: AXFinder,
         grimoire: GrimoireController, settings: Settings) {
        self.overlays = overlays; self.ghost = ghost; self.finder = finder
        self.grimoire = grimoire; self.settings = settings
    }

    func begin(step: GuideStep, completion: @escaping () -> Void) {
        stop(); self.step = step; self.completion = completion
        ghost.handle(.cannotFind)
        ghost.say("The spirits can’t see it… show me where it is")
        startPolling()
    }

    func beginManual() {
        let alert = NSAlert(); alert.messageText = "Name this spell"
        alert.informativeText = "What should Wailo remember at the place you click?"
        let field = NSTextField(string: "Remember this spot"); field.font = .systemFont(ofSize: 18)
        alert.accessoryView = field; alert.addButton(withTitle: "Teach Wailo"); alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let label = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return }
        begin(step: GuideStep(instruction: label, query: .none, action: .none), completion: {})
    }

    func stop() {
        timer?.invalidate(); timer = nil; node?.removeFromParent(); node = nil; nodeOverlay = nil
        step = nil; completion = nil; previousDown = false
    }

    private func startPolling() {
        previousDown = NSEvent.pressedMouseButtons & 1 != 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    private func tick() {
        let point = NSEvent.mouseLocation
        updatePlanchette(at: point)
        let down = NSEvent.pressedMouseButtons & 1 != 0
        defer { previousDown = down }
        guard down && !previousDown, !ghost.containsGhost(at: point), !ghost.containsBubble(at: point) else { return }
        record(point)
    }

    private func updatePlanchette(at global: CGPoint) {
        guard let overlay = overlays.overlay(containing: global) else { return }
        if node == nil || nodeOverlay !== overlay {
            node?.removeFromParent()
            let root = SKNode(); root.zPosition = 90
            let board = SKShapeNode(path: planchettePath())
            board.fillColor = NSColor(calibratedRed: 0.45, green: 0.25, blue: 0.12, alpha: 0.94)
            board.strokeColor = NSColor(calibratedRed: 0.88, green: 0.70, blue: 0.34, alpha: 1); board.lineWidth = 3
            let lens = SKShapeNode(circleOfRadius: 10); lens.fillColor = NSColor(calibratedRed: 0.55, green: 0.28, blue: 0.75, alpha: 0.45); lens.strokeColor = .white; lens.position.y = 3
            root.addChild(board); root.addChild(lens); overlay.effectsScene.add(root, to: .fx)
            node = root; nodeOverlay = overlay
        }
        node?.position = CoordinateSpace.globalToLocal(global, screenFrame: overlay.screen.frame)
        if !settings.reduceMotion { node?.zRotation = sin(CACurrentMediaTime() * 2) * 0.04 }
        overlay.effectsScene.wake()
    }

    private func record(_ cocoaPoint: CGPoint) {
        guard let step else { return }
        let frames = NSScreen.screens.map(\.frame)
        guard frames.contains(where: { $0.origin == .zero }) else { return }
        let context = finder.context(at: cocoaPoint, screenFrames: frames)
        guard let bundleID = step.bundleHint ?? context?.bundleID else {
            ghost.say("Please click over the app you want me to remember.", style: .warning)
            return
        }
        let axPoint = CoordinateSpace.cocoaToAX(cocoaPoint, screenFrames: frames)
        var relX: Double?, relY: Double?
        if let frame = context?.frameAX, frame.width > 0, frame.height > 0 {
            relX = Double(min(max((axPoint.x - frame.minX) / frame.width, 0), 1))
            relY = Double(min(max((axPoint.y - frame.minY) / frame.height, 0), 1))
        }
        let spell = Spell(bundleID: bundleID,
                          appName: context?.appName ?? bundleID,
                          stepText: step.instruction,
                          relX: relX, relY: relY,
                          absX: Double(axPoint.x), absY: Double(axPoint.y))
        grimoire.learn(spell)
        let done = completion
        ghost.say("✨ I learned that spell!", style: .celebratory, autoHide: 1.5)
        stop(); done?()
    }

    private func planchettePath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 34)); path.addCurve(to: CGPoint(x: -32, y: -24), control1: CGPoint(x: -25, y: 25), control2: CGPoint(x: -38, y: -4))
        path.addCurve(to: CGPoint(x: 32, y: -24), control1: CGPoint(x: -12, y: -12), control2: CGPoint(x: 12, y: -12))
        path.addCurve(to: CGPoint(x: 0, y: 34), control1: CGPoint(x: 38, y: -4), control2: CGPoint(x: 25, y: 25)); path.closeSubpath()
        return path
    }
}
