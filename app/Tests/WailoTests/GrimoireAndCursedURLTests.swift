import XCTest
@testable import Wailo

final class GrimoireAndCursedURLTests: XCTestCase {
    func testMatchingIsSymmetricAndEmptyStringsDoNotMatch() {
        let pairs = [
            ("Click the File menu", "file click menu"),
            ("Open… Folder", "open folder"),
            ("alpha beta gamma delta", "alpha beta gamma delta epsilon"),
            ("", "!!!")
        ]
        for pair in pairs {
            XCTAssertEqual(Grimoire.matches(pair.0, pair.1), Grimoire.matches(pair.1, pair.0))
        }
        XCTAssertFalse(Grimoire.matches("", "!!!"))
        XCTAssertTrue(Grimoire.matches("alpha beta gamma delta", "alpha beta gamma delta zeta"))
        XCTAssertFalse(Grimoire.matches("alpha beta gamma delta epsilon", "alpha beta gamma delta zeta"))
    }

    func testBestMatchIsIsolatedByBundle() throws {
        let wrongApp = Spell(bundleID: "other", appName: "Other", stepText: "Click File", absX: 10, absY: 10)
        let rightApp = Spell(bundleID: "finder", appName: "Finder", stepText: "click file", absX: 20, absY: 20)
        let match = try XCTUnwrap(Grimoire.bestMatch(in: [wrongApp, rightApp], bundleID: "finder", stepText: "Click File"))
        XCTAssertEqual(match.id, rightApp.id)
    }

    func testRelativeLocationAndAbsoluteFallbackStayVisible() throws {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 1000)]
        let relative = Spell(bundleID: "finder", appName: "Finder", stepText: "File",
                             relX: 0.5, relY: 0.5, absX: -1000, absY: -1000)
        let rect = try XCTUnwrap(Grimoire.locate(spell: relative,
                                                 windowFrameAX: CGRect(x: 100, y: 100, width: 200, height: 200),
                                                 visibleScreenFrames: screens))
        XCTAssertEqual(rect.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(rect.midX, 200, accuracy: 1e-6)
        XCTAssertEqual(rect.midY, 800, accuracy: 1e-6)
        XCTAssertTrue(screens[0].contains(rect))

        let fallback = Spell(bundleID: "finder", appName: "Finder", stepText: "File", absX: 5000, absY: 5000)
        let clamped = try XCTUnwrap(Grimoire.locate(spell: fallback, windowFrameAX: nil, visibleScreenFrames: screens))
        XCTAssertTrue(screens[0].contains(clamped))
    }

    func testVersionedPersistenceAndCorruptionRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("grimoire.json")
        let spell = Spell(bundleID: "finder", appName: "Finder", stepText: "Click File", absX: 10, absY: 20)
        var store = GrimoireStore(fileURL: url)
        store.learn(spell)
        try store.save()

        var loaded = GrimoireStore(fileURL: url)
        XCTAssertNil(loaded.load())
        XCTAssertEqual(loaded.spells, [spell])
        XCTAssertTrue(loaded.markCast(id: spell.id))
        XCTAssertEqual(loaded.spells[0].timesCast, 1)

        try Data("not-json".utf8).write(to: url, options: .atomic)
        let recovery = loaded.load()
        XCTAssertNotNil(recovery)
        XCTAssertTrue(loaded.spells.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(recovery).path))
    }

    func testCursedURLCaseInsensitivityAndDeduplication() {
        XCTAssertTrue(CursedURL.isCursed("HTTPS://EXAMPLE.COM/UPDATE-PAN"))
        XCTAssertTrue(CursedURL.isCursed("https://example.com/refund?id=1"))
        XCTAssertFalse(CursedURL.isCursed("https://example.com/account"))

        var detector = CursedURLDetector()
        XCTAssertTrue(detector.inspect("https://bad.test/lottery"))
        XCTAssertFalse(detector.inspect("https://bad.test/lottery"))
        XCTAssertFalse(detector.inspect("https://safe.test"))
        XCTAssertTrue(detector.inspect("https://bad.test/lottery"))
    }
}
