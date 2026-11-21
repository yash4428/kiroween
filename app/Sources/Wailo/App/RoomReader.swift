import AppKit

@MainActor
final class RoomReader {
    struct Offer {
        let bundleID: String
        let appName: String
        let kind: AppTipKind
    }

    private let isSuppressed: () -> Bool
    private let onOffer: (Offer) -> Void
    private var tracker = TipOfferTracker()
    private var timer: Timer?

    init(isSuppressed: @escaping () -> Bool, onOffer: @escaping (Offer) -> Void) {
        self.isSuppressed = isSuppressed; self.onOffer = onOffer
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common); self.timer = timer; tick()
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != getpid(),
              let bundleID = app.bundleIdentifier,
              !["com.apple.dock", "com.apple.controlcenter", "com.apple.notificationcenterui",
                "com.apple.systemuiserver", "com.apple.WindowManager"].contains(bundleID) else {
            tracker.focus(bundleID: nil, at: now); return
        }
        tracker.focus(bundleID: bundleID, at: now)
        guard !isSuppressed(), tracker.shouldOffer(bundleID: bundleID, at: now) else { return }
        let name = app.localizedName ?? bundleID
        onOffer(Offer(bundleID: bundleID, appName: name,
                      kind: AppTipMapper.map(bundleID: bundleID, appName: name)))
    }
}
