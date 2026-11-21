# Spec critique and proposed resolutions

This review covers the original `wailo-app` requirements, design, and implementation plan before the
feature split. The split specs apply the resolutions below. No app or backend code is changed by this
work.

## Scope and traceability gaps

| Finding | Why it matters | Resolution in the split specs |
|---|---|---|
| R14 was omitted from the requested feature allocation. | Dropping it would lose the build, test, performance, and multi-monitor gates. Assigning it to one feature would make cross-feature checks misleading. | Keep R14 in the `wailo-app` overview as a global quality requirement. Every feature task cites R14 when it implements or verifies a global gate. |
| The original tasks assume haunting starts on launch, but no requirement says so. | Task 3.9 expects “launch → full intro,” while R3 only defines what happens when haunting starts. | Add R1.6: start haunting after launch setup, unless a deliberate future launch preference disables it. |
| “Keep working, with reduced features” in R1.2 does not identify those features. | Permission-denied behavior cannot be accepted or tested. | Define the degraded mode: ambience, pet, prompt, instruction-only guidance, and backend planning remain available; AX target search, Return observation, Safari watching, and Dock discovery are unavailable and lead to an explanation or séance/fallback. |
| Settings defaults are incomplete. | Only Cozy, sounds, and vision have stated defaults. Cursor footprints, slime, bats, and Safari watching can vary accidentally. | State every default in R12.1. |
| Sky opacity is defined only for Cozy. | Spooky and Haunted rendering can change between implementations and may hide the real wallpaper. | Define 85%/90%/94% sky opacity for Cozy/Spooky/Haunted and retain the no-wallpaper-mutation rule. |
| There is no acceptance behavior for a saved ghost position after a display is disconnected or rearranged. | A persisted point can leave the pet unreachable. | R4.3 now requires restoration to the saved display when available and clamping to the nearest current visible frame otherwise. |
| Live-mode parsing omits several rules from the existing backend contract. | Missing fields, fenced JSON, `clarify`, default `action`, details messages, and malformed steps otherwise produce undefined behavior. | Expand R7 to require lenient parsing, default `click`, safe degradation to instruction-only, friendly `details`, and explicit handling of clarification and errors. |
| The optional vision fallback had a task but no complete functional requirement. | Task 11 specified capture, confidence rejection, and bbox mapping without a requirement that traced those behaviors. | Expand R13.3 to define opt-in consent, Screen Recording permission, `/nova-vision`, confidence ≥ 0.55, bbox validation/mapping, no screenshot logging, and séance fallback. |
| Manual séance has no source for app and step metadata. | A spell cannot satisfy R8.2 without an active guide step. | Manual séance asks for a short spell label and infers the app/window under the click. |
| The spec does not say what happens if AppleScript cannot close Safari. | The safety UI could disappear while the unsafe tab remains open. | R9.3 keeps the warning visible and gives a manual close instruction when Automation fails. |
| The Grimoire’s relative point has no behavior when the original window is absent, resized, or partly off-screen. | Remembered targets can be off-screen or unusable. | R8.4 and its design define current-window relative mapping, absolute fallback, and visible-screen clamping. |
| Elderly-first accessibility is mostly tone, font size, and Reduce Motion. | Button sizing, keyboard operation, VoiceOver names, and contrast are not accepted anywhere. | Add R12.5 for 44 pt controls where custom controls are used, keyboard operation, meaningful accessibility labels, and WCAG AA text contrast. |
| R13 says no personal data may be sent, but R7 sends the user’s task text and the backend contract allows `userEmail` and screen context. | The literal requirement contradicts Live mode. | Limit Wailo requests to explicit user task text and required plan fields. Do not send email, screen context, raw AX text, or pixels except the separately consented vision request. |

## Contradictions and ambiguities

| Finding | Conflict | Resolution in the split specs |
|---|---|---|
| The ghost must stay “exactly” where dragged and also be clamped to the visible screen. | A release outside the visible frame cannot satisfy both, and the same shorthand also appears in product steering. | Interpret “exactly” as “parked at the last valid user placement and never cursor-following”: the body follows the pointer subject to the visible-frame boundary, then persists that reachable position. A future steering edit should use this qualified wording. |
| The prompt must contain a focused text field “without stealing focus,” but a text field must become key to receive typing. | AppKit cannot focus the field while another app remains key. | Specify that the nonactivating prompt becomes key for text entry without activating Wailo or bringing all Wailo windows forward; closing it restores the prior app. |
| R4 says danger overrides every state and cancel always returns to idle. | Cancel during danger cannot both remain in danger and become idle. | Danger has safety precedence. Cancel clears the suspended activity and sets the restore state to idle; `dangerCleared` performs the return. |
| R2 says every overlay cannot become key, while the bubble design says the prompt panel can become key. | “Overlay” is being used for two different window groups. | R2 applies only to ambience, decor, and effects windows. Ghost and bubble panels have their own R4 behavior. |
| R6 always enters `searchingHard`, whose crystal ball means vision fallback, while vision is optional and off by default. | The state would imply pixels are being sent when no vision request occurs and would contradict product steering. | Keep local exhaustive work in `searching`; enter `searchingHard` and show the crystal ball only when an enabled, consented vision request begins. |
| R8 requires equal text or Jaccard ≥ 0.8, while the design says equal word sets or Jaccard ≥ 0.8. | Exact normalized strings and equal token sets are not the same rule, and empty normalized strings need an explicit policy. | Define normalization once: case-fold, split on non-alphanumerics, discard empty tokens. Two empty normalized strings do not match; otherwise match nonempty normalized strings exactly or use token-set Jaccard ≥ 0.8. |
| Task routing uses “contains” without defining priority or tokenization. | “email,” “folder scam,” punctuation, and casing can route unpredictably. | Define case-insensitive normalized phrase matching and preserve the table order as priority. Whitespace-only input maps to `nothing`; every other string maps to exactly one route. |
| The moon maps 6 pm to 6 am, but daytime behavior is absent. | A pure `moonProgress(hour:)` is not total for all clock values. | Clamp nighttime progress to [0,1] and hide the moon from 6 am until 6 pm. |
| “First step” spider behavior is ambiguous when earlier steps are instruction-only. | The first target could otherwise receive a pumpkin ring. | “First step” now means the first target-bearing step in that guide run. |
| “Same bundle ID” is required for Grimoire matching, but the bundle hint can be absent. | The matcher has no stated candidate set. | Infer the frontmost/window-under-point app where possible. Without a bundle ID, do not match stored spells automatically. |

## Untestable or subjective acceptance language

| Original language | Problem | Replacement or test method |
|---|---|---|
| “about 4.5 s,” “about 0.8 s,” “about 3.6 s,” and “about 3.5 s” | No tolerance. | Use explicit windows in manual/fake-clock checks: auto-demo 4.0–5.0 s; first search presentation 0.7–0.9 s; exhaustive local search starts at 1.6 s; séance 3.4–3.8 s; success visible 3.0–4.0 s. |
| “cute,” “friendly,” “soft,” “subtle,” “magical,” and “cozy-spooky” | Visual taste cannot be proven by unit tests. | Keep these as design goals. Accept objective proxies: opacity, no jump cuts in Cozy, minimum text/control sizes, no downloaded sound, and a manual elderly-user readability checklist. |
| “occasionally,” “rarely,” “fast,” and “one at a time” | Frequencies and thresholds are incomplete. | Use testable ranges in requirements: Cozy bat flight every 45–75 s, Spooky/Haunted every 20–40 s, window speed thresholds of 900/150/500 pt/s, and one-active-drip as an invariant. |
| “work reliably” for demos | No environment or success definition. | Define the supported setup: stock English-labelled Finder/Safari on macOS 14+, Accessibility granted, app present in Dock, with séance as the declared fallback for unavailable AX labels. |
| “landing exactly” and “inside with 10 pt slack” | Floating-point and pixel boundaries need a convention. | Use target center within 1 pt for the spider; use a closed rectangle expanded by 10 pt for click acceptance. |
| Idle CPU “target < 5%” | CPU varies by hardware, build mode, and attached screens. | Treat it as an operational benchmark: one display, no guide, animations settled for 20 s, then record a 30 s median and the hardware/build context. It remains a target rather than a portable unit-test assertion. |
| “Everything shall work across multiple monitors and Spaces.” | “Everything” is too broad. | Use an explicit manual matrix: primary plus right and above displays, target on each display, display reconfiguration, Space change, and full-screen app. Pure coordinate cases remain automated. |

## Original tasks without direct requirement trace

The following original tasks either had no `_Req` citation or implemented behavior absent from the
requirements:

- Task 1.1’s exact Swift Package layout was supported only by steering/design; R14.1 merely required
  successful commands.
- Task 1.2’s `softCircle`, gradient texture, and `node` helpers were implementation details, not
  requirements.
- Task 1.3’s `Palette` type and derived-setting fields were design details.
- Task 1.4’s “rebuilt in `menuWillOpen`” behavior was not required.
- Task 2.1 required YOLO conversion even though the backend contract explicitly marks YOLO endpoints
  unused by Wailo. The split removes YOLO work.
- Task 2.1’s nearest-screen fallback was absent from R2.
- Task 3.4’s tombstone wobble was absent from R3.
- Tasks 3.9, 4.5, 6.6, 7.3, and 8.4 were uncited manual checks.
- Task 7.1 named an undefined `handle` operation.
- Task 10.3 prescribed Instruments and possible refactors beyond the CPU requirement.
- Task 10.5’s README content had no requirement except indirect asset attribution.
- Task 11 specified most vision behavior without a matching functional requirement.

The feature plans now cite requirement IDs on every numbered task and subtask. Implementation-only
choices remain in the relevant design rather than being presented as independently required work.

## Requirement coverage missing from the original tasks

- No explicit acceptance task verified the Accessibility-denied degraded mode in R1.2.
- No explicit audit verified that screen changes reinstall decorations without replaying the intro.
- No privacy audit checked request bodies, logs, screenshot lifetime, or the backend-only network rule.
- No parser task covered missing plan fields, default `action`, backend `details`, 402, 429, or 502.
- No task defined or tested the setting defaults and live setting changes as a complete matrix.
- No task checked VoiceOver labels, keyboard operation, text contrast, or custom control size.
- No task tested Safari watcher deduplication or Automation denial.
- Optional Grimoire sync in R8.7 had no task. It remains explicitly deferred and is not needed for
  acceptance.

The new tasks add these checks or mark an item as deferred where the requirement itself says it is
optional.
