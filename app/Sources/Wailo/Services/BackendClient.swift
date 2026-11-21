import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct BackendPlan: Equatable, Sendable {
    let task: String?
    let app: String?
    let cached: Bool?
    let steps: [GuideStep]
}

struct BackendClarification: Equatable, Sendable {
    let prompt: String
    let options: [String]
}

struct BackendFailure: Error, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case invalidResponse
        case noUsableSteps
        case transport
        case http(status: Int, code: String?)
    }

    let kind: Kind
    let details: String?
}

enum PlanParseResult: Equatable, Sendable {
    case plan(BackendPlan)
    case clarify(BackendClarification)
    case failure(BackendFailure)
}

struct BackendClient {
    static let defaultBaseURL = URL(string: "http://localhost:3000")!
    let baseURL: URL

    init(baseURL: URL? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) {
        let configured = environment["WAILO_BACKEND_URL"]
            .flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        self.baseURL = BackendClient.validOrigin(baseURL ?? configured) ?? Self.defaultBaseURL
    }

    func makePlanRequest(task: String) throws -> URLRequest {
        guard let url = endpoint(path: "/plan") else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(PlanRequest(
            task: task.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: "macos"
        ))
        return request
    }

    func plan(task: String) async -> PlanParseResult {
        let request: URLRequest
        do {
            request = try makePlanRequest(task: task.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return .failure(BackendFailure(kind: .transport, details: "The backend address is invalid."))
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(BackendFailure(kind: .invalidResponse, details: "The backend returned an invalid response."))
            }
            guard (200..<300).contains(http.statusCode) else {
                let error = try? JSONDecoder().decode(ErrorDTO.self, from: data)
                return .failure(BackendFailure(
                    kind: .http(status: http.statusCode, code: error?.code),
                    details: Self.bounded(error?.details ?? error?.error)
                ))
            }
            return Self.parse(data: data)
        } catch is CancellationError {
            return .failure(BackendFailure(kind: .transport, details: "The request was cancelled."))
        } catch {
            return .failure(BackendFailure(kind: .transport, details: "Wailo could not reach the backend."))
        }
    }

    static func parse(data: Data) -> PlanParseResult {
        guard let source = String(data: data, encoding: .utf8),
              let jsonData = stripFence(from: source).data(using: .utf8),
              let response = try? JSONDecoder().decode(ResponseDTO.self, from: jsonData) else {
            return .failure(BackendFailure(kind: .invalidResponse, details: "The plan response was not valid JSON."))
        }

        if let clarification = response.clarify,
           let prompt = nonempty(clarification.prompt) {
            return .clarify(BackendClarification(
                prompt: prompt,
                options: (clarification.options ?? []).compactMap(nonempty)
            ))
        }

        let mapped = (response.steps ?? []).compactMap(mapStep)
        guard !mapped.isEmpty else {
            return .failure(BackendFailure(kind: .noUsableSteps, details: "The backend did not return any usable steps."))
        }
        return .plan(BackendPlan(task: nonempty(response.task),
                                 app: nonempty(response.app),
                                 cached: response.cached,
                                 steps: mapped))
    }

    private func endpoint(path: String) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = path
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func validOrigin(_ url: URL?) -> URL? {
        guard let url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.path = ""
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        return components.url
    }

    private static func mapStep(_ dto: StepDTO) -> GuideStep? {
        let label = nonempty(dto.targetLabel) ?? nonempty(dto.findDescription)
        let instruction = nonempty(dto.instruction) ?? label.map { "Click \($0)" }
        guard let instruction else { return nil }

        let action = nonempty(dto.action)?.lowercased() ?? "click"
        if action == "click", let label {
            return GuideStep(instruction: instruction,
                             query: .smart(label),
                             action: .tap,
                             bundleHint: nil,
                             advance: .clickInTarget)
        }
        return GuideStep(instruction: instruction,
                         query: .none,
                         action: .none,
                         bundleHint: nil,
                         advance: .returnKeyOrNext)
    }

    private static func stripFence(from source: String) -> String {
        var text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("```") else { return text }
        guard let openingEnd = text.firstIndex(of: "\n") else { return text }
        let opening = text[..<openingEnd].trimmingCharacters(in: .whitespaces)
        guard opening == "```" || opening.lowercased() == "```json" else { return text }
        text = String(text[text.index(after: openingEnd)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasSuffix("```") {
            text.removeLast(3)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    private static func nonempty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func bounded(_ value: String?) -> String? {
        guard let value = nonempty(value) else { return nil }
        return String(value.prefix(500))
    }
}

private struct PlanRequest: Encodable {
    let task: String
    let platform: String
}

private struct ResponseDTO: Decodable {
    let task: String?
    let app: String?
    let cached: Bool?
    let steps: [StepDTO]?
    let clarify: ClarificationDTO?

    private enum CodingKeys: String, CodingKey { case task, app, cached, steps, clarify }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        task = container.lossyString(forKey: .task)
        app = container.lossyString(forKey: .app)
        cached = try? container.decodeIfPresent(Bool.self, forKey: .cached)
        let decodedSteps = try? container.decodeIfPresent([Failable<StepDTO>].self, forKey: .steps)
        steps = decodedSteps?.compactMap(\.value)
        clarify = try? container.decodeIfPresent(ClarificationDTO.self, forKey: .clarify)
    }
}

private struct StepDTO: Decodable {
    let instruction: String?
    let targetLabel: String?
    let findDescription: String?
    let action: String?

    private enum CodingKeys: String, CodingKey { case instruction, targetLabel, findDescription, action }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instruction = container.lossyString(forKey: .instruction)
        targetLabel = container.lossyString(forKey: .targetLabel)
        findDescription = container.lossyString(forKey: .findDescription)
        action = container.lossyString(forKey: .action)
    }
}

private struct ClarificationDTO: Decodable {
    let prompt: String?
    let options: [String]?

    private enum CodingKeys: String, CodingKey { case prompt, options }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prompt = container.lossyString(forKey: .prompt)
        let decodedOptions = try? container.decodeIfPresent([Failable<String>].self, forKey: .options)
        options = decodedOptions?.compactMap(\.value)
    }
}

private struct Failable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    func lossyString(forKey key: Key) -> String? {
        try? decodeIfPresent(String.self, forKey: key)
    }
}

private struct ErrorDTO: Decodable {
    let code: String?
    let error: String?
    let details: String?
}
