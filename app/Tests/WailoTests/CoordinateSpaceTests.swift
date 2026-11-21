import XCTest
@testable import Wailo

final class CoordinateSpaceTests: XCTestCase {
    private let frames = [
        CGRect(x: 0, y: 0, width: 1920, height: 1080),
        CGRect(x: -1280, y: 0, width: 1280, height: 1024),
        CGRect(x: 0, y: 1080, width: 1600, height: 900)
    ]

    func testPointAndRectangleRoundTripsAcrossLayout() throws {
        let points = [CGPoint(x: -1000, y: 200), CGPoint(x: 700, y: -400), CGPoint(x: 800, y: 1500)]
        for point in points {
            let cocoa = CoordinateSpace.axToCocoa(point, screenFrames: frames)
            let roundTrip = CoordinateSpace.cocoaToAX(cocoa, screenFrames: frames)
            XCTAssertEqual(roundTrip.x, point.x, accuracy: 1e-6)
            XCTAssertEqual(roundTrip.y, point.y, accuracy: 1e-6)
        }

        let rect = CGRect(x: 120, y: -700, width: 340, height: 90)
        let cocoa = CoordinateSpace.axToCocoa(rect, screenFrames: frames)
        let roundTrip = CoordinateSpace.cocoaToAX(cocoa, screenFrames: frames)
        XCTAssertEqual(roundTrip.origin.x, rect.origin.x, accuracy: 1e-6)
        XCTAssertEqual(roundTrip.origin.y, rect.origin.y, accuracy: 1e-6)
        XCTAssertEqual(roundTrip.size.width, rect.size.width, accuracy: 1e-6)
        XCTAssertEqual(roundTrip.size.height, rect.size.height, accuracy: 1e-6)
    }

    func testLocalGlobalRoundTrip() {
        let point = CGPoint(x: -900, y: 300)
        let local = CoordinateSpace.globalToLocal(point, screenFrame: frames[1])
        XCTAssertEqual(CoordinateSpace.localToGlobal(local, screenFrame: frames[1]), point)
    }

    func testScreenSelectionUsesContainmentThenNearestDistance() {
        XCTAssertEqual(CoordinateSpace.screenIndex(containing: CGPoint(x: -10, y: 500), screenFrames: frames), 1)
        XCTAssertEqual(CoordinateSpace.screenIndex(containing: CGPoint(x: 2500, y: 500), screenFrames: frames), 0)
        XCTAssertEqual(CoordinateSpace.screenIndex(containing: CGPoint(x: 100, y: 1300), screenFrames: frames), 2)
    }

    func testValidatedBboxMapping() throws {
        let screen = CGRect(x: -100, y: 200, width: 1000, height: 800)
        let rect = try XCTUnwrap(CoordinateSpace.bbox1000ToCocoa([100.0, 200.0, 500.0, 600.0], screenFrame: screen))
        XCTAssertEqual(rect, CGRect(x: 0, y: 520, width: 400, height: 320))
        XCTAssertTrue(screen.contains(rect))
        XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([-1.0, 0, 1, 1], screenFrame: screen))
        XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([500.0, 0, 400, 1], screenFrame: screen))
        XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([0.0, .nan, 1, 1], screenFrame: screen))
        XCTAssertNil(CoordinateSpace.bbox1000ToCocoa([0.0, 1, 2], screenFrame: screen))
    }
}
