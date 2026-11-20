# Prompts to paste into Kiro (in order)

Paste each phase in the **Kiro IDE** chat unless the phase says otherwise. Each phase uses one or more
Kiro capabilities on purpose. After each phase, commit with a message like
`kiro(phase-N): …`.

---

## Phase 0 — Kickoff (Spec critique, Steering)
```
You are building Wailo, a haunted, cozy macOS guide for elderly users, for the Kiroween 2026
Costume Contest. Read ALL steering in .kiro/steering/ and the spec in .kiro/specs/wailo-app/.
The backend in backend/ is an existing, working server: reuse it, don't rewrite it.

Before writing any code:
1. Critique the spec: list gaps, contradictions, untestable acceptance criteria, and anything in
   tasks.md that doesn't trace to a requirement. Propose fixes.
2. Split the single spec into three feature specs, each with requirements.md (EARS, keep the R-IDs),
   design.md and tasks.md (every task cites requirement IDs):
   - haunting-foundation (R1–R3, R10, R12, R13)
   - ghost-pet (R4, R5)
   - guidance-and-safety (R6–R9, R11)
   Keep wailo-app/ as the overview, linking to them.
3. In each requirements.md, add a "Correctness properties" section with properties suitable for
   property-based testing (coordinates round-trip, footprint ends inside the target, state-machine
   invariants, router totality, bbox mapping stays on screen, Grimoire.matches symmetry).
Don't write app code yet.
```

## Phase 1 — Steering upgrade (inclusion modes)
```
Reorganise steering for precision:
- Keep product.md and structure.md as inclusion: always.
- Split tech.md into coordinates.md, windows-and-perf.md and privacy.md.
  - coordinates.md: fileMatch on Overlay/, Services/AX*, Guidance/
  - windows-and-perf.md: fileMatch on Overlay/, Haunting/, Pet/
  - privacy.md: always
- backend-api.md: fileMatch on BackendClient.swift and LiveMode.swift.
- Add cozy-design.md (palette, motion and Reduce Motion rules, ≥18 pt text, warm copy for elderly
  users; Cozy has no flicker or lightning), fileMatch on Haunting/, Pet/, Guidance/, Safety/.
- Add kiro-journal.md (inclusion: manual) describing how to write docs/KIRO_JOURNAL.md entries.
Preserve every "gotcha" rule verbatim. They came from real bugs.
```

## Phase 2 — Hooks (automation)
Create these with the **Agent Hooks** panel, or ask Kiro to create them:
```
Create agent hooks in .kiro/hooks/:
1. build-on-save: on save of app/Sources/**/*.swift, run `cd app && swift build`. If it fails, fix
   the errors.
2. test-pure-logic: on save of CoordinateSpace/FootprintPath/GhostState/TaskRouter/Grimoire or any
   *Tests.swift, run `cd app && swift test` and report failures.
3. privacy-guard: Pre Tool Use on file writes. Deny edits that log or transmit screenshots, screen
   text, emails or secrets (see privacy.md).
4. asset-license-audit: on file create under app/Sources/Wailo/Resources/, make sure the file is
   listed in assets/ASSETS.md with source and licence.
5. spec-sync: after each spec task, tick it in tasks.md and confirm the code covers the cited
   requirement IDs.
6. journal: on Agent Stop, append 3 bullets to docs/KIRO_JOURNAL.md (what was built, which Kiro
   feature helped, what went wrong or was learned).
7. cozy-check: on save under Haunting/, Pet/ or Guidance/, check Cozy rules (cozy-design.md).
```

## Phase 3 — Custom agents (+ CLI)
```
Create project custom agents in .kiro/agents/ (usable from the IDE, CLI and Web):
- spec-guardian: read-only reviewer. Compares the current diff with the requirement IDs in the
  three specs and lists unimplemented or untested acceptance criteria. May run `swift test`.
- ax-detective: specialist for Accessibility, coordinate spaces and multi-monitor issues. Uses the
  wailo-devtools MCP (ax_dump, screenshot).
- haunt-designer: visual polish within cozy-design.md. May only write under app/Sources/Wailo/
  {Haunting,Pet,Guidance}. Verifies with screenshots.
- perf-ghost: measures idle CPU with the wailo-devtools MCP cpu_sample and xctrace, then proposes
  changes to meet the < 5% budget.
- privacy-warden: read-only audit for PII, screenshot or secret leaks.
Give each agent a focused prompt, the minimal tools, and the relevant steering resources. Explain
when the main agent should delegate to each as a subagent.
```
Then, in a terminal (**Kiro CLI**): run `spec-guardian` and `privacy-warden` against the repo, and
paste the results into the journal.

## Phase 4 — Your own MCP server (Kiro can *see* the app)
```
Create tools/wailo-devtools-mcp, a small stdio MCP server (Node, no heavy deps), and register it in
.kiro/settings/mcp.json. Tools:
- launch_wailo({autodemo?: "folder"|"safari"|"cursed"|"prompt"}): builds app/ with `swift build` and
  runs .build/debug/Wailo with WAILO_AUTODEMO, returning the pid
- quit_wailo()
- screenshot({delay_s?}): uses `screencapture -x` and returns the PNG path (and image content if
  supported)
- ax_dump({bundle_id, depth}): dumps the AX tree of an app as JSON (small Swift or AppleScript helper)
- cpu_sample({seconds}): returns ps %cpu samples for the Wailo process
- grimoire_read(): returns ~/Library/Application Support/Wailo/grimoire.json
- backend_health({url?}): GET /health
Add a README to the tool. Never send screenshots anywhere; paths only (privacy.md).
```

## Phase 5 — Build with specs (task by task)
For each feature spec, open `tasks.md` and use **Start task** in order. After every task, the hooks
build and test. At the end of each spec:
```
Use the wailo-devtools MCP: launch_wailo with autodemo=<relevant>, wait, take a screenshot and check
it against the acceptance criteria of the tasks just finished. Delegate visual issues to
haunt-designer and coordinate issues to ax-detective. Then run spec-guardian.
```

## Phase 6 — Property-based tests (IDE)
```
For every "Correctness properties" entry in the three specs, generate property-based tests in
app/Tests/WailoTests/Properties/. Use a PBT library if one is suitable for SwiftPM; otherwise use a
seeded random-input harness running 1,000 iterations, with shrinking-style minimal counterexample
reporting. Cover:
- random multi-screen layouts, including negative origins (a left-hand monitor) and screens above
  the primary
- random targets, including rects smaller than the footprint spacing
- random ghost event sequences
- random strings for TaskRouter
- random bboxes for vision mapping
Report every counterexample found, fix the code, and add the counterexample as a regular unit test.
```

## Phase 7 — Vibe vs spec experiment (for the write-up)
In a **plain chat** (no spec), say:
```
Vibe-code R11 Ghost Mail quickly: a little ghost flies in with a letter from "Grandson Aarav" and
the pet reads it in a bubble.
```
Then compare it with how R9 (Cursed Page) went spec-first. Ask Kiro:
```
Compare the Ghost Mail (vibe) and Cursed Page (spec) implementations: time taken, rework, bugs
found later, test coverage, how well they match the requirements. Write it to
docs/VIBE_VS_SPEC.md.
```

## Phase 8 — Powers
```
List Kiro powers relevant to this project (GitHub, AWS/Bedrock, testing, design) and install the
useful ones. Then create our own power at powers/spooky-macos-overlays/:
- POWER.md with activation keywords: overlay, NSPanel, SpriteKit, click-through, accessibility, AX
- steering/: windows-and-perf.md and coordinates.md
- mcp.json: wailo-devtools
- hooks: build-on-save and privacy-guard
Install it from the local path and confirm it activates when I mention "click-through overlay".
```

## Phase 9 — Kiro Web and Crew (parallel work)
- In GitHub, open issues and label them `kiro` (Kiro Web opens PRs):
  - "Add supertest coverage for backend GET /health and POST /plan input validation (no live LLM)"
  - "README: features-to-try list, hotkeys table, permissions, Noto credit"
  - "Add a GitHub Action: macOS runner, `swift build && swift test` in app/"
- (Optional) In **Kiro Crew**, start a long-running "polish & performance" workspace with the goal
  "idle CPU < 5% with all Cozy effects on", and let it iterate using perf-ghost and the MCP.

## Phase 10 — Write-up draft
```
Using docs/KIRO_JOURNAL.md, docs/VIBE_VS_SPEC.md, the .kiro/ folder and the git history, draft
docs/KIRO_WRITEUP.md with one section per judging question: surfaces (IDE/CLI/Web/Crew), custom
agents, hooks, spec-driven development, steering, MCP, property-based testing, powers. Use concrete
examples, file paths and numbers. Mark anything unverified as TODO; don't invent.
```
