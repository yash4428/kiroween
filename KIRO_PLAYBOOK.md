# Kiro playbook — use every capability, and capture evidence for the write-up

Judging gives real weight to **"Was a variety of Kiro tools used impactfully? Does the project show a
deep understanding of Kiro features?"** This playbook gives each write-up question a concrete action
in this repo, plus the **evidence to capture**: screenshots, file paths and before/after notes.

> Rule of thumb: everything Kiro creates lives in `.kiro/` and gets committed. Judges read that
> folder. Never gitignore it.
> Keep `docs/KIRO_JOURNAL.md` updated (a hook does it for you, see §3). It becomes your write-up.

Verify the exact menu names in your Kiro version. Feature names below follow kiro.dev docs as of
Nov 2026.

---

## 1. Surfaces: IDE, CLI, Web, Crew (write-up: "how did they differ?")

| Surface | Use it for, in this project | Evidence |
|---|---|---|
| **Kiro IDE** | The main build: specs (requirements → design → tasks), **property-based tests (IDE-only)**, hooks, steering, powers | Screenshots of the spec panel and the task "Start" buttons |
| **Kiro CLI** (`kiro-cli`, V3 harness) | Run the **custom agents headless** in the terminal: the `spec-guardian` review before each commit and the `perf-ghost` CPU check. Shares steering, hooks and MCP with the IDE. | Terminal recording of `kiro-cli` running an agent |
| **Kiro Web** (app.kiro.dev) | Assign GitHub issues: label an issue `kiro` (or comment `/kiro`) and let Web open a PR. Good targets: "backend: add `/health` test with supertest", "README: hotkey table", "add `/wailo/plan-preview` docs". | The PR it opened, with the issue link |
| **Kiro Crew** (optional) | A persistent workspace that remembers context across days. Use it for the multi-day **polish/performance** thread: give it the CPU-budget goal and let it keep iterating. | Crew session notes or screenshot |

Write-up angle: the IDE was for design and correctness (specs plus PBT), the CLI for automation and
review gates, Web for parallel, low-risk chores via PRs, and Crew for long-running polish.

## 2. Spec-driven development (write-up: structure, benefit, versus vibe coding)
- **Three specs, not one giant one.** Split the existing `.kiro/specs/wailo-app/` into feature
  specs:
  - `haunting-foundation` (R1–R3, R10, R12)
  - `ghost-pet` (R4, R5)
  - `guidance-and-safety` (R6–R9, R11)
  Each has `requirements.md` (EARS), `design.md` and `tasks.md` with requirement traceability.
- Ask Kiro to **critique the spec before coding** (gaps, contradictions, untestable requirements).
  Screenshot what it found.
- **Controlled comparison with vibe coding:** build **Ghost Mail (R11)** by *vibe coding* in a normal
  chat with no spec, and build **Cursed Page (R9)** *spec-first*. Note the time taken, rework,
  bugs and test coverage for each. This makes a great paragraph.
- Evidence: commit history per task (`feat(ghost-pet): 4.3 …`) and the spec files.

## 3. Agent hooks (write-up: which workflows, how they helped)
Create them in **Kiro panel → Agent Hooks → +** so they're saved in `.kiro/hooks/`.

| Hook | Trigger | Action |
|---|---|---|
| `build-on-save` | File Save `app/Sources/**/*.swift` | Command: `cd app && swift build 2>&1 \| tail -20`. Agent: "fix compile errors" |
| `test-pure-logic` | File Save on `CoordinateSpace.swift`, `FootprintPath.swift`, `GhostState.swift`, `TaskRouter.swift`, `Grimoire.swift`, `*Tests.swift` | `cd app && swift test` |
| `privacy-guard` | **Pre Tool Use** on write tools | Agent: block (exit 2) any edit that logs screenshots, screen text, emails or keys, per tech.md › Privacy |
| `asset-license-audit` | File Create `app/Sources/Wailo/Resources/*` | Agent: make sure the asset is listed in `assets/ASSETS.md` with source and licence |
| `spec-sync` | **Post Task Execution** (or Agent Stop) | Agent: tick the task, check the code matches the requirement IDs, update `tasks.md` |
| `journal` | **Agent Stop** | Agent: append 3 bullets to `docs/KIRO_JOURNAL.md` (what was built, which Kiro feature helped, problems hit) |
| `cozy-check` | File Save `app/Sources/Wailo/{Haunting,Guidance,Pet}/**` | Agent: check Cozy defaults (no flicker or lightning in Cozy, Reduce Motion handled, ≥18 pt text) |

Evidence: the `.kiro/hooks/*` files, plus one screenshot each of `privacy-guard` blocking a bad edit
and `build-on-save` fixing an error.

## 4. Steering (write-up: strategy that made the biggest difference)
Already present: `product.md`, `tech.md`, `structure.md`, `backend-api.md`. Upgrade them with
**inclusion modes** (front-matter):
- `product.md`, `structure.md` → `inclusion: always`
- **Split `tech.md`** into:
  - `coordinates.md` → `inclusion: fileMatch` on `**/Overlay/**`, `**/Services/AX*`, `**/Guidance/**`
  - `windows-and-perf.md` → `fileMatch` on `**/Overlay/**`, `**/Haunting/**`, `**/Pet/**`
  - `privacy.md` → `always`
- `backend-api.md` → `fileMatch` on `**/Services/BackendClient.swift`, `**/LiveMode.swift`
- `cozy-design.md` (new: palette, motion rules, copy tone for elderly users) → `fileMatch` on UI
  folders
- `kiro-journal.md` → `manual` (pull it in with `#kiro-journal` when writing the write-up)

The strategy to highlight: **"gotchas as steering."** Every bug from the prototype became a steering
rule. For example, `isFloatingPanel` resets the window level, and NSHostingView auto-sizes. Kiro then
never reintroduced them. Note any time it would have.

## 5. Custom agents and subagents (write-up: which, where, impact)
Have Kiro create these in `.kiro/agents/` (project-level works in the IDE, CLI and Web):

| Agent | Role | Tools / scope |
|---|---|---|
| `spec-guardian` | Reviews a diff against the requirement IDs. Flags untested or unimplemented acceptance criteria. | Read-only plus `swift test` |
| `ax-detective` | Specialist for AX, coordinates and multi-monitor issues. Uses the `wailo-devtools` MCP to dump the AX tree and screenshot. | Read, `wailo-devtools` MCP |
| `haunt-designer` | Visual polish within Cozy rules. Proposes animation timing and colour. Verifies with screenshots. | Write `app/Sources/Wailo/{Haunting,Pet,Guidance}` only |
| `perf-ghost` | Measures idle CPU (`ps`, Instruments CLI `xctrace`) and suggests fixes against the < 5% budget | Shell (read-only) |
| `privacy-warden` | Audits for PII, screenshot or secret leaks | Read-only |

Use them **as subagents** from the main agent ("delegate to `ax-detective`"), and run
`spec-guardian` from the **CLI** before commits. Evidence: the agent JSON files, and one example
each of a subagent finding or fixing something.

## 6. MCP (write-up: what became possible)
1. **Build your own MCP server: `tools/wailo-devtools-mcp`** (Node or Python, stdio). This is the
   strongest MCP story, because Kiro can then *see* the haunted desktop. Tools:
   - `launch_wailo(autodemo?)`, `quit_wailo()`
   - `screenshot(region?)` (uses `screencapture`, returns a path or PNG)
   - `ax_dump(app_bundle_id, depth)` (AX tree as JSON)
   - `cpu_sample(seconds)` (`ps -o %cpu` on the Wailo process)
   - `grimoire_read()` (the spells JSON)
   - `backend_health()` (`GET /health`)

   That gives a visual-verification loop: Kiro builds, launches `WAILO_AUTODEMO=folder`, screenshots,
   checks the spider is on the Dock icon, and iterates. The prototype was verified exactly this way
   (by hand).
2. **Third-party MCP**, if available in your setup:
   - **GitHub MCP** (issues and PRs that feed Kiro Web)
   - **Fetch/Context7-style docs MCP** (Apple docs on AX, SpriteKit, Carbon)
   - **AWS docs MCP** (Bedrock/Titan for the backend)

## 7. Property-based testing (write-up: what PBT caught that unit tests missed)
In the spec, write **correctness properties**, and let the IDE generate the property tests
(PBT is IDE-only). Swift has no Hypothesis, so either ask Kiro to use a PBT library (for example
SwiftCheck) or a seeded random-input harness in XCTest that runs 1,000 iterations. Good properties:
- **Coordinates:** for any screen layout and any point,
  `cocoaToAX(axToCocoa(p)) == p` and `axRectToCocoa` keeps width and height. `screenIndex` always
  returns a valid index.
- **Footprints:** for any start point and any non-empty target rect, the last footprint is inside
  the target. Consecutive prints are ≤ 1.8 × spacing apart and alternate left/right.
- **Ghost state machine:** for any event sequence:
  - `cancel` → idle
  - `dangerDetected` then `dangerCleared` restores the prior state
  - the machine never ends in a state unreachable from idle
- **TaskRouter:** total (never crashes); whitespace-only → `.nothing`; routing is case-insensitive.
- **bbox mapping (0–1000):** any valid bbox maps inside the screen frame. Invalid boxes are
  rejected.
- **Grimoire.matches:** reflexive and symmetric.

Write down any counterexample PBT finds (likely candidates: a target rect smaller than the spacing,
or negative screen origins on a left-hand monitor). That's your PBT paragraph.

## 8. Powers (write-up: bundled expertise, third-party tooling)
- Browse **kiro.dev/powers** and install any that fit, such as GitHub, AWS/Bedrock for the backend,
  or a design or testing power. Note what each one added (MCP tools plus steering) without you
  writing config.
- **Build your own power: `spooky-macos-overlays`.** A `POWER.md` (activation keywords: "overlay",
  "NSPanel", "SpriteKit", "click-through", "AX") that bundles:
  - the windows, levels and gotchas steering
  - the `wailo-devtools` MCP
  - the `build-on-save` and `privacy-guard` hooks

  Install it from a local path, and describe it as reusable for any macOS overlay app. That shows a
  deep understanding.

## 9. Skills (newer Kiro feature)
Optionally package "screenshot-verify" (launch → screenshot → compare checklist) as an **agent
skill**, so any agent can reuse it.

---

## Checklist for the submission
- [ ] Public repo with `/.kiro` at the root (not gitignored), and a LICENSE (MIT included)
- [ ] Demo video < 3 min on YouTube (public). Use `WAILO_AUTODEMO` for clean takes.
- [ ] Write-up: one section per heading above, using `docs/KIRO_JOURNAL.md` as the source
- [ ] Built during the hackathon window. The repo history starts now; this repo is new.
- [ ] Bonus: a social post (Social Blitz) and a blog post that says it was written for Kiroween 2026
  (Bonus Blog). Check the rules page.
