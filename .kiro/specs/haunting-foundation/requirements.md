# Requirements: Haunting foundation

## Scope

This feature owns Wailo’s app shell, coordinates, overlay windows, haunted ambience, ambient cursor
footprints, settings, accessibility defaults, assets, and privacy boundary. Global quality gates are
in [R14](../wailo-app/requirements.md#r14-global-quality-gates).

Requirements use EARS wording. “Overlay windows” in R2 means the ambience, decor, and effects
windows; it does not include the interactive ghost or bubble panels from R4.

## R1. App shell and menu

**User story:** As a user, I want Wailo to live quietly in my menu bar so it never gets in my way.

1. THE SYSTEM SHALL be delivered as the macOS 14+ Swift Package executable in `app/` with processed
   resources and a test target. WHEN the app launches THE SYSTEM SHALL use accessory activation
   policy, show a 🎃 menu-bar item, and show no Dock icon.
2. WHEN Accessibility permission is absent THE SYSTEM SHALL request it once through the macOS system
   prompt and SHALL explain the reduced mode without repeatedly prompting. WHILE permission remains
   absent THE SYSTEM SHALL keep ambience, the ghost, prompt, backend planning, instruction-only
   steps, and manual séance available; it SHALL treat AX target search, Dock discovery, Return-key
   observation, and Safari URL watching as unavailable and SHALL offer Next or séance where useful.
3. WHEN the user opens the 🎃 menu THE SYSTEM SHALL offer:
   - Start/Stop Haunting; Ask Wailo…; Run Demo: New Folder; Run Demo: Safari; Next step; Stop guidance;
   - Simulate Cursed Page; Start Séance; Show Grimoire; Ghost mail;
   - Boo Level with Cozy, Spooky, and Haunted;
   - Cursor footprints, Slime, Bats, Sounds, Watch Safari, and Vision fallback toggles;
   - Debug actions for Cycle ghost state, Show target frames, and Accessibility status;
   - Quit.
4. WHEN the app is running THE SYSTEM SHALL register these global hotkeys with Carbon
   `RegisterEventHotKey`, without requiring Accessibility permission:

   | Keys | Action |
   |---|---|
   | ⌃⌥H | toggle Haunting |
   | ⌃⌥L | open prompt |
   | ⌃⌥D | New Folder demo |
   | ⌃⌥F | Safari demo |
   | ⌃⌥N | next step |
   | ⌃⌥S | show or dismiss cursed-page warning |
   | ⌃⌥G | cycle ghost state |
   | ⌃⌥M | ghost mail |
   | ⌃⌥Esc | stop guidance |

5. WHEN `WAILO_AUTODEMO` equals `folder`, `safari`, `cursed`, or `prompt` THE SYSTEM SHALL invoke that
   action 4.0–5.0 seconds after launch. WHEN it has any other value THE SYSTEM SHALL ignore it.
6. WHEN launch setup completes THE SYSTEM SHALL start haunting. It SHALL NOT replay the transition
   solely because displays change.

## R2. Overlay and coordinate foundation

**User story:** As a user, I want effects to look magical without blocking clicks or moving to the
wrong display.

1. THE SYSTEM SHALL create one set per display: an ambience window at desktop level + 1, a decor
   window at status-bar level, and an effects window at screen-saver level.
2. THE SYSTEM SHALL make each R2.1 window borderless, transparent, non-opaque, shadowless,
   click-through, unable to become key or main, available on all Spaces and full-screen auxiliary
   spaces, stationary, and absent from the window cycle.
3. WHEN displays are added, removed, resized, or rearranged THE SYSTEM SHALL rebuild the display
   sets, preserve whether haunting is active, and reinstall the current decorations without
   replaying the start transition.
4. WHILE a SpriteKit scene has no actions or emitters THE SYSTEM SHALL pause its view after one wake
   grace interval. WHEN a client adds or changes an effect THE SYSTEM SHALL wake the scene.
5. THE SYSTEM SHALL perform AX↔Cocoa, global↔screen-local, and 0–1000 bbox conversions only through
   pure functions in `CoordinateSpace`, using the display whose Cocoa origin is `(0,0)` as primary.
   WHEN no frame contains a point THE SYSTEM SHALL select the nearest display by point-to-rectangle
   distance.
6. WHEN the effects layer is not guiding THE SYSTEM SHALL cap ambience at 20 fps and decor/effects at
   30 fps. WHILE guiding THE SYSTEM SHALL run the active target display’s effects scene at 60 fps and
   SHALL keep every other effects scene at or below 30 fps.

## R3. The Haunting transition and ambience

**User story:** As a user, I want starting Wailo to feel as if my desktop becomes gently haunted.

1. WHEN haunting starts THE SYSTEM SHALL begin the following beats in order, start the final beat by
   2.8 seconds, and complete the transition by 3.5 seconds, without a jump cut in Cozy:
   1. a short dim in Cozy, or no more than two brightness flickers in Spooky and Haunted;
   2. edge fog and a vignette;
   3. a night sky, at 85%/90%/94% opacity in Cozy/Spooky/Haunted, containing a purple-to-navy
      gradient, stars, drifting clouds, silhouette hills, tombstones, bare trees, and a moon whose
      nighttime horizontal position follows the real clock from left at 6 pm to right at 6 am;
   4. cobwebs growing into all four corners below the menu bar;
   5. bats hanging under the menu bar;
   6. a tombstone marked “R.I.P.” over the Dock Trash;
   7. slime on visible top edges of front windows;
   8. the ghost rising from the tombstone and waving.
2. THE SYSTEM SHALL render the night scene in Wailo-owned transparent windows and SHALL NOT change
   the system wallpaper or recolor another app’s pixels.
3. WHEN the Dock Trash cannot be found THE SYSTEM SHALL place the tombstone at the bottom-right of
   the primary display’s visible frame.
4. WHEN haunting stops THE SYSTEM SHALL stop guidance and transient safety/séance effects, sink the
   ghost, remove decorations, transition the sky toward sunrise, fade Wailo’s overlays, and leave the
   real wallpaper unchanged.
5. WHILE haunting and Bats is on THE SYSTEM SHALL keep bats hanging most of the time and use finite,
   timer-started flights that return to their perch, choosing 45–75 seconds between flights in Cozy
   and 20–40 seconds in Spooky or Haunted. WHEN Bats is turned off THE SYSTEM SHALL remove existing
   bats and cancel their flight timers.
6. WHILE haunting and Slime is on THE SYSTEM SHALL attach slime to at most the frontmost three
   qualifying windows in Cozy and five in Spooky or Haunted whose top edge is visible. It SHALL
   stretch, drop, and retract no more than one active drip at once. WHEN a tracked window exceeds 900
   pt/s THE SYSTEM SHALL splatter its slime; WHEN its speed remains below 150 pt/s after the cooldown
   THE SYSTEM SHALL regrow it. WHEN Slime is turned off THE SYSTEM SHALL remove existing slime and
   cancel its timers.
7. WHILE Boo Level is Spooky or Haunted THE SYSTEM SHALL drop leaves that land on visible window top
   edges, cap each pile at 14 leaves, and slide a pile off WHEN that window exceeds 500 pt/s or
   disappears. WHILE Boo Level is Cozy THE SYSTEM SHALL show no falling leaves.
8. WHILE Boo Level is Haunted THE SYSTEM SHALL schedule a soft lightning flash at a randomly chosen
   interval in 18–35 seconds. WHILE Boo Level is Cozy or Spooky THE SYSTEM SHALL show no lightning.
9. WHILE the clock is from 6 am inclusive to 6 pm exclusive THE SYSTEM SHALL hide the moon. WHILE it
   is nighttime THE SYSTEM SHALL keep its horizontal progress in the closed interval `[0,1]`.

## R10. Ambient cursor footprints

**User story:** As a user, I want the cursor trail to reinforce the haunted theme without obscuring
my work.

1. WHILE haunting is active and Cursor footprints is on THE SYSTEM SHALL place alternating left and
   right lavender footprints after every 22–26 pt of accumulated cursor travel, rotate them to the
   travel direction, and fade each over 1.0–1.4 seconds.
2. WHILE the cursor is over the ghost’s body THE SYSTEM SHALL create no ambient footprint.
3. THE SYSTEM SHALL read `NSEvent.mouseLocation` for the ambient trail and SHALL NOT request a
   permission for that read.

## R12. Boo Level, accessibility, motion, and sound

**User story:** As an elderly user, I want calm defaults and controls I can read and operate.

1. WHEN no preferences have been saved THE SYSTEM SHALL use Cozy, Cursor footprints on, Slime on,
   Bats on, Sounds off, Watch Safari off, Vision fallback off, and Show target frames off. Cozy SHALL
   use pastel purple/orange, light fog, no brightness flicker, 45–75 second bat-flight intervals, no
   leaves, and no lightning.
2. WHILE macOS Reduce Motion is on THE SYSTEM SHALL replace drops, swings, drifts, flights, path
   walks, and large movement transitions with fades or static state changes that communicate the
   same result.
3. WHILE Sounds is on THE SYSTEM SHALL use only macOS system sounds from the approved set Tink,
   Glass, Pop, Purr, and Submarine. WHILE Sounds is off THE SYSTEM SHALL initiate no sound.
4. WHEN Boo Level or any toggle changes THE SYSTEM SHALL persist the setting under the `wailo.`
   prefix, publish `Settings.changed`, and apply the behavior without restarting or replaying the
   haunting transition. WHEN Show target frames is on THE SYSTEM SHALL draw a labeled debug outline
   around the current target; WHEN it is off THE SYSTEM SHALL remove that outline.
5. WHEN Wailo presents custom text or controls THE SYSTEM SHALL use at least 18 pt body text, at least
   19 pt speech-bubble text, 44×44 pt minimum hit targets where space permits, keyboard-operable
   actions, meaningful VoiceOver labels, and WCAG 2.1 AA contrast for text. THE SYSTEM SHALL not use
   a jump scare at any Boo Level.

## R13. Assets, network privacy, and optional vision

**User story:** As a user, I want Wailo to protect my data and remain usable when an art asset is
missing.

1. WHEN a sprite is requested THE SYSTEM SHALL load its bundled PNG credited in
   `assets/ASSETS.md`. WHEN either the PNG or resource bundle is unavailable THE SYSTEM SHALL render
   the sprite’s system-emoji fallback and SHALL NOT crash or leave a required visual blank.
2. THE SYSTEM SHALL draw the sky, moon, hills, cobwebs, slime, fog, footprints, ring, candles,
   cauldron, planchette, frost, and ghost procedurally. THE SYSTEM SHALL use no copyrighted character,
   brand-logo, or downloaded music asset.
3. WHILE Vision fallback is off THE SYSTEM SHALL never capture or send screen pixels. WHEN a user
   first attempts to enable it THE SYSTEM SHALL explain that a screenshot of the current target
   display will be sent to the configured Wailo backend and requires Screen Recording permission,
   and SHALL require explicit confirmation. WHEN enabled, consented, Screen Recording permission is
   granted, and local target finding fails THE SYSTEM SHALL capture only that display, POST it to
   `/nova-vision`, reject confidence below 0.55 and invalid bboxes, map a valid 0–1000 top-left bbox
   through `CoordinateSpace`, and fall back to séance when no accepted target is returned. WHEN
   Screen Recording permission is denied THE SYSTEM SHALL explain that vision is unavailable and
   continue to séance without capturing pixels.
4. WHEN Live mode requests a plan THE SYSTEM SHALL send only the text the user explicitly submitted
   and `platform: "macos"`, unless a later requirement adds another consented field. THE SYSTEM SHALL
   NOT send `userEmail`, general screen context, raw AX text, or pixels in a plan request.
5. THE SYSTEM SHALL make network calls only to `WAILO_BACKEND_URL` through `URLSession.shared`, SHALL
   collect no analytics, and SHALL NOT log screenshots, raw screen text, task text, email addresses,
   or other personal data. WHEN operational logging is enabled THE SYSTEM SHALL limit fields to task
   category, HTTP status, and app bundle ID.
6. WHEN a vision screenshot has been encoded for its single request THE SYSTEM SHALL retain it only
   in memory until that request completes or is cancelled and SHALL never write it to disk.

## Correctness properties

The following properties are intended for property-based tests. Generated floating-point inputs must
exclude NaN and infinity; comparisons use a documented tolerance such as `1e-6`.

1. **AX/Cocoa point round trip (R2.5, R14.2):** For every finite point and every valid display layout
   containing exactly one `(0,0)` primary frame,
   `cocoaToAX(axToCocoa(p, frames), frames) ≈ p`, and the inverse also holds.
2. **AX/Cocoa rectangle round trip (R2.5, R14.2):** For every standardized finite rectangle,
   converting AX→Cocoa→AX or Cocoa→AX→Cocoa preserves origin and size within tolerance, including a
   rectangle on a display above the primary.
3. **Local/global round trip (R2.5):** For every display frame and point or rectangle,
   `localToGlobal(globalToLocal(value, frame), frame) ≈ value`.
4. **Screen selection totality (R2.5):** For every finite point and non-empty valid frame list,
   `screenIndex` returns a valid index; if one or more frames contain the point it selects a
   containing frame, otherwise it selects a frame with minimum point-to-rectangle distance.
5. **Vision bbox remains on screen (R13.3, R14.2):** For every screen frame and ordered bbox with all
   components in `[0,1000]`, `bbox1000ToCocoa` produces a standardized rectangle contained by that
   screen frame. Its center equals the contract formula within tolerance. Reversed, non-finite, or
   out-of-range bboxes are rejected.
6. **Moon mapping is bounded and monotonic (R3.1, R3.9, R14.2):** For all nighttime instants from 6 pm
   through 6 am, moon progress is in `[0,1]` and does not decrease as time advances across midnight;
   daytime instants produce no visible moon position.
7. **Settings round trip (R12.1, R12.4):** For every supported settings value set, encoding to
   `UserDefaults` and decoding yields the same values; absent or invalid values yield the declared
   defaults.
8. **Ambient footprint exclusion (R10):** For every finite cursor path and ghost hit region, every
   emitted mark lies outside that region, including paths that cross its boundary. Generated marks
   alternate sides, and no zero-length segment produces a non-finite angle.
