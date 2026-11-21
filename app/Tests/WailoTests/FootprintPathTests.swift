import XCTest
@testable import Wailo

final class FootprintPathTests: XCTestCase {
    func testFinalMarkAlwaysFallsInsideTarget() {
        let targets = [
            CGRect(x: 100, y: 100, width: 1, height: 1),
            CGRect(x: -500, y: 300, width: 80, height: 40),
            CGRect(x: 0, y: 0, width: 44, height: 44)
        ]
        let starts = [CGPoint.zero, CGPoint(x: 100.5, y: 100.5), CGPoint(x: 900, y: -200)]
        for target in targets {
            for start in starts {
                let marks = FootprintPath.marks(from: start, to: target)
                XCTAssertFalse(marks.isEmpty)
                let final = marks.last!.position
                XCTAssertGreaterThanOrEqual(final.x, target.standardized.minX)
                XCTAssertLessThanOrEqual(final.x, target.standardized.maxX)
                XCTAssertGreaterThanOrEqual(final.y, target.standardized.minY)
                XCTAssertLessThanOrEqual(final.y, target.standardized.maxY)
            }
        }
    }

    func testMarksAreDeterministicFiniteAndAlternating() {
        let target = CGRect(x: 400, y: 300, width: 30, height: 50)
        let first = FootprintPath.marks(from: CGPoint(x: -50, y: 20), to: target, spacing: 23)
        XCTAssertEqual(first, FootprintPath.marks(from: CGPoint(x: -50, y: 20), to: target, spacing: 23))
        for (index, mark) in first.enumerated() {
            XCTAssertTrue(mark.position.x.isFinite)
            XCTAssertTrue(mark.position.y.isFinite)
            XCTAssertTrue(mark.rotation.isFinite)
            XCTAssertEqual(mark.side, index.isMultiple(of: 2) ? .left : .right)
        }
    }
}
