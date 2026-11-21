import AppKit
import ApplicationServices

/// Safe, bounded Accessibility searches. AX failures are ordinary "not found" results.
@MainActor
final class AXFinder {
    struct WindowContext {
        let bundleID: String
        let appName: String
        let frameAX: CGRect?
    }

    private let nodeLimit = 4_000

    func find(_ query: TargetQuery, bundleHint: String? = nil) -> CGRect? {
        guard AXIsProcessTrusted() else { return nil }
        switch query {
        case .none:
            return nil
        case .dockItem(let label):
            return dockItem(label)
        case .menuBarItem(let label):
            return menuBarItem(label, bundleHint: bundleHint)
        case .menuItem(let label):
            return menuItem(label, bundleHint: bundleHint)
        case .element(let keywords, let roles):
            return element(keywords: keywords, roles: roles, bundleHint: bundleHint)
        case .safariAddressBar:
            return safariAddressBar()
        case .smart(let label):
            return smart(label, bundleHint: bundleHint)
        }
    }

    func smart(_ label: String, bundleHint: String? = nil) -> CGRect? {
        menuItem(label, bundleHint: bundleHint)
            ?? menuBarItem(label, bundleHint: bundleHint)
            ?? dockItem(label)
            ?? element(keywords: [label], roles: [], bundleHint: bundleHint)
    }

    func safariURL() -> String? {
        guard frontmostBundleID == "com.apple.Safari",
              let app = application(bundleID: "com.apple.Safari") else { return nil }
        var visited = 0
        for node in breadthFirst(from: app, limit: nodeLimit, visited: &visited) {
            if let url = attribute(node, kAXURLAttribute) as? URL { return url.absoluteString }
            if let value = string(node, kAXURLAttribute), !value.isEmpty { return value }
        }
        return nil
    }

    func frontmostWindowFrameAX(bundleID: String) -> CGRect? {
        guard let app = application(bundleID: bundleID) else { return nil }
        if let window = elementAttribute(app, kAXFocusedWindowAttribute) { return frame(window) }
        return elements(app, kAXWindowsAttribute).compactMap(frame).first
    }

    func context(at cocoaPoint: CGPoint, screenFrames: [CGRect]) -> WindowContext? {
        guard AXIsProcessTrusted(), !screenFrames.isEmpty else { return nil }
        let axPoint = CoordinateSpace.cocoaToAX(cocoaPoint, screenFrames: screenFrames)
        let system = AXUIElementCreateSystemWide()
        var raw: AXUIElement?
        guard AXUIElementCopyElementAtPosition(system, Float(axPoint.x), Float(axPoint.y), &raw) == .success,
              let element = raw else { return nil }
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)),
              let bundleID = app.bundleIdentifier, !bundleID.isEmpty else { return nil }
        let appElement = AXUIElementCreateApplication(pid)
        let window = elementAttribute(element, kAXWindowAttribute)
            ?? elementAttribute(appElement, kAXFocusedWindowAttribute)
        return WindowContext(bundleID: bundleID,
                             appName: app.localizedName ?? bundleID,
                             frameAX: window.flatMap(frame))
    }

    var frontmostBundleID: String? { NSWorkspace.shared.frontmostApplication?.bundleIdentifier }

    private func dockItem(_ label: String) -> CGRect? {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else { return nil }
        let root = AXUIElementCreateApplication(dock.processIdentifier)
        return bestMatch(in: root, label: label, acceptedRoles: [kAXDockItemRole as String], depth: 8)
    }

    private func menuBarItem(_ label: String, bundleHint: String?) -> CGRect? {
        guard let app = frontmostApplication(matching: bundleHint),
              let menuBar = elementAttribute(app, kAXMenuBarAttribute) else { return nil }
        return bestMatch(in: menuBar, label: label,
                         acceptedRoles: [kAXMenuBarItemRole as String], depth: 3)
    }

    private func menuItem(_ label: String, bundleHint: String?) -> CGRect? {
        guard let app = frontmostApplication(matching: bundleHint),
              let menuBar = elementAttribute(app, kAXMenuBarAttribute) else { return nil }
        return bestMatch(in: menuBar, label: label,
                         acceptedRoles: [kAXMenuItemRole as String], depth: 5,
                         requireFrame: true)
    }

    private func safariAddressBar() -> CGRect? {
        element(keywords: ["address", "search", "website"],
                roles: [kAXTextFieldRole as String, "AXWebBrowserAddressAndSearchField"],
                bundleHint: "com.apple.Safari")
    }

    private func element(keywords: [String], roles: [String], bundleHint: String?) -> CGRect? {
        guard let app = frontmostApplication(matching: bundleHint) else { return nil }
        let normalizedKeywords = keywords.map(normalize).filter { !$0.isEmpty }
        var visited = 0
        var candidates: [(score: Int, area: CGFloat, rect: CGRect)] = []
        for node in breadthFirst(from: app, limit: nodeLimit, visited: &visited) {
            guard let rect = frame(node), rect.width > 1, rect.height > 1 else { continue }
            let role = string(node, kAXRoleAttribute) ?? ""
            if !roles.isEmpty && !roles.contains(where: { role.localizedCaseInsensitiveContains($0) }) { continue }
            let names = [string(node, kAXTitleAttribute), string(node, kAXDescriptionAttribute),
                         string(node, kAXIdentifierAttribute), string(node, kAXPlaceholderValueAttribute)]
                .compactMap { $0 }.map(normalize)
            let exact = normalizedKeywords.contains { key in names.contains(key) }
            let contains = normalizedKeywords.isEmpty || normalizedKeywords.contains { key in
                names.contains { $0.contains(key) || key.contains($0) }
            }
            guard exact || contains else { continue }
            candidates.append((exact ? 0 : 1, rect.width * rect.height, rect))
        }
        return candidates.min { ($0.score, $0.area) < ($1.score, $1.area) }?.rect
    }

    private func bestMatch(in root: AXUIElement, label: String, acceptedRoles: [String], depth: Int,
                           requireFrame: Bool = false) -> CGRect? {
        let wanted = normalize(label)
        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var candidates: [(Int, CGFloat, CGRect)] = []
        var count = 0
        while !queue.isEmpty && count < nodeLimit {
            let (node, level) = queue.removeFirst(); count += 1
            let role = string(node, kAXRoleAttribute) ?? ""
            let name = normalize(string(node, kAXTitleAttribute)
                ?? string(node, kAXDescriptionAttribute) ?? "")
            if acceptedRoles.contains(role), name == wanted || name.contains(wanted), let rect = frame(node) {
                if !requireFrame || (!rect.isEmpty && rect.width > 0 && rect.height > 0) {
                    candidates.append((name == wanted ? 0 : 1, rect.width * rect.height, rect))
                }
            }
            if level < depth { queue.append(contentsOf: children(node).map { ($0, level + 1) }) }
        }
        return candidates.min { ($0.0, $0.1) < ($1.0, $1.1) }?.2
    }

    private func frontmostApplication(matching hint: String?) -> AXUIElement? {
        guard let running = NSWorkspace.shared.frontmostApplication else { return nil }
        if let hint, running.bundleIdentifier != hint { return nil }
        return AXUIElementCreateApplication(running.processIdentifier)
    }

    private func application(bundleID: String) -> AXUIElement? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else { return nil }
        return AXUIElementCreateApplication(app.processIdentifier)
    }

    private func breadthFirst(from root: AXUIElement, limit: Int, visited: inout Int) -> [AXUIElement] {
        var output: [AXUIElement] = [], queue = [root]
        while !queue.isEmpty && visited < limit {
            let node = queue.removeFirst(); visited += 1; output.append(node)
            queue.append(contentsOf: children(node))
        }
        return output
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func string(_ element: AXUIElement, _ name: String) -> String? {
        attribute(element, name) as? String
    }

    private func children(_ element: AXUIElement) -> [AXUIElement] {
        elements(element, kAXChildrenAttribute)
    }

    private func elements(_ element: AXUIElement, _ name: String) -> [AXUIElement] {
        attribute(element, name) as? [AXUIElement] ?? []
    }

    private func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func frame(_ element: AXUIElement) -> CGRect? {
        guard let positionValue = attribute(element, kAXPositionAttribute),
              let sizeValue = attribute(element, kAXSizeAttribute),
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero, size = CGSize.zero
        guard AXValueGetValue(unsafeBitCast(positionValue, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeBitCast(sizeValue, to: AXValue.self), .cgSize, &size),
              point.x.isFinite, point.y.isFinite, size.width.isFinite, size.height.isFinite else { return nil }
        return CGRect(origin: point, size: size).standardized
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "…", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
