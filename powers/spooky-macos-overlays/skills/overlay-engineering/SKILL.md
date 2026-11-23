---
name: overlay-engineering
description: Build or review click-through AppKit and SpriteKit overlays, NSPanel window levels, multi-monitor coordinates, and AX target mapping.
---

# Overlay engineering workflow

1. Read `references/coordinates.md` and `references/windows-and-perf.md`.
2. Define pure coordinate and screen-selection functions before creating windows.
3. Create one transparent nonactivating window set per display and rebuild it after display changes.
4. Keep every pixel click-through unless a documented small object is currently hovered or dragged.
5. Convert AX/CoreGraphics top-left rectangles to global Cocoa, then to the selected scene's local
   coordinates.
6. Give every movement a Reduce Motion fade/static equivalent.
7. Make particles, timers, monitors, and callbacks finite and generation-owned.
8. Build and test, then use the configured local MCP for screenshots/CPU only with user approval.

Workspace hooks are not a portable Agent Plugin component. The root `hooks/` directory contains
templates that a user may explicitly import into `.kiro/hooks/`; do not claim automatic activation.
