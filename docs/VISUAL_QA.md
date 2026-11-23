# Wailo visual QA through `wailo-devtools` MCP

Run locally on macOS 26.2 using the official MCP SDK stdio server. All screenshots and logs remained
under `/tmp/wailo-devtools/`; nothing was uploaded. Haunted mode was used for pumpkin checks and the
saved setting was restored to Cozy afterward.

## Results

| Check | Result | Evidence |
|---|---|---|
| 1. Maximized-window exclusion and Trash tombstone alignment | **PASS** | Screenshot: `/tmp/wailo-devtools/screenshot-1795343955404.png`. No slime or landed pumpkin appeared on the maximized front window. Debug: `tombstone frame=(1384.9,10.0,66.6,82.6) foundInDock=true`. `dock_items` returned Bin/Trash AX frame `(1384.8995,889.4498,66.5502,82.5502)`; with primary height 982 this converts to Cocoa y=10.0 and overlaps the logged tombstone. Dock JSON: `/tmp/wailo-devtools/dock-items.json`. |
| 2. Throwaway-window tracking | **PASS** | Before/during/after: `/tmp/wailo-devtools/screenshot-1795419526591.png`, `/tmp/wailo-devtools/screenshot-1795419527645.png`, `/tmp/wailo-devtools/screenshot-1795419529290.png`. The green slime edge and title-bar pumpkins are visible on the helper window. During glide, pumpkin `3A091EA8…` relanded as its tracked title-bar x changed from 362.3 to 516.2, 679.5 and 1046.0; decorations remained tied to window ID 153607. |
| 3. Synthetic drag into pumpkin bin | **PASS** | A fresh landing was logged at `(784.8,630.0)` on helper window 153607. `synthetic_drag` moved it to tombstone center `(1418.2,51.3)` and returned `{ "ok": true }`; burial count changed from 1 to 2. Synthetic input remained gated by `WAILO_DEVTOOLS_ALLOW_INPUT=1`. |
| 4. Eight-second title and two-second Dock expiry | **PASS** | Title pumpkin `3A091EA8…` last landed at 13:08:59.175 and vanished idle at 13:09:07.243: **8.068 s**. Dock pumpkin `F5D4A3A5…` docked at 12:54:44.991 and vanished at 12:54:47.024: **2.033 s**. `7A1D8AB1…` measured **2.032 s**. A new privacy-safe `pumpkin docked` debug event was added because a vanished event alone could not prove when the two-second interval started. |
| 5. Finder autodemo target | **PASS** | Screenshot: `/tmp/wailo-devtools/screenshot-1795419406994.png`. It shows the Finder Dock icon surrounded by the haunted glow, a peeking marker/spider thread, guide footprints, candles, ghost and instruction bubble. Debug emitted one, not two, `guide step=0 target=(63.6,10.0,69.6,85.6)` event and `dock target haunted bundleID=com.apple.finder`. |
| 6. Ten-second idle CPU sample | **RECORDED** | After a fresh Cozy launch and 30-second settle: samples `[0.6,0.6,0.7,0.6,0.7,0.6,0.7,0.7,0.8,0.6]`; arithmetic mean **0.66%**. Raw MCP result: `/tmp/wailo-devtools/check6-cpu.json`. This is a measurement on this machine, not a portable performance guarantee. |

## Failures found and fixed

- **Duplicate target presentation:** the first Finder search race allowed the initial delayed lookup
  and repeating timer to present the same target twice. The R6 search acceptance criteria now state
  first-valid-target wins per generation. `GuidanceDirector` guards both search and presentation;
  re-verification logged exactly one guide presentation.
- **Stale helper binary:** the MCP originally reused the Swift helper without comparing source mtime.
  It now recompiles when its source is newer.
- **Test-window lifetime:** `NSApplication.delegate` is weak. The helper now wraps the run loop in
  `withExtendedLifetime`, keeping the throwaway window alive.
- **Test-window observability:** the helper is a regular layer-zero window so Wailo tracks it, uses a
  wide but non-full-screen frame, and uses bounded glide coordinates.
- **Synthetic drag hover gate:** pumpkin panels correctly ignore input until hover. The helper now
  posts a mouse-move and waits 180 ms before mouse-down, allowing Wailo's hover poll to enable only
  that nonactivating pumpkin panel.
- **Dock expiry evidence:** debug logging gained a typed `pumpkin docked` event. It contains only UUID
  and coordinates and allows the two-second interval to be measured.

## Cleanup

`quit_wailo` and `test_window(close)` were called at the end of the run. Wailo's saved Boo Level was
restored to Cozy. Runtime files remain in `/tmp/wailo-devtools/` for local judging evidence and are
not committed.
