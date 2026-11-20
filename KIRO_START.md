# How to build Wailo with Kiro

> **Start here, then follow [KIRO_MASTER_PROMPT.md](KIRO_MASTER_PROMPT.md)** (phase-by-phase prompts) and
> [KIRO_PLAYBOOK.md](KIRO_PLAYBOOK.md) (every Kiro capability + what evidence to capture for the write-up).

This repo is set up for **spec-driven development** in Kiro. Everything Kiro needs is in `.kiro/`:

| Path | What it is |
|---|---|
| `.kiro/steering/product.md` | what Wailo is, who it's for, the ghost-pet behaviour |
| `.kiro/steering/tech.md` | stack, coordinate rules, window levels, **gotchas from the prototype**, performance budget, privacy |
| `.kiro/steering/structure.md` | folder layout and conventions |
| `.kiro/steering/backend-api.md` | the contract of the reused backend in `backend/` |
| `.kiro/specs/wailo-app/requirements.md` | R1–R14 in EARS form |
| `.kiro/specs/wailo-app/design.md` | architecture, components, data models |
| `.kiro/specs/wailo-app/tasks.md` | the step-by-step implementation plan |

## 1. Open the repo in Kiro
- **File → Open Folder → `wailo-kiro`**.
- In the Kiro panel, check that the **Steering** list shows the 4 files and **Specs** shows
  `wailo-app`.

## 2. Review the spec first (good for the judges, too)
Open `requirements.md` → `design.md` → `tasks.md` and ask Kiro to refine anything you want changed
**before** coding. For example:
> "Review the wailo-app spec against the steering files. Point out gaps or contradictions; don't write
> code yet."

## 3. Execute tasks one at a time
In `tasks.md`, click **Start task** next to **1.1**, and keep going in order. After each top-level
task:
- Kiro should run `cd app && swift build && swift test`.
- Do the "Manual check" tasks yourself: open `app/Package.swift` in Xcode and press ⌘R.
- Commit (keep the history; it shows Kiro's work).

If a task gets big, tell Kiro:
> "Implement only task 3.6 from the wailo-app spec. Follow tech.md exactly. Run swift build and
> swift test."

## 4. Agent hooks worth adding (Kiro panel → Agent Hooks → +)
Create these in Kiro's UI so they're saved under `.kiro/hooks/`:
1. **On save of `app/Sources/**/*.swift`** → "Run `swift build` in app/ and fix any compile errors."
2. **On save of `*Tests.swift` or the pure-logic files** (`CoordinateSpace`, `FootprintPath`,
   `GhostState`, `TaskRouter`, `Grimoire`) → "Run `swift test` in app/ and report failures."
3. **Manual hook "Asset audit"** → "Check every PNG in app/Sources/Wailo/Resources is listed in
   assets/ASSETS.md with source and license."
4. **Manual hook "Privacy check"** → "Scan the diff for logging of screenshots, screen text, emails or
   secrets; flag anything that violates tech.md › Privacy."

## 5. Run the backend (only needed for Live mode)
```bash
cd backend
npm install
cp .env.example .env    # fill in AI_PROVIDER + keys, DATABASE_URL (optional), etc.
npm start               # http://localhost:3000/health
```
Or point the app at your already-deployed backend: in Xcode, Edit Scheme → Run → Environment, set
`WAILO_BACKEND_URL`.

## 6. Permissions when running from Xcode
- Accessibility goes to **Xcode** (System Settings → Privacy & Security → Accessibility).
- Screen Recording isn't needed.
- Safari Automation is asked the first time you press "Close this page".

## Reference
A working prototype of the same app exists in the original Waylo repo, on branch
`kiroween/wailo-haunted-prototype` (folder `kiroween-haunted/`). The spec was written from it. Let
Kiro build from the spec rather than copying it, so the Kiro workflow is real.
