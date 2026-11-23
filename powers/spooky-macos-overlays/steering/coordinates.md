# General macOS overlay coordinates

- Keep every conversion in pure functions that receive display frames as values.
- Identify the primary display by Cocoa frame origin `(0,0)`, not `NSScreen.main`.
- AX, CoreGraphics, and CGWindowList use top-left global coordinates; AppKit uses bottom-left.
- Convert points with `cocoaY = primaryHeight - axY`; convert rectangles with source `maxY`.
- Convert global Cocoa to scene-local coordinates by subtracting the selected display origin.
- Test negative display origins, a display above primary, off-screen nearest selection, points,
  rectangles, and round trips with a floating-point tolerance.
- Validate normalized or model-provided rectangles before conversion and keep accepted targets on the
  selected display.
