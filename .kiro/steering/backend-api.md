---
inclusion: fileMatch
fileMatchPattern: ["**/BackendClient.swift", "**/LiveMode.swift"]
---
# Backend API contract (existing Waylo backend in `backend/`)

The app talks to the backend over HTTP JSON at `WAILO_BACKEND_URL` (default `http://localhost:3000`).
Run it locally with `cd backend && npm install && cp .env.example .env` (fill in the values), then
`npm start`.

Rate limits are per IP: **120 requests/min overall**, and **20/min on `/plan`**.

## GET /health
→ `200 { "status": "ok", "timestamp": ISO8601 }`

## POST /plan — task → steps (used by Live mode)
Request:
```json
{ "task": "make a new folder on my desktop", "platform": "macos",
  "screenContext": "optional compact AX snapshot", "sessionContext": "optional (≤1200 chars)",
  "userContext": "optional note (≤400 chars)", "userEmail": "optional" }
```
Response `200`:
```json
{ "task": "...", "app": "Finder", "cached": true,
  "steps": [ { "index": 1, "instruction": "Click File in the menu bar",
               "targetLabel": "File", "findDescription": "File menu in the menu bar",
               "elementDescription": "...", "action": "click|type|key|info", "key": "return",
               "screenRegion": "menuBar|toolbar|dialog|...", "targetType": "text|icon",
               "controlKind": "button|menuItem|...", "accessibleName": "", "awaitURL": "" } ] }
```
- `cached` is present only when the plan came from the semantic plan cache.
- Parse **leniently**: the body may be wrapped in markdown fences, and fields may be missing. Default
  `action` is `click`.
- Errors:
  - `400` when the task is missing
  - `402 { code: "limit_reached", details }` when a free-tier user is out of tasks (only when
    `userEmail` is sent)
  - `429` when quota or rate limited
  - `502` when no steps could be produced
  - Other errors: `{ error, details }`. Show `details` in a friendly bubble.
- Some deployments (the Genkit variant) may return `{ "clarify": { "prompt", "options": [] } }`.
  Show the question in a bubble.

## POST /plan/learn — remember a plan that worked (user said "that worked")
`{ task, platform: "macos", app, steps }` → `202 { accepted }`

## POST /plan/forget — forget a bad cached plan
`{ task, platform: "macos" }` → `202`

## POST /label/lookup — step-label cache (fleet-wide memory of AX labels)
`{ appName, stepDescription }` → `{ found: true, axLabel }` or `{ found: false }`.
The app name is currently ignored server-side.

## POST /label/store — save a label that worked
`{ appName, stepDescription, axLabel }` → `202 { accepted: true }` (fire-and-forget)

## POST /nova-vision — vision fallback (the 🔮 crystal ball). OPTIONAL, off by default.
Request: `{ image_base64, target_label, step_instruction?, ocr_context?, high_accuracy? }`. The image
is a screenshot and **needs Screen Recording permission**.

Response: `{ found, bbox: [xMin,yMin,xMax,yMax], confidence, container, hint }`
- `bbox` is on a **0–1000 scale, top-left origin**, relative to the image.
- Map it with `x = screen.minX + (xMin+xMax)/2000 * width`, and
  `cocoaY = screen.maxY - (yMin+yMax)/2000 * height`.
- Reject results with `confidence < 0.55`.

## POST /recover — self-healing when a step can't be found (needs a screenshot)
`{ screenshot, task, instruction, targetLabel, stepIndex, totalSteps, userMessage? }` →
`{ replan: Bool, visibleLabel, scrollDirection, instruction, steps: [] }`

## GET /config — remote config
→ `{ maxAccuracy, novaMinConfidence, voiceEngine, ... }` from `backend/app-config.json`.

## POST /tts — Google Cloud TTS (off unless `voiceEngine == "google"`)

## Not used by Wailo
`/qa`, `/ask-screen`, `/pick-*`, `/act*`, `/icon/*`, `/curriculum`, `/register`, `/me`, `/upgrade`,
`/guide`, `/failure`, `/admin/*`, `/detect-elements` (YOLO).

## Privacy rule for the app
Only `/nova-vision` and `/recover` send pixels. They must stay behind a setting that is **off by
default**, with a clear explanation, because the users are elderly people.
