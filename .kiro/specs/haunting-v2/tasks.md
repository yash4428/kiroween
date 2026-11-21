# Implementation plan: Haunting v2

After every numbered task, run `swift build` and `swift test` in `app/`. Never run `xcodebuild` and do
not modify `backend/`.

- [x] 1. Add pure Haunting v2 geometry, physics, shake, and app-tip logic with correctness tests.
  _Req: R16.2, R16.5–R16.6, R17.1–R17.5, R18, R20.1, R21.1–R21.6_
  - [x] 1.1 Implement tombstone placement, title-bar landing, system-owner filtering, menu-bar flush
    and full-screen detection. _Req: R17.1–R17.3, R18_
  - [x] 1.2 Implement throw clamping, bin distance/magnet eligibility, and timestamped shake
    detection. _Req: R16.5, R17.4–R17.5, R20.1_
  - [x] 1.3 Implement deterministic app-tip mapping and cooldown/dwell bookkeeping. _Req: R21.1–R21.8_
  - [x] 1.4 Add property-oriented XCTest loops for all seven requested geometry/detection/mapping
    properties and tip cooldown. _Req: R16.2, R16.5, R17.1–R17.5, R18, R20.1, R21_

- [x] 2. Replace the mascot face and add optional Kiro logo loading. _Req: R15_
  - [x] 2.1 Add safe optional `kiro-logo.png` lookup without `Bundle.module`. _Req: R15.1–R15.2_
  - [x] 2.2 Draw the leaning white purple-glow fallback with tall oval eyes, no mouth, and map every
    semantic state to an eye-only expression. _Req: R15.2–R15.4_

- [x] 3. Enforce shared window eligibility for tracking and slime. _Req: R18_
  - [x] 3.1 Add owner names to tracked windows and exclude Wailo/system-owned windows. _Req: R18.3_
  - [x] 3.2 Remove menu-bar-flush and full-screen windows before slime placement or pumpkin landing.
    _Req: R18.1–R18.4_

- [x] 4. Replace leaves with interactive pumpkin physics and nonactivating hover panels. _Req: R16,
  R18.4_
  - [x] 4.1 Implement spawn, gravity, title-bar attachment, traffic-light clearance, 8-second title
    expiry, 2-second Dock expiry, and fast-window knockoff. _Req: R16.1–R16.4, R16.6, R18.4_
  - [x] 4.2 Implement pumpkin-only hover mouse capture, drag sampling, and clamped throwing without
    activating Wailo. _Req: R16.5_
  - [x] 4.3 Remove all falling-leaf construction and runtime behavior. _Req: R16.7_

- [x] 5. Turn the Trash tombstone into the pumpkin bin. _Req: R17_
  - [x] 5.1 Place the tombstone on the Trash rect, expose its bin rect, and keep a bottom-Dock bin
    below the Dock floor. _Req: R17.1–R17.3_
  - [x] 5.2 Integrate direct burial, near-miss magnet curves, rolling, deduplicated counts, and the
    click-through count label. _Req: R17.4–R17.6_

- [x] 6. Clear intro fog, remove clouds, and implement shake-to-find. _Req: R19–R20_
  - [x] 6.1 Make intro fog self-remove completely by 3 seconds and delete cloud rendering/timers.
    _Req: R19.1–R19.4_
  - [x] 6.2 Add the permission-free shake detector controller, pointer lantern, exact bubble copy,
    guide suppression, 1.8-second cleanup, and Reduce Motion behavior. _Req: R20_

- [x] 7. Add app-aware ambient help. _Req: R21_
  - [x] 7.1 Track frontmost-app dwell and per-bundle 15-minute cooldown while suppressing tips during
    guides and warnings. _Req: R21.1, R21.8_
  - [x] 7.2 Present mapped Finder/browser/Mail/System Settings/generic help through large bubble
    actions and existing routes. _Req: R21.2–R21.7_

- [x] 8. Add haunted Dock targets and patient app waiting. _Req: R22_
  - [x] 8.1 Resolve Dock app frames and draw the icon copy, glow, peeking ghost, and Reduce Motion
    treatment without intercepting clicks. _Req: R22.1–R22.2_
  - [x] 8.2 Integrate marker lifecycle and frontmost-app waiting with guide generations and cleanup.
    _Req: R22.3–R22.5_

- [ ] 9. Run integrated Haunting v2 acceptance and update documentation. _Req: R15–R22_
  - [ ] 9.1 Run a clean build/test and manually check logo fallback, every eye expression, pumpkin
    landing/drag/throw/bin behavior, filtering, fog/cloud removal, shake, tips, and Dock waiting.
    _Req: R15–R22_
  - [x] 9.2 Update README feature descriptions and controls without claiming unverified manual or
    performance results. _Req: R15–R22_
