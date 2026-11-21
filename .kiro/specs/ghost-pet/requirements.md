# Requirements: Ghost pet

## Scope

This feature owns the stationary desktop ghost, its semantic state machine, speech and prompt panels,
and pure routing of submitted text. It consumes overlay/settings contracts from
[haunting-foundation](../haunting-foundation/design.md) and sends routes to
[guidance-and-safety](../guidance-and-safety/design.md). Global quality gates are in
[R14](../wailo-app/requirements.md#r14-global-quality-gates).

## R4. Ghost pet

**User story:** As a user, I want a friendly ghost that stays where I put it and shows what Wailo is
doing.

1. THE SYSTEM SHALL draw an original procedural ghost with a gentle idle bob, a blink at randomized
   intervals of 3–7 seconds, and an occasional yawn no more often than every 40 seconds while idle.
2. WHILE the user is not dragging the ghost and no explicit rise/sink animation is active THE SYSTEM
   SHALL keep the ghost parked at its current position and SHALL NOT make it follow or chase the
   cursor.
3. WHILE the user drags the ghost THE SYSTEM SHALL preserve the initial pointer offset and move the
   panel with the pointer subject only to keeping the complete ghost body inside the union of current
   visible frames. WHEN the drag ends THE SYSTEM SHALL keep it at that reachable placement and
   persist the position. WHEN the app next launches THE SYSTEM SHALL restore that position on the
   saved display if available, or clamp it to the nearest current visible frame after a display
   change.
4. WHEN pointer movement between mouse-down and mouse-up is less than 4 pt THE SYSTEM SHALL treat the
   gesture as a click and open the R5 prompt; otherwise it SHALL treat it as a drag.
5. WHEN the pointer first enters the parked idle ghost body and no bubble is visible THE SYSTEM SHALL
   perform one Reduce-Motion-aware giggle response and show a short “hehe” bubble. It SHALL NOT repeat
   until the pointer exits and re-enters.
6. THE SYSTEM SHALL let pointer events pass through the transparent area of the ghost panel and SHALL
   accept pointer events only over the ghost body while the pet is visible or a drag is in progress.
7. WHEN the state machine enters a state THE SYSTEM SHALL show its distinct semantic look:

   | State | Required look |
   |---|---|
   | `idle` | smiling; gentle bob and blink unless Reduce Motion is on |
   | `listening` | cyan glow, ear symbol, inward wisps |
   | `planning` | bubbling cauldron and plan candles rising or fading in |
   | `searching` | lantern and local sweeping beam or static beam under Reduce Motion |
   | `searchingHard` | purple crystal ball, entered only while a consented vision request is active |
   | `found` | sparkles and delighted face |
   | `waitingForClick` | pointing/nudging pose or static point under Reduce Motion |
   | `wrongClick` | frown and head shake or expression-only change under Reduce Motion |
   | `seance` | purple glow and candle |
   | `success` | lit candle and giggle response |
   | `danger` | 1.5× puff, frosty edge, ice spikes, and warning symbol |
   | `sleeping` | closed eyes, tilt, and floating or static sleep symbol |

8. WHILE the ghost is `idle`, WHEN it has had no pointer movement or semantic event for 10 minutes
   THE SYSTEM SHALL enter `sleeping`; from midnight inclusive to 5 am exclusive the threshold SHALL
   be 1 minute. WHEN pointer movement occurs while sleeping THE SYSTEM SHALL return to `idle`.
9. THE SYSTEM SHALL drive semantic states through a pure deterministic state machine with these
   rules:
   - `dangerDetected` from any non-danger state stores that state and enters `danger`;
   - events other than `dangerCleared`, `dangerDetected`, and `cancel` SHALL NOT leave `danger`;
   - `cancel` outside danger enters `idle`; `cancel` during danger keeps `danger` active and changes
     the saved restore state to `idle`;
   - `dangerCleared` restores the saved state, or `idle` if none exists;
   - unsupported event/state pairs leave the current state unchanged;
   - normal transitions SHALL follow this relation: `startListening` from idle/sleeping/success →
     listening; `startPlanning` from idle/listening/sleeping/success → planning; `startSearching`
     from planning/found/waitingForClick/seance/searchingHard → searching; `escalateSearch` from
     searching → searchingHard; `targetFound` from searching/searchingHard → found; `awaitClick`
     from found/wrongClick → waitingForClick; `clickedWrong` from waitingForClick → wrongClick;
     `wrongClickRecovered` from wrongClick → waitingForClick; `cannotFind` from
     searching/searchingHard → seance; `stepDone(last)` from waitingForClick/found/seance → success
     when last or searching otherwise; `idleTooLong` from idle → sleeping; and `activity` from
     sleeping/success → idle.
10. WHEN Wailo shows a speech message THE SYSTEM SHALL use a rounded cream bubble with dark text at
    least 19 pt, give actionable controls meaningful accessibility labels, place it adjacent to the
    ghost above when space exists and below otherwise, and clamp the complete bubble to a current
    visible frame.

## R5. Prompt and task routing

**User story:** As a user, I want to click the ghost and type what I want to do.

1. WHEN the prompt opens THE SYSTEM SHALL send `startListening` to the ghost and show “What would you
   like to do?” with a focused text field, example suggestions, a “Go 🎃” button, and a close button.
   The nonactivating prompt panel SHALL become key for typing without activating Wailo or reordering
   all Wailo windows. WHEN it closes THE SYSTEM SHALL restore the previously active app when possible.
2. WHEN the user presses Return or Go THE SYSTEM SHALL trim the input, close the prompt for nonempty
   input, send `cancel` to end `listening`, and route it case-insensitively. It SHALL normalize
   punctuation to token boundaries and use the first matching row as priority:

   | Priority | Complete token or phrase contains | Route |
   |---:|---|---|
   | 1 | `folder` | New Folder demo |
   | 2 | `safari`, `website`, `wikipedia`, or `browse` | Safari demo |
   | 3 | `scam` or `cursed` | cursed-page warning |
   | 4 | `mail`, `letter`, or `aarav` | ghost mail |
   | 5 | `grimoire` or `spell` | Grimoire |
   | 6 | no row above | Live mode with the trimmed original text |

   Empty or whitespace-only input SHALL remain on the prompt and SHALL start no action.
3. WHEN the user presses Escape or the close button THE SYSTEM SHALL close the prompt, submit no
   task, send `cancel` to restore `idle` unless danger is active, and restore the previously active
   app when possible.
4. WHEN a suggestion is activated THE SYSTEM SHALL place its text into the field or submit the same
   text through the R5.2 routing path; it SHALL NOT use a separate routing implementation.

## Correctness properties

The following properties are intended for property-based tests.

1. **State is always valid (R4.9, R14.2):** For every initial `GhostState` and every generated event
   sequence, each result is one member of the finite `GhostState` enum and processing the sequence is
   deterministic.
2. **Danger precedence and restoration (R4.9, R14.2):** For every non-danger state `s` and event
   sequence containing no `dangerCleared`, applying `dangerDetected` then that sequence leaves the
   visible state at `danger`. A following `dangerCleared` restores `s`, except that any intervening
   `cancel` restores `idle`.
3. **Cancel invariant (R4.9, R14.2):** For every state, `cancel` yields `idle` when danger is inactive;
   when danger is active it preserves `danger` and sets the eventual restore state to `idle`.
4. **Unsupported events are identity (R4.9):** For every state/event pair outside the declared
   transition relation and safety events, handling the event returns the same visible state and does
   not mutate the saved restore state.
5. **Parking remains visible (R4.3):** For every non-empty valid display layout whose visible frames
   can contain the ghost body and every finite release point, clamping produces a ghost body
   rectangle wholly contained in one display’s visible frame. Applying the clamp again is
   idempotent.
6. **Router totality and uniqueness (R5.2, R14.2):** For every Unicode string, `route` terminates and
   returns exactly one `Route`; whitespace-only strings return `nothing`, and every other string
   returns a built-in route or `live` with the trimmed original.
7. **Router normalization invariance (R5.2):** Changing only letter case or replacing punctuation
   boundaries with whitespace does not change a built-in route. If several route vocabularies occur,
   the lowest numbered priority always wins.
8. **Prompt cancellation safety (R5.3):** For every current field value, Escape/close emits no route;
   Return/Go emits at most one route.
