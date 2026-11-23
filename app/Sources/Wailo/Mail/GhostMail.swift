import AppKit
import SpriteKit

@MainActor
final class GhostMail {
    private let overlays: OverlayWindowManager
    private let ghost: GhostPet
    private let settings: Settings
    private var activeNode: SKNode?

    init(overlays: OverlayWindowManager, ghost: GhostPet, settings: Settings) {
        self.overlays = overlays; self.ghost = ghost; self.settings = settings
    }

    func deliver() {
        activeNode?.removeFromParent()
        let destination = CGPoint(x: ghost.ghostFrame.midX, y: ghost.ghostFrame.midY)
        guard let overlay = overlays.overlay(containing: destination) else { showLetter(); return }
        let localEnd = CoordinateSpace.globalToLocal(destination, screenFrame: overlay.screen.frame)
        let start = CGPoint(x: max(40, localEnd.x - 360), y: min(overlay.screen.frame.height - 70, localEnd.y + 180))
        let root = SKNode(); root.zPosition = 75
        let carrier = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .ghost)))
        carrier.size = CGSize(width: 64, height: 64)
        let envelope = SKSpriteNode(texture: SKTexture(image: AssetLoader.shared.image(for: .envelope)))
        envelope.size = CGSize(width: 28, height: 28); envelope.position = CGPoint(x: 28, y: -16)
        root.addChild(carrier); root.addChild(envelope); root.position = settings.reduceMotion ? localEnd : start
        overlay.effectsScene.add(root, to: .fx); activeNode = root
        if settings.reduceMotion {
            root.alpha = 0
            root.run(.sequence([.fadeIn(withDuration: 0.3), .wait(forDuration: 0.25),
                                .run { [weak self] in self?.showLetter() },
                                .fadeOut(withDuration: 0.25), .removeFromParent()]))
        } else {
            let control = CGPoint(x: (start.x + localEnd.x) / 2, y: max(start.y, localEnd.y) + 130)
            let path = CGMutablePath(); path.move(to: start); path.addQuadCurve(to: localEnd, control: control)
            let wave = SKAction.sequence([.rotate(toAngle: 0.22, duration: 0.12),
                                          .rotate(toAngle: -0.22, duration: 0.18),
                                          .rotate(toAngle: 0.18, duration: 0.18),
                                          .rotate(toAngle: 0, duration: 0.12)])
            root.run(.sequence([.follow(path, asOffset: false, orientToPath: false, duration: 1.6),
                                .run { carrier.run(wave) }, .wait(forDuration: 0.65),
                                .run { [weak self] in self?.showLetter() },
                                .fadeOut(withDuration: 0.25), .removeFromParent()]))
        }
    }

    private func showLetter() {
        ghost.handle(.activity); WailoSound.purr.play(ifEnabled: settings)
        let letter = "💌 A letter from Grandson Aarav: ‘Hi Nani! Don’t forget your medicine. I’ll call you on Sunday. Love you!’"
        if settings.reduceMotion { ghost.say(letter) }
        else { ghost.sayTypewriter(letter) }
    }
}
