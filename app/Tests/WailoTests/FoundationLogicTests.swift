import XCTest
@testable import Wailo

final class FoundationLogicTests: XCTestCase {
    func testMoonProgressAcrossWholeDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: hour, minute: minute))!
        }
        XCTAssertEqual(try XCTUnwrap(NightSkyScene.moonProgress(date: date(18), calendar: calendar)), 0, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(NightSkyScene.moonProgress(date: date(0), calendar: calendar)), 0.5, accuracy: 1e-9)
        XCTAssertGreaterThan(try XCTUnwrap(NightSkyScene.moonProgress(date: date(5, 59), calendar: calendar)), 0.99)
        for hour in 6..<18 { XCTAssertNil(NightSkyScene.moonProgress(date: date(hour), calendar: calendar)) }
    }

    func testSettingsDefaultsAndRoundTrip() {
        let suite = "WailoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = Settings(defaults: defaults)
        XCTAssertEqual(settings.snapshot, Settings.defaultSnapshot)
        settings.booLevel = .haunted
        settings.sounds = true
        settings.visionFallback = true
        let restored = Settings(defaults: defaults)
        XCTAssertEqual(restored.booLevel, .haunted)
        XCTAssertTrue(restored.sounds)
        XCTAssertTrue(restored.visionFallback)
    }

    func testAmbientMarksNeverEnterExcludedRegion() {
        var sampler = FootprintPathSampler(spacing: { 24 })
        sampler.reset(at: CGPoint(x: 0, y: 0))
        let excluded = CGRect(x: 40, y: -20, width: 30, height: 40)
        let marks = sampler.consume(point: CGPoint(x: 120, y: 0)) { excluded.contains($0) }
        XCTAssertFalse(marks.isEmpty)
        XCTAssertTrue(marks.allSatisfy { !excluded.contains($0.point) })
        for pair in zip(marks, marks.dropFirst()) { XCTAssertNotEqual(pair.0.side, pair.1.side) }
    }
}
