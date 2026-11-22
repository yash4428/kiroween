import XCTest
@testable import Wailo

final class WailoDebugTests: XCTestCase {
    func testLoggerIsSilentWhenDebugEnvironmentIsUnset() {
        var output: [String] = []
        let logger = WailoDebugLogger(environment: [:]) { output.append($0) }
        logger.log(.lanternLit(point: CGPoint(x: 10, y: 20)))
        logger.log(.ghostStateChanged(.danger))
        XCTAssertTrue(output.isEmpty)
    }

    func testEnabledLoggerUsesTypedPrivacySafeFields() {
        var output: [String] = []
        let logger = WailoDebugLogger(environment: ["WAILO_DEBUG": "1"]) { output.append($0) }
        logger.log(.tombstone(frame: CGRect(x: 1, y: 2, width: 3, height: 4), foundInDock: true))
        logger.log(.tipOffered(bundleID: "com.apple.finder"))
        XCTAssertEqual(output.count, 2)
        XCTAssertTrue(output.allSatisfy { $0.hasPrefix("WAILO ") })
        XCTAssertFalse(output.joined().localizedCaseInsensitiveContains("http"))
        XCTAssertFalse(output.joined().contains("@"))
    }
}
