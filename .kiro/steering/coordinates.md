---
inclusion: fileMatch
fileMatchPattern: ["app/Sources/Wailo/Overlay/**", "app/Sources/Wailo/Services/AX*", "app/Sources/Wailo/Guidance/**", "app/Sources/Wailo/Haunting/HauntingV2Logic.swift"]
---
# Coordinate rules

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
