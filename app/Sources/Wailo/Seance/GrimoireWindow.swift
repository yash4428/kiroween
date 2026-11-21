import AppKit
import SwiftUI

@MainActor
final class GrimoireController: ObservableObject {
    @Published private(set) var spells: [Spell] = []
    private var store: GrimoireStore
    private let finder: AXFinder
    weak var ghost: GhostPet?

    init(finder: AXFinder, ghost: GhostPet? = nil) {
        self.finder = finder; self.ghost = ghost
        store = GrimoireStore(); let recovery = store.load(); spells = store.spells
        if recovery != nil { ghost?.say("I found a damaged Grimoire and kept it safe for recovery.", style: .warning) }
    }

    func learn(_ spell: Spell) {
        store.learn(spell); persist(); spells = store.spells
    }

    func forget(_ id: UUID) {
        guard store.forget(id: id) else { return }; persist(); spells = store.spells
    }

    func rememberedTarget(for step: GuideStep) -> CGRect? {
        guard let bundle = step.bundleHint, let spell = store.match(bundleID: bundle, stepText: step.instruction) else { return nil }
        let frames = NSScreen.screens.map(\.frame)
        guard frames.contains(where: { $0.origin == .zero }),
              let rect = Grimoire.locate(spell: spell,
                                         windowFrameAX: finder.frontmostWindowFrameAX(bundleID: bundle),
                                         visibleScreenFrames: frames) else { return nil }
        store.markCast(id: spell.id); persist(); spells = store.spells
        ghost?.say("📖 I remember this one!", autoHide: 1.2)
        return rect
    }

    private func persist() { try? store.save() }
}

@MainActor
final class GrimoireWindowController {
    private var panel: NSPanel?
    private let model: GrimoireController
    init(model: GrimoireController) { self.model = model }

    func show() {
        if let panel { panel.orderFrontRegardless(); return }
        let view = GrimoireView(model: model)
        let host = NSHostingView(rootView: view)
        let fitting = host.fittingSize; host.sizingOptions = []
        let size = CGSize(width: min(max(fitting.width, 480), 620), height: min(max(fitting.height, 360), 620))
        host.frame = CGRect(origin: .zero, size: size)
        let panel = NSPanel(contentRect: CGRect(origin: .zero, size: size),
                            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.title = "Wailo’s Grimoire"; panel.isFloatingPanel = true; panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = host; panel.center(); panel.isReleasedWhenClosed = false
        self.panel = panel; panel.makeKeyAndOrderFront(nil)
    }
}

private struct GrimoireView: View {
    @ObservedObject var model: GrimoireController
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.86, blue: 0.66).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("📖 The Grimoire").font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.22, green: 0.12, blue: 0.20))
                if model.spells.isEmpty {
                    Text("No spells yet. When the spirits need help, teach Wailo where to look.")
                        .font(.system(size: 19)).padding(.vertical, 28)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(model.spells.sorted(by: { $0.createdAt > $1.createdAt })) { spell in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(spell.stepText).font(.system(size: 19, weight: .semibold))
                                        Text("\(spell.appName) • learned \(spell.createdAt.formatted(date: .abbreviated, time: .omitted)) • cast \(spell.timesCast)×")
                                            .font(.system(size: 16)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Forget") { model.forget(spell.id) }
                                        .accessibilityLabel("Forget spell \(spell.stepText)")
                                }.padding(14).background(.white.opacity(0.38), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }.padding(24)
        }.frame(minWidth: 460, minHeight: 340)
    }
}
