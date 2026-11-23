import AppKit
import ApplicationServices
import Foundation

func attr(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}
func string(_ element: AXUIElement, _ name: String) -> String? { attr(element, name) as? String }
func children(_ element: AXUIElement) -> [AXUIElement] { attr(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] }
func frame(_ element: AXUIElement) -> [String: Double]? {
    guard let pv = attr(element, kAXPositionAttribute), let sv = attr(element, kAXSizeAttribute),
          CFGetTypeID(pv) == AXValueGetTypeID(), CFGetTypeID(sv) == AXValueGetTypeID() else { return nil }
    var p = CGPoint.zero, s = CGSize.zero
    guard AXValueGetValue(pv as! AXValue, .cgPoint, &p), AXValueGetValue(sv as! AXValue, .cgSize, &s) else { return nil }
    return ["x": p.x, "y": p.y, "w": s.width, "h": s.height]
}
func json(_ value: Any) {
    let data = try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    print(String(data: data, encoding: .utf8)!)
}

func axDump(bundleID: String, maxDepth: Int) {
    guard AXIsProcessTrusted(), let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
        json(["error": "Accessibility permission or running app unavailable"]); return
    }
    let root = AXUIElementCreateApplication(app.processIdentifier)
    var count = 0
    func walk(_ element: AXUIElement, _ depth: Int) -> [String: Any] {
        guard count < 1500 else { return ["truncated": true] }
        count += 1
        let role = string(element, kAXRoleAttribute) ?? ""
        var item: [String: Any] = ["role": role]
        if let title = string(element, kAXTitleAttribute) { item["title"] = String(title.prefix(200)) }
        if let desc = string(element, kAXDescriptionAttribute) { item["description"] = String(desc.prefix(200)) }
        if let f = frame(element) { item["frame"] = f }
        // Deliberately never read kAXValueAttribute, especially for text fields.
        if depth < maxDepth && count < 1500 {
            var descendants: [[String: Any]] = []
            for child in children(element) where count < 1500 { descendants.append(walk(child, depth + 1)) }
            item["children"] = descendants
        }
        return item
    }
    let tree = walk(root, 0)
    json(["bundleId": bundleID, "nodeCount": count, "tree": tree])
}

func dockItems() {
    guard AXIsProcessTrusted(), let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
        json(["error": "Accessibility permission or Dock unavailable"]); return
    }
    var output: [[String: Any]] = []
    var count = 0
    func walk(_ element: AXUIElement, _ depth: Int) {
        guard depth <= 8, count < 1500 else { return }; count += 1
        let role = string(element, kAXRoleAttribute) ?? ""
        if role == (kAXDockItemRole as String) {
            var item: [String: Any] = ["title": string(element, kAXTitleAttribute) ?? "",
                                       "subrole": string(element, kAXSubroleAttribute) ?? ""]
            if let f = frame(element) { item["frame"] = f }
            output.append(item)
        }
        children(element).forEach { walk($0, depth + 1) }
    }
    walk(AXUIElementCreateApplication(dock.processIdentifier), 0)
    json(output)
}

final class TestWindowDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var timer: Timer?
    let actionFile: String
    init(actionFile: String) { self.actionFile = actionFile }
    func applicationDidFinishLaunching(_ notification: Notification) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) })
            ?? NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.screens[0]
        let rect = CGRect(x: screen.visibleFrame.minX + 120, y: screen.visibleFrame.minY + 180, width: 1_120, height: 340)
        window = NSWindow(contentRect: rect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Wailo Devtools Test Window"
        let label = NSTextField(labelWithString: "Safe throwaway window for slime and pumpkin tracking")
        label.font = .systemFont(ofSize: 22); label.alignment = .center; label.frame = CGRect(x: 30, y: 130, width: 1_060, height: 60)
        window.contentView?.addSubview(label); window.orderFrontRegardless(); NSApp.activate(ignoringOtherApps: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.checkAction() }
        json(["pid": getpid(), "frame": ["x": rect.minX, "y": rect.minY, "w": rect.width, "h": rect.height]])
    }
    func checkAction() {
        guard let action = try? String(contentsOfFile: actionFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines), !action.isEmpty else { return }
        try? "".write(toFile: actionFile, atomically: true, encoding: .utf8)
        switch action {
        case "glide":
            let to = CGPoint(x: window.frame.minX + 100, y: window.frame.minY + 70)
            NSAnimationContext.runAnimationGroup { $0.duration = 1.2; window.animator().setFrameOrigin(to) }
        case "jump": window.setFrameOrigin(CGPoint(x: window.frame.minX - 260, y: window.frame.minY + 180))
        case "close": NSApp.terminate(nil)
        default: break
        }
    }
}

func syntheticDrag(_ values: [String]) {
    guard values.count >= 5, let x1 = Double(values[0]), let y1 = Double(values[1]),
          let x2 = Double(values[2]), let y2 = Double(values[3]), let steps = Int(values[4]) else {
        json(["error": "invalid drag arguments"]); return
    }
    let cocoaStart = CGPoint(x: x1, y: y1), cocoaEnd = CGPoint(x: x2, y: y2)
    let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
        ?? NSScreen.screens.first?.frame.height ?? 0
    let start = CGPoint(x: cocoaStart.x, y: primaryHeight - cocoaStart.y)
    let end = CGPoint(x: cocoaEnd.x, y: primaryHeight - cocoaEnd.y)
    let source = CGEventSource(stateID: .hidSystemState)
    CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: start, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(180_000) // Let hover-gated nonactivating pumpkin panels enable mouse handling.
    CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: start, mouseButton: .left)?.post(tap: .cghidEventTap)
    for i in 1...max(1, steps) {
        let t = CGFloat(i) / CGFloat(max(1, steps))
        let p = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(18_000)
    }
    CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: end, mouseButton: .left)?.post(tap: .cghidEventTap)
    json(["ok": true])
}

let args = CommandLine.arguments
switch args.dropFirst().first {
case "ax-dump": axDump(bundleID: args.count > 2 ? args[2] : "", maxDepth: args.count > 3 ? Int(args[3]) ?? 4 : 4)
case "dock-items": dockItems()
case "test-window":
    let delegate = TestWindowDelegate(actionFile: args.count > 2 ? args[2] : "/tmp/wailo-devtools/test-window-action")
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.delegate = delegate
    withExtendedLifetime(delegate) { NSApplication.shared.run() }
case "drag": syntheticDrag(Array(args.dropFirst(2)))
default: json(["error": "unknown helper mode"])
}
