import Carbon
import Foundation

enum WailoAction: UInt32 {
    case toggleHaunting = 1, prompt, folderDemo, safariDemo, nextStep, cursedPage, cycleGhost, ghostMail, stopGuidance
}

@MainActor
final class HotKeys {
    private var references: [EventHotKeyRef?] = []
    private var handlerRef: EventHandlerRef?
    private let onAction: (WailoAction) -> Void

    init(onAction: @escaping (WailoAction) -> Void) {
        self.onAction = onAction
        installHandler()
        register(.toggleHaunting, keyCode: 4) // H
        register(.prompt, keyCode: 37)        // L
        register(.folderDemo, keyCode: 2)     // D
        register(.safariDemo, keyCode: 3)     // F
        register(.nextStep, keyCode: 45)      // N
        register(.cursedPage, keyCode: 1)     // S
        register(.cycleGhost, keyCode: 5)     // G
        register(.ghostMail, keyCode: 46)     // M
        register(.stopGuidance, keyCode: 53)  // Escape
    }

    deinit {
        references.forEach { if let ref = $0 { UnregisterEventHotKey(ref) } }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard status == noErr, let action = WailoAction(rawValue: hotKeyID.id) else { return status }
            let owner = Unmanaged<HotKeys>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in owner.onAction(action) }
            return noErr
        }, 1, &eventType, pointer, &handlerRef)
    }

    private func register(_ action: WailoAction, keyCode: UInt32) {
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: OSType(0x5741494C), id: action.rawValue) // WAIL
        RegisterEventHotKey(keyCode, UInt32(controlKey | optionKey), identifier,
                            GetApplicationEventTarget(), 0, &reference)
        references.append(reference)
    }
}
