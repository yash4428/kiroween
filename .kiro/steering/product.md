---
inclusion: always
---
# Product: Wailo 👻

Wailo is a Halloween ("Kiroween") macOS app built on the **Waylo** idea: a menu-bar assistant that
guides **elderly and non-technical users** through computer tasks by pointing at the right thing on
screen and telling them what to do.

The macOS app in `app/` is built **from scratch in this repo**. The backend in `backend/` is the
existing, working Waylo backend (Node/Express). It is reused as-is, so don't rewrite it.

## The feeling
When Wailo starts, the whole desktop turns into a **cozy-spooky night scene**, and a friendly
**ghost pet** lives on the screen like a desktop pet. **Every spooky effect does a job**. Nothing is
decoration only:
- **The ghost's look shows what Wailo is doing**: listening, planning (stirring a cauldron),
  searching (lantern), searching hard (crystal ball = vision-model fallback), found, waiting for a
  click, wrong click, séance (can't find it), success, danger, sleeping.
- **Guidance** draws the eye to the next click: a fog spotlight with a hole, a spider dropping on a
  silk thread, a pumpkin ring, glowing footprints walking from the cursor, a ghost hand showing the
  action, and candles for progress.
- **Protection**: frost creeps in and the ghost puffs up to warn about scam pages.
- **Teaching**: a séance lets the user show Wailo where something is. It is saved as a spell in the
  Grimoire, and next time the ghost "flips to the page" and goes straight there.

## The ghost is a desktop pet (like a Codex pet)
- It **stays exactly where the user drags it**, and the position is remembered between launches.
  **It never follows or chases the cursor.**
- **Clicking the ghost opens a prompt** ("What would you like to do?") to type a request. This is
  the app's main input; there is no notch UI.
- Known tasks run built-in, offline demos. Any other request is sent to the backend's `POST /plan`
  and guided step by step (Live mode).

## Users and tone
- Elderly people come first. The default **Boo Level is Cozy**: friendly ghosts, no jump scares,
  gentle motion, strong contrast, text ≥18 pt, big buttons, warm wording.
- **Spooky** (darker, more bats, falling leaves) and **Haunted** (adds lightning) are opt-in.
- Always respect macOS **Reduce Motion** by replacing movement with fades.

## Non-goals
- Never change the real wallpaper, recolour other apps' pixels, or record the screen by default.
- No copyrighted characters, brand logos or music. Assets must be free and listed in
  `assets/ASSETS.md`.
- No analytics. Network calls go only to the configured Waylo backend.

## Hackathon
Kiroween 2026, **Costume Contest** category: a polished, unforgettable haunted UI. The repo is open
source, and the `.kiro/` folder (steering, specs, hooks) is part of the submission, so never
gitignore it.
