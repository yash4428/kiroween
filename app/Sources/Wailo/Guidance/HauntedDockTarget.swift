import AppKit
import SpriteKit

@MainActor
final class HauntedDockTarget: GuideVisual {
    private let root = SKNode()
    private weak var scene: EffectsScene?

    init?(overlays: OverlayWindowManager, finder: AXFinder, appLabel: String,
          bundleID: String?, reduceMotion: Bool) {
        let frames = NSScreen.screens.map(\.frame)
        guard frames.contains(where: { $0.origin == .zero }),
              let axRect = finder.find(.dockItem(appLabel)),
              let overlay = overlays.overlay(containing: CoordinateSpace.axToCocoa(CGPoint(x: axRect.midX, y: axRect.midY), screenFrames: frames)) else { return nil }
        self.scene = overlay.effectsScene
        let cocoa = CoordinateSpace.axToCocoa(axRect, screenFrames: frames)
        let local = CoordinateSpace.globalToLocal(cocoa, screenFrame: overlay.screen.frame)
        root.position = CGPoint(x: local.midX, y: local.midY)
        root.zPosition = 95

        let glow = SKShapeNode(circleOfRadius: max(local.width, local.height) * 0.62)
        glow.fillColor = NSColor(calibratedRed: 0.55, green: 0.30, blue: 0.95, alpha: 0.20)
        glow.strokeColor = NSColor(calibratedRed: 0.76, green: 0.52, blue: 1, alpha: 0.92)
        glow.lineWidth = 4; glow.glowWidth = 10; root.addChild(glow)

        let image = Self.appIcon(bundleID: bundleID) ?? AssetLoader.shared.image(for: .pumpkin)
        let icon = SKSpriteNode(texture: SKTexture(image: image))
        icon.size = CGSize(width: max(34, local.width), height: max(34, local.height)); root.addChild(icon)

        let ghost = SKShapeNode(ellipseOf: CGSize(width: 25, height: 30))
        ghost.fillColor = .white; ghost.strokeColor = .systemPurple; ghost.lineWidth = 2
        ghost.position = CGPoint(x: local.width * 0.34, y: local.height * 0.35); ghost.zPosition = -1
        let eye1 = SKShapeNode(ellipseOf: CGSize(width: 3, height: 7)); eye1.fillColor = .black; eye1.strokeColor = .clear; eye1.position = CGPoint(x: -5, y: 3)
        let eye2 = SKShapeNode(ellipseOf: CGSize(width: 3, height: 7)); eye2.fillColor = .black; eye2.strokeColor = .clear; eye2.position = CGPoint(x: 5, y: 3)
        ghost.addChild(eye1); ghost.addChild(eye2); root.addChild(ghost)

        overlay.effectsScene.add(root, to: .guide)
        if reduceMotion { root.alpha = 0; root.run(.fadeIn(withDuration: 0.22)) }
        else {
            root.run(.repeatForever(.sequence([.rotate(toAngle: -0.07, duration: 0.17),
                                               .rotate(toAngle: 0.07, duration: 0.34),
                                               .rotate(toAngle: 0, duration: 0.17),
                                               .wait(forDuration: 0.35)])))
        }
    }

    func remove() { root.removeAllActions(); root.removeFromParent(); scene?.wake() }

    private static func appIcon(bundleID: String?) -> NSImage? {
        guard let bundleID,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
