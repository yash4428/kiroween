import Foundation

enum GhostState: String, CaseIterable, Codable, Sendable {
    case idle
    case listening
    case planning
    case searching
    case searchingHard
    case found
    case waitingForClick
    case wrongClick
    case seance
    case success
    case danger
    case sleeping
}

enum GhostEvent: Equatable, Sendable {
    case startListening
    case startPlanning
    case startSearching
    case escalateSearch
    case targetFound
    case awaitClick
    case clickedWrong
    case wrongClickRecovered
    case cannotFind
    case stepDone(last: Bool)
    case idleTooLong
    case activity
    case dangerDetected
    case dangerCleared
    case cancel
}

struct GhostStateMachine: Equatable, Sendable {
    private(set) var visible: GhostState
    private(set) var suspendedByDanger: GhostState?

    init(visible: GhostState = .idle, suspendedByDanger: GhostState? = nil) {
        self.visible = visible
        self.suspendedByDanger = visible == .danger ? suspendedByDanger : nil
    }

    mutating func handle(_ event: GhostEvent) {
        switch event {
        case .dangerDetected:
            if visible != .danger {
                suspendedByDanger = visible
                visible = .danger
            }
            return
        case .dangerCleared:
            guard visible == .danger else { return }
            visible = suspendedByDanger ?? .idle
            suspendedByDanger = nil
            return
        case .cancel:
            if visible == .danger {
                suspendedByDanger = .idle
            } else {
                visible = .idle
                suspendedByDanger = nil
            }
            return
        default:
            guard visible != .danger else { return }
        }

        switch (visible, event) {
        case (.idle, .startListening), (.sleeping, .startListening), (.success, .startListening):
            visible = .listening
        case (.idle, .startPlanning), (.listening, .startPlanning),
             (.sleeping, .startPlanning), (.success, .startPlanning):
            visible = .planning
        case (.planning, .startSearching), (.found, .startSearching),
             (.waitingForClick, .startSearching), (.seance, .startSearching),
             (.searchingHard, .startSearching):
            visible = .searching
        case (.searching, .escalateSearch):
            visible = .searchingHard
        case (.searching, .targetFound), (.searchingHard, .targetFound):
            visible = .found
        case (.found, .awaitClick), (.wrongClick, .awaitClick):
            visible = .waitingForClick
        case (.waitingForClick, .clickedWrong):
            visible = .wrongClick
        case (.wrongClick, .wrongClickRecovered):
            visible = .waitingForClick
        case (.searching, .cannotFind), (.searchingHard, .cannotFind):
            visible = .seance
        case (.waitingForClick, .stepDone(let last)),
             (.found, .stepDone(let last)),
             (.seance, .stepDone(let last)):
            visible = last ? .success : .searching
        case (.idle, .idleTooLong):
            visible = .sleeping
        case (.sleeping, .activity), (.success, .activity):
            visible = .idle
        default:
            break
        }
    }

    func handling(_ event: GhostEvent) -> GhostStateMachine {
        var copy = self
        copy.handle(event)
        return copy
    }
}
