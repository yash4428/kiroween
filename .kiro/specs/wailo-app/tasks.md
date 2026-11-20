# Implementation plan: Wailo macOS app

Rules for every task:
- Follow `.kiro/steering/*`.
- After each task, run `swift build && swift test` in `app/` and make sure both pass.
- Commit after each numbered top-level task.
- Never run `xcodebuild`.

- [ ] 1. Package skeleton and app shell
  - [ ] 1.1 Create `app/Package.swift`:
    - executable `Wailo` with `resources: [.process("Resources")]`
    - test target `WailoTests`
    - macOS 14
    _Req: R1.1, R14.1_
  - [ ] 1.2 Copy `assets/*.png` into `app/Sources/Wailo/Resources/`. Implement `AssetLoader`:
    - safe bundle lookup (no `Bundle.module`)
    - `Sprite` enum with emoji fallbacks
    - `softCircle` and gradient textures, `node(_:size:)`
    _Req: R13.1_
  - [ ] 1.3 `Settings` (UserDefaults `wailo.*`, `Settings.changed`, derived values), `Palette` and
    `Sfx` (system sounds, gated by Sounds). _Req: R12_
  - [ ] 1.4 `WailoApp` (`@main`, accessory policy), an `AppDelegate` that prompts for AX, and
    `MenuBarController` (🎃 menu, rebuilt in `menuWillOpen`). _Req: R1.1–R1.3_
  - [ ] 1.5 `HotKeys` (Carbon) with every R1.4 binding (stubs are fine for now) and the
    `WAILO_AUTODEMO` env hook. _Req: R1.4, R1.5_

- [ ] 2. Coordinates and overlays
  - [ ] 2.1 `CoordinateSpace` (pure + live) and **unit tests**:
    - a layout of primary + right screen + a screen above, with the primary not first in the list
    - round trips, the above-screen rect, local conversion, nearest screen
    - Vision vs YOLO, bbox1000
    _Req: R2.5, R14.2_
  - [ ] 2.2 `PassThroughWindow`, `WailoLevel`, `EffectsScene` (layers, local helpers, `add`/`wake`,
    auto-pause with a grace period). _Req: R2.2, R2.4_
  - [ ] 2.3 `ScreenOverlay` (ambience/decor/effects windows, SKViews at 20/30/30 fps, and
    `FogSpotlightView` under the effects SKView) and `OverlayWindowManager` (screen-change rebuild).
    _Req: R2.1, R2.3_

- [ ] 3. Haunting transition and ambient decor
  - [ ] 3.1 `NightSkyScene`:
    - flattened static art (gradient, stars, two hills, tombstones, bare trees)
    - twinkle sprites, clock moon (`moonProgress` + test), drifting clouds
    - `fadeIn`, `applyOpacity`, `sunriseAndFade`, `lightning`
    _Req: R3.1.3, R3.2, R3.8_
  - [ ] 3.2 `EdgeFog` (4 edge emitters, removed after the roll-in, and a vignette at the Boo-level
    settle). _Req: R3.1.2_
  - [ ] 3.3 `Cobwebs` (procedural, flattened, 4 corners, grow and shrink). _Req: R3.1.4_
  - [ ] 3.4 `DockLocator` + `TombstoneTrash` (Dock orientation, fallback, `globalTop`, wobble).
    _Req: R3.1.6, R3.3_
  - [ ] 3.5 `BatColony` (hang, timed loop flights, fly away on stop, Reduce Motion). _Req: R3.1.5,
    R3.5_
  - [ ] 3.6 `WindowTracker` (+ `isTopEdgeVisible` test) and `SlimeDrips` (rim, drips, one-at-a-time
    drip timer, follow, splatter, regrow). _Req: R3.1.7, R3.6_
  - [ ] 3.7 `FallingLeaves` (Spooky+, land on window tops, piles, slide off). _Req: R3.7_
  - [ ] 3.8 `HauntingController`:
    - the start timeline and the reverse stop
    - `applySettings` diffing
    - lightning timer, screen-change reinstall
    _Req: R3.1, R3.4, R12.4_
  - [ ] 3.9 Manual check: launch → full intro, then ⌃⌥H twice → sunrise and back. Measure idle CPU
    after 20 s (target < 5%; record the number in README).

- [ ] 4. Ghost pet
  - [ ] 4.1 `GhostState` + `GhostStateMachine` and **unit tests** (happy path, danger override and
    restore, ignored events, cancel from every state). _Req: R4.9_
  - [ ] 4.2 `GhostBodyView` (procedural body, eyes, blush, 6 mouths, puff, frost spikes, glow),
    `CauldronView`, and `GhostView` with a look per state plus animations (bob, blink, yawn, giggle,
    wiggle, shake, rising candles, wisps, cauldron bubbles). _Req: R4.1, R4.7_
  - [ ] 4.3 `GhostPet`:
    - panel (floating before level!) and modes `hidden/parked/anchored/dragging`
    - **no cursor following**
    - drag → park → save position; click → `openPrompt()`
    - hover giggle, mouse pass-through toggling
    - doze and wake, rise and sink
    - searching lantern beam in the effects scene
    _Req: R4.2–R4.6, R4.8_
  - [ ] 4.4 `SpeechBubble`:
    - `say` (normal, warning, seance; buttons; autoHide; centred)
    - `ask` prompt (focused field, Go, ✕, Esc, suggestions)
    - `follow`
    - **measure, then `sizingOptions = []`**
    _Req: R4.10, R5.1, R5.3_
  - [ ] 4.5 Manual check: drag the ghost, relaunch (the position persists); ⌃⌥G through all 12 looks;
    hover; click → prompt.

- [ ] 5. Cursor footprints
  - [ ] 5.1 `FootprintShape` + `CursorFootprints` (24 pt spacing, alternating, rotated, 1.2 s fade,
    none on the ghost). _Req: R10_

- [ ] 6. Guidance
  - [ ] 6.1 `FootprintPath.marks` (pure) and **tests** (the last print is inside the target,
    including tiny targets and starting inside), plus `FootprintTrail`. _Req: R6.3.4, R14.2_
  - [ ] 6.2 `FogSpotlightView`, `SpiderPointer`, `PumpkinRing`, `GhostHand`, `CandleProgress` and
    `Confetti`. _Req: R6.1, R6.3, R6.6_
  - [ ] 6.3 `AX` helpers + `AXFinder` (dock item, menu bar item, open-menu item, element BFS, Safari
    address bar, smart). _Req: R6.2, R6.8, R6.9_
  - [ ] 6.4 `DemoScripts` (New Folder, Safari) and the `TargetQuery`, `AdvanceRule` and `HandAction`
    types. _Req: R6.8, R6.9_
  - [ ] 6.5 `GuidanceDirector`:
    - run, beginStep, search loop with escalation, present
    - click polling, wrong click, Return monitor
    - stepComplete, finish, stop
    - `generation` guard; 60 fps while guiding
    _Req: R6.1–R6.7_
  - [ ] 6.6 Manual check: ⌃⌥D completes Dock → File → New Folder, with the spider on step 1, rings
    after that, and confetti at the end. Wrong-click feedback works.

- [ ] 7. Prompt routing and Live mode
  - [ ] 7.1 `TaskRouter.route` (pure) and **tests**, plus `handle`. _Req: R5.2_
  - [ ] 7.2 `BackendClient` (env base URL, `URLSession.shared`, 90 s timeout, `parse` + **tests**
    with fenced JSON and `clarify`) and `LiveMode.run` (planning → plan → director; clarify bubble;
    friendly fallback to the demo). _Req: R7_
  - [ ] 7.3 Manual check: run `backend/` locally, then click the ghost → "turn on dark mode" → guided
    steps (or the séance when AX can't find them).

- [ ] 8. Séance and Grimoire
  - [ ] 8.1 `Spell` + `Grimoire` (JSON store, learn/forget/markCast/match/locate) and **tests** for
    `matches`. _Req: R8.2–R8.4_
  - [ ] 8.2 `SeanceMode` (planchette, click capture, spell recording, manual séance). Wire it into the
    director (enter on not-found; check spells before AX, with the 📖 flip). _Req: R8.1, R8.2, R8.4,
    R8.6_
  - [ ] 8.3 Parchment `GrimoireWindow` (SwiftUI list, Forget, empty state). _Req: R8.5_
  - [ ] 8.4 Manual check: Safari demo → séance on the address bar → rerun → "I remember this one!".

- [ ] 9. Cursed page warning
  - [ ] 9.1 `isCursed(url:)` + **tests**, `AXFinder.safariURL`, and the watch timer. _Req: R9.2_
  - [ ] 9.2 Frost visuals, danger ghost, centred warning bubble with buttons, close tab via
    AppleScript, dismiss/melt. _Req: R9.1, R9.3, R9.4_

- [ ] 10. Delight and polish
  - [ ] 10.1 `GhostMail` (⌃⌥M). _Req: R11_
  - [ ] 10.2 Boo Level differences and a Reduce Motion pass over every component. _Req: R12_
  - [ ] 10.3 Performance pass: profile with Instruments (Time Profiler) and cut idle CPU below 5%.
    For example, move clouds to Core Animation and only poll at 60 Hz while dragging or guiding.
    _Req: R2.4_
  - [ ] 10.4 Multi-monitor and Spaces pass. _Req: R14.3_
  - [ ] 10.5 README:
    - run steps and permissions (Accessibility goes to Xcode when run from Xcode)
    - hotkeys, features to try
    - asset credits (Noto Emoji CC BY 4.0)
    - how Kiro was used (specs, steering, hooks)

- [ ] 11. (Optional) Vision fallback — the 🔮 really looks
  - [ ] 11.1 A setting, off by default, with an explanation. When on and AX fails:
    - capture the screen (requires Screen Recording)
    - `POST /nova-vision`
    - map the 0–1000 bbox; reject confidence < 0.55
    - present, else go to the séance
    _Req: R13.3_
