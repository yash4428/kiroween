# Implementation plan: Guidance and safety

Complete tasks after required foundation and pet contracts exist. After each implementation task,
run `swift build && swift test` in `app/`. Never run `xcodebuild`, and reuse `backend/` unchanged.

- [ ] 1. Define guide models and built-in demos. _Req: R6.5, R6.8–R6.9, R14.5_
  - [ ] 1.1 Add `GuideStep`, `TargetQuery`, `AdvanceRule`, `HandAction`, and `DemoScript` as
    value types independent of AppKit state. _Req: R6.5, R14.5_
  - [ ] 1.2 Encode the Finder New Folder and Safari Wikipedia scripts with the exact target and
    instruction-only sequence. _Req: R6.8–R6.9_

- [ ] 2. Implement pure footprint paths and guide visuals. _Req: R6.1, R6.3, R6.6–R6.7, R12.2,
  R14.2_
  - [ ] 2.1 Add `FootprintPath.marks` and generated tests for finite output, alternation,
    determinism, tiny targets, starts inside targets, and final-mark containment. _Req: R6.3,
    R14.2_
  - [ ] 2.2 Add finite-lifetime footprint trails, spotlight, spider, pumpkin ring, and ghost hand with
    all geometry/timing bounds and Reduce Motion variants. _Req: R6.3, R12.2_
  - [ ] 2.3 Add candle progress and finite confetti with target/ghost fallback and complete cleanup.
    _Req: R6.1, R6.6–R6.7, R12.2_

- [ ] 3. Implement target services. _Req: R6.2, R6.8–R6.9, R9.2, R14.5_
  - [ ] 3.1 Add safe AX attribute/frame helpers, normalization, on-screen checks, and permission-denied
    empty-result behavior. _Req: R1.2, R6.2, R14.5_
  - [ ] 3.2 Add frontmost app, menu bar, open menu, bounded BFS element, Safari address-field, and
    smart-label searches. _Req: R6.2, R6.8–R6.9, R7.2_
  - [ ] 3.3 Add local Safari URL lookup without logging or network transmission. _Req: R9.2, R13.5_

- [ ] 4. Implement Grimoire matching, location, and persistence. _Req: R8.2–R8.5, R14.2, R14.5_
  - [ ] 4.1 Add versioned `Spell`, normalization, exact/Jaccard matching, bundle filtering, ranking,
    and cast counting. _Req: R8.2, R8.4_
  - [ ] 4.2 Generate arbitrary strings and spell sets to verify matching symmetry, reflexivity policy,
    zero-union handling, threshold, and bundle isolation. _Req: R8.4, R14.2_
  - [ ] 4.3 Add relative/current-window and absolute fallback location with 44×44 visible-frame
    clamping; generate location monotonicity and containment tests. _Req: R8.2, R8.4, R14.2–R14.3_
  - [ ] 4.4 Add atomic application-support persistence, missing-file empty state, corruption
    preservation, learn/forget, and once-per-cast updates. _Req: R8.3–R8.4_
  - [ ] 4.5 Add the parchment Grimoire panel, empty state, metadata, keyboard/VoiceOver operation, and
    Forget confirmation. _Req: R8.5, R12.5_

- [ ] 5. Implement séance teaching. _Req: R6.2, R8.1–R8.2, R8.6, R12.2_
  - [ ] 5.1 Add generation-safe guided séance with pointer/static planchette, rising-edge click capture,
    and ghost/bubble exclusion. _Req: R8.1–R8.2, R12.2_
  - [ ] 5.2 Record scoped app/window data, relative top-left and absolute AX points, reject missing
    bundle identity, and complete the guided step after save. _Req: R8.2–R8.3_
  - [ ] 5.3 Add manual séance label entry and reuse the same recording path without guide completion.
    _Req: R8.6_
  - [ ] 5.4 Wire remembered-target lookup before AX, accepted-location cast counting, book-flip/fade,
    and timeout entry from guidance. _Req: R6.2, R8.1, R8.4_

- [ ] 6. Implement `GuidanceDirector`. _Req: R6, R14.2–R14.5_
  - [ ] 6.1 Add single-generation run/begin/stop lifecycle, planning state, candles, and fake-scheduler
    tests for stale callback isolation. _Req: R6.1, R6.10, R14.2_
  - [ ] 6.2 Add timed Grimoire/AX search, 1.6-second exhaustive-local phase, vision-only
    `searchingHard`, retry, and séance deadline with injected-clock boundary tests. _Req: R6.2,
    R13.3, R14.2_
  - [ ] 6.3 Add target presentation on the containing display, first-target spider selection, later
    rings, live Show target frames outline, instructions, state events, and active-scene frame-rate
    switching. _Req: R6.3, R6.7, R12.4_
  - [ ] 6.4 Add rising-edge target clicks with exact 10 pt slack, ignored UI regions, wrong-click
    recovery, and generated acceptance-equivalence tests. _Req: R6.4, R14.2_
  - [ ] 6.5 Add instruction-only `found`/`waitingForClick` transitions and Return/Next handling in
    full and reduced permission modes. _Req: R1.2, R6.5, R6.6_
  - [ ] 6.6 Add step completion, final candle/confetti/success timing, generation-checked idle return,
    and complete monitor/timer/node cleanup. _Req: R6.6–R6.7, R6.10, R14.4_

- [ ] 7. Implement the existing backend plan client and Live mode. _Req: R7, R13.4–R13.5,
  R14.2, R14.5_
  - [ ] 7.1 Add backend-origin path resolution, the minimal plan request, shared-session execution,
    request timeout, cancellation, and redacted diagnostics. _Req: R7.1, R7.6, R13.4–R13.5_
  - [ ] 7.2 Add pure fenced/partial JSON parsing, clarification, missing-field defaults, generated
    instructions, malformed-step omission, and typed failures. _Req: R7.2–R7.4, R14.2_
  - [ ] 7.3 Fuzz arbitrary bytes and generated partial DTOs to verify parser totality, fence
    invariance, target-label safety, action defaults, and order preservation. _Req: R7.2, R7.5,
    R14.2_
  - [ ] 7.4 Map usable plans through `GuidanceDirector`, show clarification/options, and implement
    bounded friendly handling for transport, timeout, 402, 429, 502, and malformed responses with no
    automatic retry. _Req: R7.3–R7.5_
  - [ ] 7.5 Use a mock URL protocol/request recorder to prove only the configured backend receives
    requests and normal plans omit email, screen context, AX text, and pixels. _Req: R7.1, R7.6,
    R13.4–R13.5, R14.2_

- [ ] 8. Integrate optional vision fallback. _Req: R6.2, R13.3, R13.6, R14.2_
  - [ ] 8.1 After local escalation only, call the foundation consented capture service and
    `/nova-vision` at most once per step; present only confidence-qualified, validated mapped bboxes.
    _Req: R6.2, R13.3_
  - [ ] 8.2 Test disabled, denied, low-confidence, malformed-bbox, success, cancellation, and séance
    fallback paths without retaining screenshot bytes. _Req: R13.3, R13.6, R14.2_

- [ ] 9. Implement cursed-page protection. _Req: R9, R12.2, R12.5, R14.2_
  - [ ] 9.1 Add the pure keyword check and generated tests for arbitrary strings, case invariance, and
    non-keyword negatives. _Req: R9.2, R14.2_
  - [ ] 9.2 Add the frontmost-only two-second watcher, permission/toggle gating, exact-URL
    deduplication, and generated URL-sequence tests. _Req: R1.2, R9.2, R9.5, R14.2_
  - [ ] 9.3 Add per-display frost/tint, centered accessible warning actions, idempotent trigger,
    danger entry, and Reduce Motion behavior. _Req: R9.1, R12.2, R12.5_
  - [ ] 9.4 Add fixed AppleScript close, success dismissal, Automation-denied/manual-close behavior,
    frost cleanup, danger restoration, and reassurance. _Req: R9.3–R9.4_

- [ ] 10. Implement Ghost mail. _Req: R11, R12.2, R13.2_
  - [ ] 10.1 Add the finite curved local flight/fade, pet arrival response, exact letter text, and
    cleanup without a network request. _Req: R11.1–R11.2, R12.2_

- [ ] 11. Wire shell entry points to completed feature actions. _Req: R1.3–R1.5, R5.2, R6,
  R8.5–R8.6, R9, R11_
  - [ ] 11.1 Connect both demo commands, Next, Stop guidance, prompt Live routes, and auto-demo
    dispatch to the single director/Live paths. _Req: R1.3–R1.5, R5.2, R6.8–R6.10, R7.1_
  - [ ] 11.2 Connect Simulate Cursed Page, watcher/hotkey dismissal, manual séance, Grimoire, and
    Ghost mail without duplicate behavior. _Req: R1.3–R1.4, R8.5–R8.6, R9.1, R9.4, R11_

- [ ] 12. Run guidance-and-safety acceptance. _Req: R6–R9, R11, R13.3–R13.6, R14_
  - [ ] 12.1 Run build/tests, then complete both built-in demos on the supported stock macOS setup,
    including wrong click, instruction-only Next, success, stop, and séance fallback. _Req: R6,
    R8.1–R8.2, R14.1–R14.3_
  - [ ] 12.2 Run backend success, fenced/partial plan, clarification, timeout, 402, 429, 502, and
    unreachable fixtures while confirming `backend/` remains unchanged. _Req: R7, R14.1–R14.2_
  - [ ] 12.3 Teach, recall, cast, forget, manually teach, move/resize the app window, and recover from
    a corrupt Grimoire file. _Req: R8.2–R8.6, R14.3_
  - [ ] 12.4 Trigger each warning path, watcher deduplication, trust dismissal, close success, and
    Automation denial using keyboard and VoiceOver. _Req: R9, R12.5_
  - [ ] 12.5 Exercise vision consent/denial/success and inspect requests, logs, memory lifetime, and
    files for the complete privacy boundary. _Req: R13.3–R13.6_
  - [ ] 12.6 Run target guidance and warnings on each display, across Spaces and a full-screen app,
    then record the active/idle CPU protocols and fix only measured regressions. _Req: R6.7, R9.1,
    R14.3–R14.4_
