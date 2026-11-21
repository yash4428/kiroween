# Requirements: Haunting v2

## Scope

Haunting v2 sharpens Wailo’s mascot, desktop physics, Dock behavior, ambient help, and pointer recovery.
It supersedes conflicting visual behavior in the earlier feature specs while preserving their privacy,
accessibility, click-through, and Reduce Motion constraints.

## R15. Kiro-style ghost mascot

**User story:** As a user, I want a simple recognizable guide whose eyes communicate its mood.

1. WHEN `Resources/kiro-logo.png` is available THE SYSTEM SHALL draw that image as the mascot.
2. WHEN `Resources/kiro-logo.png` is unavailable THE SYSTEM SHALL draw an original white ghost leaning
   slightly to one side, with a purple glow, two tall oval dark eyes, and no mouth.
3. WHEN the mascot expresses normal, blink, happy, surprised, worried, or sleeping THE SYSTEM SHALL
   communicate the expression using eye shape, eye scale, eye angle, and eyelid position only.
4. WHILE Reduce Motion is enabled THE SYSTEM SHALL keep the same eye expressions and replace large
   mascot movement with fades or static poses.

## R16. Interactive falling pumpkins

**User story:** As a user, I want playful pumpkins that become physical desktop objects rather than
background decoration.

1. WHILE haunting is active outside Cozy THE SYSTEM SHALL spawn small pumpkins below the menu bar and
   let gravity move them toward eligible window title bars or the Dock floor.
2. WHEN a falling pumpkin intersects an eligible title-bar landing region THE SYSTEM SHALL land it,
   keep it attached while the window moves, and keep it outside the window’s traffic-light exclusion
   region.
3. WHEN a pumpkin has remained idle on a title bar for 8 seconds THE SYSTEM SHALL fade and remove it.
4. WHEN a pumpkin reaches the Dock floor without entering the bin THE SYSTEM SHALL remain visible for
   2 seconds and then fade and remove it.
5. WHEN the pointer presses a pumpkin THE SYSTEM SHALL make only that pumpkin’s nonactivating decor
   panel accept the drag. WHILE dragging THE SYSTEM SHALL move the pumpkin with the pointer. WHEN the
   pointer releases THE SYSTEM SHALL derive a clamped throw velocity and resume physics.
6. WHEN an attached window moves faster than 500 pt/s THE SYSTEM SHALL knock its pumpkins free using
   the window’s movement direction.
7. THE SYSTEM SHALL replace the earlier falling-leaf behavior and SHALL show no falling leaves.

## R17. Tombstone pumpkin bin

**User story:** As a user, I want the haunted Trash to act as a playful pumpkin bin.

1. WHEN Dock Trash bounds are available THE SYSTEM SHALL place an R.I.P. tombstone directly on the
   Trash rectangle rather than beside or above it.
2. WHEN Trash bounds are unavailable THE SYSTEM SHALL use the existing bottom-right visible-frame
   fallback.
3. WHEN the Dock is at the bottom THE SYSTEM SHALL keep the tombstone bin below the Dock-top floor so
   pumpkins can visibly cross into it.
4. WHEN a dropped or thrown pumpkin intersects the bin THE SYSTEM SHALL remove it and increment the
   burial count exactly once.
5. WHEN a released pumpkin is a near miss within the magnet radius THE SYSTEM SHALL curve or roll it
   into the bin, remove it, and increment the burial count exactly once.
6. WHEN the burial count changes THE SYSTEM SHALL show the count near the tombstone without blocking
   Dock clicks.

## R18. Window eligibility

**User story:** As a user, I want decorations only where they cannot obscure system controls or
full-screen content.

1. WHEN a window’s top edge is flush with the menu bar within 2 pt THE SYSTEM SHALL classify it as
   ineligible for slime and pumpkin landing.
2. WHEN a window covers at least 98% of a display in both dimensions THE SYSTEM SHALL classify it as
   full-screen and ineligible for slime and pumpkin landing.
3. WHEN a window is owned by Wailo, Dock, Window Server, Control Center, Notification Center,
   SystemUIServer, or another configured system-owner deny-list entry THE SYSTEM SHALL exclude it
   before decoration tracking.
4. WHEN a window is eligible THE SYSTEM SHALL expose a title-bar landing strip within its top 28 pt,
   inset from both sides and excluding the leftmost 86 pt traffic-light area.

## R19. Transitional fog and cloud removal

**User story:** As a user, I want an uncluttered desktop after the haunting introduction.

1. WHEN the haunting intro fog completes THE SYSTEM SHALL fully remove its emitters, vignette, and
   remaining fog nodes within 3 seconds of fog start.
2. WHILE ordinary haunting is active after the intro THE SYSTEM SHALL show no fog or mist.
3. WHILE the scam warning is active THE SYSTEM SHALL show cold mist with its frost; WHEN the warning
   is dismissed THE SYSTEM SHALL remove that mist.
4. THE SYSTEM SHALL draw no drifting clouds in the night scene.

## R20. Shake-to-find pointer lantern

**User story:** As a user, I want to find a lost pointer with a familiar shake gesture.

1. WHEN horizontal pointer direction reverses at least four times within 0.65 seconds, each qualifying
   movement is at least 18 pt, and total horizontal travel is at least 140 pt THE SYSTEM SHALL detect
   one shake.
2. WHEN a shake is detected outside an active guide THE SYSTEM SHALL show a lantern glow around the
   pointer and say “Here’s your pointer! 🏮”.
3. WHEN the lantern has been visible for 1.8 seconds THE SYSTEM SHALL fade and remove it.
4. WHILE a guide is active THE SYSTEM SHALL suppress shake-to-find feedback.
5. WHILE Reduce Motion is enabled THE SYSTEM SHALL fade the lantern in place without pulsing or
   orbiting.

## R21. App-aware ambient tips

**User story:** As a user, I want Wailo to notice where I am and offer relevant help without nagging.

1. WHEN the same frontmost app has remained active for 6 continuous seconds, no guide or warning is
   active, and that app has not received a tip in the previous 15 minutes THE SYSTEM SHALL offer one
   contextual tip with large accessible buttons.
2. WHEN the app is Finder THE SYSTEM SHALL offer “Make a new folder” and a Not now action.
3. WHEN the app is Safari, Google Chrome, Firefox, Microsoft Edge, Arc, Brave Browser, or Opera THE
   SYSTEM SHALL offer “Is this page safe?” and a Not now action.
4. WHEN the app is Mail THE SYSTEM SHALL offer help composing or finding mail and a Not now action.
5. WHEN the app is System Settings THE SYSTEM SHALL offer help changing a setting and a Not now
   action.
6. WHEN the app matches none of R21.2–R21.5 THE SYSTEM SHALL offer generic help for that app and a Not
   now action.
7. WHEN the user accepts a tip THE SYSTEM SHALL route it through the existing task/demo/safety paths.
8. WHEN app focus changes THE SYSTEM SHALL restart the 6-second dwell timer for the new app.

## R22. Haunted Dock target

**User story:** As a user, I want Wailo to make the required app obvious and patiently wait for it.

1. WHEN a guide step targets an app that is present in the Dock THE SYSTEM SHALL show a glowing copy
   of that Dock icon with a gentle wobble and a small peeking ghost without intercepting Dock clicks.
2. WHEN Reduce Motion is enabled THE SYSTEM SHALL replace wobble with a static glow.
3. WHEN a step requires an app to become frontmost THE SYSTEM SHALL keep the haunted Dock marker and
   wait until that bundle ID is frontmost instead of timing out into séance.
4. WHEN the required app becomes frontmost THE SYSTEM SHALL remove the Dock marker and continue the
   step search.
5. WHEN guidance stops or changes step THE SYSTEM SHALL remove every haunted Dock marker and waiting
   timer.

## Correctness properties

1. **Tombstone placement (R17):** For every valid Trash rectangle and screen frame, tombstone placement
   has the same center as the Trash rectangle, fits within the selected display after clamping, and
   is below the Dock-top floor for bottom Dock orientation.
2. **Header landing (R16, R18):** For every eligible window and pumpkin width, a computed landing point
   lies in the title-bar strip, outside the traffic-light exclusion, and remains inside the window’s
   horizontal bounds; ineligible windows return no landing region.
3. **Throw velocity clamping (R16):** For every finite sampled drag velocity, the clamped magnitude is
   at most 1,600 pt/s, preserves direction when nonzero, and is idempotent. Non-finite input yields
   zero velocity.
4. **Bin magnet radius (R17):** For every pumpkin center, magnet eligibility is true exactly when its
   Euclidean distance to the bin rectangle is at most 90 pt; direct intersection is always eligible.
5. **Full-screen detection (R18):** For every valid display and window rectangle, detection is true
   when both overlap ratios are at least 0.98 and false when either ratio is below 0.98.
6. **Shake detection (R20):** Generated paths that meet reversal, displacement, travel, and time
   thresholds trigger once; monotonic paths, jitter below 18 pt, and paths outside 0.65 seconds do not.
7. **Per-app tip mapping (R21):** For every bundle ID and app name the mapper returns exactly one of
   Finder, browser, Mail, System Settings, or generic; known aliases map deterministically and mapping
   is case-insensitive.
8. **Tip cooldown (R21):** For every app and timeline, no two offers for the same bundle ID occur less
   than 15 minutes apart, and focus changes reset dwell without clearing cooldown history.
