import XCTest
@testable import Wailo

final class GhostStateAndRouterTests: XCTestCase {
    func testNormalGhostTransitions() {
        var machine = GhostStateMachine()
        machine.handle(.startListening)
        XCTAssertEqual(machine.visible, .listening)
        machine.handle(.startPlanning)
        machine.handle(.startSearching)
        machine.handle(.targetFound)
        machine.handle(.awaitClick)
        machine.handle(.clickedWrong)
        machine.handle(.wrongClickRecovered)
        machine.handle(.stepDone(last: true))
        XCTAssertEqual(machine.visible, .success)
        machine.handle(.activity)
        XCTAssertEqual(machine.visible, .idle)
    }

    func testDangerPrecedenceRepeatedDetectionAndRestore() {
        var machine = GhostStateMachine(visible: .searching)
        machine.handle(.dangerDetected)
        machine.handle(.dangerDetected)
        machine.handle(.targetFound)
        XCTAssertEqual(machine.visible, .danger)
        XCTAssertEqual(machine.suspendedByDanger, .searching)
        machine.handle(.dangerCleared)
        XCTAssertEqual(machine.visible, .searching)
    }

    func testCancelDuringDangerChangesRestoreState() {
        var machine = GhostStateMachine(visible: .planning)
        machine.handle(.dangerDetected)
        machine.handle(.cancel)
        XCTAssertEqual(machine.visible, .danger)
        machine.handle(.dangerCleared)
        XCTAssertEqual(machine.visible, .idle)
    }

    func testUnsupportedTransitionIsIdentity() {
        let original = GhostStateMachine(visible: .idle)
        XCTAssertEqual(original.handling(.targetFound), original)
    }

    func testRouterPriorityBoundariesAndOriginalLiveText() {
        XCTAssertEqual(TaskRouter.route("  open SAFARI, then a folder  "), .newFolder)
        XCTAssertEqual(TaskRouter.route("browse Wikipedia"), .safari)
        XCTAssertEqual(TaskRouter.route("possible SCAM!"), .cursed)
        XCTAssertEqual(TaskRouter.route("read e-mail"), .ghostMail)
        XCTAssertEqual(TaskRouter.route("letter from Aarav"), .ghostMail)
        XCTAssertEqual(TaskRouter.route("a spell"), .grimoire)
        XCTAssertEqual(TaskRouter.route("  do something else  "), .live("do something else"))
        XCTAssertEqual(TaskRouter.route(" \n\t "), .nothing)
    }
}
