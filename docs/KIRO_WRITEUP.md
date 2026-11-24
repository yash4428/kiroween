# How we used Kiro to build Wailo

## Kiro IDE was the project’s control room

We built Wailo in Kiro IDE. The IDE was the control room for spec critique, EARS requirements,
designs, implementation, hook and MCP setup, custom-agent delegation, test execution, visual QA, Git
commits, pushes, and the final write-up. Kiro could move from a requirement to its design, Swift file,
test, runtime log, and screenshot without dropping the reason for the change.

The IDE agent read steering and Specs before editing, delegated independent modules with non-overlapping
ownership, fixed compiler/PBT failures, and ran local MCP visual checks. We also used **Kiro CLI 3.5.0**
for authoritative `--help`, Power commands, and `agent list`; it recognized all five workspace profiles
as V3 format. We intentionally did not run the CLI review gate because that is a hand-off step for the
project owner. Kiro Web and Crew remain manual/optional follow-ups, so no PR or Crew result is claimed.

## Focused sub-agents accelerated the build

The first build used isolated Kiro sub-agents for pure logic/tests, the haunting foundation, and the
ghost UI. Exact file ownership prevented collisions and kept `backend/` untouched.

We then created persistent V3 custom profiles under `.kiro/agents/`:

- `spec-guardian`: read-only traceability plus narrowly allowed `swift test`;
- `privacy-warden`: read-only data-flow audit;
- `visual-qa`: read plus only the workspace wailo-devtools MCP;
- `perf-ghost`: read-only process inspection plus `cpu_sample`;
- `haunt-designer`: writes only four visual source subtrees and can delegate only to `visual-qa`.

`kiro-cli agent list` verified their current format. The already-running IDE registry could not hot-load
the new names, so we did not pretend otherwise: two isolated IDE sub-agents were given the exact
persisted profiles as a documented fallback. Their reports in `docs/agents/` found real defects in the
backend write guard, AX node cap, backend-health origin check, logger proof, and stale guide-step
callbacks. We fixed those findings before the phase commit. A fresh session can invoke the named
profiles directly.

## Agent hooks automated build, test, privacy, licensing, traceability, journal, and Cozy checks

Seven current-format hooks live in `.kiro/hooks/`: build on Swift save, tests on logic/test save, a
blocking privacy guard, asset license audit, spec synchronization, factual journal append, and Cozy UI
review.

We exercised the workflows instead of treating configuration files as proof. A deliberate invalid
Swift declaration produced `expected type` and `expected initial value`; only the changed file was
repaired and the next build passed. The privacy command rejected the requested unsafe payload with
exit 2 and the exact `PRIVACY-GUARD DENIED` reason. We later discovered that a syntactically different
leak, `NSLog("%@", window.title)`, escaped the first phrase-based detector. That became T2.8 and an
18-case, then 19-case, allow/deny regression harness. The current guard detects `.title`, AX title/value
APIs, `AXValue`, `localizedName`, URL/email values, external hosts, secrets, pixel persistence,
`NSApp.hide`, and every direct write destination under `backend/`.

The journal records one limitation: hooks created mid-session activate at the next session start, so
the blocking command was also exercised directly with the same PreToolUse JSON payload. This keeps
the evidence precise rather than conflating a handler test with an IDE event.

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

We also ran a measured vibe-versus-spec experiment. Ghost Mail v2 took 8 minutes 23 seconds and
passed its first build, but then needed two corrections: reserving final typewriter layout before
`NSHostingView` sizing was frozen, and suppressing typewriter/wave motion under Reduce Motion. R20's
spec-first shake detector had explicit thresholds, cleanup and suppression rules plus fixed and 1,000-case
tests. `docs/VIBE_VS_SPEC.md` records the real timing and limitations.

## Steering turned prototype lessons into permanent guardrails

The four workspace steering documents had distinct jobs:

- `.kiro/steering/product.md` defined the elderly-first product, cozy-spooky tone, functional use of
  every effect, stationary pet behavior, and non-goals.
- `.kiro/steering/coordinates.md`, `windows-and-perf.md`, `privacy.md`, and `testing.md` preserve the
  technical rules with file-matched or always-on inclusion.
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

## MCP closed the visual verification loop

We built `tools/wailo-devtools-mcp`, a Node 20+ stdio server using the official MCP TypeScript SDK. It
is registered in `.kiro/settings/mcp.json`; `npm run smoke` connected through an official MCP client
and listed eleven tools.

The MCP launched and quit Wailo, captured local `/tmp` screenshots, read bounded AX/Dock geometry,
created and moved a safe helper window, tailed typed debug events, performed explicitly gated synthetic
drags, sampled CPU, read the local Grimoire, and checked backend health. `docs/VISUAL_QA.md` records six
real checks and paths. Evidence includes exact Trash/tombstone coordinate overlap, title-bar pumpkin
movement, a synthetic burial count changing 1→2, measured expiry intervals of 8.068 s and 2.032–2.033
s, one Finder guide target after a race fix, and ten Cozy idle CPU samples averaging 0.66%.

MCP QA found issues source review missed: stale helper compilation, weak delegate lifetime, hover-gated
input timing, missing Dock-arrival evidence, and duplicate guide presentation. Runtime artifacts stay
under `/tmp/wailo-devtools/`; `node_modules/` and `dist/` are ignored. A privacy-agent review then
restricted backend health to the configured origin and capped AX recursion correctly.

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

The current suite includes a stable seeded generator and nine 1,000-case XCTest properties. Failure
messages print seed, case index, and generated values. The generated coverage spans negative/above-primary
layouts, tiny targets, arbitrary event and byte sequences, string normalization, bbox validation,
Haunting v2 geometry, physics, shake paths, and tip timelines.

This approach exposed details that example-only UI tests could miss. During validation:

- a supposed Jaccard “0.8 match” was actually `4/6`, forcing the test and contract to use the real set
  math;
- `e-mail` exposed the exact meaning of punctuation boundaries and complete-token routing;
- Grimoire persistence exposed fractional-second loss in default ISO-8601 date encoding, so storage
  moved to fractional ISO-8601 with normalized precision.

The final suite has 45 passing tests, including 9,000 deterministic generated cases. It does not claim
a general shrinking engine; the retained named floating-point regression is the minimal observed
counterexample.

## Kiro Powers and CI

We packaged `powers/spooky-macos-overlays` in the current Agent Plugin format with `plugin.json`, a
reusable overlay-engineering skill, generalized coordinate/window references, configurable MCP, and a
legacy `POWER.md` compatibility entry. Kiro's current docs do not define hooks or steering as portable
Power components, so those folders are honestly labeled templates rather than auto-installed features.
The Power is ready for the owner to import from the local path and capture activation evidence.

No third-party MCP was needed. GitHub is used as the remote and every tooling phase was pushed. The
macOS 14 workflow in `.github/workflows/ci.yml` runs the same `swift build` and `swift test` commands;
remote Actions status remains separate from the locally observed pass.

## Result

Kiro’s strongest contribution was not raw code generation. It was maintaining a chain from product
intent to requirement, design, implementation, and validation:

- one critique before code;
- three traceable feature specs plus global quality gates;
- persistent steering for platform-specific failure modes;
- scoped parallel sub-agent implementation;
- 41 Swift source files;
- 45 passing tests, including 9,000 seeded generated cases;
- a warning-free clean build;
- an app launched successfully from the Kiro IDE workflow;
- no changes to the existing backend.

That discipline let us build a visually ambitious macOS app without losing the elderly-first UX,
click-through behavior, safety-state precedence, multi-monitor geometry, or privacy boundary that make
Wailo more than a Halloween skin.
