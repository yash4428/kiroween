# Implementation plan: Haunting foundation

Complete tasks in order. After each implementation task, run `swift build && swift test` in `app/`.
Never run `xcodebuild`, and do not modify `backend/`.

- [ ] 1. Create the Swift package and app lifecycle. _Req: R1.1–R1.2, R13.1, R14.1_
  - [ ] 1.1 Add the macOS 14 Swift 5.9 executable and test targets, processed resources, accessory
    app entry, and AppDelegate. _Req: R1.1, R13.1, R14.1_
  - [ ] 1.2 Add one-time Accessibility trust prompting and the explicit reduced-mode capability
    state. Test granted and denied capability decisions without invoking the system prompt in unit
    tests. _Req: R1.2, R14.2_
  - [ ] 1.3 Add the menu command surface and Carbon hotkey registrations through feature-action
    protocols. _Req: R1.3–R1.4_
  - [ ] 1.4 Add launch haunting and the recognized auto-demo scheduler with fake-clock tests for the
    4.0–5.0 second window and ignored values. _Req: R1.5–R1.6, R14.2_

- [ ] 2. Implement settings, shared accessibility styles, and sound gating. _Req: R12, R14.2_
  - [ ] 2.1 Persist every declared default under `wailo.*`, publish one change notification per
    actual update, and add round-trip/default property tests. _Req: R12.1, R12.4, R14.2_
  - [ ] 2.2 Implement Boo Level derived values, explicit Bats/Slime cleanup, and the persisted Show
    target frames signal without transition replay. _Req: R3.5–R3.8, R12.1, R12.4_
  - [ ] 2.3 Add Reduce Motion alternatives and approved system-sound gating to shared effect helpers.
    _Req: R12.2–R12.3_
  - [ ] 2.4 Add shared custom-control typography, hit-target, keyboard, VoiceOver, and contrast styles.
    _Req: R12.5_

- [ ] 3. Implement pure coordinates and property tests. _Req: R2.5, R13.3, R14.2, R14.5_
  - [ ] 3.1 Implement point and rectangle AX↔Cocoa and global↔local conversions with generated
    round-trip tests over primary, right-side, and above-primary layouts. _Req: R2.5, R14.2_
  - [ ] 3.2 Implement containing/nearest screen selection and totality/minimum-distance property
    tests. _Req: R2.5, R14.2_
  - [ ] 3.3 Implement validated 0–1000 backend bbox mapping and properties that accepted rectangles
    stay on their selected screen while malformed bboxes are rejected. _Req: R13.3, R14.2_

- [ ] 4. Build per-screen overlays and pausable scenes. _Req: R2, R14.3_
  - [ ] 4.1 Add pass-through ambience, decor, and effects windows with the required levels,
    collection behavior, and non-key behavior. _Req: R2.1–R2.2_
  - [ ] 4.2 Add local-coordinate scene layers, wake/grace-pause behavior, emitter cleanup support, and
    20/30/60 fps switching tests where pure scheduling can be isolated. _Req: R2.4, R2.6, R14.5_
  - [ ] 4.3 Build `OverlayWindowManager` and restore semantic visual state after display changes
    without replaying the intro. _Req: R2.3, R1.6, R14.3_
  - [ ] 4.4 Manually verify click-through, window order, Spaces/full-screen presence, and the complete
    display reconfiguration matrix. _Req: R2.1–R2.3, R14.3_

- [ ] 5. Implement the night sky, transition, and static decor. _Req: R3.1–R3.5, R3.8–R3.9_
  - [ ] 5.1 Build the flattened night scene, twinkles, clouds, sunrise fade, and bounded clock moon;
    add generated tests across every time of day and midnight. _Req: R3.1.3, R3.2, R3.4, R3.9,
    R14.2_
  - [ ] 5.2 Build finite edge fog, vignette, and four flattened cobwebs below the menu bar. _Req:
    R3.1.1–R3.1.4, R12.2_
  - [ ] 5.3 Build Dock Trash discovery and the orientation-aware tombstone with primary visible-frame
    fallback. _Req: R3.1.6, R3.3_
  - [ ] 5.4 Build the hanging bat colony with 45–75 second Cozy and 20–40 second Spooky/Haunted
    finite flights, live-toggle cleanup, and Reduce Motion behavior. _Req: R3.1.5, R3.5,
    R12.1–R12.2, R12.4_

- [ ] 6. Implement tracked window decorations. _Req: R3.1.7, R3.6–R3.7, R14.5_
  - [ ] 6.1 Add subscriber-driven window tracking, pure top-edge visibility, front ordering, and
    velocity calculations with generated geometry tests. _Req: R3.6, R14.2, R14.5_
  - [ ] 6.2 Add slime rims, stretch/drop/retract with the one-active-drip invariant,
    follow/splatter/cooldown/regrow behavior, per-Boo-Level limits, and live-toggle cleanup. _Req:
    R3.1.7, R3.6, R12.1, R12.4_
  - [ ] 6.3 Add Spooky/Haunted falling leaves, capped window piles, and movement/disappearance
    cleanup. _Req: R3.7, R12.1–R12.2_

- [ ] 7. Orchestrate haunting. _Req: R1.6, R2.3, R3.1–R3.8, R12.4_
  - [ ] 7.1 Implement generation-safe start/stop phases and the ordered timeline, with fake-scheduler
    tests for order and stale-callback cancellation. _Req: R3.1, R3.4, R14.2_
  - [ ] 7.2 Wire live settings, screen-state reinstall, lightning interval generation, and cleanup of
    timers/actions/emitters. _Req: R2.3–R2.4, R3.5–R3.8, R12.4_
  - [ ] 7.3 Manually verify launch intro, repeated toggle, sunrise stop, no wallpaper mutation, and
    no transition replay after a display change. _Req: R1.6, R2.3, R3.1–R3.4_

- [ ] 8. Implement ambient cursor footprints. _Req: R10, R12.2, R14.2_
  - [ ] 8.1 Add accumulated-distance spacing, alternating shapes, direction, fade cleanup, and ghost
    exclusion through a hit-test protocol. _Req: R10.1–R10.2_
  - [ ] 8.2 Add generated path tests for alternation, finite angles, permission-free operation, and
    proof that every emitted mark stays outside the ghost region even when a path crosses it. _Req:
    R10.2–R10.3, R14.2_

- [ ] 9. Implement assets and privacy controls. _Req: R13, R14.2_
  - [ ] 9.1 Add safe resource-bundle discovery, `Sprite` metadata, emoji rendering, and tests that
    missing bundles and PNGs yield nonblank fallbacks. _Req: R13.1–R13.2_
  - [ ] 9.2 Add vision consent/settings flow, request-scoped in-memory capture, Screen Recording
    capability checks, confidence/bbox rejection, and cancellation cleanup. _Req: R13.3, R13.6_
  - [ ] 9.3 Add backend-origin enforcement and shared redacted logging, with tests that reject other
    origins and never log request bodies. _Req: R13.5, R14.2_
  - [ ] 9.4 Audit every bundled third-party asset against `assets/ASSETS.md` and confirm that Wailo
    contains no downloaded audio, logo, or copyrighted character. _Req: R13.1–R13.2_

- [ ] 10. Run foundation acceptance. _Req: R2.4, R12.2, R12.5, R13, R14_
  - [ ] 10.1 Run build/tests and the R14 display/Spaces matrix. _Req: R14.1–R14.3_
  - [ ] 10.2 Run the CPU protocol after effects settle and record the median plus environment; if it
    misses 5%, profile only the active foundation components and fix the measured cause. _Req: R2.4,
    R14.4_
  - [ ] 10.3 Check Accessibility denied mode, Reduce Motion, keyboard/VoiceOver labels, control sizes,
    text contrast, and missing-asset fallback manually. _Req: R1.2, R12.2, R12.5, R13.1_
  - [ ] 10.4 Inspect network destinations, request bodies, logs, and temporary files during normal
    and consented-vision flows. _Req: R13.3–R13.6_
