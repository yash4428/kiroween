import Foundation
import CoreGraphics

struct Spell: Codable, Identifiable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var id: UUID
    var bundleID: String
    var appName: String
    var stepText: String
    var relX: Double?
    var relY: Double?
    var absX: Double
    var absY: Double
    var createdAt: Date
    var timesCast: Int

    init(
        schemaVersion: Int = Spell.currentSchemaVersion,
        id: UUID = UUID(),
        bundleID: String,
        appName: String,
        stepText: String,
        relX: Double? = nil,
        relY: Double? = nil,
        absX: Double,
        absY: Double,
        createdAt: Date = Date(),
        timesCast: Int = 0
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.stepText = stepText
        self.relX = relX
        self.relY = relY
        self.absX = absX
        self.absY = absY
        self.createdAt = Date(timeIntervalSince1970: (createdAt.timeIntervalSince1970 * 1_000).rounded() / 1_000)
        self.timesCast = timesCast
    }
}

enum Grimoire {
    static func normalizedTokens(_ text: String) -> [String] {
        TaskRouter.tokens(in: text)
    }

    static func normalized(_ text: String) -> String {
        normalizedTokens(text).joined(separator: " ")
    }

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let left = Set(normalizedTokens(lhs))
        let right = Set(normalizedTokens(rhs))
        let union = left.union(right)
        guard !union.isEmpty else { return 0 }
        return Double(left.intersection(right).count) / Double(union.count)
    }

    static func matches(_ lhs: String, _ rhs: String) -> Bool {
        let left = normalized(lhs)
        let right = normalized(rhs)
        guard !left.isEmpty, !right.isEmpty else { return false }
        return left == right || similarity(left, right) >= 0.8
    }

    static func bestMatch(in spells: [Spell], bundleID: String, stepText: String) -> Spell? {
        spells
            .filter { $0.bundleID == bundleID && matches($0.stepText, stepText) }
            .sorted { lhs, rhs in
                let lhsExact = normalized(lhs.stepText) == normalized(stepText)
                let rhsExact = normalized(rhs.stepText) == normalized(stepText)
                if lhsExact != rhsExact { return lhsExact }
                let lhsScore = similarity(lhs.stepText, stepText)
                let rhsScore = similarity(rhs.stepText, stepText)
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                if lhs.timesCast != rhs.timesCast { return lhs.timesCast > rhs.timesCast }
                return lhs.createdAt > rhs.createdAt
            }
            .first
    }

    /// Window frames and absolute fallback values use AX's global top-left coordinate space.
    static func locate(
        spell: Spell,
        currentWindowFramesAX: [CGRect],
        visibleScreenFrames: [CGRect]
    ) -> CGRect? {
        guard !visibleScreenFrames.isEmpty else { return nil }
        var axPoint = CGPoint(x: spell.absX, y: spell.absY)
        if let window = currentWindowFramesAX.first,
           window.isFinite,
           let relX = spell.relX, let relY = spell.relY,
           relX.isFinite, relY.isFinite,
           (0...1).contains(relX), (0...1).contains(relY) {
            axPoint = CGPoint(x: window.minX + CGFloat(relX) * window.width,
                              y: window.minY + CGFloat(relY) * window.height)
        }
        let cocoaPoint = CoordinateSpace.axToCocoa(axPoint, screenFrames: visibleScreenFrames)
        guard cocoaPoint.x.isFinite, cocoaPoint.y.isFinite else { return nil }
        let screenIndex = CoordinateSpace.screenIndex(containing: cocoaPoint, screenFrames: visibleScreenFrames)
        return targetRect(centeredAt: cocoaPoint, clampedTo: visibleScreenFrames[screenIndex])
    }

    static func locate(spell: Spell, windowFrameAX: CGRect?, visibleScreenFrames: [CGRect]) -> CGRect? {
        locate(spell: spell,
               currentWindowFramesAX: windowFrameAX.map { [$0] } ?? [],
               visibleScreenFrames: visibleScreenFrames)
    }

    private static func targetRect(centeredAt point: CGPoint, clampedTo frame: CGRect) -> CGRect? {
        guard frame.isFinite, frame.width > 0, frame.height > 0 else { return nil }
        let width = min(44, frame.width)
        let height = min(44, frame.height)
        let x = min(max(point.x - width / 2, frame.minX), frame.maxX - width)
        let y = min(max(point.y - height / 2, frame.minY), frame.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct GrimoireStore {
    private(set) var spells: [Spell]
    let fileURL: URL

    init(fileURL: URL = GrimoireStore.defaultFileURL(), spells: [Spell] = []) {
        self.fileURL = fileURL
        self.spells = spells
    }

    static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Wailo", isDirectory: true)
            .appendingPathComponent("grimoire.json", isDirectory: false)
    }

    /// Loads persisted spells. A returned URL identifies a corrupt file preserved for recovery.
    @discardableResult
    mutating func load(fileManager: FileManager = .default) -> URL? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            spells = []
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let value = try decoder.singleValueContainer().decode(String.self)
                let fractional = ISO8601DateFormatter()
                fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = fractional.date(from: value) { return date }
                let basic = ISO8601DateFormatter()
                if let date = basic.date(from: value) { return date }
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                        debugDescription: "Invalid ISO 8601 date"))
            }
            let envelope = try decoder.decode(Envelope.self, from: data)
            guard envelope.schemaVersion == Envelope.currentSchemaVersion else {
                throw GrimoireError.unsupportedSchema
            }
            spells = envelope.spells
            return nil
        } catch {
            spells = []
            let formatter = ISO8601DateFormatter()
            let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let recovery = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(stamp)-\(UUID().uuidString).json")
            do {
                try fileManager.moveItem(at: fileURL, to: recovery)
                return recovery
            } catch {
                return fileURL
            }
        }
    }

    func save(fileManager: FileManager = .default) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        let data = try encoder.encode(Envelope(schemaVersion: Envelope.currentSchemaVersion, spells: spells))
        try data.write(to: fileURL, options: .atomic)
    }

    mutating func learn(_ spell: Spell) {
        if let index = spells.firstIndex(where: { $0.id == spell.id }) {
            spells[index] = spell
        } else {
            spells.append(spell)
        }
    }

    @discardableResult
    mutating func forget(id: UUID) -> Bool {
        guard let index = spells.firstIndex(where: { $0.id == id }) else { return false }
        spells.remove(at: index)
        return true
    }

    static func matches(_ lhs: String, _ rhs: String) -> Bool {
        Grimoire.matches(lhs, rhs)
    }

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        Grimoire.similarity(lhs, rhs)
    }

    static func locate(
        spell: Spell,
        currentWindowFramesAX: [CGRect],
        visibleScreenFrames: [CGRect]
    ) -> CGRect? {
        Grimoire.locate(spell: spell,
                        currentWindowFramesAX: currentWindowFramesAX,
                        visibleScreenFrames: visibleScreenFrames)
    }

    func match(bundleID: String, stepText: String) -> Spell? {
        Grimoire.bestMatch(in: spells, bundleID: bundleID, stepText: stepText)
    }

    @discardableResult
    mutating func markCast(id: UUID) -> Bool {
        guard let index = spells.firstIndex(where: { $0.id == id }) else { return false }
        spells[index].timesCast += 1
        return true
    }
}

private struct Envelope: Codable {
    static let currentSchemaVersion = 1
    let schemaVersion: Int
    let spells: [Spell]
}

private enum GrimoireError: Error {
    case unsupportedSchema
}

private extension CGRect {
    var isFinite: Bool { origin.x.isFinite && origin.y.isFinite && width.isFinite && height.isFinite }
}
