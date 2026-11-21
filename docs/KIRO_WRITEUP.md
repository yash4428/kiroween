# How we used Kiro to build Wailo

## Kiro IDE was the project’s control room

We built Wailo in Kiro IDE. The IDE was where we reviewed the repository, challenged the initial
specification, wrote the feature specs, delegated isolated implementation work, integrated the app,
ran Swift builds and tests, audited privacy-sensitive code, and launched the finished app.

The integrated workflow mattered for a macOS overlay app because design decisions, AppKit constraints,
visual behavior, and validation all affected one another. Kiro could move from an EARS requirement to
the corresponding design, implementation file, and XCTest without losing the reason behind the
change.

We used the IDE’s agent tools to:

- read every steering document and the complete initial spec before editing;
- create and update files across the Swift Package;
- run `swift build`, `swift test`, source audits, and Git diff checks;
- delegate independent modules to focused sub-agents with non-overlapping file ownership;
- inspect compiler and test output, fix failures, and rerun the complete suite;
- launch Wailo as a background macOS process and verify that it stayed running.

We did not use Kiro CLI, Kiro Web, or Kiro Crew for the submitted build. Terminal commands shown in the
session ran through Kiro IDE’s tool integration, not through the Kiro CLI client. The IDE was the best
fit for this build because the work required continuous visual and architectural context. CLI would
be a good fit for headless review gates, Web for issue-to-PR chores, and Crew for a long-running
performance-polish loop, but claiming those surfaces without session or PR evidence would weaken the
submission rather than strengthen it.

## Focused sub-agents accelerated the build

We did not create persistent project custom-agent profiles under `.kiro/agents/`. Instead, we used
Kiro’s focused sub-agent delegation from the IDE. This gave us the main benefit of specialist agents,
clean context and parallel work, without inventing a custom-agent story after the fact.

The main agent split the first implementation pass into three non-overlapping assignments:

1. **Pure logic and tests:** coordinates, ghost state machine, task routing, footprint paths, backend
   parsing, Grimoire matching/persistence, cursed-URL logic, and XCTest coverage.
2. **Haunting foundation:** settings, asset loading, screen overlays, night sky, fog, webs, bats,
   tombstone, tracked-window slime/leaves, haunting orchestration, and ambient footprints.
3. **Ghost pet UI:** the procedural ghost, semantic state visuals, drag/persistence behavior,
   body-only mouse handling, speech bubbles, and the focused prompt.

Each assignment named the exact files it could modify. That ownership boundary prevented agents from
rewriting `Package.swift`, touching `backend/`, or colliding in shared files. All three modules reached
Swift compilation independently; their only package-level linker issue was the intentionally
not-yet-created app entry point. The main IDE session then integrated guidance, AX discovery, séance,
safety, Live mode, menu actions, and global hotkeys.

A documentation-specialist sub-agent was also used to verify official Kiro terminology for this
write-up. That helped us distinguish custom agents from delegated sub-agents, and Kiro Powers from
ordinary built-in tools.

The practical impact was substantial: Kiro produced 40 Swift source files while preserving module
boundaries, and the final clean build completed without warnings. The suite finished with 32 passing
tests and no backend changes.

## Agent hooks: designed, but not claimed as executed

The repository contains a detailed hook plan in `KIRO_MASTER_PROMPT.md` and `KIRO_PLAYBOOK.md` for:

- building Swift after source saves;
- running pure-logic tests after logic/test changes;
- rejecting privacy-sensitive writes;
- auditing new asset licenses;
- checking requirement/task synchronization;
- recording a Kiro development journal;
- checking Cozy and Reduce Motion rules.

Those hooks were not configured under `.kiro/hooks/` during the submitted build, so we do not claim
that they ran. We applied the same gates explicitly in the agent workflow: every implementation phase
was followed by `swift build` and `swift test`, privacy-sensitive APIs were searched directly, asset
paths were checked against `assets/ASSETS.md`, and `git diff --check` was run before completion.

This was still useful design work because it identified where event-driven automation would remove
human memory from the next iteration. A build-on-save hook and privacy pre-tool hook would be the
first two additions: one shortens compiler feedback, while the other enforces the rule that screenshots
exist only in memory for an explicitly enabled vision request.

## Spec-driven development was the biggest multiplier

The first instruction to Kiro explicitly prohibited app code. Kiro had to critique the spec before it
could implement anything. That review found issues that would otherwise have become expensive UI bugs:

- R14 was missing from the requested feature allocation, so it became a global quality gate.
- “The ghost stays exactly where dragged” conflicted with keeping it reachable on-screen.
- A focused prompt cannot literally leave another app’s field focused, so the requirement was
  rewritten around a nonactivating key-capable panel and restoring the previous app.
- `danger` overriding every state conflicted with “cancel always returns to idle.” Safety precedence
  and restoration were defined explicitly.
- `searchingHard` risked implying that a screenshot was sent even when vision was disabled. It was
  restricted to an enabled, consented vision request.
- Routing priority, punctuation, partial backend responses, corrupt Grimoire files, Automation
  failure, display removal, and Accessibility-denied behavior were all previously underspecified.
- Subjective timings such as “occasionally” and “about 3.6 seconds” were replaced with ranges or
  measurable procedures.

Kiro then split one large spec into three feature specs:

- `.kiro/specs/haunting-foundation/` for R1–R3, R10, R12, and R13;
- `.kiro/specs/ghost-pet/` for R4 and R5;
- `.kiro/specs/guidance-and-safety/` for R6–R9 and R11.

Each feature has `requirements.md`, `design.md`, and `tasks.md`. Requirements use EARS-style triggers,
designs define interfaces and state ownership, and every task cites requirement IDs. The original
`.kiro/specs/wailo-app/` became an overview rather than a second source of truth. The full critique is
preserved in `.kiro/specs/wailo-app/critique.md`.

This structure let Kiro work from contracts instead of guessing. For example, coordinate conversion
was isolated as pure logic; the ghost state machine owned danger restoration; both demo and backend
steps flowed through one `GuidanceDirector`; and only the vision service was allowed to handle pixels.
Those boundaries made parallel delegation possible.

Compared with vibe coding, the spec-first approach shifted effort earlier. We did not run a staged,
measured “vibe versus spec” experiment, so we do not claim invented timing numbers. The concrete
comparison is architectural: a vibe-coded version could make the ghost move and show Halloween art
quickly, but it would be easy to miss menu window levels, multi-monitor coordinate flips, stale timers,
permission-denied behavior, click-through rules, or privacy constraints. The spec made those cases
part of “done” before animation code existed.

## Steering turned prototype lessons into permanent guardrails

The four workspace steering documents had distinct jobs:

- `.kiro/steering/product.md` defined the elderly-first product, cozy-spooky tone, functional use of
  every effect, stationary pet behavior, and non-goals.
- `.kiro/steering/tech.md` defined the AppKit/SpriteKit/Core Animation/SwiftUI split, performance
  budget, permissions, privacy, and test strategy.
- `.kiro/steering/structure.md` defined file ownership and kept pure logic independent of AppKit.
- `.kiro/steering/backend-api.md` treated the existing Waylo backend as a contract and explicitly
  prohibited rewriting it.

The most effective strategy was **putting known failure modes into steering, not relying on memory**.
Examples included:

- selecting the zero-origin primary display instead of `NSScreen.main`;
- converting AX rectangle Y coordinates with `maxY`;
- setting `NSPanel.isFloatingPanel` before its final window level;
- measuring `NSHostingView.fittingSize` before disabling automatic sizing;
- avoiding `Bundle.module` because it can terminate when the resource bundle is missing;
- using only `URLSession.shared`;
- never calling `NSApp.hide`;
- checking generations in delayed callbacks so stale animations cannot overwrite safety state;
- keeping screen pixels behind an off-by-default consented setting.

These details directly appear in the implementation. The resource loader searches safely and falls
back to rendered emoji. Overlay levels are created per display. Guide callbacks carry generations.
The normal plan request contains only `task` and `platform`. The backend directory remained untouched.
Steering gave Kiro the kind of project memory that usually exists only in a senior developer’s head.

## MCP: deliberately not part of the submitted implementation

We did not configure an MCP server in `.kiro/settings/mcp.json`, so we do not claim MCP usage. The
playbook proposes a strong next step: a local `wailo-devtools` MCP with tools for launching Wailo,
capturing local screenshots, dumping AX trees, sampling CPU, reading the Grimoire, and checking backend
health. That would let Kiro close a visual verification loop that ordinary source inspection cannot:
launch an auto-demo, inspect where the spider landed, compare it with the AX target, sample idle CPU,
and iterate.

For this submission, Kiro’s built-in file and shell tools were sufficient to build, test, audit, and
launch the app. Avoiding a last-minute MCP also kept screen-capture scope simple and auditable. The
existing Waylo HTTP backend is an application service, not an MCP server, and we keep that distinction
clear.

## Correctness properties changed both the tests and the implementation

Each feature requirements file contains a **Correctness properties** section. We used the
property-based-testing mindset to state behavior over classes of inputs rather than one happy path:

- AX/Cocoa and local/global coordinate conversions round-trip across negative and above-primary
  display origins.
- Valid 0–1000 vision boxes remain inside the selected screen; malformed boxes are rejected.
- The last guide footprint always lands inside the target, including tiny targets and starts already
  inside it.
- Danger remains dominant and restores the suspended ghost state; cancel during danger changes the
  eventual restore state to idle.
- Task routing is total, deterministic, case-insensitive, and priority ordered.
- `Grimoire.matches(a,b)` is symmetric, handles empty token sets, and uses an explicit Jaccard
  threshold.
- Backend parsing returns a typed plan, clarification, or failure for arbitrary bytes and never traps.
- Moon position is bounded across the full day and absent during daytime.

The current suite uses property-oriented XCTest loops and generated-input sweeps rather than an
external Swift PBT dependency. One parser test feeds 256 deterministic arbitrary byte sequences.
Geometry tests cover multiple monitor origins, tiny targets, off-screen points, malformed boxes, and
path combinations.

This approach exposed details that example-only UI tests could miss. During validation:

- a supposed Jaccard “0.8 match” was actually `4/6`, forcing the test and contract to use the real set
  math;
- `e-mail` exposed the exact meaning of punctuation boundaries and complete-token routing;
- Grimoire persistence exposed fractional-second loss in default ISO-8601 date encoding, so storage
  moved to fractional ISO-8601 with normalized precision.

The final suite has 32 passing tests. We describe it as property-oriented coverage, not as thousands
of randomized cases with shrinking, because the latter was not run.

## Kiro Powers and third-party integrations

We did not install or activate a Kiro Power for the submitted build. The project playbook sketches a
reusable `spooky-macos-overlays` Power that would bundle the NSPanel/window-level rules, coordinate
steering, local visual-verification MCP, and build/privacy hooks. That would be valuable for a future
macOS overlay project, but it remains a design rather than a shipped Power.

Likewise, we did not use third-party GitHub, AWS, or documentation MCP integrations. Kiro’s built-in
agent, sub-agent, file, and shell capabilities covered the implementation while the existing backend
contract isolated cloud-provider details from the macOS app.

## Result

Kiro’s strongest contribution was not raw code generation. It was maintaining a chain from product
intent to requirement, design, implementation, and validation:

- one critique before code;
- three traceable feature specs plus global quality gates;
- persistent steering for platform-specific failure modes;
- scoped parallel sub-agent implementation;
- 40 Swift source files;
- 32 passing tests;
- a warning-free clean build;
- an app launched successfully from the Kiro IDE workflow;
- no changes to the existing backend.

That discipline let us build a visually ambitious macOS app without losing the elderly-first UX,
click-through behavior, safety-state precedence, multi-monitor geometry, or privacy boundary that make
Wailo more than a Halloween skin.
