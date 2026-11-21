import XCTest
@testable import Wailo

final class BackendClientTests: XCTestCase {
    func testFencedPartialPlanParsingAndMapping() throws {
        let json = """
        ```json
        {"task":"test","app":"Finder","steps":[
          {"targetLabel":"File"},
          {"instruction":"Type hello","action":"type"},
          {"action":"click"}
        ]}
        ```
        """
        guard case .plan(let plan) = BackendClient.parse(data: Data(json.utf8)) else {
            return XCTFail("Expected plan")
        }
        XCTAssertEqual(plan.steps.count, 2)
        XCTAssertEqual(plan.steps[0].instruction, "Click File")
        XCTAssertEqual(plan.steps[0].query, .smart("File"))
        XCTAssertEqual(plan.steps[1].query, .none)
        XCTAssertEqual(plan.steps[1].advance, .returnKeyOrNext)
    }

    func testClarificationTakesPrecedence() {
        let data = Data(#"{"clarify":{"prompt":"Which app?","options":["Mail","Safari"]},"steps":[]}"#.utf8)
        XCTAssertEqual(BackendClient.parse(data: data),
                       .clarify(BackendClarification(prompt: "Which app?", options: ["Mail", "Safari"])))
    }

    func testMalformedFieldsDoNotDiscardOtherwiseUsableSteps() {
        let data = Data(#"{"task":42,"steps":["bad",{"instruction":"Continue","action":9},{"targetLabel":"File"}]}"#.utf8)
        guard case .plan(let plan) = BackendClient.parse(data: data) else {
            return XCTFail("Expected partial plan")
        }
        XCTAssertEqual(plan.steps.map(\.instruction), ["Continue", "Click File"])
        XCTAssertEqual(plan.steps.map(\.query), [.none, .smart("File")])
    }

    func testParserIsTotalForArbitraryBytes() {
        for count in 0..<256 {
            let data = Data((0..<count).map { UInt8(($0 * 73 + count) % 256) })
            _ = BackendClient.parse(data: data)
        }
    }

    func testRequestContainsOnlyConsentedPlanFields() throws {
        let client = BackendClient(baseURL: URL(string: "https://example.test/base?secret=no")!)
        let request = try client.makePlanRequest(task: "create a note")
        XCTAssertEqual(request.url?.absoluteString, "https://example.test/plan")
        XCTAssertEqual(request.timeoutInterval, 90)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: String])
        XCTAssertEqual(object, ["task": "create a note", "platform": "macos"])
    }
}
