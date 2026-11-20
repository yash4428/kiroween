# Repo structure

```
.kiro/
  steering/      product.md · tech.md · structure.md · backend-api.md
  specs/wailo-app/  requirements.md · design.md · tasks.md
app/                         ← macOS app, built from scratch (Swift Package)
  Package.swift
  Sources/Wailo/
    App/        WailoApp.swift (entry + AppDelegate) · MenuBarController.swift · HotKeys.swift · Settings.swift
    Overlay/    CoordinateSpace.swift · OverlayWindowManager.swift (PassThroughWindow, EffectsScene, ScreenOverlay)
    Haunting/   HauntingController.swift · NightSkyScene.swift · Cobwebs.swift · Bats.swift
                TombstoneTrash.swift · SlimeDrips.swift · FallingLeaves.swift · EdgeFog.swift
    Pet/        GhostPet.swift · GhostState.swift · GhostView.swift · SpeechBubble.swift
    Cursor/     CursorFootprints.swift
    Guidance/   GuidanceDirector.swift · DemoScripts.swift · TaskRouter.swift · LiveMode.swift
                SpiderPointer.swift · PumpkinRing.swift · FootprintPath.swift · FogSpotlight.swift
                GhostHand.swift · CandleProgress.swift · Confetti.swift
    Safety/     CursedPageWarning.swift
    Seance/     SeanceMode.swift · Grimoire.swift
    Mail/       GhostMail.swift
    Services/   AXFinder.swift · DockLocator.swift · WindowTracker.swift · BackendClient.swift
    Assets/     AssetLoader.swift (Sprite enum + emoji fallback)
    Resources/  *.png (copied from /assets)
  Tests/WailoTests/
assets/         ← licensed source art (Noto Emoji PNGs) + ASSETS.md
backend/        ← existing Waylo backend (reused, Node/Express) — see backend-api.md
README.md · KIRO_START.md · LICENSE
```

## Conventions
- One responsibility per file. Singletons (`static let shared`) are fine for app-wide controllers.
- Pure logic (coordinates, footprint path, state machine, task router, URL check, text match, plan
  parse) has **no AppKit state**, so it is unit-testable.
- Every visual effect lives in its own small type with `init(scene:…)` and `remove()`.
- Name sprites through the `Sprite` enum. Each case has a PNG name and an emoji fallback.
- Settings live in `UserDefaults` under the `wailo.` prefix and post `Settings.changed`.
