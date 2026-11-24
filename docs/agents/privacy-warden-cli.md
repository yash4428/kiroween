I'll start by mapping the repo and searching for the main sinks.
Next I'll check the vision call site, the Grimoire, the tooling directories and secrets.
# Wailo privacy audit

Scope: `app/Sources`, `tools/wailo-devtools-mcp`, `scripts/hooks`, `.kiro/hooks` and `.kiro/settings`, `powers/`, `.gitignore`, `docs/`. I read `backend/` for logging only. I changed no files, and no secret values appear here.

I reviewed the logging, vision, URL and AX code paths in full. I did not run the app or the tests, and I did not inspect git history.

## Confirmed findings

**No confirmed leak of screenshots, AX values, window titles, URLs, email content or secrets was found in the app.** These are the confirmed policy deviations:

| # | Sev | Location | Data | Path | Rule | Fix |
|---|---|---|---|---|---|---|
| C1 | Medium | `.kiro/settings/mcp.json:6-9` | Synthetic input enablement, plus the absolute home path (`/Users/<name>/…`) at lines 5 and 7 | The committed workspace MCP config sets `WAILO_DEVTOOLS_ALLOW_INPUT=1`. Every session therefore has the synthetic-drag gate open (`index.ts` `synthetic_drag`). The config is not gitignored and ships with the repo. | privacy.md: the QA tool is "explicitly invoked", and T4.3 requires input to be refused unless explicitly enabled | Remove the `ALLOW_INPUT` line from the committed file. Set it per QA run, or use a gitignored override. Use `${workspaceFolder}` or a relative path instead of the absolute path. |
| C2 | Medium | `scripts/hooks/privacy_guard.py:12-15` | Any write that bypasses the guard | The guard only inspects tool names containing `write`, `str_replace`, `strreplace`, `bash` or `execute_bash`. A tool such as `fsAppend` does not match, so it exits 0. This is inferred from the name filter. I did not run the tool. | T2.3 (deny before file-writing tools) | Invert the check: inspect every tool except an explicit read-only allowlist. |
| C3 | Low-Med | `scripts/hooks/privacy_guard.py:48-55` | Log calls the guard cannot see | The `logging` regex matches `nslog(`, `print(`, `os_log(` and `logger.x(` / `log.x(`. It misses `debugPrint(` (no `\b` before `print` in `debugprint`), `dump(`, `fputs(` and `FileHandle.standardError.write`. | T2.3 | Add `debugprint`, `dump`, `fputs` and `standardError` to the pattern. Add deny fixtures for them. |
| C4 | Low | `scripts/hooks/privacy_guard.py:7-10` | Guard failure mode | If the hook payload cannot be parsed as JSON, the guard exits 0 and allows the write (fail-open). | Least privilege, and "when in doubt, do less" | Exit 2 on a parse error for write-capable tools. |
| C5 | Low | MCP `screenshot` tool (`index.ts`, `registerTool("screenshot")`) and `/tmp/wailo-devtools` (`index.ts:11`) | Full-screen PNGs | Files go to `/tmp/wailo-devtools/screenshot-<ts>.png`. The path is correct. Nothing deletes them, and the directory is created with default permissions (`mkdir`, no mode). Other local users may be able to read them. | privacy.md: the QA tool may write only below `/tmp/wailo-devtools/` | Create the directory with mode `0o700` and write files with `0o600`. Delete old captures when a run starts. |

## Risks

| # | Sev | Location | Concern | Fix |
|---|---|---|---|---|
| R1 | Medium | `BackendClient.swift:40-44` (the `validOrigin` helper just below it) and `VisionService.swift:28-30` | `WAILO_BACKEND_URL` accepts any `http` or `https` host. If it points at a remote host over plain `http`, typed tasks and the vision screenshot cross the network in cleartext. The rule restricts calls to this variable but does not require HTTPS. | Require `https` unless the host is loopback (`localhost`, `127.0.0.1`, `::1`). |
| R2 | Medium | `backend/index.js:225,249,254,275`; `backend/semanticPlanCache.js:231` | The backend logs full user task text (`Plan requested: ${task}`). The user types tasks, so they could contain names, addresses or other personal data. This is outside the app's own logging rule, and `backend/` is read-only. | Raise it with the backend owner: log only the language, a hash or the length. |
| R3 | Low | `VisionService.swift:41-44`, backend `/nova-vision` | The screenshot leaves the machine for the backend, which forwards it to a model provider. This is consented and off by default, but the consent dialog (`MenuBarController.swift:105`) says only "your configured Wailo backend". It does not mention the AI provider behind it. I did not trace `/nova-vision` to confirm the provider call. | Add "and its AI provider" to the dialog text. |
| R4 | Low | `index.ts:52-56` | `launch_wailo` merges the full `process.env` into the child process. The child's stdout and stderr go to `/tmp/wailo-devtools/wailo.log`. Non-`WAILO` stderr (AppKit warnings, crash text) is captured with it. It is returned through `log_tail`, and `log_tail` is not limited to `WAILO ` lines. | Pass only `WAILO_*` and `PATH`. Have `log_tail` return only lines that start with `WAILO `. |
| R5 | Low | `helpers/wailo-helper.swift:34-35`, `dock_items` | `ax_dump` returns titles and descriptions (200 characters each, 1,500 nodes) for any bundle the caller names. Titles of browsers or mail clients can contain subjects, URLs or recipient names. This is allowed for explicit QA runs. It goes into the Kiro session transcript. | State in the README that `ax_dump` must not target mail or browser bundles. Optionally refuse a short denylist of those bundles. |
| R6 | Low | MCP `grimoire_read` (`index.ts`) | Returns the full Grimoire JSON, including `stepText`, `appName` and timestamps, to the session. | Return `bundleID`, counts and coordinates only. |
| R7 | Low | `Grimoire.swift:4-17`, `:192` | `Spell` stores `id`, `createdAt` and `timesCast` in addition to the five allowed field groups. `stepText` comes from a backend plan label, so it can echo user task wording. All of it is local, with no pixels, and the file is in Application Support. This is minor over-collection against "only bundle ID, app name, step text, click position". | Optionally drop `timesCast` and `createdAt`, or document them as allowed in `privacy.md`. |
| R8 | Info | `scripts/kiro-review.sh:19` | Runs the CLI with `--trust-workspace` on report-writing agents. The agents are read-only, so impact is low. | None needed. |

## Verified controls

- **App logging:** `NSLog` appears at one call site only, `WailoDebug.swift:27`. There is no other `print`, `os_log`, `Logger`, `dump` or `fputs` in `app/Sources`.
- **Typed debug events:** The event enum (`WailoDebug.swift:7-19`) holds only numeric values, UUIDs, `CGRect`/`CGPoint`, `GhostState`, the two-case `VanishReason` and bundle IDs. It has no free-form string field. The `%@` format at line 27 prevents format-string injection.
- **Silence when off:** Events are dropped unless `WAILO_DEBUG == "1"` (`WailoDebug.swift:28,33-34`).
- **Call sites (from grep):** Every call passes IDs, points, rects, counts or a bundle ID. See `PumpkinRain.swift:72,103,125,132,159`, `TombstoneTrash.swift:101,128`, `RoomReader.swift:42`, `HauntedDockTarget.swift:38`, `GuidanceDirector.swift:159`, `GhostPet.swift:173`, `ShakeToFind.swift:45`. `RoomReader.swift:41` reads `localizedName` but passes it only to the UI offer, not to the logger.
- **Vision gating:** Three conditions apply.
  - The setting defaults to off (`Settings.swift:109`).
  - Enabling it needs a modal consent dialog (`MenuBarController.swift:102-108`).
  - `WailoApp.swift:64` and `GuidanceDirector.swift:125` check the setting again before capture.
  - The capture is `CGDisplayCreateImage` → JPEG → base64 → request body. All of it is in memory (`VisionService.swift:37-44`). No write-to-disk, `UserDefaults` or log call touches the image.
  - It is sent once per step (`visionAttempted`).
- **Network scope:** `URLSession` is used only in `BackendClient.swift:70` and `VisionService.swift:55`. Both build URLs from the `WAILO_BACKEND_URL` origin. The code strips the path, query, fragment and credentials. The vision URL must match the backend's scheme and host (`VisionService.swift:47`). The `/plan` body holds only `task` and `platform`. A test covers this (`BackendClientTests.swift:47`).
- **Safari URL:** `AXFinder.safariURL` (`:42-49`) feeds only the in-memory `CursedURLDetector` and `CursedURL.isCursed`. It is never logged, stored or sent. Safari watching is off by default (`Settings.swift:108`).
- **AX title use:** `TombstoneTrash.swift:53` and `AXFinder.swift:116,138` read titles only to match Dock and UI targets locally.
- **Secrets:** The only matches for key-like assignments were environment-variable reads in `backend/` and the placeholder `your-gemini-api-key` in `backend/.env.example`. No real `.env` exists in the workspace. `.gitignore` ignores `backend/.env` and `*.log`. `.kiro/` is not ignored, as the product rules require.
- **MCP boundaries:**
  - Artifacts go to `/tmp/wailo-devtools/` (`index.ts:11-15`).
  - The AX dump stops at 1,500 nodes (`wailo-helper.swift:30,38`).
  - The helper never reads `kAXValueAttribute` (comment at `:37`).
  - The health check is limited to the `WAILO_BACKEND_URL` origin and refuses redirects.
  - Synthetic drag needs the environment gate (see C1).
- **`docs/VISUAL_QA.md`:** It cites screenshot paths and typed debug lines only. I found no image bytes, titles, URLs or personal text in it.
- **Guard coverage:** `scripts/hooks/tests/test_privacy_guard.py` has deny cases for `NSApp.hide`, an external network host and a secret literal. I did not run it or count its fixtures.

## Minimal remediation order

1. C1: remove `ALLOW_INPUT` and the absolute paths from `.kiro/settings/mcp.json`.
2. C2, C3 and C4: fix the guard's tool filter, its log regex and its fail-open exit. Add fixtures for each.
3. R1: require HTTPS for non-loopback `WAILO_BACKEND_URL` values.
4. C5 and R4: set `/tmp/wailo-devtools` permissions and filter what `log_tail` returns.
5. R2: report the backend task logging to the backend owner.I didn't append the journal entry. This audit is read-only: you told me not to edit files, and I have no write tool in this session. The main agent can add the entry to `docs/KIRO_JOURNAL.md`.

For that entry, these three facts are observed:

- **Built:** a read-only privacy audit of the app, the devtools MCP, the hooks and the docs. No files were changed.
- **Kiro capability used:** only the read, search and directory tools. I didn't run the hooks, the MCP server, the tests or the CLI.
- **Lesson:** `scripts/hooks/privacy_guard.py` filters on tool names, so a write tool whose name lacks `write`, `replace` or `bash` would skip it. It also exits 0 (allows the write) if its input can't be parsed. See findings C2 and C4.
