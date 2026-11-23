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
## 2026-11-23 16:21:35 IST
- Hardened privacy-guard property-access detection and added 18 table-driven allow/deny cases, including the exact `NSLog("%@", window.title)` regression.
- Used the blocking hook's standalone JSON harness to verify exit 2 for `.title`, AX title/value APIs, AXValue, localizedName, URL and email values while preserving six safe edits.
- The first run found two missed identifier forms, `AXValueGetValue` and `currentURL`; generalized patterns fixed both. The matrix, `swift build`, and all 34 app tests then passed.
## 2026-11-23 17:15:03 IST
- Built five V3 workspace custom-agent profiles with least-privilege tools/permissions, saved IDE fallback reports, and created a help-verified Kiro CLI review script without running it.
- Used Kiro's custom-agent creator and two isolated IDE sub-agents for spec and privacy reviews; `kiro-cli agent list` recognized every profile as V3 format.
- The live IDE registry could not hot-load the new names, so the reports disclose the fallback. Reviews found backend-write, AX-cap, backend-origin, logger-proof, and stale-step risks; these were fixed before `swift build` and all 35 tests passed.
## 2026-11-23 17:28:37 IST
- Built a stable seeded generator and ten 1,000-case cross-feature properties covering coordinates, bboxes, footprints, ghost safety, routing, matching, parsing, URL detection, Haunting v2 geometry, throw/bin physics, shake detection, and tip cooldown.
- Used correctness properties from all four feature Specs as executable PBT inputs; every failure message carries seed, case index, and generated values.
- Seed 6287387146879770662 exposed 149 exact-equality failures from sub-ULP local/global floating arithmetic, not a conversion defect. The property now uses 1e-7 tolerance and a named large-negative-origin regression; `swift build` and all 45 tests passed.
## 2026-11-23 17:32:31 IST
- Packaged the current Agent Plugin form of spooky-macos-overlays with plugin metadata, reusable skill, generalized references, configurable MCP, legacy POWER.md compatibility, reviewed hook templates, and local installation instructions; added macOS 14 CI.
- Used official Kiro Power/Agent Plugin guidance and `kiro-cli powers --help`; every JSON artifact parsed successfully and installation remains a user-controlled UI/CLI action.
- Learned that current Powers port instructions through skills and MCP, while hooks/steering are not documented portable components, so those directories are explicitly labeled templates. `swift build` and all 45 tests passed locally; remote CI status is not claimed yet.
## 2026-11-23 17:44:53 IST
- Vibe-coded Ghost Mail v2 without a spec from 17:33:02 to 17:41:25 IST: the courier waves, then the existing local letter appears with a typewriter effect.
- Used a controlled comparison against spec-first R20 and recorded real timing, commits, files, test counts, privacy, and Reduce Motion behavior in docs/VIBE_VS_SPEC.md.
- The first passing build missed final-text layout reservation and Reduce Motion for typewriter motion; both required rework. No dedicated Ghost Mail v2 test was added, while R20 has fixed and 1,000-case tests. Final `swift build` and all 45 tests passed.
