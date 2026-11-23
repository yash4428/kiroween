---
inclusion: always
---
# Privacy and trust boundary

## Privacy and safety
- Never log screenshots, raw screen text, emails or other personal data. Logs may contain the task
  category and app bundle ID only.
- The Grimoire stores only the app bundle ID, app name, step text, and the click position relative to
  the window (plus an absolute fallback). No pixels.
- No secrets in code. The backend URL comes from the `WAILO_BACKEND_URL` env var (default
  `http://localhost:3000`). Backend secrets live in `backend/.env`, which is gitignored.

## Always-on additions
- App-runtime screenshots exist in memory only for the duration of one explicitly consented vision
  request; never persist or log their bytes.
- The explicitly invoked local `wailo-devtools` QA screenshot tool may write only below
  `/tmp/wailo-devtools/`, return the image to the requesting Kiro session, and never upload or commit
  it. Do not invoke or auto-log it outside a declared visual-QA run.
- Never log raw screen text, AX values, window titles, URLs or email content. During an explicitly
  invoked local QA run, `ax_dump` may return bounded role/title/description/frame metadata for the
  caller-selected bundle, but it must never read text-field values, exceed 1,500 nodes, write that
  output to repository files, or send it over the network.
- Network calls go only to `WAILO_BACKEND_URL`.
- Treat `backend/` as read-only unless the user explicitly requests a backend change.
