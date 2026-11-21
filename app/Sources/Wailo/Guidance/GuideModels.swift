import Foundation
import CoreGraphics

struct GuideStep: Equatable, Sendable {
    let instruction: String
    let query: TargetQuery
    let action: HandAction
    let bundleHint: String?
    let advance: AdvanceRule

    init(
        instruction: String,
        query: TargetQuery,
        action: HandAction = .tap,
        bundleHint: String? = nil,
        advance: AdvanceRule = .clickInTarget
    ) {
        self.instruction = instruction
        self.query = query
        self.action = action
        self.bundleHint = bundleHint
        self.advance = advance
    }
}

enum TargetQuery: Equatable, Sendable {
    case none
    case dockItem(String)
    case menuBarItem(String)
    case menuItem(String)
    case element(keywords: [String], roles: [String])
    case safariAddressBar
    case smart(String)
}

enum AdvanceRule: Equatable, Sendable {
    case clickInTarget
    case returnKeyOrNext
}

enum HandAction: Equatable, Sendable {
    case tap
    case doubleTap
    case drag(to: CGPoint)
    case none

    static func == (lhs: HandAction, rhs: HandAction) -> Bool {
        switch (lhs, rhs) {
        case (.tap, .tap), (.doubleTap, .doubleTap), (.none, .none):
            return true
        case (.drag(let left), .drag(let right)):
            return left.x == right.x && left.y == right.y
        default:
            return false
        }
    }
}

struct DemoScript: Equatable, Sendable {
    let title: String
    let steps: [GuideStep]

    static let newFolder = DemoScript(
        title: "New Folder",
        steps: [
            GuideStep(instruction: "Click Finder in the Dock", query: .dockItem("Finder"), bundleHint: "com.apple.finder"),
            GuideStep(instruction: "Click File in the menu bar", query: .menuBarItem("File"), bundleHint: "com.apple.finder"),
            GuideStep(instruction: "Click New Folder", query: .menuItem("New Folder"), bundleHint: "com.apple.finder")
        ]
    )

    static let safari = DemoScript(
        title: "Safari",
        steps: [
            GuideStep(instruction: "Click Safari in the Dock", query: .dockItem("Safari"), bundleHint: "com.apple.Safari"),
            GuideStep(instruction: "Click the address and search field", query: .safariAddressBar, bundleHint: "com.apple.Safari"),
            GuideStep(
                instruction: "Type wikipedia.org and press Return",
                query: .none,
                action: .none,
                bundleHint: "com.apple.Safari",
                advance: .returnKeyOrNext
            )
        ]
    )

    static let finderNewFolder = newFolder
    static let safariWikipedia = safari
}
