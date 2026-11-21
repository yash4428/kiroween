# Implementation plan: Ghost pet

Complete tasks after the foundation contracts they use exist. After each implementation task, run
`swift build && swift test` in `app/`. Never run `xcodebuild`, and do not modify `backend/`.

- [ ] 1. Implement the pure ghost state machine and property tests. _Req: R4.7–R4.9, R14.2, R14.5_
  - [ ] 1.1 Add the finite state/event types, normal transition table, unsupported-event identity,
    and deterministic sequence tests. _Req: R4.7, R4.9, R14.2_
  - [ ] 1.2 Add danger precedence, repeated-danger behavior, restore, and danger-aware cancellation;
    generate arbitrary sequences to verify the invariants. _Req: R4.9, R14.2_
  - [ ] 1.3 Add sleep/activity transitions with injected time and tests for daytime/nighttime
    thresholds. _Req: R4.8–R4.9, R14.2_

- [ ] 2. Build the ghost panel, body, and state appearances. _Req: R4.1–R4.2, R4.6–R4.7, R12.2_
  - [ ] 2.1 Add the procedural body path, body-path hit testing, expressions, glow, puff, frost, and
    accessible semantic description. _Req: R4.1, R4.6–R4.7, R12.5_
  - [ ] 2.2 Add the nonactivating panel with body-only event capture and click-through transparent
    pixels. _Req: R4.6_
  - [ ] 2.3 Add every semantic accessory/effect and ensure state entry removes prior-state effects;
    distinguish careful local search from an active consented vision request. _Req: R4.7, R13.3_
  - [ ] 2.4 Add blink/yawn/bob/giggle timing with injected clock/random sources and fade/static
    alternatives under Reduce Motion. _Req: R4.1, R4.5, R12.2_
  - [ ] 2.5 Wire Ask Wailo and debug Cycle ghost state actions from the shell protocol, keeping debug
    cycling separate from production state-machine transitions. _Req: R1.3–R1.4, R4.7, R5.1_

- [ ] 3. Implement stationary movement, dragging, persistence, and sleeping. _Req: R4.2–R4.5,
  R4.8, R14.2–R14.3_
  - [ ] 3.1 Add `hidden`, `parked`, rise/sink-only `anchored`, and `dragging` modes with no cursor-follow
    mode. _Req: R4.2–R4.3_
  - [ ] 3.2 Add offset-preserving drag, the 4 pt click threshold, visible-frame clamp, display-aware
    persistence, and generated clamp/idempotence tests. _Req: R4.3–R4.4, R14.2_
  - [ ] 3.3 Add display-change reachability, slow parked polling, temporary active polling, doze/wake,
    and edge-triggered hover response. _Req: R4.3, R4.5, R4.8, R14.3–R14.4_

- [ ] 4. Implement speech bubbles and the prompt. _Req: R4.10, R5.1, R5.3–R5.4, R12.5_
  - [ ] 4.1 Add measured-before-fixed hosting, adjacent/centered placement, complete visible-frame
    clamping, passive click-through, action hit testing, wrapping, and large high-contrast text.
    _Req: R4.10, R12.5_
  - [ ] 4.2 Add the nonactivating key prompt with focused field, suggestions, Go/close controls,
    Return/Escape behavior, `startListening`/cancel events, single-emission guard, and previous-app
    restoration. _Req: R5.1, R5.3–R5.4, R12.5_
  - [ ] 4.3 Add keyboard and VoiceOver tests where automatable and a manual edge-placement matrix on
    every display. _Req: R4.10, R5.1, R12.5, R14.3_

- [ ] 5. Implement pure task routing and property tests. _Req: R5.2, R5.4, R14.2, R14.5_
  - [ ] 5.1 Add Unicode-aware normalization, complete-token matching, ordered route groups, trimmed
    Live payload, and whitespace `nothing`. _Req: R5.2_
  - [ ] 5.2 Generate arbitrary Unicode, casing, punctuation, and multi-keyword inputs to verify
    totality, uniqueness, normalization invariance, priority, and no crash. _Req: R5.2, R14.2_
  - [ ] 5.3 Wire prompt and suggestions through one route-to-action adapter without duplicate text
    matching. _Req: R5.2, R5.4_

- [ ] 6. Run ghost-pet acceptance. _Req: R4–R5, R12.2, R12.5, R14_
  - [ ] 6.1 Run build/tests, then manually cycle all states and inspect cleanup plus Reduce Motion
    alternatives. _Req: R4.7–R4.9, R12.2, R14.1–R14.2_
  - [ ] 6.2 Drag, click, hover, sleep/wake, relaunch, remove the saved display, and verify the pet
    remains stationary, reachable, and body-only interactive. _Req: R4.2–R4.6, R4.8, R14.3_
  - [ ] 6.3 Exercise prompt submit/cancel/suggestions using keyboard and VoiceOver, including
    whitespace and competing route terms. _Req: R5, R12.5_
  - [ ] 6.4 Measure parked idle polling as part of the R14 CPU protocol and correct only measured pet
    regressions. _Req: R4.2, R14.4_
