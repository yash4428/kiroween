# Delivery roadmap: Wailo macOS app

Implementation work lives in the three feature plans. Complete them in dependency order; later
features may begin once the contracts they use are available.

- [ ] 1. Build the [haunting foundation](../haunting-foundation/tasks.md), including coordinates,
  overlays, app shell, haunting, settings, assets, and privacy controls. _Req: R1–R3, R10, R12–R14_
- [ ] 2. Build the [ghost pet](../ghost-pet/tasks.md), including the state machine, pet panel,
  bubble/prompt, and task router. _Req: R4–R5, R14_
- [ ] 3. Build [guidance and safety](../guidance-and-safety/tasks.md), including demos, live plans,
  Grimoire/séance, cursed-page protection, and mail. _Req: R6–R9, R11, R13.3, R14_
- [ ] 4. Run the cross-feature build, test, privacy, display/Spaces, accessibility, and CPU acceptance
  checks. Record manual results in the README with hardware and macOS context. _Req: R12.2, R12.5,
  R13.3–R13.5, R14.1–R14.4_

Rules for each implementation task:

- Read and follow `.kiro/steering/*` and the relevant feature spec.
- Treat `backend/` as read-only.
- Run `swift build && swift test` in `app/` after each implementation task.
- Never run `xcodebuild`.
- Do not commit unless the user asks for a commit.
