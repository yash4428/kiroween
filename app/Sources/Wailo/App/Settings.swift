import AppKit
import Foundation

extension Notification.Name {
    static let wailoSettingsChanged = Notification.Name("Settings.changed")
}

enum BooLevel: String, CaseIterable, Codable, Sendable {
    case cozy
    case spooky
    case haunted

    var skyOpacity: CGFloat {
        switch self {
        case .cozy: 0.85
        case .spooky: 0.90
        case .haunted: 0.94
        }
    }

    var fogOpacity: CGFloat {
        switch self {
        case .cozy: 0.20
        case .spooky: 0.30
        case .haunted: 0.38
        }
    }

    var batFlightInterval: ClosedRange<TimeInterval> {
        self == .cozy ? 45 ... 75 : 20 ... 40
    }

    var trackedWindowLimit: Int { self == .cozy ? 3 : 5 }
    var showsPumpkins: Bool { self != .cozy }
    var allowsBrightnessFlicker: Bool { self != .cozy }
    var showsLightning: Bool { self == .haunted }
}

/// All user preferences owned by the foundation layer.
///
/// Values are validated on load, stored below the `wailo.` namespace, and emit exactly one
/// notification when a setter changes an effective value.
final class Settings {
    static let changed = Notification.Name.wailoSettingsChanged

    struct Snapshot: Equatable, Sendable {
        var booLevel: BooLevel
        var cursorFootprints: Bool
        var slime: Bool
        var bats: Bool
        var sounds: Bool
        var watchSafari: Bool
        var visionFallback: Bool
        var showTargetFrames: Bool
    }

    private enum Key {
        static let prefix = "wailo."
        static let booLevel = prefix + "booLevel"
        static let cursorFootprints = prefix + "cursorFootprints"
        static let slime = prefix + "slime"
        static let bats = prefix + "bats"
        static let sounds = prefix + "sounds"
        static let watchSafari = prefix + "watchSafari"
        static let visionFallback = prefix + "visionFallback"
        static let showTargetFrames = prefix + "showTargetFrames"
    }

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let workspace: NSWorkspace

    private var stored: Snapshot

    init(
        defaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default,
        workspace: NSWorkspace = .shared
    ) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.workspace = workspace

        let fallback = Self.defaultSnapshot
        let rawLevel = defaults.string(forKey: Key.booLevel)
        let loadedLevel = rawLevel.flatMap(BooLevel.init(rawValue:)) ?? fallback.booLevel
        stored = Snapshot(
            booLevel: loadedLevel,
            cursorFootprints: Self.bool(for: Key.cursorFootprints, in: defaults) ?? fallback.cursorFootprints,
            slime: Self.bool(for: Key.slime, in: defaults) ?? fallback.slime,
            bats: Self.bool(for: Key.bats, in: defaults) ?? fallback.bats,
            sounds: Self.bool(for: Key.sounds, in: defaults) ?? fallback.sounds,
            watchSafari: Self.bool(for: Key.watchSafari, in: defaults) ?? fallback.watchSafari,
            visionFallback: Self.bool(for: Key.visionFallback, in: defaults) ?? fallback.visionFallback,
            showTargetFrames: Self.bool(for: Key.showTargetFrames, in: defaults) ?? fallback.showTargetFrames
        )

        // Persist declared defaults and repair invalid values without publishing a synthetic change.
        persist(stored)
    }

    static let defaultSnapshot = Snapshot(
        booLevel: .cozy,
        cursorFootprints: true,
        slime: true,
        bats: true,
        sounds: false,
        watchSafari: false,
        visionFallback: false,
        showTargetFrames: false
    )

    var snapshot: Snapshot { stored }
    var reduceMotion: Bool { workspace.accessibilityDisplayShouldReduceMotion }

    var booLevel: BooLevel {
        get { stored.booLevel }
        set { update(\.booLevel, to: newValue, key: Key.booLevel, encoded: newValue.rawValue) }
    }

    var cursorFootprints: Bool {
        get { stored.cursorFootprints }
        set { update(\.cursorFootprints, to: newValue, key: Key.cursorFootprints, encoded: newValue) }
    }

    var slime: Bool {
        get { stored.slime }
        set { update(\.slime, to: newValue, key: Key.slime, encoded: newValue) }
    }

    var bats: Bool {
        get { stored.bats }
        set { update(\.bats, to: newValue, key: Key.bats, encoded: newValue) }
    }

    var sounds: Bool {
        get { stored.sounds }
        set { update(\.sounds, to: newValue, key: Key.sounds, encoded: newValue) }
    }

    var watchSafari: Bool {
        get { stored.watchSafari }
        set { update(\.watchSafari, to: newValue, key: Key.watchSafari, encoded: newValue) }
    }

    var visionFallback: Bool {
        get { stored.visionFallback }
        set { update(\.visionFallback, to: newValue, key: Key.visionFallback, encoded: newValue) }
    }

    var showTargetFrames: Bool {
        get { stored.showTargetFrames }
        set { update(\.showTargetFrames, to: newValue, key: Key.showTargetFrames, encoded: newValue) }
    }

    private static func bool(for key: String, in defaults: UserDefaults) -> Bool? {
        guard let value = defaults.object(forKey: key) as? NSNumber else { return nil }
        return value.boolValue
    }

    private func update<Value: Equatable>(
        _ path: WritableKeyPath<Snapshot, Value>,
        to value: Value,
        key: String,
        encoded: Any
    ) {
        guard stored[keyPath: path] != value else { return }
        stored[keyPath: path] = value
        defaults.set(encoded, forKey: key)
        notificationCenter.post(name: Self.changed, object: self)
    }

    private func persist(_ snapshot: Snapshot) {
        defaults.set(snapshot.booLevel.rawValue, forKey: Key.booLevel)
        defaults.set(snapshot.cursorFootprints, forKey: Key.cursorFootprints)
        defaults.set(snapshot.slime, forKey: Key.slime)
        defaults.set(snapshot.bats, forKey: Key.bats)
        defaults.set(snapshot.sounds, forKey: Key.sounds)
        defaults.set(snapshot.watchSafari, forKey: Key.watchSafari)
        defaults.set(snapshot.visionFallback, forKey: Key.visionFallback)
        defaults.set(snapshot.showTargetFrames, forKey: Key.showTargetFrames)
    }
}

enum WailoSound: String, CaseIterable {
    case tink = "Tink"
    case glass = "Glass"
    case pop = "Pop"
    case purr = "Purr"
    case submarine = "Submarine"

    func play(ifEnabled settings: Settings) {
        guard settings.sounds else { return }
        NSSound(named: NSSound.Name(rawValue))?.play()
    }
}

enum WailoAccessibilityStyle {
    static let minimumBodyFontSize: CGFloat = 18
    static let minimumBubbleFontSize: CGFloat = 19
    static let minimumHitTarget = CGSize(width: 44, height: 44)
}
