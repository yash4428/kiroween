# Tech rules

These rules were learned the hard way in a working prototype. Follow them.

## Stack
- **App:** a Swift Package in `app/` (`swift-tools-version:5.9`, macOS 14+).
  - Executable target `Wailo` with `resources: [.process("Resources")]`, plus test target
    `WailoTests`.
  - Run by opening `app/Package.swift` in Xcode and pressing ⌘R.
  - Check with `swift build` and `swift test` inside `app/`. **Never run `xcodebuild`.**
  - AppKit + **SpriteKit** (particles and sprites) + **Core Animation** (spotlight, ghost) +
    **SwiftUI** (bubbles and panels only).
  - Run as an accessory app: `NSApplication.shared.setActivationPolicy(.accessory)`. A 🎃 menu bar
    item, no Dock icon.
  - Global hotkeys via **Carbon `RegisterEventHotKey`**, which needs no permission.
  - Networking: `URLSession.shared` only, **never create a new URLSession**.
- **Backend:** `backend/` is the existing Node/Express Waylo server (Bedrock or Gemini, Postgres with
  pgvector). Treat it as **read-only and reused**. The contract is in `backend-api.md`. Only change it
  if a task explicitly says so.

## Coordinates (the #1 source of bugs)
- All conversions live in **one** file, `CoordinateSpace.swift`, built from **pure functions that
  take screen frames as input** so they can be unit-tested with fake multi-monitor layouts.
- The primary screen is `NSScreen.screens.first { $0.frame.origin == .zero }`, **never
  `NSScreen.main`**.
- AX, CoreGraphics and `CGWindowList` use a **top-left** origin. AppKit uses **bottom-left**. Flip Y
  with the **primary** screen's height: `cocoaY = primaryHeight - axY`. For rects use `maxY`.
- Overlay scenes use **local** coordinates: global Cocoa minus that screen's `frame.origin`.
- Apple Vision normalized rects need a Y flip. YOLO-style normalized rects do not. The backend's
  `/nova-vision` bbox is `[xMin, yMin, xMax, yMax]` on a **0–1000 scale, top-left origin**.

## Windows (one set per screen, rebuilt on `NSApplication.didChangeScreenParametersNotification`)

| Window | Level | Contents |
|---|---|---|
| Ambience | `CGWindowLevelForKey(.desktopWindow) + 1` | Night sky. Above the wallpaper, **below desktop icons**. |
| Decor | `.statusBar` | Slime, leaves, bats, cobwebs, tombstone, fog. **Below open menus**, so it never covers a menu. |
| Effects | `CGWindowLevelForKey(.screenSaverWindow)` | Spotlight, spider, ring, footprints, hand, candles, frost. **Above menus**, so the spider can land on a menu item. |
| Ghost panel | `screenSaver + 1` | The ghost |
| Bubble panel | `screenSaver + 2` | Speech bubbles and the prompt |

- Every overlay window: borderless, `backgroundColor = .clear`, `isOpaque = false`,
  `hasShadow = false`, `ignoresMouseEvents = true`, `collectionBehavior = [.canJoinAllSpaces,
  .stationary, .fullScreenAuxiliary, .ignoresCycle]`, and `canBecomeKey/Main = false`.
- **Clicks must always reach the apps underneath.** The ghost panel catches the mouse **only while
  the cursor is over the ghost's body**: toggle `ignoresMouseEvents` from a tick. A bubble catches
  the mouse only when it has buttons or a text field.

## Gotchas that already bit us
1. `NSPanel.isFloatingPanel = true` **resets `level` to `.floating` (3)**. Set it **before**
   `level`.
2. `NSHostingView` resizes its window by default (a bubble with buttons grew to 1,899 pt and drew
   off-screen). Read `host.fittingSize` **first**, then set `host.sizingOptions = []`. Setting it
   first makes `fittingSize` zero.
3. `Bundle.module` calls `fatalError` if the resource bundle is missing. Locate
   `Wailo_Wailo.bundle` next to the executable or in `Bundle.main.resourceURL`, and fall back to
   rendering the **system emoji** into an `NSImage`.
4. A typing prompt needs an `NSPanel` with `.nonactivatingPanel`, `canBecomeKey = true` and
   `makeKeyAndOrderFront`. Then the user can type without Wailo stealing app focus.
5. **Never call `NSApp.hide`.** It hides the overlays too.
6. Swift can't destructure a tuple in `if let`/`guard let` (`if let (a, b) = opt` doesn't compile).
   Bind the tuple first.
7. When an intro animation schedules "go back to X later", check the mode hasn't changed since. A
   stale timer once yanked the ghost away from a warning.

## Performance budget (idle CPU target < 5% on one screen)
- Each `SKView` **pauses itself** when no node has actions or emitters. Call `scene.wake()` after
  any change made outside an SKAction, and stay awake for at least one check interval after waking.
- **Flatten static art** (sky gradient, stars, hills, trees, cobwebs) into one texture with
  `SKView.texture(from:crop:)`. Shape nodes are expensive to re-render every frame.
- Frame rates: sky 20 fps, decor and effects 30 fps, and 60 fps only while guiding.
- Drive ambient life (slime drips, bat flights, leaves) from **timers that start short actions**,
  not `repeatForever` loops, so scenes can sleep.
- Remove particle emitters once the fog roll-in finishes (set birth rate 0, then remove).
- The prototype measured ~9–13% idle CPU. Beat it: drift clouds with Core Animation, and only poll
  the mouse at 60 Hz while dragging or guiding.

## Permissions
- **Accessibility:** AX element finding, the Dock Trash position, the Return-key watch on "type"
  steps, and reading the Safari URL. When run from Xcode, **the grant belongs to Xcode**. Prompt via
  `AXIsProcessTrustedWithOptions`.
- **Screen Recording: not needed** by default. Only window **bounds** from
  `CGWindowListCopyWindowInfo` are used. Only the optional vision fallback (screenshot to
  `/nova-vision`) needs it, and it is **off by default**.
- **Automation (Safari):** only for the "Close this page" button (AppleScript).

## Privacy and safety
- Never log screenshots, raw screen text, emails or other personal data. Logs may contain the task
  category and app bundle ID only.
- The Grimoire stores only the app bundle ID, app name, step text, and the click position relative to
  the window (plus an absolute fallback). No pixels.
- No secrets in code. The backend URL comes from the `WAILO_BACKEND_URL` env var (default
  `http://localhost:3000`). Backend secrets live in `backend/.env`, which is gitignored.

## Testing
- Pure logic goes in small types with XCTest coverage:
  - coordinate conversions (fake multi-screen layouts, including a screen *above* the primary)
  - footprint path: the last print always lands inside the target
  - ghost state-machine transitions, including the danger override and restore
  - task routing
  - scam-URL keyword check
  - Grimoire text matching
  - plan parsing (with markdown fences)
- After every task: `swift build` then `swift test` must pass.
