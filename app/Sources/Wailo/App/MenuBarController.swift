import AppKit
import ApplicationServices

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let settings: Settings
    private let haunting: HauntingController
    private let onAction: (WailoAction) -> Void
    private let onSeance: () -> Void
    private let onGrimoire: () -> Void

    init(settings: Settings, haunting: HauntingController,
         onAction: @escaping (WailoAction) -> Void,
         onSeance: @escaping () -> Void,
         onGrimoire: @escaping () -> Void) {
        self.settings = settings; self.haunting = haunting; self.onAction = onAction
        self.onSeance = onSeance; self.onGrimoire = onGrimoire
        super.init()
        statusItem.button?.title = "🎃"; statusItem.button?.toolTip = "Wailo — your friendly haunted guide"
        menu.delegate = self; statusItem.menu = menu; rebuild()
    }

    func menuWillOpen(_ menu: NSMenu) { rebuild() }

    private func rebuild() {
        menu.removeAllItems()
        add(haunting.phase == .off ? "Start Haunting" : "Stop Haunting", command: "haunt")
        add("Ask Wailo…", command: "prompt")
        menu.addItem(.separator())
        add("Run Demo: New Folder", command: "folder")
        add("Run Demo: Safari", command: "safari")
        add("Next step", command: "next")
        add("Stop guidance", command: "stop")
        menu.addItem(.separator())
        add("Simulate Cursed Page", command: "cursed")
        add("Start Séance", command: "seance")
        add("Show Grimoire", command: "grimoire")
        add("Ghost mail", command: "mail")

        let boo = NSMenu(title: "Boo Level")
        for level in BooLevel.allCases {
            let item = actionItem(level.rawValue.capitalized, command: "boo:\(level.rawValue)")
            item.state = settings.booLevel == level ? .on : .off; boo.addItem(item)
        }
        let booRoot = NSMenuItem(title: "Boo Level", action: nil, keyEquivalent: ""); booRoot.submenu = boo; menu.addItem(booRoot)

        menu.addItem(.separator())
        toggle("Cursor footprints", value: settings.cursorFootprints, command: "toggle:footprints")
        toggle("Slime", value: settings.slime, command: "toggle:slime")
        toggle("Bats", value: settings.bats, command: "toggle:bats")
        toggle("Sounds", value: settings.sounds, command: "toggle:sounds")
        toggle("Watch Safari", value: settings.watchSafari, command: "toggle:watch")
        toggle("Vision fallback", value: settings.visionFallback, command: "toggle:vision")

        let debug = NSMenu(title: "Debug")
        debug.addItem(actionItem("Cycle ghost state", command: "cycle"))
        let frames = actionItem("Show target frames", command: "toggle:frames"); frames.state = settings.showTargetFrames ? .on : .off; debug.addItem(frames)
        debug.addItem(actionItem("Accessibility status", command: "accessibility"))
        let root = NSMenuItem(title: "Debug", action: nil, keyEquivalent: ""); root.submenu = debug; menu.addItem(root)
        menu.addItem(.separator()); add("Quit Wailo", command: "quit")
    }

    private func add(_ title: String, command: String) { menu.addItem(actionItem(title, command: command)) }
    private func toggle(_ title: String, value: Bool, command: String) {
        let item = actionItem(title, command: command); item.state = value ? .on : .off; menu.addItem(item)
    }
    private func actionItem(_ title: String, command: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performCommand(_:)), keyEquivalent: "")
        item.target = self; item.representedObject = command; return item
    }

    @objc private func performCommand(_ sender: NSMenuItem) {
        guard let command = sender.representedObject as? String else { return }
        switch command {
        case "haunt": onAction(.toggleHaunting)
        case "prompt": onAction(.prompt)
        case "folder": onAction(.folderDemo)
        case "safari": onAction(.safariDemo)
        case "next": onAction(.nextStep)
        case "stop": onAction(.stopGuidance)
        case "cursed": onAction(.cursedPage)
        case "cycle": onAction(.cycleGhost)
        case "mail": onAction(.ghostMail)
        case "seance": onSeance()
        case "grimoire": onGrimoire()
        case "accessibility": showAccessibilityStatus()
        case "quit": NSApp.terminate(nil)
        case "toggle:footprints": settings.cursorFootprints.toggle()
        case "toggle:slime": settings.slime.toggle()
        case "toggle:bats": settings.bats.toggle()
        case "toggle:sounds": settings.sounds.toggle()
        case "toggle:watch": settings.watchSafari.toggle()
        case "toggle:frames": settings.showTargetFrames.toggle()
        case "toggle:vision": toggleVision()
        default:
            if command.hasPrefix("boo:"), let level = BooLevel(rawValue: String(command.dropFirst(4))) { settings.booLevel = level }
        }
    }

    private func toggleVision() {
        if settings.visionFallback { settings.visionFallback = false; return }
        let alert = NSAlert(); alert.messageText = "Let the crystal ball look at the screen?"
        alert.informativeText = "Only when Wailo cannot find a target, one screenshot of that display will be sent to your configured Wailo backend. It requires Screen Recording permission. Screenshots are not saved."
        alert.addButton(withTitle: "Enable vision"); alert.addButton(withTitle: "Keep it off")
        if alert.runModal() == .alertFirstButtonReturn { settings.visionFallback = true }
    }

    private func showAccessibilityStatus() {
        let trusted = AXIsProcessTrusted()
        let alert = NSAlert(); alert.messageText = trusted ? "Accessibility is ready" : "Accessibility is not enabled"
        alert.informativeText = trusted ? "Wailo can find controls and guide clicks." : "Visual ambience and instruction-only guidance still work. Enable Xcode or Wailo in System Settings → Privacy & Security → Accessibility for target finding."
        alert.addButton(withTitle: "OK"); alert.runModal()
    }
}
