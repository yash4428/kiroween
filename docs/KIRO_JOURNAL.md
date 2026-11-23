# Kiro journal

Appended by the `journal` hook after each agent session. Source material for the write-up.

## 2026-11-21 18:32:10 IST
- Built a nine-commit history separating the spec critique, feature specs, Haunting v2, app layers, tests, and documentation.
- Used Kiro IDE file, shell, and Git tooling to turn the uncommitted build into reviewable evidence.
- Learned that overview links for Haunting v2 had to be staged separately so each historical commit contained only its claimed scope; `swift build` and all 32 tests passed afterward.
## 2026-11-22 11:05:30 IST
- Built the dev-tooling Spec with EARS requirements T1–T9, a trust-boundary design, and requirement-cited tasks for steering, hooks, logging, MCP, agents, CLI, PBT, Power, and CI.
- Used Kiro Specs to define proof requirements before creating developer tooling.
- Learned to distinguish configuration presence from execution evidence; the spec requires an actual hook output, MCP call, report, or test rather than treating a planned file as proof. The app build and all 32 tests passed.
## 2026-11-22 11:09:41 IST
- Built context-sensitive steering: always-on product/structure/privacy, file-matched coordinates/windows/backend/testing/cozy rules, and a manual journal procedure; every original nonblank tech.md line was preserved.
- Used Kiro's documented steering inclusion modes (`always`, `fileMatch`, and `manual`) and printed every resulting front-matter block as evidence.
- Learned that multi-pattern `fileMatchPattern` must be a YAML array, not a comma-separated string. The app build and all 32 tests passed.
## 2026-11-22 11:13:49 IST
- Built a typed, opt-in WAILO_DEBUG logger and instrumented tombstone, pumpkin, lantern, tip, Dock target, ghost-state, and guide-presentation events using only IDs, states, counts, and coordinates.
- Used Kiro's spec task T3 as a privacy boundary: event payloads cannot accept arbitrary UI text, URLs, email, screenshots, or AX values.
- Tests proved the logger is silent when disabled and emits only prefixed typed fields when enabled; `swift build` and all 34 tests passed.
## 2026-11-22 12:41:05 IST
- Built seven current-format Kiro hooks. The build-on-save demonstration inserted an invalid declaration in WailoDebug.swift, surfaced `expected type` / `expected initial value`, repaired only that file, and the next build passed.
- Used the blocking privacy-guard command against the requested unsafe GhostPet payload; it exited 2 with: `PRIVACY-GUARD DENIED — privacy.md: never log screen text, AX values, window titles, URLs, emails, or pixels`. The unsafe source edit is absent.
- Learned that hooks created during a running session report activation on the next session start, so the denial handler was also exercised directly with the same PreToolUse JSON payload. `swift build` and all 34 tests passed.
## 2026-11-23 16:07:17 IST
- Built and registered the Node 20+ wailo-devtools MCP with 11 local tools, then ran all six QA checks and saved real screenshots, logs, timings, and CPU samples in docs/VISUAL_QA.md.
- Used MCP launch, screenshot, Dock AX, log-tail, test-window, synthetic-drag, quit, and CPU tools; Finder QA produced one target presentation, and Cozy idle CPU averaged 0.66% across ten samples.
- Visual QA found and fixed duplicate guide presentation, stale helper compilation, weak delegate lifetime, hover-gated drag timing, and missing Dock-arrival evidence. The final app build and all 34 tests passed; node_modules and dist remain ignored.
