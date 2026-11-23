import XCTest
@testable import Wailo

final class CrossFeaturePropertyTests: XCTestCase {
    private let seed: UInt64 = 0x5741_494C_4F20_2026

    func testCoordinateRoundTripsAcrossOneThousandLayouts() {
        var g = SeededGenerator(seed: seed)
        for i in 0..<1_000 {
            let primary = CGRect(x: 0, y: 0, width: g.cg(600...3_000), height: g.cg(500...2_000))
            let left = CGRect(x: -g.cg(400...2_000), y: g.cg(-1_000...1_000), width: g.cg(400...2_000), height: g.cg(400...1_500))
            let above = CGRect(x: g.cg(-500...500), y: primary.maxY, width: g.cg(400...2_000), height: g.cg(400...1_500))
            let frames = g.bool() ? [left, above, primary] : [primary, above, left]
            let p = g.point(-5_000...5_000)
            let round = CoordinateSpace.cocoaToAX(CoordinateSpace.axToCocoa(p, screenFrames: frames), screenFrames: frames)
            let message = propertyContext(seed: seed, case: i, values: frames, p)
            XCTAssertEqual(round.x, p.x, accuracy: 1e-7, message)
            XCTAssertEqual(round.y, p.y, accuracy: 1e-7, message)
            let r = g.rect()
            let rr = CoordinateSpace.cocoaToAX(CoordinateSpace.axToCocoa(r, screenFrames: frames), screenFrames: frames)
            XCTAssertEqual(rr.origin.x, r.origin.x, accuracy: 1e-7, message)
            XCTAssertEqual(rr.origin.y, r.origin.y, accuracy: 1e-7, message)
            XCTAssertEqual(rr.size.width, r.width, accuracy: 1e-7, message)
            let local = CoordinateSpace.globalToLocal(p, screenFrame: left)
            let restored = CoordinateSpace.localToGlobal(local, screenFrame: left)
            XCTAssertEqual(restored.x, p.x, accuracy: 1e-7, message)
            XCTAssertEqual(restored.y, p.y, accuracy: 1e-7, message)
            let index = CoordinateSpace.screenIndex(containing: p, screenFrames: frames)
            XCTAssertTrue(frames.indices.contains(index), message)
        }
    }

    func testVisionBboxesAcrossOneThousandCases() {
        var g = SeededGenerator(seed: seed ^ 1)
        for i in 0..<1_000 {
            let screen = g.rect(origin: -2_000...2_000, size: 100...2_000)
            let x1 = g.double(0...999), x2 = g.double(x1...1000)
            let y1 = g.double(0...999), y2 = g.double(y1...1000)
            let message = propertyContext(seed: seed ^ 1, case: i, values: screen, x1, y1, x2, y2)
            let mapped = CoordinateSpace.bbox1000ToCocoa([x1, y1, x2, y2], screenFrame: screen)
            XCTAssertNotNil(mapped, message)
            if let mapped { XCTAssertTrue(screen.contains(mapped), message) }
            XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([-1.0, y1, x2, y2], screenFrame: screen), message)
            XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([x2, y1, x1, y2], screenFrame: screen), message)
        }
    }

    func testFootprintEndpointAndAlternationAcrossOneThousandTargets() {
        var g = SeededGenerator(seed: seed ^ 2)
        for i in 0..<1_000 {
            let target = g.rect(origin: -2_000...2_000, size: 0.01...80)
            let start = g.bool() ? CGPoint(x: target.midX, y: target.midY) : g.point()
            let spacing = g.cg(4...120)
            let marks = FootprintPath.marks(from: start, to: target, spacing: spacing)
            let message = propertyContext(seed: seed ^ 2, case: i, values: start, target)
            XCTAssertFalse(marks.isEmpty, message)
            XCTAssertTrue(target.contains(marks.last!.position), message)
            XCTAssertEqual(marks, FootprintPath.marks(from: start, to: target, spacing: spacing),
                           "determinism is separately checked with fixed input; \(message)")
        }
    }

    func testGhostSafetyStateMachineAcrossOneThousandSequences() {
        var g = SeededGenerator(seed: seed ^ 3)
        let events: [GhostEvent] = [.startListening, .startPlanning, .startSearching, .escalateSearch,
                                    .targetFound, .awaitClick, .clickedWrong, .wrongClickRecovered,
                                    .cannotFind, .stepDone(last: false), .stepDone(last: true),
                                    .idleTooLong, .activity]
        for i in 0..<1_000 {
            let prior = GhostState.allCases.filter { $0 != .danger }[g.int(0...(GhostState.allCases.count - 2))]
            var a = GhostStateMachine(visible: prior), b = a
            let sequence = (0..<g.int(0...30)).map { _ in events[g.int(0...(events.count - 1))] }
            sequence.forEach { a.handle($0); b.handle($0) }
            let message = propertyContext(seed: seed ^ 3, case: i, values: prior, sequence)
            XCTAssertEqual(a, b, message)
            a.handle(.dangerDetected); a.handle(.targetFound); XCTAssertEqual(a.visible, .danger, message)
            a.handle(.dangerCleared); XCTAssertTrue(GhostState.allCases.contains(a.visible), message)
            var cancel = GhostStateMachine(visible: prior); cancel.handle(.cancel); XCTAssertEqual(cancel.visible, .idle, message)
            var dangerCancel = GhostStateMachine(visible: prior); dangerCancel.handle(.dangerDetected); dangerCancel.handle(.cancel)
            XCTAssertEqual(dangerCancel.visible, .danger, message); dangerCancel.handle(.dangerCleared); XCTAssertEqual(dangerCancel.visible, .idle, message)
        }
    }

    func testRouterAndGrimoireStringPropertiesAcrossOneThousandInputs() {
        var g = SeededGenerator(seed: seed ^ 4)
        for i in 0..<1_000 {
            let raw = g.ascii()
            let message = propertyContext(seed: seed ^ 4, case: i, values: raw)
            let routed = TaskRouter.route(raw)
            let upperRouted = TaskRouter.route(raw.uppercased())
            switch routed {
            case .live:
                if case .live = upperRouted {} else { XCTFail(message) }
            default:
                XCTAssertEqual(routed, upperRouted, message)
            }
            let other = g.ascii()
            XCTAssertEqual(Grimoire.matches(raw, other), Grimoire.matches(other, raw), message)
            if !Grimoire.normalized(raw).isEmpty { XCTAssertTrue(Grimoire.matches(raw, raw), message) }
        }
    }

    func testPlanParserAndCursedDetectorAcrossOneThousandInputs() {
        var g = SeededGenerator(seed: seed ^ 5)
        for i in 0..<1_000 {
            let count = g.int(0...128)
            let data = Data((0..<count).map { _ in UInt8(truncatingIfNeeded: g.next()) })
            _ = BackendClient.parse(data: data)
            let raw = g.ascii()
            XCTAssertEqual(CursedURL.isCursed(raw), CursedURL.isCursed(raw.uppercased()), propertyContext(seed: seed ^ 5, case: i, values: raw))
            var detector = CursedURLDetector(); let cursed = "https://example.test/refund/\(i)"
            XCTAssertTrue(detector.inspect(cursed)); XCTAssertFalse(detector.inspect(cursed))
        }
    }

    func testHauntingV2GeometryAcrossOneThousandCases() {
        var g = SeededGenerator(seed: seed ^ 6)
        for i in 0..<1_000 {
            let screen = CGRect(x: g.cg(-2_000...2_000), y: g.cg(-500...500), width: g.cg(700...2_000), height: g.cg(600...1_500))
            let trash = CGRect(x: g.cg(screen.minX + 80...screen.maxX - 120), y: screen.minY + 4,
                              width: g.cg(40...90), height: g.cg(45...95))
            let stone = TombstonePlacement.frame(on: trash, screen: screen, orientation: .bottom)
            let message = propertyContext(seed: seed ^ 6, case: i, values: screen, trash)
            XCTAssertEqual(stone.midX, trash.midX, accuracy: 1e-6, message)
            XCTAssertLessThanOrEqual(stone.maxY, trash.maxY + 1e-6, message)
            XCTAssertTrue(screen.contains(stone), message)

            let window = CGRect(x: screen.minX + 20, y: screen.minY + 80,
                                width: g.cg(240...min(1_200, screen.width - 40)), height: g.cg(120...400))
            if let header = WindowEligibility.titleBarLandingRegion(window: window, visibleFrame: screen, pumpkinWidth: 22) {
                XCTAssertGreaterThanOrEqual(header.minX, window.minX + 97, message)
                XCTAssertLessThanOrEqual(header.maxX, window.maxX, message)
            }
            XCTAssertNil(WindowEligibility.titleBarLandingRegion(window: screen, visibleFrame: screen), message)
            XCTAssertNil(WindowEligibility.titleBarLandingRegion(window: window, visibleFrame: screen, ownerName: "Dock"), message)
        }
    }

    func testThrowClampAndBinRadiusAcrossOneThousandVectors() {
        var g = SeededGenerator(seed: seed ^ 7)
        let bin = CGRect(x: 100, y: 100, width: 60, height: 70)
        for i in 0..<1_000 {
            let v = CGVector(dx: g.cg(-10_000...10_000), dy: g.cg(-10_000...10_000))
            let c = PumpkinPhysics.clampThrowVelocity(v)
            let message = propertyContext(seed: seed ^ 7, case: i, values: v)
            XCTAssertLessThanOrEqual(hypot(c.dx, c.dy), 1_600.000_1, message)
            XCTAssertEqual(PumpkinPhysics.clampThrowVelocity(c), c, message)
            if hypot(v.dx, v.dy) > 0 { XCTAssertGreaterThanOrEqual(v.dx * c.dx + v.dy * c.dy, 0, message) }
            let distance = g.cg(0...180), p = CGPoint(x: bin.maxX + distance, y: bin.midY)
            XCTAssertEqual(PumpkinPhysics.isInsideMagnetRadius(p, bin: bin), distance <= 90, message)
        }
        XCTAssertEqual(PumpkinPhysics.clampThrowVelocity(CGVector(dx: CGFloat.nan, dy: 1)), .zero)
    }

    func testShakeAndTipCooldownAcrossOneThousandTimelines() {
        for i in 0..<1_000 {
            var monotone = ShakeDetector()
            for step in 0..<12 { XCTAssertFalse(monotone.consume(x: CGFloat(step * 20), time: Double(step) * 0.04), propertyContext(seed: seed ^ 8, case: i, values: step)) }
            var slow = ShakeDetector()
            for step in 0..<8 { XCTAssertFalse(slow.consume(x: step.isMultiple(of: 2) ? 0 : 50, time: Double(step) * 0.3)) }
            var valid = ShakeDetector(); var fired = false
            for (step, x) in [0, 40, 0, 40, 0, 40].enumerated() { fired = valid.consume(x: CGFloat(x), time: Double(step) * 0.1) || fired }
            XCTAssertTrue(fired)
            var tips = TipOfferTracker(); let app = "example.\(i)"; tips.focus(bundleID: app, at: 0)
            XCTAssertFalse(tips.shouldOffer(bundleID: app, at: 5.9)); XCTAssertTrue(tips.shouldOffer(bundleID: app, at: 6))
            XCTAssertFalse(tips.shouldOffer(bundleID: app, at: 905.9)); XCTAssertTrue(tips.shouldOffer(bundleID: app, at: 906))
        }
    }
}
