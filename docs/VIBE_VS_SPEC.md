# Vibe coding versus spec-first: a controlled Wailo comparison

## Method and limits

The vibe experiment deliberately added no requirement or design artifact before code. The prompt was:

> Ghost Mail v2: the courier ghost waves before leaving, and the letter text appears with a
> typewriter effect.

Start: **2026-11-23 17:33:02 IST**  
Final validated end: **2026-11-23 17:41:25 IST**  
Elapsed wall time: **8 minutes 23 seconds**

The spec-first comparison is R20, shake-to-find. Its spec was committed at `de6fa77` and implementation
landed inside the larger haunting-foundation commit `2365bbb`. Because that commit contains many
features and the journal did not record an R20-only start/end, an honest R20 development duration
cannot be calculated. This document therefore compares process and observable rework, not invented
speed numbers.

## Results

| Dimension | Ghost Mail v2, vibe coded | R20 shake-to-find, spec first |
|---|---|---|
| Up-front contract | One sentence; no acceptance criteria | Five EARS criteria plus shake correctness property in `.kiro/specs/haunting-v2/requirements.md` |
| Files changed | `GhostMail.swift`, `GhostPet.swift`, `SpeechBubble.swift` | Pure detector in `HauntingV2Logic.swift`, controller in `ShakeToFind.swift`, App wiring, unit/PBT files |
| First implementation | Courier follows its existing curve, runs a three-wave rotation, then opens a typewriter bubble | Explicit reversal, displacement, travel, timing, guide-suppression, 1.8 s cleanup and Reduce Motion behavior |
| Bugs/rework after “done” | Two issues found after the first passing build: the initial blank typewriter content under-measured `NSHostingView` and could clip the final letter; typewriter motion still ran under Reduce Motion | No shake counterexample or post-done shake correction was observed in the recorded unit/PBT runs |
| Fixes | Invisible full text now reserves final wrapped size before `sizingOptions = []`; Reduce Motion shows the complete letter immediately and skips the wave | The implementation already separated pure detection from visual response and had a static/fade Reduce Motion path because the criteria required it |
| Dedicated automated coverage | **0 new dedicated tests**; the unchanged 45-test suite proves compilation/regression only | One named fixed-example test plus 1,000 seeded monotone/slow/valid shake timelines in `CrossFeaturePropertyTests` |
| Privacy | No network or personal-data source was added; text remains the existing static demo letter | No network; reads only pointer coordinates through `NSEvent.mouseLocation` |
| Validation | Three build/test passes while rework was discovered; final result: 45 tests, 0 failures | Original unit suite plus later seeded PBT; current result: 45 tests, 0 failures |

## What the experiment showed

The vibe-coded change reached a compiling visual result quickly, but “waves” and “typewriter effect”
did not say how layout measurement or Reduce Motion should work. Both omissions survived the first
successful build. The first issue was especially specific to Wailo's known AppKit/SwiftUI gotcha:
`NSHostingView.fittingSize` must be measured before automatic sizing is disabled. Measuring while only
one blank character existed reserved too little height for the finished letter.

R20's spec made equivalent edge behavior part of the design before implementation. It defined the
minimum movement, reversal count, total travel, time window, guide suppression, effect lifetime and
Reduce Motion result. That enabled a pure `ShakeDetector` and repeatable generated tests. The
1,000-case harness explicitly proves that monotone and slow paths do not trigger, while valid reversal
paths do.

The comparison does not show that every small feature needs a long spec. It shows that a one-sentence
visual request leaves cross-cutting obligations implicit. For Wailo, the most valuable spec content is
not prose volume; it is the boundary cases that change architecture: pure detection, interruption
rules, accessibility, cleanup, privacy, and testable thresholds.

## Evidence

- Vibe implementation diff: commit created by Phase 9
- R20 spec: `.kiro/specs/haunting-v2/requirements.md`
- R20 implementation: `app/Sources/Wailo/Cursor/ShakeToFind.swift` and
  `app/Sources/Wailo/Haunting/HauntingV2Logic.swift`
- R20 fixed test: `app/Tests/WailoTests/HauntingV2LogicTests.swift`
- R20 generated test: `app/Tests/WailoTests/Properties/CrossFeaturePropertyTests.swift`
- Build/test result at experiment end: **45 tests, 0 failures**
