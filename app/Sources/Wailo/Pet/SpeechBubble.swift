import AppKit
import SwiftUI

/// Owns Wailo's transient speech and prompt panel.
@MainActor
final class SpeechBubble {
    struct Action {
        let title: String
        let accessibilityLabel: String
        let callback: () -> Void

        init(_ title: String, accessibilityLabel: String? = nil, callback: @escaping () -> Void) {
            self.title = title
            self.accessibilityLabel = accessibilityLabel ?? title
            self.callback = callback
        }
    }

    enum Style {
        case normal
        case celebratory
        case warning
    }

    private var panel: BubblePanel?
    private var lastGhostFrame: CGRect?
    private var lastVisibleFrames: [CGRect] = []
    private var generation = 0
    private var previousApplication: NSRunningApplication?

    var isVisible: Bool { panel?.isVisible == true }

    func say(
        _ text: String,
        style: Style = .normal,
        actions: [Action] = [],
        autoHide: TimeInterval? = nil,
        centerOnScreen: NSScreen? = nil
    ) {
        generation += 1
        let currentGeneration = generation
        closePanel(restorePreviousApplication: false)

        let content = SpeechContent(text: text, style: style, actions: actions)
        let newPanel = makePanel(interactive: !actions.isEmpty, keyCapable: false)
        install(content, in: newPanel, maximumSize: CGSize(width: 460, height: 360))
        panel = newPanel

        if let screen = centerOnScreen {
            center(newPanel, in: screen.visibleFrame)
        } else if let ghostFrame = lastGhostFrame {
            place(newPanel, nextTo: ghostFrame, visibleFrames: lastVisibleFrames)
        }
        newPanel.orderFrontRegardless()

        if let delay = autoHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                self.hide()
            }
        }
    }

    func sayTypewriter(_ text: String, characterDelay: TimeInterval = 0.025) {
        generation += 1
        closePanel(restorePreviousApplication: false)
        let content = TypewriterContent(text: text, characterDelay: characterDelay)
        let newPanel = makePanel(interactive: false, keyCapable: false)
        install(content, in: newPanel, maximumSize: CGSize(width: 460, height: 360))
        panel = newPanel
        if let ghostFrame = lastGhostFrame { place(newPanel, nextTo: ghostFrame, visibleFrames: lastVisibleFrames) }
        newPanel.orderFrontRegardless()
    }

    func ask(
        prompt: String,
        suggestions: [String],
        initialText: String = "",
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        generation += 1
        closePanel(restorePreviousApplication: false)
        previousApplication = NSWorkspace.shared.frontmostApplication

        let newPanel = makePanel(interactive: true, keyCapable: true)
        let content = PromptContent(
            prompt: prompt,
            suggestions: suggestions,
            initialText: initialText,
            onSubmit: { [weak self] value in
                guard let self else { return }
                self.closePanel(restorePreviousApplication: true)
                onSubmit(value)
            },
            onCancel: { [weak self] in
                guard let self else { return }
                self.closePanel(restorePreviousApplication: true)
                onCancel()
            }
        )
        install(content, in: newPanel, maximumSize: CGSize(width: 520, height: 520))
        panel = newPanel
        if let ghostFrame = lastGhostFrame {
            place(newPanel, nextTo: ghostFrame, visibleFrames: lastVisibleFrames)
        }

        // A nonactivating panel can become key without bringing the accessory app to the front.
        newPanel.makeKeyAndOrderFront(nil)
    }

    func follow(ghostFrame: CGRect, visibleFrames: [CGRect]) {
        lastGhostFrame = ghostFrame
        lastVisibleFrames = visibleFrames
        guard let panel, panel.isVisible else { return }
        place(panel, nextTo: ghostFrame, visibleFrames: visibleFrames)
    }

    func covers(globalPoint: CGPoint) -> Bool {
        guard let panel, panel.isVisible else { return false }
        return panel.frame.contains(globalPoint)
    }

    func hide() {
        generation += 1
        closePanel(restorePreviousApplication: false)
    }

    private func makePanel(interactive: Bool, keyCapable: Bool) -> BubblePanel {
        let panel = BubblePanel(keyCapable: keyCapable)
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 2)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = !interactive
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        return panel
    }

    private func install<Content: View>(
        _ content: Content,
        in panel: NSPanel,
        maximumSize: CGSize
    ) {
        let host = NSHostingView(rootView: content)

        // NSHostingView must be measured before automatic sizing is disabled.
        let fitting = host.fittingSize
        host.sizingOptions = []

        let width = min(max(fitting.width, 280), maximumSize.width)
        let height = min(max(fitting.height, 90), maximumSize.height)
        let size = CGSize(width: width, height: height)
        host.frame = CGRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        panel.setContentSize(size)
    }

    private func place(_ panel: NSPanel, nextTo ghostFrame: CGRect, visibleFrames: [CGRect]) {
        guard !visibleFrames.isEmpty else { return }
        let screenFrame = containingOrNearestFrame(to: ghostFrame, among: visibleFrames)
        let gap: CGFloat = 12

        var origin = CGPoint(
            x: ghostFrame.midX - panel.frame.width / 2,
            y: ghostFrame.maxY + gap
        )
        if origin.y + panel.frame.height > screenFrame.maxY {
            origin.y = ghostFrame.minY - gap - panel.frame.height
        }
        origin.x = clamped(origin.x, screenFrame.minX, screenFrame.maxX - panel.frame.width)
        origin.y = clamped(origin.y, screenFrame.minY, screenFrame.maxY - panel.frame.height)
        panel.setFrameOrigin(origin)
    }

    private func center(_ panel: NSPanel, in visibleFrame: CGRect) {
        panel.setFrameOrigin(CGPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.midY - panel.frame.height / 2
        ))
    }

    private func closePanel(restorePreviousApplication: Bool) {
        panel?.orderOut(nil)
        panel = nil
        if restorePreviousApplication {
            restorePreviousAppIfPossible()
        }
    }

    private func restorePreviousAppIfPossible() {
        defer { previousApplication = nil }
        guard let previousApplication, !previousApplication.isTerminated else { return }
        previousApplication.activate(options: [])
    }

    private func containingOrNearestFrame(to rect: CGRect, among frames: [CGRect]) -> CGRect {
        if let containing = frames.first(where: { $0.contains(CGPoint(x: rect.midX, y: rect.midY)) }) {
            return containing
        }
        let point = CGPoint(x: rect.midX, y: rect.midY)
        return frames.min(by: { distanceSquared(from: point, to: $0) < distanceSquared(from: point, to: $1) }) ?? frames[0]
    }

    private func distanceSquared(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let x = clamped(point.x, rect.minX, rect.maxX)
        let y = clamped(point.y, rect.minY, rect.maxY)
        return pow(point.x - x, 2) + pow(point.y - y, 2)
    }

    private func clamped(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

private final class BubblePanel: NSPanel {
    private let acceptsKey: Bool

    init(keyCapable: Bool) {
        acceptsKey = keyCapable
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
    }

    override var canBecomeKey: Bool { acceptsKey }
    override var canBecomeMain: Bool { false }
}

private struct TypewriterContent: View {
    let text: String
    let characterDelay: TimeInterval
    @State private var displayed = ""

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Reserve the final wrapped size before NSHostingView automatic sizing is disabled.
            Text(text)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0)
                .accessibilityHidden(true)
            Text(displayed.isEmpty ? " " : displayed)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.13, green: 0.10, blue: 0.17))
                .fixedSize(horizontal: false, vertical: true)
        }
            .frame(maxWidth: 430, minHeight: 48, alignment: .leading)
            .padding(20)
            .background(Color(red: 0.98, green: 0.93, blue: 0.78), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.42, green: 0.29, blue: 0.56), lineWidth: 3))
            .task {
                for character in text {
                    guard !Task.isCancelled else { return }
                    displayed.append(character)
                    try? await Task.sleep(nanoseconds: UInt64(max(0.005, characterDelay) * 1_000_000_000))
                }
            }
            .accessibilityLabel(text)
    }
}

private struct SpeechContent: View {
    let text: String
    let style: SpeechBubble.Style
    let actions: [SpeechBubble.Action]

    private var borderColor: Color {
        switch style {
        case .normal: return Color(red: 0.42, green: 0.29, blue: 0.56)
        case .celebratory: return Color(red: 0.78, green: 0.43, blue: 0.08)
        case .warning: return Color(red: 0.55, green: 0.12, blue: 0.12)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.13, green: 0.10, blue: 0.17))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isStaticText)

            if !actions.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                        Button(action.title, action: action.callback)
                            .buttonStyle(WailoButtonStyle(accent: borderColor))
                            .accessibilityLabel(action.accessibilityLabel)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 430, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 1.0, green: 0.96, blue: 0.83))
                .shadow(color: .black.opacity(0.24), radius: 12, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 3)
        )
        .padding(8)
    }
}

private struct PromptContent: View {
    let prompt: String
    let suggestions: [String]
    let initialText: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String
    @State private var validationMessage: String?
    @State private var consumed = false
    @FocusState private var fieldFocused: Bool

    init(
        prompt: String,
        suggestions: [String],
        initialText: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.prompt = prompt
        self.suggestions = suggestions
        self.initialText = initialText
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(prompt)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.13, green: 0.10, blue: 0.17))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Close request prompt")
                .keyboardShortcut(.cancelAction)
            }

            TextField("Type what you would like Wailo to help with", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 19))
                .frame(minHeight: 44)
                .focused($fieldFocused)
                .onSubmit(submit)
                .accessibilityLabel("What would you like to do?")

            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.12, blue: 0.12))
                    .accessibilityLabel(validationMessage)
            }

            if !suggestions.isEmpty {
                Text("Try an example")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.30))

                FlexibleSuggestionStack(suggestions: suggestions) { suggestion in
                    text = suggestion
                    validationMessage = nil
                    fieldFocused = true
                }
            }

            Button("Go 🎃", action: submit)
                .buttonStyle(WailoButtonStyle(accent: Color(red: 0.42, green: 0.29, blue: 0.56)))
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel("Start this request")
        }
        .padding(22)
        .frame(width: 480, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 1.0, green: 0.96, blue: 0.83))
                .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.42, green: 0.29, blue: 0.56), lineWidth: 3)
        )
        .padding(8)
        .onAppear {
            DispatchQueue.main.async { fieldFocused = true }
        }
        .onExitCommand(perform: cancel)
    }

    private func submit() {
        guard !consumed else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Please tell me what you would like help with."
            fieldFocused = true
            return
        }
        consumed = true
        onSubmit(trimmed)
    }

    private func cancel() {
        guard !consumed else { return }
        consumed = true
        onCancel()
    }
}

private struct FlexibleSuggestionStack: View {
    let suggestions: [String]
    let select: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(suggestion) { select(suggestion) }
                    .buttonStyle(.plain)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.30))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.62))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.57, green: 0.45, blue: 0.66), lineWidth: 1.5)
                    )
                    .accessibilityLabel("Use example: \(suggestion)")
            }
        }
    }
}

private struct WailoButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(accent.opacity(configuration.isPressed ? 0.72 : 1))
            )
            .contentShape(Rectangle())
    }
}
