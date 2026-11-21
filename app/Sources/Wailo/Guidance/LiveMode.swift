import Foundation

@MainActor
final class LiveMode {
    private let backend: BackendClient
    private let director: GuidanceDirector
    private let ghost: GhostPet
    private var generation = 0
    private var requestTask: Task<Void, Never>?

    init(backend: BackendClient = BackendClient(), director: GuidanceDirector, ghost: GhostPet) {
        self.backend = backend; self.director = director; self.ghost = ghost
    }

    func run(task: String) {
        let trimmed = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        generation += 1; let active = generation
        requestTask?.cancel()
        ghost.handle(.startPlanning); ghost.say("Let me ask the spirits’ library… 🔮")
        requestTask = Task { [weak self] in
            guard let self else { return }
            let result = await backend.plan(task: trimmed)
            guard !Task.isCancelled, self.generation == active else { return }
            self.handle(result, originalTask: trimmed)
        }
    }

    func cancel() { generation += 1; requestTask?.cancel(); requestTask = nil }

    private func handle(_ result: PlanParseResult, originalTask: String) {
        switch result {
        case .plan(let plan):
            director.run(DemoScript(title: plan.task ?? originalTask, steps: plan.steps))
        case .clarify(let clarification):
            let actions = clarification.options.prefix(3).map { option in
                SpeechBubble.Action(option) { [weak self] in self?.run(task: "\(originalTask). \(option)") }
            }
            ghost.say(clarification.prompt, actions: actions)
        case .failure(let failure):
            let detail: String
            if case .http(let status, let code) = failure.kind, status == 402 || code == "limit_reached" {
                detail = "The free task limit has been reached for now."
            } else { detail = failure.details ?? "The spirits’ library is closed right now." }
            ghost.say("\(detail) 🌙 Let me show you a demo instead!", style: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in self?.director.run(.newFolder) }
        }
    }
}
