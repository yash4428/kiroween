import AppKit
import CoreGraphics

struct TrackedWindow: Equatable {
    let id: CGWindowID
    let frame: CGRect
    let ownerPID: pid_t
    let ownerName: String
    let velocity: CGFloat
    let frontOrder: Int
}

final class WindowTracker {
    typealias Subscriber = ([TrackedWindow]) -> Void

    private struct PreviousSample {
        let center: CGPoint
        let time: TimeInterval
    }

    private var subscribers: [UUID: Subscriber] = [:]
    private var previous: [CGWindowID: PreviousSample] = [:]
    private var timer: Timer?

    @discardableResult
    func subscribe(_ subscriber: @escaping Subscriber) -> UUID {
        let token = UUID()
        subscribers[token] = subscriber
        if timer == nil { start() }
        sample()
        return token
    }

    func unsubscribe(_ token: UUID) {
        subscribers.removeValue(forKey: token)
        if subscribers.isEmpty { stop() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        previous.removeAll()
    }

    private func start() {
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.sample() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func sample() {
        guard !subscribers.isEmpty else { return }
        let screens = NSScreen.screens
        let screenFrames = screens.map(\.frame)
        guard screenFrames.contains(where: { $0.origin == .zero }) else { return }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }
        let now = ProcessInfo.processInfo.systemUptime
        var nextPrevious: [CGWindowID: PreviousSample] = [:]
        var windows: [TrackedWindow] = []

        for (order, info) in list.enumerated() {
            guard (info[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  let windowID = (info[kCGWindowNumber as String] as? NSNumber)?.uint32Value,
                  let ownerPID = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  let ownerName = info[kCGWindowOwnerName as String] as? String,
                  ownerPID != getpid(),
                  !WindowEligibility.isSystemOwner(ownerName),
                  ((info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0.05,
                  let boundsObject = info[kCGWindowBounds as String],
                  let axFrame = CGRect(dictionaryRepresentation: boundsObject as! CFDictionary),
                  axFrame.width >= 120, axFrame.height >= 80
            else { continue }

            let cocoaFrame = CoordinateSpace.axToCocoa(axFrame, screenFrames: screenFrames)
            guard Self.hasVisibleTopEdge(cocoaFrame, visibleFrames: screens.map(\.visibleFrame)),
                  let screen = screens.max(by: {
                      $0.frame.intersection(cocoaFrame).width * $0.frame.intersection(cocoaFrame).height <
                      $1.frame.intersection(cocoaFrame).width * $1.frame.intersection(cocoaFrame).height
                  }),
                  !WindowEligibility.isFullScreen(cocoaFrame, on: screen.frame),
                  !WindowEligibility.isFlushWithMenuBar(cocoaFrame, visibleFrame: screen.visibleFrame)
            else { continue }
            let center = CGPoint(x: cocoaFrame.midX, y: cocoaFrame.midY)
            let velocity: CGFloat
            if let old = previous[windowID] {
                let elapsed = max(0.001, now - old.time)
                velocity = hypot(center.x - old.center.x, center.y - old.center.y) / elapsed
            } else {
                velocity = 0
            }
            nextPrevious[windowID] = PreviousSample(center: center, time: now)
            windows.append(TrackedWindow(
                id: windowID,
                frame: cocoaFrame,
                ownerPID: ownerPID,
                ownerName: ownerName,
                velocity: velocity,
                frontOrder: order
            ))
        }
        previous = nextPrevious
        subscribers.values.forEach { $0(windows) }
    }

    static func hasVisibleTopEdge(_ frame: CGRect, visibleFrames: [CGRect]) -> Bool {
        visibleFrames.contains { visible in
            let horizontalOverlap = min(frame.maxX, visible.maxX) - max(frame.minX, visible.minX)
            return horizontalOverlap >= 20 && frame.maxY >= visible.minY && frame.maxY <= visible.maxY + 1
        }
    }
}
