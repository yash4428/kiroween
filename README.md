# Wailo 👻

Wailo is a cozy haunted macOS guide for elderly and non-technical users, built for the Kiroween 2026
Costume Contest. A leaning white, purple-glow mascot explains tasks while a spotlight, haunted Dock
icon, spider, pumpkin ring, footprints, hand, and candles point to the next control. Interactive
pumpkins fall onto window title bars, can be grabbed and thrown, and curve into an R.I.P. bin drawn
on the Dock Trash. Frost warns about likely scam pages.

Every spooky effect has a job. Cozy mode has gentle motion, large text, warm colors, no jump scares,
and sounds off by default.

## Run the macOS app

Requirements: macOS 14+, Xcode with Swift 5.9 or newer.

1. Open `app/Package.swift` in Xcode.
2. Select the `Wailo` executable scheme.
3. Press ⌘R.

From Terminal, validation commands are:

```sh
cd app
swift build
swift test
```

Do not use `xcodebuild` for this package.

Wailo runs as an accessory app. It has a 🎃 menu-bar item and no Dock icon. On first launch, the
haunting begins automatically.

## Permissions

- **Accessibility:** lets Wailo find controls, inspect the Dock and open menus, observe Return during
  instruction steps, and read the front Safari URL when Watch Safari is enabled. If Wailo runs from
  Xcode, macOS grants this permission to **Xcode**. Without it, ambience, the ghost, prompt, backend
  planning, Next, and manual teaching still work.
- **Screen Recording:** not needed by default. It is requested only after the user explicitly enables
  Vision fallback and a local control search fails. One screenshot of the target display is sent to
  the configured backend and is never written to disk.
- **Automation for Safari:** requested only if “Close this page” needs to close the current Safari
  tab. If denied, Wailo keeps the warning visible and explains how to press ⌘W manually.

## Things to try

- Click or drag the ghost. It stays at the saved position and never chases the cursor. If
  `app/Sources/Wailo/Resources/kiro-logo.png` exists, Wailo uses it as the mascot; otherwise it draws
  the mouthless eye-expressive mascot in code.
- In Spooky or Haunted mode, grab and throw the small pumpkins. Land them on a title bar or bury them
  in the R.I.P. Trash bin.
- Shake the pointer left and right to call up its lantern.
- Stay in an app for six seconds to see Wailo’s contextual help suggestion. It will not interrupt a
  guide and will not repeat for that app for 15 minutes.
- Ask for “Make a new folder” or “Open Wikipedia in Safari.” The required Dock app glows, wobbles,
  and gets a peeking ghost while Wailo waits for it to become active.
- Ask for another task while the existing backend is running to use Live mode.
- Trigger **Simulate Cursed Page** to see the safety warning.
- Start a **Séance**, teach a target, and inspect it in the **Grimoire**.
- Switch Boo Level between Cozy, Spooky, and Haunted.
- Turn on Reduce Motion in macOS to see fade-based alternatives.

## Global hotkeys

| Shortcut | Action |
|---|---|
| ⌃⌥H | Start or stop haunting |
| ⌃⌥L | Open the prompt |
| ⌃⌥D | New Folder demo |
| ⌃⌥F | Safari demo |
| ⌃⌥N | Next step |
| ⌃⌥S | Show or dismiss the cursed-page warning |
| ⌃⌥G | Cycle the ghost’s visual state |
| ⌃⌥M | Deliver ghost mail |
| ⌃⌥Esc | Stop guidance |

For hands-free recording, set `WAILO_AUTODEMO` to `folder`, `safari`, `cursed`, or `prompt`.

## Existing backend

The Node/Express backend in `backend/` is reused unchanged. To run it locally:

```sh
cd backend
npm install
cp .env.example .env
# Fill in backend credentials, then:
npm start
```

The app reads `WAILO_BACKEND_URL`, defaulting to `http://localhost:3000`. Normal plans send only the
user-submitted task and `platform: "macos"`. Wailo has no analytics and makes no other network calls.

## Repository layout

- `app/` — macOS Swift Package and XCTest suite
- `backend/` — existing Waylo backend, reused without modification
- `assets/` — licensed source artwork and attribution
- `.kiro/steering/` — product, technical, structure, and backend rules
- `.kiro/specs/` — overview plus the haunting-foundation, ghost-pet, and guidance-and-safety specs

## How Kiro was used

Wailo was built spec-first with Kiro. Steering captured product and platform constraints. The initial
spec was critiqued, split into three traceable feature specs, and expanded with property-based
correctness criteria before implementation. The implementation plan and tests trace back to those
requirement IDs.

## Assets and credits

Emoji artwork is **Noto Emoji by Google, CC BY 4.0**. Source URLs and per-file details are in
[`assets/ASSETS.md`](assets/ASSETS.md). The ghost, sky, moon, hills, cobwebs, slime, fog, footprints,
rings, candles, cauldron, planchette, frost, and other main effects are drawn procedurally. Wailo
bundles no downloaded music or audio.

Built on the Waylo idea.
