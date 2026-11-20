# Requirements: Wailo macOS app

## Introduction
Wailo is a haunted, cozy macOS menu-bar app that guides elderly users through computer tasks.
It turns the desktop into a night scene, gives the user a ghost pet that shows what Wailo is doing,
and guides each click with spooky-but-useful visuals. It reuses the existing Waylo backend
(`backend/`, contract in `.kiro/steering/backend-api.md`) for plans.

Requirements use EARS wording. "Cocoa" means AppKit bottom-left coordinates, "AX" means top-left.

---

### R1. App shell and menu
**User story:** As a user, I want Wailo to live quietly in my menu bar so it never gets in my way.
1. WHEN the app launches THE SYSTEM SHALL run as an accessory app: a 🎃 menu-bar item and no Dock icon.
2. WHEN the app launches THE SYSTEM SHALL request Accessibility permission if it is not granted, and
   SHALL keep working, with reduced features, while it is not.
3. WHEN the user opens the 🎃 menu THE SYSTEM SHALL offer:
   - Start/Stop Haunting
   - Ask Wailo… (opens the ghost prompt)
   - Run Demo: New Folder
   - Run Demo: Safari
   - Next step
   - Stop guidance
   - Simulate Cursed Page
   - Start Séance
   - Show Grimoire
   - Ghost mail
   - Boo Level ▸ Cozy/Spooky/Haunted
   - toggles: Cursor footprints, Slime, Bats, Sounds, Watch Safari, Vision fallback
   - Debug ▸ Cycle ghost state, Show target frames, Accessibility status
   - Quit
4. THE SYSTEM SHALL register global hotkeys with Carbon `RegisterEventHotKey` (⌃⌥ = Control+Option):

   | Keys | Action |
   |---|---|
   | ⌃⌥H | toggle Haunting |
   | ⌃⌥L | open prompt |
   | ⌃⌥D | New Folder demo |
   | ⌃⌥F | Safari demo |
   | ⌃⌥N | next step |
   | ⌃⌥S | cursed page (press again to dismiss) |
   | ⌃⌥G | cycle ghost state |
   | ⌃⌥M | ghost mail |
   | ⌃⌥Esc | stop guidance |

5. WHEN the env var `WAILO_AUTODEMO` is `folder|safari|cursed|prompt` THE SYSTEM SHALL start that
   demo about 4.5 s after launch (for hands-free video recording).

### R2. Overlay foundation
**User story:** As a user, I want the effects to look magical but never block my clicks.
1. THE SYSTEM SHALL create, per screen:
   - an **ambience** window above the wallpaper and below the desktop icons
   - a **decor** window at status-bar level, below open menus
   - an **effects** window at screen-saver level, above menus
2. THE SYSTEM SHALL make every overlay window borderless, transparent, click-through, unable to
   become key, and present on all Spaces and over full-screen apps.
3. WHEN screens are added, removed or rearranged THE SYSTEM SHALL rebuild the overlays and reinstall
   the decorations without replaying the transition.
4. WHILE nothing is animating THE SYSTEM SHALL pause rendering, so idle CPU stays low (target < 5%).
5. THE SYSTEM SHALL do every coordinate conversion through one `CoordinateSpace` helper that uses the
   screen whose origin is (0,0) as the primary screen.

### R3. "The Haunting" transition (~3 s)
**User story:** As a user, I want starting Wailo to feel like my desktop gets haunted.
1. WHEN haunting starts THE SYSTEM SHALL run these steps in order:
   1. a short dim, or two subtle brightness flickers outside Cozy
   2. fog rolling in from the screen edges with a soft vignette
   3. the night sky fading in at 85% opacity in Cozy (the real wallpaper still shows through):
      - a purple-to-navy gradient and stars
      - a **moon positioned by the real clock** (6 pm on the left → 6 am on the right)
      - drifting clouds
      - silhouette hills with tombstones and bare trees
   4. cobwebs growing into all four corners, below the menu bar
   5. bats hanging under the menu bar
   6. the Dock Trash turning into a tombstone with "R.I.P."
   7. slime on the top edges of the front windows
   8. the ghost rising out of the tombstone and waving
2. THE SYSTEM SHALL NOT change the real system wallpaper.
3. WHEN the Dock Trash cannot be found THE SYSTEM SHALL place the tombstone at the bottom-right of the
   primary screen.
4. WHEN haunting stops THE SYSTEM SHALL sink the ghost into the tombstone, remove the decorations,
   lighten the sky to a sunrise, and fade everything out.
5. WHILE haunting THE SYSTEM SHALL let bats occasionally flap off on a loop and return (rarely in
   Cozy).
6. WHILE haunting THE SYSTEM SHALL animate slime drips stretching and dropping, one at a time, on the
   frontmost 3 windows (5 outside Cozy) whose top edge is visible. WHEN a window moves fast its slime
   SHALL splatter off, and it SHALL regrow once the window settles.
7. WHILE Boo Level is Spooky or Haunted THE SYSTEM SHALL drop leaves that pile on window top edges and
   slide off when the window is dragged.
8. WHILE Boo Level is Haunted THE SYSTEM SHALL show a soft lightning flash every 18–35 s, and never in
   Cozy.

### R4. Ghost pet (Codex-pet style)
**User story:** As a user, I want a friendly ghost that stays where I put it and shows me what Wailo
is doing.
1. THE SYSTEM SHALL draw a cute procedural ghost that bobs, blinks every few seconds, and sometimes
   yawns.
2. THE SYSTEM SHALL keep the ghost exactly where it is. **It SHALL NOT follow or chase the cursor.**
3. WHEN the user drags the ghost THE SYSTEM SHALL move it with the cursor. On release it SHALL stay
   there, clamped to the visible screen area, and save the position for the next launch.
4. WHEN the user clicks the ghost without dragging THE SYSTEM SHALL open the prompt (R5).
5. WHEN the cursor hovers over the ghost while it is idle THE SYSTEM SHALL do a giggle wiggle with a
   short "hehe" bubble, unless a bubble is already showing.
6. THE SYSTEM SHALL let clicks pass through everywhere except the ghost's body.
7. THE SYSTEM SHALL show a distinct look for each state:

   | State | Look |
   |---|---|
   | idle | bobbing, blinking, smiling |
   | listening | brighter cyan glow, 👂, wisps flowing in |
   | planning | stirring a bubbling cauldron; plan steps rise as candles |
   | searching | 🏮 lantern plus a soft light beam sweeping the screen |
   | searchingHard | 🔮 crystal ball with a purple glow (stands for the vision fallback) |
   | found | ✨, delighted face |
   | waitingForClick | 👉 nudging |
   | wrongClick | frown, head shake |
   | seance | purple glow, 🕯 |
   | success | lit candle, giggle, wiggle |
   | danger | puffed to 1.5×, frosty edge with ice spikes, ⚠️ |
   | sleeping | eyes closed, tilted, 💤 floating |

8. WHILE idle for 10 minutes (or 1 minute between midnight and 5 am) THE SYSTEM SHALL let the ghost
   doze in place. WHEN the mouse moves it SHALL wake.
9. THE SYSTEM SHALL drive states with a pure, unit-tested state machine. `danger` overrides every
   state and restores the previous one when cleared. `cancel` always returns to idle.
10. THE SYSTEM SHALL show messages in a large speech bubble next to the ghost: rounded text ≥19 pt,
    dark ink on cream, always on-screen, above the ghost or below it when there is no room.

### R5. Prompt and task routing
**User story:** As a user, I want to click the ghost and just type what I want to do.
1. WHEN the prompt opens THE SYSTEM SHALL show "What would you like to do?" with a focused text
   field, a "Go 🎃" button, a ✕ button and example suggestions. It SHALL accept typing without
   stealing focus from my app.
2. WHEN the user presses Return or Go THE SYSTEM SHALL close the prompt and route the text:

   | Text contains | Action |
   |---|---|
   | "folder" | New Folder demo |
   | "safari", "website", "wikipedia" or "browse" | Safari demo |
   | "scam" or "cursed" | cursed-page warning |
   | "mail", "letter" or "aarav" | ghost mail |
   | "grimoire" or "spell" | Grimoire |
   | anything else | Live mode (R7) |
   | empty | nothing |

3. WHEN the user presses Esc or ✕ THE SYSTEM SHALL close the prompt.

### R6. Guidance visuals
**User story:** As a user, I want to clearly see where to click next and how.
1. WHEN a guide starts THE SYSTEM SHALL put the ghost in `planning` and show a bottom-centre bar of
   **candles**, one per step: the current one flickers, finished ones stay lit, future ones are
   unlit.
2. FOR each step THE SYSTEM SHALL:
   1. put the ghost in `searching` for about 0.8 s
   2. check the Grimoire (R8) for a matching spell, then search with AX, retrying every 0.25 s
   3. escalate to `searchingHard` after 1.6 s
   4. go to the séance after about 3.6 s without a result
3. WHEN the target is found THE SYSTEM SHALL:
   1. dim the screen with a **fog spotlight** (35% in Cozy, 55% in Spooky, 60% in Haunted) that has
      a soft circular hole around the target, animated open
   2. on the **first step**, drop a **spider** from the top of the screen on a silk thread, landing
      exactly on the target's centre and swinging no more than about 4 pt
   3. on **later steps**, show a glowing orange **pumpkin ring** pulsing around the target's frame,
      with a small 🎃 on its edge
   4. loop **footprints** walking from the cursor to the target along a gentle curve (the last print
      always lands inside the target) until the user clicks
   5. show a translucent **ghost hand** acting out tap, double-tap or drag
   6. show the instruction in the bubble, with the ghost going `found` then `waitingForClick`
4. WHEN the user clicks inside the target frame (with 10 pt slack) THE SYSTEM SHALL complete the
   step. WHEN they click elsewhere (not on the ghost or bubble) THE SYSTEM SHALL show `wrongClick`
   and "Boo… not there 🙂", replay the footprints, and restore the instruction after about 1.8 s.
5. WHEN a step is instruction-only (type or key) THE SYSTEM SHALL advance when Return is pressed or
   on the Next hotkey.
6. WHEN the last step completes THE SYSTEM SHALL light all candles, burst candy-corn, bat and pumpkin
   confetti at the target, say "You did it! 🎉🍬", and return to idle after about 3.5 s.
7. THE SYSTEM SHALL show guidance on the screen that contains the target. It SHALL run at 60 fps only
   while guiding.
8. **Demo "Make a new folder in Finder"** SHALL work reliably:
   1. Dock item "Finder"
   2. menu-bar item "File" (once Finder is frontmost)
   3. "New Folder" inside the **open** menu
   4. success
9. **Demo "Open Safari and go to a website"** SHALL run:
   1. Dock item "Safari"
   2. the Safari address bar (`WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD` / text field), with the séance
      as fallback
   3. "Type wikipedia.org and press Return" (instruction-only)

### R7. Live mode (backend plans)
**User story:** As a user, I want to ask for anything, not just the demos.
1. WHEN routed to Live mode THE SYSTEM SHALL put the ghost in `planning`, then `POST /plan` with
   `{ task, platform: "macos" }` to `WAILO_BACKEND_URL`.
2. WHEN a plan is returned THE SYSTEM SHALL map:
   - `click` steps with a label (`targetLabel`, else `findDescription`) to a "smart" AX search across
     the menu bar, Dock, open menus and front-window elements
   - all other steps to instruction-only steps
   It SHALL then run them through the guidance director.
3. WHEN the backend asks a clarifying question THE SYSTEM SHALL show it in a bubble.
4. WHEN the backend is unreachable or errors THE SYSTEM SHALL say "The spirits' library is closed
   right now 🌙 Let me show you a demo instead!" and run the New Folder demo.
5. THE SYSTEM SHALL use `URLSession.shared` and a 90 s timeout.

### R8. Séance (Tap-to-Teach) and Grimoire
**User story:** As a user, when Wailo can't find something, I want to show it once so it remembers.
1. WHEN a target cannot be found THE SYSTEM SHALL enter `seance`, say "The spirits can't see it… show
   me where it is", and show a wooden **planchette** following the cursor.
2. WHEN the user clicks (not on the ghost or bubble) THE SYSTEM SHALL save a **spell** containing:
   - the app bundle ID (the step's hint, else the app of the window under the click)
   - the app name and the step text
   - the position relative to that window (0–1, top-left origin)
   - an absolute AX fallback point
   It SHALL then treat the step as done.
3. THE SYSTEM SHALL store spells in `~/Library/Application Support/Wailo/grimoire.json`. It SHALL
   never store pixels.
4. WHEN a later step matches a spell (same bundle ID, and step text equal or word-Jaccard ≥ 0.8) THE
   SYSTEM SHALL show the ghost flipping a 📖 with "I remember this one!", count the cast, and point at
   the remembered spot.
5. WHEN the user opens the Grimoire THE SYSTEM SHALL show a parchment-styled floating panel. It SHALL
   list each spell's text, app, date learned and cast count, with a Forget button, plus a friendly
   empty state.
6. WHEN the user chooses "Start Séance" from the menu THE SYSTEM SHALL let them teach a spot without a
   running demo.
7. (Optional) Sync spells with the backend: `/label/store`, and `/plan/learn` when a whole Live-mode
   plan succeeds.

### R9. Cursed page warning (scam protection)
**User story:** As a user, I want Wailo to protect me from scam pages in a way that feels caring.
1. WHEN triggered from the menu, hotkey or prompt THE SYSTEM SHALL:
   - grow frost in from all four edges, with branching ice crystals
   - add a cool tint over the screen
   - switch the ghost to `danger`
   - show a centred bubble: **"This page feels cursed 👻 Don't enter your bank details. Call your
     family first."** with big buttons **"Close this page"** and **"I trust it"**
2. WHILE "Watch Safari" is on THE SYSTEM SHALL read the front Safari URL via AX every 2 s. The URL
   SHALL stay local. WHEN it contains `kyc`, `update-pan`, `electricity-bill`, `refund` or `lottery`
   THE SYSTEM SHALL trigger the warning once per URL.
3. WHEN the user presses "Close this page" THE SYSTEM SHALL close the front Safari tab via AppleScript,
   then dismiss.
4. WHEN dismissed THE SYSTEM SHALL melt the frost, restore the ghost's previous state, and say "Phew!
   Stay safe 💜".

### R10. Cursor footprints (ambient)
1. WHILE haunting and the toggle is on THE SYSTEM SHALL leave faint lavender footprints behind the
   cursor: alternating left and right, rotated to the direction of travel, about 24 pt apart, each
   fading over about 1.2 s. There SHALL be none on the ghost.
2. THE SYSTEM SHALL track the cursor with `NSEvent.mouseLocation` and SHALL NOT require any
   permission for it.

### R11. Ghost mail (delight)
1. WHEN triggered THE SYSTEM SHALL fly a small 👻 carrying ✉️ in a curve to the pet. The pet giggles
   and shows: "💌 A letter from Grandson Aarav: 'Hi Nani! Don't forget your medicine. I'll call you on
   Sunday. Love you!'"

### R12. Boo Level, accessibility and sounds
1. THE SYSTEM SHALL default to **Cozy**: pastel purple and orange, light fog, no flicker, rare bats,
   sounds off.
2. WHILE macOS Reduce Motion is on THE SYSTEM SHALL replace drops, swings, drifts and flights with
   fades.
3. WHEN Sounds is on THE SYSTEM SHALL play only macOS system sounds (Tink, Glass, Pop, Purr,
   Submarine). No downloaded audio.
4. WHEN Boo Level or a toggle changes THE SYSTEM SHALL apply it live, without restarting.

### R13. Assets and privacy
1. THE SYSTEM SHALL load sprites from bundled PNGs (`assets/ASSETS.md`: Noto Emoji, CC BY 4.0). WHEN a
   PNG is missing it SHALL render the system emoji instead, and SHALL never crash or show a blank.
2. THE SYSTEM SHALL draw the sky, moon, hills, cobwebs, slime, fog, footprints, ring, candles,
   cauldron, planchette, frost and the ghost procedurally.
3. THE SYSTEM SHALL NOT log or send screenshots, screen text or personal data. The optional vision
   fallback (`/nova-vision`) SHALL be off by default and explained before use.

### R14. Quality
1. `swift build` and `swift test` SHALL pass after every task. No `xcodebuild`.
2. Unit tests SHALL cover:
   - coordinate conversions on a fake multi-screen layout
   - the last footprint landing inside the target
   - ghost state transitions
   - task routing
   - the cursed-URL check
   - spell text matching
   - plan parsing
   - moon position from the clock
3. Everything SHALL work across multiple monitors and Spaces.
