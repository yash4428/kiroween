import AppKit
import SpriteKit

@MainActor
final class ShakeToFindController {
    private let overlays: OverlayWindowManager
    private let ghost: GhostPet
    private let settings: Settings
    private let isGuideActive: () -> Bool
    private var detector = ShakeDetector()
    private var timer: Timer?
    private var lantern: SKNode?
    private var effectGeneration = 0

    init(overlays: OverlayWindowManager, ghost: GhostPet, settings: Settings,
         isGuideActive: @escaping () -> Bool) {
        self.overlays = overlays; self.ghost = ghost; self.settings = settings
        self.isGuideActive = isGuideActive
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common); self.timer = timer
    }

    func stop() {
        timer?.invalidate(); timer = nil; lantern?.removeFromParent(); lantern = nil
        detector = ShakeDetector(); effectGeneration += 1
    }

    private func tick() {
        if isGuideActive() { detector = ShakeDetector(); return }
        let point = NSEvent.mouseLocation
        if detector.consume(x: point.x, time: ProcessInfo.processInfo.systemUptime) { showLantern(at: point) }
    }

    private func showLantern(at global: CGPoint) {
        effectGeneration += 1; let generation = effectGeneration
        lantern?.removeFromParent()
        guard let overlay = overlays.overlay(containing: global) else { return }
        let local = CoordinateSpace.globalToLocal(global, screenFrame: overlay.screen.frame)
        WailoDebugLogger.shared.log(.lanternLit(point: global))
        let root = SKNode(); root.position = local; root.zPosition = 110
        for radius in [34.0, 52.0, 72.0] {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.strokeColor = NSColor(calibratedRed: 0.76, green: 0.46, blue: 1, alpha: 0.7)
            ring.fillColor = NSColor(calibratedRed: 1, green: 0.58, blue: 0.12, alpha: radius == 34 ? 0.16 : 0.05)
            ring.lineWidth = 3; ring.glowWidth = 8; root.addChild(ring)
            if !settings.reduceMotion {
                ring.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 0.35), .scale(to: 1, duration: 0.35)])))
            }
        }
        let icon = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .lantern)))
        icon.size = CGSize(width: 50, height: 50); icon.position = CGPoint(x: 35, y: 36); root.addChild(icon)
        root.alpha = 0; overlay.effectsScene.add(root, to: .fx); root.run(.fadeIn(withDuration: 0.18))
        lantern = root
        ghost.say("Here’s your pointer! 🏮", autoHide: 1.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self, weak root] in
            guard let self, self.effectGeneration == generation else { return }
            root?.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
            self.lantern = nil
        }
    }
}
