# Privacy Warden IDE Report

**Execution:** IDE sub-agent fallback using `.kiro/agents/privacy-warden.json`. The running session
registry could not hot-load the newly created named profile, so an isolated Kiro sub-agent was given
the exact persisted profile and steering. It made no edits.

## Findings

| Severity | Finding | Evidence | Recommended action |
|---|---|---|---|
| High | MCP screenshots are written to `/tmp` and returned as image content. This conflicts with the app-level “memory only” wording unless developer QA is explicitly scoped as a separate consented exception. | `tools/wailo-devtools-mcp/src/index.ts`, screenshot tool | Clarify app-versus-devtool policy; keep files local, consented and outside Git. |
| High | `ax_dump` returns AX titles/descriptions. It never reads text-field values, but labels can still contain personal text. | `helpers/wailo-helper.swift` | Restrict use and avoid persistence; prefer role/frame-only output where labels are unnecessary. |
| High | `backend_health(url?)` accepted arbitrary HTTP(S) hosts. | `src/index.ts`, `safeHealthURL` | Require exact configured backend origin and reject redirect/origin changes. |
| High risk | App `URLSession.shared` may follow a redirect away from the configured origin. | `BackendClient.swift`, `VisionService.swift` | Record as an unresolved platform/architecture risk because shared-session steering prevents a delegate-based redirect policy. |
| Medium | `grimoire_read` returns complete local spell records, including user-entered step text. | `src/index.ts` | Treat as an explicitly invoked local developer tool; never auto-log its output. |
| Medium | The hook could allow a full-file write into `backend/` because destination checks were incomplete. | `scripts/hooks/privacy_guard.py` | Deny every write tool whose destination is under `backend/`; add a regression fixture. |
| Low | Workspace MCP config includes an absolute local account path. | `.kiro/settings/mcp.json` | Prefer a workspace-relative root if Kiro adds a documented workspace variable. |

## Verified controls

- App debug events use a typed opt-in allowlist and cannot accept free-form UI text.
- Vision defaults off, explains pixel transmission, and has no app-side file write or pixel log.
- Grimoire app persistence follows its approved local schema and stores no pixels.
- Safari URL checks and static Ghost Mail content have no logger or persistence sink.
- No hardcoded credential was found.

## Parent follow-up

The main agent should preserve this report as the original review evidence, fix the backend guard and
backend-health origin findings, clarify the local-QA screenshot exception, and separately document the
shared-session redirect risk rather than claiming it is solved.
