import Foundation
import CoreGraphics

/// Typed, opt-in diagnostics. Events deliberately have no free-form text payload.
struct WailoDebugLogger {
    enum VanishReason: String { case idle, dock }
    enum Event {
        case tombstone(frame: CGRect, foundInDock: Bool)
        case pumpkinSpawned(id: UUID, point: CGPoint)
        case pumpkinLanded(id: UUID, point: CGPoint, windowID: CGWindowID)
        case pumpkinVanished(id: UUID, reason: VanishReason)
        case pumpkinBuried(total: Int)
        case lanternLit(point: CGPoint)
        case tipOffered(bundleID: String)
        case dockTargetHaunted(bundleID: String)
        case ghostStateChanged(GhostState)
        case guideStepPresented(index: Int, target: CGRect)
    }

    static let shared = WailoDebugLogger()

    private let enabled: Bool
    private let sink: (String) -> Void

    init(environment: [String: String] = ProcessInfo.processInfo.environment,
         sink: @escaping (String) -> Void = { NSLog("%@", $0) }) {
        enabled = environment["WAILO_DEBUG"] == "1"
        self.sink = sink
    }

    func log(_ event: Event) {
        guard enabled else { return }
        sink("WAILO \(render(event))")
    }

    private func render(_ event: Event) -> String {
        switch event {
        case .tombstone(let frame, let found):
            return "tombstone frame=\(rect(frame)) foundInDock=\(found)"
        case .pumpkinSpawned(let id, let point):
            return "pumpkin spawned id=\(id.uuidString) point=\(self.point(point))"
        case .pumpkinLanded(let id, let point, let windowID):
            return "pumpkin landed id=\(id.uuidString) point=\(self.point(point)) windowID=\(windowID)"
        case .pumpkinVanished(let id, let reason):
            return "pumpkin vanished id=\(id.uuidString) reason=\(reason.rawValue)"
        case .pumpkinBuried(let total):
            return "pumpkin buried total=\(total)"
        case .lanternLit(let point):
            return "lantern lit point=\(self.point(point))"
        case .tipOffered(let bundleID):
            return "tip offered bundleID=\(bundleID)"
        case .dockTargetHaunted(let bundleID):
            return "dock target haunted bundleID=\(bundleID)"
        case .ghostStateChanged(let state):
            return "ghost state=\(state.rawValue)"
        case .guideStepPresented(let index, let target):
            return "guide step=\(index) target=\(rect(target))"
        }
    }

    private func point(_ point: CGPoint) -> String {
        "(\(number(point.x)),\(number(point.y)))"
    }

    private func rect(_ rect: CGRect) -> String {
        "(\(number(rect.minX)),\(number(rect.minY)),\(number(rect.width)),\(number(rect.height)))"
    }

    private func number(_ value: CGFloat) -> String { String(format: "%.1f", Double(value)) }
}
