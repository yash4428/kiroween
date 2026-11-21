# Requirements overview: Wailo macOS app

## Purpose

Wailo is a haunted, cozy macOS menu-bar guide for elderly and non-technical users. It turns the
desktop into a functional night scene, provides a stationary ghost pet as the main interaction, and
guides users to visible controls. The app is built in `app/`. The existing server in `backend/` is
reused unchanged under `.kiro/steering/backend-api.md`.

The former single feature specification is split by responsibility:

| Feature spec | Requirement IDs | Scope |
|---|---|---|
| [haunting-foundation](../haunting-foundation/requirements.md) | R1–R3, R10, R12, R13 | App shell, overlays, coordinates, haunting, ambient footprints, settings, assets, privacy |
| [ghost-pet](../ghost-pet/requirements.md) | R4–R5 | Pet behavior, state machine, speech/prompt UI, task routing |
| [guidance-and-safety](../guidance-and-safety/requirements.md) | R6–R9, R11 | Guided tasks, backend plans, séance/Grimoire, scam warnings, ghost mail |
| [haunting-v2](../haunting-v2/requirements.md) | R15–R22 | Mascot redesign, pumpkin physics/bin, eligibility, shake-to-find, ambient tips, haunted Dock targets |

The [pre-split critique](critique.md) records gaps, contradictions, untestable criteria, and task
traceability fixes.

## Shared vocabulary

- **Cocoa coordinates:** AppKit global coordinates with a bottom-left origin.
- **AX coordinates:** Accessibility/CoreGraphics global coordinates with a top-left origin relative
  to the primary display.
- **Primary display:** The display whose Cocoa frame origin is `(0, 0)`.
- **Target-bearing step:** A guide step that requires a visible target rectangle and click.
- **Instruction-only step:** A guide step completed by Return or the Next command without a target.
- **Cozy, Spooky, Haunted:** Increasing opt-in Boo Levels. Cozy is the default.

## R14. Global quality gates

**User story:** As a user, I want Wailo to remain dependable across displays and updates.

1. WHEN an implementation task is completed THE SYSTEM SHALL pass `swift build` and `swift test`
   from `app/`; project validation SHALL NOT use `xcodebuild`.
2. THE SYSTEM SHALL have automated tests for:
   - coordinate conversions and round trips using primary, right-side, and above-primary displays;
   - valid vision bbox mapping and invalid bbox rejection;
   - the final footprint ending inside its target;
   - ghost state transitions, danger precedence, restoration, and cancellation;
   - total and deterministic task routing;
   - cursed-URL matching;
   - symmetric Grimoire text matching;
   - lenient plan parsing, including fenced JSON and missing fields;
   - moon position for every hour of the day.
3. WHEN manually accepted on multiple displays THE SYSTEM SHALL pass this matrix: a primary display
   plus a display to its right and one above it; a target on each display; a display add/remove or
   rearrangement; a Space switch; and a full-screen app. Effects SHALL stay on the target display,
   the ghost SHALL remain reachable, and underlying apps SHALL remain clickable.
4. WHEN benchmarked with one display, a non-debug build, no active guide, and ambient animations
   settled for 20 seconds, THE SYSTEM SHALL record the median process CPU over the next 30 seconds,
   with hardware, macOS version, build configuration, and Boo Level. The acceptance target SHALL be
   below 5%; a higher result SHALL remain documented and create a measured performance-remediation
   task rather than fail a portable unit test.
5. THE SYSTEM SHALL keep pure logic independent of AppKit state for coordinates, footprint paths,
   state transitions, task routing, URL checks, text matching, and plan parsing.

## Cross-feature constraints

1. The app SHALL follow all files in `.kiro/steering/`, including the window-level, coordinate,
   permission, privacy, and performance rules.
2. The app SHALL treat `backend/` as an existing read-only service and SHALL use only the API contract
   in `.kiro/steering/backend-api.md`.
3. Feature behavior that depends on another feature SHALL use the public contracts in the linked
   designs rather than duplicate ownership.
