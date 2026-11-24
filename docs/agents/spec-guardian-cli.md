I'll start with the Git state and the repository layout.
The working tree is clean apart from one untracked file, so I'll review HEAD as a whole. I'll run the tests now and read the key sources while they run.
I'll check the specific acceptance criteria against the code with targeted searches.
# Wailo spec compliance report

## 1. Scope and baseline

- **Baseline:** HEAD `af90936` on a clean working tree. `git status` shows one untracked file, `docs/agents/spec-guardian-cli.md.tmp`. The diff is empty, so I reviewed the whole repository at HEAD against R1–R22 and T1–T9.
- **Depth:** I read these files in full: `HauntingV2Logic`, `GuidanceDirector`, `PumpkinRain`, `EdgeFog`, `HauntedDockTarget`, `RoomReader`, `ShakeToFind` and `TombstoneTrash`. I read parts of `WailoApp`, `HauntingController` and `GhostView`, and searched the rest by pattern. I did not read the Pet, Seance, Grimoire, Backend, Safety, Overlay and Settings sources line by line. They are marked "not verified" below where that matters.
- **Pre-existing versus diff-caused:** with an empty diff, nothing is caused by the current diff. Every finding below is a pre-existing gap at HEAD.
- **Tool use:** I changed no files. I used only Git inspection plus `swift build` and `swift test`.

## 2. Findings, by severity

None of these are blockers. I found no contradicted privacy rule in the files I read.

**F1 (medium). The "Is this page safe?" tip checks Safari only (R21.3, R21.7).**
- `WailoApp.swift:~96–101` calls `checkCurrentPageSafety()`, which reads `finder.safariURL()`.
- The tip is offered for Chrome, Firefox, Edge, Arc, Brave and Opera too. In those browsers the check can't read a URL, so the ghost says "I don't see one of the scam warning signs I know." That reassures the user without checking anything.
- R21.7 says accepting a tip routes through the existing safety path, which is Safari-only (R9.2). The tip's behavior matches that path, but it misleads users of the other browsers.

**F2 (low). Pumpkins vanish instantly instead of fading (R16.3, R16.4).**
- `PumpkinRain.remove(_:animated:)` sets `alphaValue = 0` and calls `orderOut(nil)` in the same turn, so no fade is visible.
- The 8 s and 2 s timings are logged and measured (`docs/VISUAL_QA.md`, 8.068 s and 2.033 s). The "fade" part is not implemented.

**F3 (low). The magnet pulls any falling pumpkin within 90 pt, not only a released near-miss (R17.5).**
- `PumpkinRain.tryBin` switches every `.falling` or `.dockIdle` pumpkin to `.magnetized` when it is within 90 pt.
- The magnet motion is a linear ease toward the bin center, not a curve or roll.
- Burial is counted once per UUID, because `TombstoneTrash.bury` dedupes through the `buriedPumpkins` set. That part of R17.4 and R17.5 holds.

**F4 (low). Full-screen classification uses `visibleFrame` in the pumpkin path (R18.2).**
- `titleBarLandingRegion(window:visibleFrame:)` passes `visibleFrame` as the "display" argument to `isFullScreen`.
- `WindowTracker.swift:82` correctly uses `screen.frame`. R18.2 says "display".
- A maximized, non-full-screen window is already excluded as menu-bar-flush, so the practical impact is small.

**F5 (low). Test coverage gaps for Haunting v2 behavior (R14.2).**
- Pure logic is covered. The 45 tests include the V2 logic tests and the 1,000-case property tests.
- No automated test covers these items (no match for PumpkinRain, HauntedDock, RoomReader, ShakeToFindController or EdgeFog in `app/Tests`):
  - the R19.1 3-second fog removal
  - the R22 Dock marker lifecycle (R22.3–R22.5)
  - R16.6 knock-free above 500 pt/s
  - R20.3 lantern expiry
- `docs/VISUAL_QA.md` records manual evidence for some of these (pumpkin expiry, Dock marker, drag into the bin). That doc is a record of a manual run, not a test I re-ran.

**F6 (info). Stray untracked file.** `docs/agents/spec-guardian-cli.md.tmp` contains agent narration lines, not a report. The main agent should delete it or exclude it, because T6.2 says no fake reports.

**F7 (info, spec tension).**
- Haunting-v2 correctness property 1 says the tombstone has "the same center as the Trash rectangle". R17.3 says it stays "below the Dock-top floor".
- `TombstonePlacement.frame` applies `y = min(y, trash.maxY - height)` for a bottom Dock. The two requirements only agree while the tombstone is no taller than the Trash tile.
- `testTombstoneStaysCenteredOnTrashAndBelowDockFloor` passes. I did not inspect which inputs it uses.

## 3. Requirement-to-code coverage

Status: **Impl** = code found and read. **Partial** = deviates in the way described. **NV** = not verified by me.

| Req | Evidence | Status |
|---|---|---|
| R15.1–R15.3 | `GhostView.swift:215–219` hides the mouth and blush and loads `kiro-logo.png` through `AssetLoader.optionalImage`. Rotation 0.07 rad at `:240`. Eyes are `open/closed/delighted/sad/wide`. | Impl. I did not check that the eyes use only shape, scale, angle and lid position. The `MouthExpression` enum still exists but its layer is hidden. |
| R15.4 | Not read | NV |
| R16.1 | `Settings.swift:34` (`showsPumpkins` is false for Cozy), `HauntingController.swift:377`, spawn below `visibleFrame.maxY − 18` | Impl |
| R16.2 | `PumpkinRain.tryLand`, relative X in `update`, `titleBarLandingRegion` (86 pt exclusion) | Impl |
| R16.3 | 8 s timer in `PumpkinRain.update` | Partial (F2) |
| R16.4 | 2 s `dockIdle` in `tick` | Partial (F2) |
| R16.5 | `PumpkinPanel` is `.nonactivatingPanel`, `ignoresMouseEvents` toggled by hover, throw clamped through `PumpkinPhysics` | Impl |
| R16.6 | `window.velocity > 500` detaches with directional velocity | Impl, untested (F5) |
| R16.7 | No "FallingLeaves" or "leaves" match anywhere in `app/Sources` | Impl |
| R17.1–R17.3 | `TombstoneTrash`, `TombstonePlacement`, fallback frame at `visibleFrame.maxX − 84` | Impl (F7) |
| R17.4–R17.5 | `tryBin`, `bury(pumpkinID:)` | Partial (F3) |
| R17.6 | `countLabel` "🎃 N" in the decor scene (click-through windows) | Impl |
| R18.1–R18.4 | `WindowEligibility`, `WindowTracker.swift:69,82–83` | Impl (F4). The deny-list covers only the six hard-coded owners; "another configured entry" is not configurable. |
| R19.1 | `EdgeFog`: normal path removes the root at 2.35 s + 0.4 s fade = 2.75 s. Reduce Motion path is 2.4 s. | Impl by reading, untested (F5) |
| R19.2, R19.4 | No cloud code or persistent fog found | Impl |
| R19.3 | `CursedPageWarning.swift:75–80` creates `coldMist` nodes. I did not confirm removal on dismiss. | Impl for creation, NV for removal |
| R20.1 | `ShakeDetector` (4 reversals, 18 pt, 140 pt, 0.65 s, 1.8 s cooldown) | Impl, tested |
| R20.2–R20.5 | `ShakeToFindController`: exact bubble text, 1.8 s fade, suppressed while `isGuideActive`, no pulse under Reduce Motion | Impl |
| R21.1, R21.8 | `RoomReader`, `TipOfferTracker` (6 s dwell, 900 s cooldown per bundle, suppressed during guide or warning) | Impl, tested |
| R21.2–R21.6 | `showRoomTip` | Impl, with F1 for browsers |
| R22.1–R22.2 | `HauntedDockTarget` (glow, icon copy, wobble or fade, peeking ghost) | Impl. The peeking ghost is a small shape, not a polished sprite. |
| R22.3–R22.5 | `GuidanceDirector.searchTick` resets `searchStarted` while the hinted app isn't frontmost, then removes the marker. `invalidateStepWork` removes it. | Impl, untested (F5) |
| R6.1–R6.7, R6.10 | `GuidanceDirector`: first lookup at 0.8 s, 0.25 s retry, vision at ≥ 1.6 s, séance at ≥ 3.6 s, ±10 pt click rule, wrong-click text, 3.5 s success cleanup, generation guards | Impl |
| R6.8–R6.9 | Not read (`DemoScripts`) | NV |
| R7, R8, R9, R11 | `BackendClient`, `Grimoire`, `CursedURL` and `GhostMail` exist. Parser, Grimoire and URL tests pass. | NV for UI behavior |
| R4, R5 | `GhostState`, `TaskRouter`, `GhostPet`, `SpeechBubble` exist. State machine and router tests pass. | NV for panel behavior |
| R1–R3, R10, R12, R13 | Source files exist. Coordinates, settings, moon and footprint logic have tests. | NV for window levels, hotkeys and vision consent |
| R14.1–R14.2, R14.5 | Build and tests pass (section 4). Tests exist for each listed item. | Impl |
| R14.3–R14.4 | `docs/VISUAL_QA.md` records a one-display run and an idle CPU mean of 0.66%. The R14.3 multi-display matrix is not evidenced there. | Partial |
| T1–T9 | `.github/workflows/ci.yml` exists. Hooks, agents, MCP, Power and journal files not read. | NV |

## 4. Test evidence

- **Build:** `cd app && swift build` finished with "Build complete!".
- **Tests:** `cd app && swift test` ran 45 tests with 0 failures. This includes `HauntingV2LogicTests` (8 tests), `WailoDebugTests` (3 tests) and the 1,000-case `CrossFeaturePropertyTests`.
- **Swift Testing:** the Swift Testing runner reported 0 tests, which is expected.
- **Not run:** `xcodebuild`, which is forbidden. I did not run the MCP server, the Node tests or CI.

## 5. Unresolved or blocked checks

I cannot do these from this session. They are manual or require permissions:

- **R14.3 multi-display matrix:** displays above and right of the primary, display hot-plug, Space switch and full-screen app.
- **R14.4:** a 30-second median CPU benchmark with hardware and build configuration recorded. `docs/VISUAL_QA.md` has a 10-sample mean from a debug-style run, which doesn't match the R14.4 protocol.
- **Permission paths:** Accessibility denied mode, Screen Recording and vision consent, Safari Automation for "Close this page".
- **R15.1 and R15.2:** I could not render the logo-present and logo-absent mascots. `Resources/kiro-logo.png` is not in the resources listing, so the procedural fallback is the one in use.
- **Visual behavior:** Reduce Motion alternatives, spider, ring and footprint visuals, and Haunted-level lightning.
- **R6.8–R6.9 demo scripts, R7 backend flows:** needs a running backend. I did not start one, and `backend/` is read-only.
- **CI:** remote GitHub Actions status is unknown. I observed only the local build and test result.
- **Dev-tooling spec (T1–T9):** the requirements were provided, but the design file was not loaded for this review, and I did not inspect hooks, agents or the Power.I didn't append to `docs/KIRO_JOURNAL.md`. This review role is read-only, and the only way for me to write a file is through the shell, which I'm not allowed to use for that. The main agent can append the entry. Here are the three bullets, limited to what I observed:

- **Built:** I produced a read-only spec-compliance report for HEAD `af90936` (clean working tree). It covers R1–R22 and traces the Haunting v2 requirements to code, with six findings.
- **Kiro capability run:** I ran this delegated review agent with read, search and code-intelligence tools plus shell. The shell ran `git status`, `swift build` and `swift test`. The build succeeded and 45 tests passed with 0 failures. I did not observe any hook, MCP server, CLI review or Power execution.
- **Problem or lesson:**
  - The "Is this page safe?" tip for non-Safari browsers uses the Safari-only URL check, so it can reassure a user without checking anything. That is F1 in the report.
  - The stray `docs/agents/spec-guardian-cli.md.tmp` contains agent narration, not a report. It should be deleted or excluded.
  - The R14.3 multi-display matrix and the R14.4 CPU protocol are still not evidenced.

Suggested heading: `## <local date time>`.
