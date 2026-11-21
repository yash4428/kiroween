import Foundation
import CoreGraphics

struct WindowEligibility {
    static let systemOwners = ["Dock", "Window Server", "Control Center", "Notification Center", "SystemUIServer", "Wailo"]

    static func isSystemOwner(_ ownerName: String) -> Bool {
        let folded = ownerName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return systemOwners.contains { folded == $0.folding(options: [.caseInsensitive], locale: .current) }
    }

    static func isFullScreen(_ window: CGRect, on display: CGRect) -> Bool {
        guard display.width > 0, display.height > 0 else { return false }
        let overlap = window.standardized.intersection(display.standardized)
        guard !overlap.isNull else { return false }
        return overlap.width / display.width >= 0.98 && overlap.height / display.height >= 0.98
    }

    static func isFlushWithMenuBar(_ window: CGRect, visibleFrame: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(window.standardized.maxY - visibleFrame.standardized.maxY) <= tolerance
    }

    static func titleBarLandingRegion(window: CGRect, visibleFrame: CGRect,
                                      pumpkinWidth: CGFloat = 22, ownerName: String = "") -> CGRect? {
        let frame = window.standardized
        guard !isSystemOwner(ownerName), !isFullScreen(frame, on: visibleFrame),
              !isFlushWithMenuBar(frame, visibleFrame: visibleFrame), frame.width > 86 + pumpkinWidth + 24 else { return nil }
        let left = frame.minX + 86 + pumpkinWidth / 2
        let right = frame.maxX - 12 - pumpkinWidth / 2
        guard right > left else { return nil }
        return CGRect(x: left, y: frame.maxY - 28, width: right - left, height: 28)
    }
}

struct TombstonePlacement {
    static func frame(on trash: CGRect, screen: CGRect,
                      orientation: DockTrashLocation.Orientation) -> CGRect {
        let trash = trash.standardized, screen = screen.standardized
        let width = min(max(34, trash.width), screen.width)
        let height = min(max(42, trash.height), screen.height)
        var x = trash.midX - width / 2
        var y = trash.midY - height / 2
        x = min(max(x, screen.minX), screen.maxX - width)
        y = min(max(y, screen.minY), screen.maxY - height)
        if orientation == .bottom { y = min(y, trash.maxY - height) }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct PumpkinPhysics {
    static let maximumThrowSpeed: CGFloat = 1_600
    static let magnetRadius: CGFloat = 90

    static func clampThrowVelocity(_ velocity: CGVector) -> CGVector {
        guard velocity.dx.isFinite, velocity.dy.isFinite else { return .zero }
        let magnitude = hypot(velocity.dx, velocity.dy)
        guard magnitude > maximumThrowSpeed + 0.000_001 else { return velocity }
        let scale = maximumThrowSpeed / magnitude
        return CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
    }

    static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        guard point.x.isFinite, point.y.isFinite else { return .infinity }
        let r = rect.standardized
        let x = min(max(point.x, r.minX), r.maxX)
        let y = min(max(point.y, r.minY), r.maxY)
        return hypot(point.x - x, point.y - y)
    }

    static func isInsideMagnetRadius(_ point: CGPoint, bin: CGRect,
                                     radius: CGFloat = magnetRadius) -> Bool {
        distance(from: point, to: bin) <= radius
    }
}

struct ShakeDetector {
    private var samples: [(x: CGFloat, time: TimeInterval)] = []
    private var directions: [Int] = []
    private(set) var lastTrigger: TimeInterval = -.infinity

    mutating func consume(x: CGFloat, time: TimeInterval) -> Bool {
        guard x.isFinite, time.isFinite, time - lastTrigger >= 1.8 else { return false }
        if let last = samples.last, time - last.time > 0.65 { samples.removeAll(); directions.removeAll() }
        guard let last = samples.last else { samples = [(x, time)]; return false }
        let delta = x - last.x
        guard abs(delta) >= 18 else { return false }
        samples.append((x, time)); directions.append(delta > 0 ? 1 : -1)
        while let first = samples.first, time - first.time > 0.65 {
            samples.removeFirst()
            if !directions.isEmpty { directions.removeFirst() }
        }
        let reversals = zip(directions, directions.dropFirst()).filter { $0 != $1 }.count
        let travel = zip(samples, samples.dropFirst()).reduce(CGFloat.zero) { $0 + abs($1.1.x - $1.0.x) }
        if reversals >= 4 && travel >= 140 {
            lastTrigger = time; samples = [(x, time)]; directions.removeAll(); return true
        }
        return false
    }
}

enum AppTipKind: Equatable {
    case finder, browser, mail, systemSettings, generic(appName: String)
}

enum AppTipMapper {
    private static let browserIDs = ["com.apple.safari", "com.google.chrome", "org.mozilla.firefox",
                                     "com.microsoft.edgemac", "company.thebrowser.browser",
                                     "com.brave.browser", "com.operasoftware.opera"]
    static func map(bundleID: String, appName: String) -> AppTipKind {
        let id = bundleID.lowercased(), name = appName.lowercased()
        if id == "com.apple.finder" || name == "finder" { return .finder }
        if browserIDs.contains(id) || ["safari", "google chrome", "firefox", "microsoft edge", "arc", "brave browser", "opera"].contains(name) { return .browser }
        if id == "com.apple.mail" || name == "mail" { return .mail }
        if id == "com.apple.systempreferences" || name == "system settings" { return .systemSettings }
        return .generic(appName: appName.isEmpty ? "this app" : appName)
    }
}

struct TipOfferTracker {
    private(set) var focusedBundleID: String?
    private(set) var focusStarted: TimeInterval = 0
    private(set) var lastOffered: [String: TimeInterval] = [:]

    mutating func focus(bundleID: String?, at time: TimeInterval) {
        guard bundleID != focusedBundleID else { return }
        focusedBundleID = bundleID; focusStarted = time
    }

    mutating func shouldOffer(bundleID: String, at time: TimeInterval,
                              dwell: TimeInterval = 6, cooldown: TimeInterval = 900) -> Bool {
        guard focusedBundleID == bundleID, time - focusStarted >= dwell,
              time - (lastOffered[bundleID] ?? -.infinity) >= cooldown else { return false }
        lastOffered[bundleID] = time
        return true
    }
}
