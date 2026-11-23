# General overlay windows and performance

- Use borderless transparent nonactivating `NSPanel` windows with no shadow.
- Set `isFloatingPanel` before assigning the final window level because it can reset the level.
- Use `.canJoinAllSpaces`, `.stationary`, `.fullScreenAuxiliary`, and `.ignoresCycle`.
- Keep overlays click-through. Toggle mouse handling only for the smallest documented hovered or
  dragged object and return to pass-through immediately.
- Put ambience below desktop icons, decor below menus, guide effects above menus, and interactive
  mascot/bubbles above effects.
- Rebuild one window set per display after screen-parameter changes without replaying introductions.
- Measure `NSHostingView.fittingSize` before setting `sizingOptions = []`.
- Never call `NSApp.hide`; order owned windows out explicitly.
- Pause SpriteKit scenes with no actions or emitters, remove finite emitters, and wake scenes after
  external mutations.
- Prefer flattened static art and timer-started finite actions over permanent repeat loops.
- Provide Reduce Motion fades/static states and invalidate every timer, monitor, network callback, and
  animation by ownership generation.
