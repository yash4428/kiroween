import XCTest
@testable import Wailo

final class HauntingV2LogicTests: XCTestCase {
    func testTombstoneStaysCenteredOnTrashAndBelowDockFloor() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        for x in stride(from: CGFloat(40), through: 1360, by: 110) {
            let trash = CGRect(x: x, y: 2, width: 64, height: 64)
            let result = TombstonePlacement.frame(on: trash, screen: screen, orientation: .bottom)
            XCTAssertEqual(result.midX, trash.midX, accuracy: 0.001)
            XCTAssertEqual(result.midY, trash.midY, accuracy: 0.001)
            XCTAssertLessThanOrEqual(result.maxY, trash.maxY)
            XCTAssertTrue(screen.contains(result))
        }
    }

    func testHeaderLandingAvoidsTrafficLightsAndRejectsIneligibleWindows() throws {
        let visible = CGRect(x: 0, y: 0, width: 1440, height: 875)
        for width in stride(from: CGFloat(240), through: 1200, by: 73) {
            let window = CGRect(x: 20, y: 100, width: width, height: 500)
            let region = try XCTUnwrap(WindowEligibility.titleBarLandingRegion(window: window, visibleFrame: visible))
            XCTAssertGreaterThanOrEqual(region.minX, window.minX + 97)
            XCTAssertLessThanOrEqual(region.maxX, window.maxX)
            XCTAssertGreaterThanOrEqual(region.minY, window.maxY - 28)
            XCTAssertLessThanOrEqual(region.maxY, window.maxY)
        }
        XCTAssertNil(WindowEligibility.titleBarLandingRegion(window: CGRect(x: 0, y: 0, width: 1440, height: 875), visibleFrame: visible))
        XCTAssertNil(WindowEligibility.titleBarLandingRegion(window: CGRect(x: 20, y: 375, width: 500, height: 500), visibleFrame: visible))
        XCTAssertNil(WindowEligibility.titleBarLandingRegion(window: CGRect(x: 20, y: 100, width: 500, height: 500), visibleFrame: visible, ownerName: "Dock"))
    }

    func testThrowVelocityClampingBoundDirectionAndIdempotence() {
        for dx in stride(from: CGFloat(-3000), through: 3000, by: 173) {
            let original = CGVector(dx: dx, dy: dx * 0.43)
            let clamped = PumpkinPhysics.clampThrowVelocity(original)
            XCTAssertLessThanOrEqual(hypot(clamped.dx, clamped.dy), 1600.0001)
            if hypot(original.dx, original.dy) > 0 {
                XCTAssertGreaterThanOrEqual(original.dx * clamped.dx + original.dy * clamped.dy, 0)
            }
            XCTAssertEqual(PumpkinPhysics.clampThrowVelocity(clamped), clamped)
        }
        XCTAssertEqual(PumpkinPhysics.clampThrowVelocity(CGVector(dx: CGFloat.nan, dy: 2)), .zero)
    }

    func testBinMagnetRadiusIsExact() {
        let bin = CGRect(x: 100, y: 100, width: 50, height: 50)
        XCTAssertTrue(PumpkinPhysics.isInsideMagnetRadius(CGPoint(x: 120, y: 120), bin: bin))
        XCTAssertTrue(PumpkinPhysics.isInsideMagnetRadius(CGPoint(x: 240, y: 125), bin: bin))
        XCTAssertFalse(PumpkinPhysics.isInsideMagnetRadius(CGPoint(x: 240.01, y: 125), bin: bin))
        for distance in stride(from: CGFloat(0), through: 140, by: 5) {
            XCTAssertEqual(PumpkinPhysics.isInsideMagnetRadius(CGPoint(x: bin.maxX + distance, y: bin.midY), bin: bin), distance <= 90)
        }
    }

    func testFullScreenDetectionRequiresBothAxes() {
        let display = CGRect(x: -1000, y: 0, width: 1000, height: 800)
        XCTAssertTrue(WindowEligibility.isFullScreen(display, on: display))
        XCTAssertTrue(WindowEligibility.isFullScreen(display.insetBy(dx: 10, dy: 8), on: display))
        XCTAssertFalse(WindowEligibility.isFullScreen(display.insetBy(dx: 11, dy: 8), on: display))
        XCTAssertFalse(WindowEligibility.isFullScreen(display.insetBy(dx: 10, dy: 9), on: display))
    }

    func testShakeDetectionRejectsJitterMonotonicAndSlowPaths() {
        var shake = ShakeDetector()
        let xs: [CGFloat] = [0, 40, 0, 40, 0, 40]
        var triggered = false
        for (i, x) in xs.enumerated() { triggered = shake.consume(x: x, time: Double(i) * 0.1) || triggered }
        XCTAssertTrue(triggered)

        var monotonic = ShakeDetector()
        XCTAssertFalse((0...8).contains { monotonic.consume(x: CGFloat($0 * 25), time: Double($0) * 0.06) })
        var jitter = ShakeDetector()
        XCTAssertFalse((0...12).contains { jitter.consume(x: $0.isMultiple(of: 2) ? 0 : 12, time: Double($0) * 0.04) })
        var slow = ShakeDetector()
        XCTAssertFalse(xs.enumerated().contains { slow.consume(x: $0.element, time: Double($0.offset) * 0.3) })
    }

    func testPerAppTipMappingIsTotalAndCaseInsensitive() {
        let cases: [(String, String, AppTipKind)] = [
            ("COM.APPLE.FINDER", "anything", .finder),
            ("com.apple.Safari", "Safari", .browser),
            ("com.google.Chrome", "Chrome", .browser),
            ("com.apple.mail", "MAIL", .mail),
            ("com.apple.systempreferences", "System Settings", .systemSettings),
            ("example.notes", "Notes Plus", .generic(appName: "Notes Plus"))
        ]
        for value in cases { XCTAssertEqual(AppTipMapper.map(bundleID: value.0, appName: value.1), value.2) }
    }

    func testTipDwellAndCooldownPerBundle() {
        var tracker = TipOfferTracker(); tracker.focus(bundleID: "finder", at: 0)
        XCTAssertFalse(tracker.shouldOffer(bundleID: "finder", at: 5.9))
        XCTAssertTrue(tracker.shouldOffer(bundleID: "finder", at: 6))
        XCTAssertFalse(tracker.shouldOffer(bundleID: "finder", at: 905))
        XCTAssertTrue(tracker.shouldOffer(bundleID: "finder", at: 906))
        tracker.focus(bundleID: "mail", at: 907)
        XCTAssertFalse(tracker.shouldOffer(bundleID: "mail", at: 912))
        XCTAssertTrue(tracker.shouldOffer(bundleID: "mail", at: 913))
        tracker.focus(bundleID: "finder", at: 914)
        XCTAssertFalse(tracker.shouldOffer(bundleID: "finder", at: 920))
    }
}
