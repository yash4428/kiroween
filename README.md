# Wailo 👻 — a haunted guide for your grandparents' Mac (Kiroween 2026)

Wailo turns the macOS desktop into a cozy-spooky night scene and adds a friendly ghost pet. It helps
elderly users do things on their computer: a spider on a silk thread drops onto the button to click,
a fog spotlight and glowing footprints lead the eye, and frost warns about scam pages. Every spooky
effect does a job.

> 🚧 Being built spec-first with **Kiro**. Start with [KIRO_START.md](KIRO_START.md).

## Repo layout
- `app/` — the macOS app (Swift Package), built from scratch with Kiro (`.kiro/specs/wailo-app`)
- `backend/` — the existing Waylo backend (Node/Express + Bedrock/Gemini + Postgres/pgvector),
  reused for task plans. See `.kiro/steering/backend-api.md`.
- `assets/` — free-licensed art (Noto Emoji, CC BY 4.0). See `assets/ASSETS.md`.
- `.kiro/` — steering, specs and hooks. **Part of the submission; don't gitignore it.**

## Credits
- Emoji art: Noto Emoji by Google (CC BY 4.0).
- Built on Waylo.
