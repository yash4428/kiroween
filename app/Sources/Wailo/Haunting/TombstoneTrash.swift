import AppKit
import ApplicationServices
import SpriteKit

struct DockTrashLocation {
    enum Orientation { case bottom, left, right }
    let frame: CGRect
    let orientation: Orientation
}

final class DockLocator {
    func locateTrash(screenFrames: [CGRect]) -> DockTrashLocation? {
        guard AXIsProcessTrusted(),
              let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first
        else { return nil }

        let root = AXUIElementCreateApplication(dock.processIdentifier)
        let descendants = elements(from: root, depth: 0)
        guard !descendants.isEmpty else { return nil }

        let trash = descendants.first(where: isTrashElement) ?? descendants.last
        guard let trash, let axFrame = frame(of: trash) else { return nil }
        let cocoaFrame = CoordinateSpace.axToCocoa(axFrame, screenFrames: screenFrames)
        let dockFrame = frame(of: root).map { CoordinateSpace.axToCocoa($0, screenFrames: screenFrames) }
        let orientation: DockTrashLocation.Orientation
        if let dockFrame, dockFrame.height > dockFrame.width {
            let center = dockFrame.midX
            let primaryMidX = screenFrames.first(where: { $0.origin == .zero })?.midX ?? center
            orientation = center < primaryMidX ? .left : .right
        } else {
            orientation = .bottom
        }
        return DockTrashLocation(frame: cocoaFrame, orientation: orientation)
    }

    private func elements(from element: AXUIElement, depth: Int) -> [AXUIElement] {
        guard depth < 7 else { return [] }
        var result = [element]
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
           let children = value as? [AXUIElement] {
            for child in children.prefix(80) {
                result.append(contentsOf: elements(from: child, depth: depth + 1))
            }
        }
        return result
    }

    private func isTrashElement(_ element: AXUIElement) -> Bool {
        let values = [
            stringAttribute(kAXRoleAttribute as CFString, element: element),
            stringAttribute(kAXSubroleAttribute as CFString, element: element),
            stringAttribute(kAXTitleAttribute as CFString, element: element),
            stringAttribute(kAXDescriptionAttribute as CFString, element: element)
        ].compactMap { $0?.lowercased() }
        return values.contains(where: { $0.contains("trash") || $0.contains("axtrashdockitem") })
    }

    private func stringAttribute(_ attribute: CFString, element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? String
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue, let sizeValue,
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else { return nil }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        else { return nil }
        return CGRect(origin: point, size: size)
    }
}

final class TombstoneTrash {
    private weak var scene: EffectsScene?
    private let root = SKNode()
    private let countLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var buriedPumpkins = Set<UUID>()
    private(set) var binRect: CGRect
    private(set) var burialCount = 0

    init(scene: EffectsScene, screenFrame: CGRect, visibleFrame: CGRect? = nil, location: DockTrashLocation?) {
        let availableFrame = visibleFrame ?? screenFrame
        let fallbackFrame = CGRect(x: availableFrame.maxX - 84, y: availableFrame.minY + 4,
                                   width: 64, height: 72)
        let orientation = location?.orientation ?? .bottom
        let target = location.map { TombstonePlacement.frame(on: $0.frame, screen: screenFrame,
                                                              orientation: $0.orientation) }
            ?? fallbackFrame
        binRect = target
        WailoDebugLogger.shared.log(.tombstone(frame: target, foundInDock: location != nil))
        self.scene = scene
        root.name = "trashTombstone"
        root.zPosition = 52
        scene.add(root, to: .decor)

        let local = CoordinateSpace.globalToLocal(target, screenFrame: screenFrame)
        let node = Self.makeTombstone()
        node.position = CGPoint(x: local.midX, y: local.midY)
        node.xScale = min(1, local.width / 68)
        node.yScale = min(1, local.height / 80)
        if orientation == .bottom { node.position.y = min(node.position.y, local.maxY - local.height / 2) }
        root.addChild(node)

        countLabel.text = "🎃 0"
        countLabel.fontSize = 13
        countLabel.fontColor = NSColor(calibratedRed: 1, green: 0.72, blue: 0.25, alpha: 1)
        countLabel.verticalAlignmentMode = .center
        countLabel.position = CGPoint(x: local.midX, y: local.maxY + 10)
        countLabel.zPosition = 2
        root.addChild(countLabel)
        scene.wake()
    }

    func bury(pumpkinID: UUID) {
        guard buriedPumpkins.insert(pumpkinID).inserted else { return }
        burialCount += 1
        WailoDebugLogger.shared.log(.pumpkinBuried(total: burialCount))
        countLabel.text = "🎃 \(burialCount)"
        countLabel.removeAllActions()
        countLabel.run(.sequence([.scale(to: 1.3, duration: 0.12), .scale(to: 1, duration: 0.18)]))
        scene?.wake()
    }

    func remove() {
        root.removeAllActions()
        root.removeFromParent()
        scene?.wake()
    }

    private static func makeTombstone() -> SKNode {
        let root = SKNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -34, y: -40))
        path.addLine(to: CGPoint(x: -31, y: 13))
        path.addCurve(to: CGPoint(x: 31, y: 13), control1: CGPoint(x: -26, y: 50), control2: CGPoint(x: 26, y: 50))
        path.addLine(to: CGPoint(x: 34, y: -40))
        path.closeSubpath()
        let stone = SKShapeNode(path: path)
        stone.fillColor = NSColor(calibratedRed: 0.29, green: 0.29, blue: 0.38, alpha: 0.98)
        stone.strokeColor = NSColor(calibratedRed: 0.58, green: 0.52, blue: 0.67, alpha: 0.9)
        stone.lineWidth = 2
        stone.glowWidth = 1
        root.addChild(stone)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "R.I.P."
        label.fontSize = 15
        label.fontColor = NSColor(calibratedWhite: 0.82, alpha: 1)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 4)
        root.addChild(label)
        return root
    }
}
