import AppKit
import Foundation

/// Licensed bitmap sprites. Everything else in the visual layer is drawn procedurally.
enum Sprite: String, CaseIterable, Sendable {
    case ghost, pumpkin, bat, spider, web, candle, crystalBall, tombstone
    case candy, lollipop, leaf, mapleLeaf, envelope, handUp, pointRight, pointLeft
    case ear, book, sparkles, zzz, warning, lantern

    var fileName: String { rawValue + ".png" }

    var emoji: String {
        switch self {
        case .ghost: "👻"
        case .pumpkin: "🎃"
        case .bat: "🦇"
        case .spider: "🕷️"
        case .web: "🕸️"
        case .candle: "🕯️"
        case .crystalBall: "🔮"
        case .tombstone: "🪦"
        case .candy: "🍬"
        case .lollipop: "🍭"
        case .leaf: "🍂"
        case .mapleLeaf: "🍁"
        case .envelope: "✉️"
        case .handUp: "👆"
        case .pointRight: "👉"
        case .pointLeft: "👈"
        case .ear: "👂"
        case .book: "📖"
        case .sparkles: "✨"
        case .zzz: "💤"
        case .warning: "⚠️"
        case .lantern: "🏮"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .ghost: "Friendly ghost"
        case .pumpkin: "Pumpkin"
        case .bat: "Bat"
        case .spider: "Spider"
        case .web: "Cobweb"
        case .candle: "Candle"
        case .crystalBall: "Crystal ball"
        case .tombstone: "Tombstone"
        case .candy: "Candy"
        case .lollipop: "Lollipop"
        case .leaf, .mapleLeaf: "Autumn leaf"
        case .envelope: "Envelope"
        case .handUp: "Pointing hand"
        case .pointRight: "Hand pointing right"
        case .pointLeft: "Hand pointing left"
        case .ear: "Listening ear"
        case .book: "Open book"
        case .sparkles: "Sparkles"
        case .zzz: "Sleeping symbol"
        case .warning: "Warning"
        case .lantern: "Lantern"
        }
    }
}

/// Finds SwiftPM resources without evaluating `Bundle.module`, which traps when the generated
/// resource bundle is absent. A rendered system emoji always supplies a nonblank fallback.
final class AssetLoader {
    static let shared = AssetLoader()

    private let searchDirectories: [URL]
    private var cache: [Sprite: NSImage] = [:]
    private let lock = NSLock()

    init(searchDirectories: [URL]? = nil) {
        if let searchDirectories {
            self.searchDirectories = searchDirectories
        } else {
            self.searchDirectories = Self.defaultSearchDirectories()
        }
    }

    func optionalImage(named fileName: String) -> NSImage? {
        for directory in searchDirectories {
            let candidate = directory.appendingPathComponent(fileName, isDirectory: false)
            if let image = NSImage(contentsOf: candidate), image.isValid,
               image.size.width > 0, image.size.height > 0 { return image }
        }
        return nil
    }

    func image(for sprite: Sprite) -> NSImage {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[sprite] { return cached }

        let loaded = loadPNG(sprite) ?? Self.emojiImage(sprite.emoji, description: sprite.accessibilityDescription)
        loaded.accessibilityDescription = sprite.accessibilityDescription
        cache[sprite] = loaded
        return loaded
    }

    private func loadPNG(_ sprite: Sprite) -> NSImage? {
        for directory in searchDirectories {
            let candidate = directory.appendingPathComponent(sprite.fileName, isDirectory: false)
            if let image = NSImage(contentsOf: candidate), image.isValid, image.size.width > 0, image.size.height > 0 {
                return image
            }
        }
        return nil
    }

    private static func defaultSearchDirectories() -> [URL] {
        var directories: [URL] = []
        let fileManager = FileManager.default
        let executableDirectory = URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
        let bundleNames = ["Wailo_Wailo.bundle", "Wailo.bundle"]

        for root in [executableDirectory, Bundle.main.resourceURL].compactMap({ $0 }) {
            directories.append(root)
            directories.append(root.appendingPathComponent("Resources", isDirectory: true))
            for bundleName in bundleNames {
                let bundleURL = root.appendingPathComponent(bundleName, isDirectory: true)
                if fileManager.fileExists(atPath: bundleURL.path) {
                    directories.append(bundleURL)
                    directories.append(bundleURL.appendingPathComponent("Resources", isDirectory: true))
                }
            }
        }

        var seen = Set<String>()
        return directories.filter { seen.insert($0.standardizedFileURL.path).inserted }
    }

    private static func emojiImage(_ emoji: String, description: String) -> NSImage {
        let size = NSSize(width: 128, height: 128)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        let font = NSFont.systemFont(ofSize: 92)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        let attributed = NSAttributedString(string: emoji, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: NSSize(width: 120, height: 120),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        attributed.draw(at: NSPoint(
            x: (size.width - bounds.width) / 2 - bounds.minX,
            y: (size.height - bounds.height) / 2 - bounds.minY
        ))
        image.unlockFocus()
        image.accessibilityDescription = description
        return image
    }
}
