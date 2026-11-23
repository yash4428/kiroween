# Requirements: Guidance and safety

## Scope

This feature owns guided steps, target discovery, visual direction, built-in demos, existing-backend
plans, séance and remembered targets, scam warnings, and ghost mail. It consumes the foundation and
pet contracts. The backend in `backend/` is reused unchanged. Global quality gates are in
[R14](../wailo-app/requirements.md#r14-global-quality-gates).

## R6. Guidance visuals and demos

**User story:** As a user, I want to see where to click next and what action to take.

1. WHEN a guide starts THE SYSTEM SHALL start haunting if necessary, cancel the prior guide, put the
   ghost in `planning`, and show a bottom-center candle bar with one candle per step. The current
   candle SHALL flicker, completed candles SHALL remain lit, and future candles SHALL remain unlit.
2. WHEN a target-bearing step starts THE SYSTEM SHALL:
   - enter `searching` and make the first Grimoire-then-AX lookup after 0.7–0.9 seconds;
   - retry unresolved AX lookup every 0.20–0.30 seconds;
   - continue exhaustive local search after 1.6 seconds;
   - enter `searchingHard` and use the R13.3 vision request only when Vision fallback is enabled,
     consented, and local search has not found a target;
   - enter séance 3.4–3.8 seconds after search starts if no accepted local, remembered, or vision
     target exists;
   - accept the first valid target once per step generation and ignore competing retry callbacks.
3. WHEN a target is found THE SYSTEM SHALL:
   - dim only the target display with a fog spotlight whose Cozy/Spooky/Haunted opacity is
     35%/55%/60% and animate or fade open a soft hole around the target;
   - drop or fade a spider from that display’s top to within 1 pt of the target center for the first
     target-bearing step, with swing displacement no greater than 4 pt;
   - show a pulsing or static orange pumpkin ring around the target on later target-bearing steps;
   - repeatedly show glowing footprints from the current pointer position to the target until the
     click, with the final footprint inside the target;
   - show a translucent ghost hand that communicates tap, double-tap, drag, or no action;
   - show the instruction and transition the ghost through `found` to `waitingForClick`.
4. WHEN the primary-button down edge is inside the closed target rectangle expanded by 10 pt THE
   SYSTEM SHALL complete the step. WHEN it is outside and not over the ghost or an actionable bubble
   THE SYSTEM SHALL enter `wrongClick`, say “Boo… not there 🙂”, replay the footprints, and restore
   the instruction 1.6–2.0 seconds later.
5. WHEN a step is instruction-only THE SYSTEM SHALL show its instruction, transition the ghost
   through `found` to `waitingForClick`, and advance on Return when Return observation is available,
   or on the Next menu/hotkey in every permission mode.
6. WHEN the last step completes THE SYSTEM SHALL light all candles, burst candy-corn, bat, pumpkin,
   and sparkle confetti at the latest target or beside the ghost when no target exists, say “You did
   it! 🎉🍬”, enter `success`, and return to `idle` after 3.0–4.0 seconds unless a newer state or guide
   has started.
7. WHILE guidance is active THE SYSTEM SHALL render guidance on the display containing the target and
   SHALL run only that display’s effects scene at 60 fps. WHEN guidance ends THE SYSTEM SHALL remove
   all guide nodes/monitors/timers and restore its normal frame rate.
8. WHEN the New Folder demo runs with Accessibility granted on stock macOS 14+ Finder THE SYSTEM
   SHALL guide these target-bearing steps in order: Dock Finder; menu-bar File after Finder is
   frontmost; New Folder in the open File menu; then success. WHEN a target is unavailable THE SYSTEM
   SHALL use séance rather than guessing a point.
9. WHEN the Safari demo runs with Accessibility granted on stock macOS 14+ Safari THE SYSTEM SHALL
   guide Dock Safari, then the address/search field by its AX role, then an instruction-only “Type
   wikipedia.org and press Return” step. WHEN the address field is unavailable THE SYSTEM SHALL use
   séance.
10. WHEN Stop guidance is invoked THE SYSTEM SHALL invalidate pending asynchronous work, remove
    guide visuals and input monitors, and send `cancel` to the ghost state machine.

## R7. Live mode using the existing backend

**User story:** As a user, I want to ask for tasks beyond the built-in demos.

1. WHEN the router selects Live mode THE SYSTEM SHALL enter `planning` and POST JSON
   `{ "task": trimmedUserText, "platform": "macos" }` to `/plan` relative to
   `WAILO_BACKEND_URL`, using `URLSession.shared` and a 90-second `URLRequest` timeout.
2. WHEN parsing a `/plan` body THE SYSTEM SHALL remove an optional Markdown JSON fence, parse missing
   fields without crashing, and default a missing `action` to `click`. For each returned step it
   SHALL map:
   - a `click` with a nonempty `targetLabel`, otherwise nonempty `findDescription`, to smart AX
     search for that label across menu bar, Dock, open menus, and front-window elements;
   - a `click` without a usable label, and every `type`, `key`, `info`, unknown, or malformed action,
     to an instruction-only step;
   - a missing instruction to a safe generated instruction from an available label, or omit the step
     when neither exists.
3. WHEN the parsed body contains `{ "clarify": { "prompt", "options" } }` with a nonempty prompt
   THE SYSTEM SHALL show the prompt and accessible option actions in a bubble and SHALL NOT start a
   guide until the user supplies a choice.
4. WHEN the backend is unreachable, times out, returns a non-2xx response, or yields no usable steps
   THE SYSTEM SHALL show a friendly explanation using a non-sensitive `details` message when present,
   then offer and run the New Folder demo. For a 402 `limit_reached` response it SHALL identify the
   free-task limit without requesting payment credentials. It SHALL not automatically retry 429 or
   502 responses.
5. WHEN a usable plan is parsed THE SYSTEM SHALL preserve step order and run it through the same
   `GuidanceDirector` path as built-in demos.
6. THE SYSTEM SHALL NOT use, change, or depend on backend routes marked “Not used by Wailo” in the
   backend contract.

## R8. Séance and Grimoire

**User story:** As a user, when Wailo cannot find a target, I want to show it once so Wailo remembers.

1. WHEN target search times out THE SYSTEM SHALL enter `seance`, say “The spirits can’t see it… show
   me where it is”, and show a wooden planchette at the pointer, or a static planchette under Reduce
   Motion.
2. WHEN the user clicks outside the ghost and actionable bubble during a guided séance THE SYSTEM
   SHALL save a spell with app bundle ID from the step hint or window under the click, app name, step
   text, relative window position in `[0,1]²` with top-left origin when a window exists, absolute AX
   fallback point, creation date, and cast count zero; it SHALL then complete the step. WHEN no bundle
   ID can be determined THE SYSTEM SHALL ask the user to retry over the intended app and SHALL not
   save an unscoped spell.
3. THE SYSTEM SHALL persist spells as versioned JSON at
   `~/Library/Application Support/Wailo/grimoire.json`, use atomic replacement, recover from a
   missing file as an empty collection, preserve a corrupt file for recovery, and SHALL never store
   pixels.
4. WHEN searching for a remembered target THE SYSTEM SHALL consider only spells with the same bundle
   ID. It SHALL normalize step text by Unicode case folding, replacing non-alphanumeric runs with
   boundaries, and dropping empty tokens. Two empty normalized strings SHALL NOT match. Otherwise it
   SHALL match exact nonempty normalized strings or token-set Jaccard similarity ≥ 0.8, show “I
   remember this one!” with a book-flip or fade, increment the cast count once, and map the relative
   point into a current matching-app window. WHEN that window is not available it SHALL use the
   absolute AX fallback; it SHALL clamp the resulting 44×44 pt target to a visible display.
5. WHEN the user opens the Grimoire THE SYSTEM SHALL show a parchment-styled floating panel listing
   each spell’s text, app, learned date, and cast count, with an accessible Forget action and a
   friendly empty state.
6. WHEN the user starts a manual séance THE SYSTEM SHALL ask for a short spell label, infer the
   app/window under the teaching click, and save the same data as R8.2 without completing a guide
   step.
7. WHERE optional Grimoire sync is implemented, WHEN a learned label succeeds THE SYSTEM SHALL send
   only its non-pixel label through `/label/store`, and WHEN a Live plan succeeds THE SYSTEM SHALL use
   `/plan/learn`; core acceptance SHALL NOT depend on optional sync.

## R9. Cursed-page warning

**User story:** As a user, I want Wailo to warn me about likely scam pages in a calm, caring way.

1. WHEN triggered by menu, hotkey, prompt, or watcher THE SYSTEM SHALL grow or fade frost with
   branching ice-crystal paths from all four display edges, add a cool tint, enter `danger`, and show
   a centered warning: “This page feels cursed 👻 Don’t enter your bank details. Call your family
   first.” It SHALL provide large, keyboard-operable “Close this page” and “I trust it” actions.
2. WHILE Watch Safari is on and Accessibility is available THE SYSTEM SHALL inspect the front
   Safari URL locally every 2 seconds. WHEN its case-folded absolute string contains `kyc`,
   `update-pan`, `electricity-bill`, `refund`, or `lottery` THE SYSTEM SHALL trigger once for that
   exact URL until the URL changes. It SHALL NOT send or log the URL.
3. WHEN the user chooses “Close this page” THE SYSTEM SHALL ask Safari through AppleScript to close
   the front tab. WHEN that succeeds THE SYSTEM SHALL dismiss the warning. WHEN Automation is denied
   or closing fails THE SYSTEM SHALL keep the warning visible and say how to close the tab manually.
4. WHEN the user chooses “I trust it,” toggles the warning hotkey while a warning is open, or
   otherwise dismisses it THE SYSTEM SHALL melt or fade the frost, send `dangerCleared`, and say
   “Phew! Stay safe 💜”. Dismissal SHALL NOT mark a different future URL as already warned.
5. WHEN Watch Safari is off or Safari is not frontmost THE SYSTEM SHALL not inspect a URL.

## R11. Ghost mail

**User story:** As a user, I want a small affectionate surprise that demonstrates Wailo’s personality.

1. WHEN Ghost mail is triggered THE SYSTEM SHALL move a small ghost carrying an envelope along a
   visible curve toward the pet, or fade it beside the pet under Reduce Motion, perform the giggle
   response, and show: “💌 A letter from Grandson Aarav: ‘Hi Nani! Don’t forget your medicine. I’ll
   call you on Sunday. Love you!’”
2. THE SYSTEM SHALL use only bundled/procedural visuals and SHALL make no network request for Ghost
   mail.

## Correctness properties

The following properties are intended for property-based tests. Geometry generators use finite,
standardized rectangles and positive spacing.

1. **Footprint endpoint is inside target (R6.3, R14.2):** For every start point and every nonempty
   target rectangle, `FootprintPath.marks` returns at least one finite mark and the final mark lies in
   the closed target rectangle. This holds for tiny targets and when the start is already inside.
2. **Footprint path determinism and bounded alternation (R6.3):** Equal inputs return equal marks;
   side designation alternates; no generated coordinate or rotation is NaN/infinite; and the final
   endpoint property is unaffected by side offset.
3. **Expanded target acceptance (R6.4):** For every target rectangle and point, click acceptance is
   equivalent to membership in exactly `target.insetBy(dx: -10, dy: -10)` using closed-edge
   semantics.
4. **Plan parser totality (R7.2, R14.2):** For every byte sequence, parsing returns a typed plan,
   clarification, or failure and never traps. Adding/removing one valid Markdown fence around valid
   JSON does not change the parsed result.
5. **Plan mapping order (R7.2, R7.5):** For every parsed step list, mapping preserves relative order
   of all usable steps, defaults missing actions to `click`, and never creates a target query without
   a nonempty label.
6. **Grimoire matching symmetry (R8.4, R14.2):** For all strings `a` and `b`,
   `Grimoire.matches(a,b) == Grimoire.matches(b,a)`. It is reflexive for every normalized nonempty
   string, returns false for two empty normalized strings, never divides by zero, and otherwise
   returns true exactly for equal nonempty normalized strings or Jaccard ≥ 0.8.
7. **Grimoire bundle isolation (R8.4):** For every spell set and query with a known bundle ID, every
   returned match has that exact bundle ID regardless of text similarity in other apps.
8. **Remembered target stays visible (R8.4):** For every relative point in `[0,1]²`, valid current
   window, and nonempty display layout containing at least one visible frame of width and height at
   least 44 pt, locating then clamping produces a 44×44 pt target contained in a display visible
   frame. Mapping is monotonic in each relative coordinate before clamping.
9. **Cursed URL check totality (R9.2, R14.2):** For every string, `isCursed` is deterministic and
   case-insensitive for the five keywords; strings containing none return false.
10. **Watcher deduplication (R9.2):** For every generated URL sequence, each maximal run of one
    cursed URL triggers at most once; changing away and later returning begins a new eligible run.
11. **Guide generation safety (R6.6, R6.10):** For every interleaving of start, stop, and delayed
    callbacks, a callback from an older generation cannot change visuals, progress, or ghost state
    owned by the current generation.
