# Spec Guardian IDE Report

**Execution:** IDE sub-agent fallback using `.kiro/agents/spec-guardian.json`. The running session
registry could not hot-load the newly created named profile, so an isolated Kiro sub-agent received
the exact profile and relevant Specs. It ran `swift test` read-only and made no edits.

## Test evidence

- `swift test`: 34 XCTest cases, 0 failures.
- The run does not prove manual UI criteria, hook triggers, remote CI, or T7's 1,000-case properties.

## Findings

| Severity | Requirement | Finding | Evidence |
|---|---|---|---|
| High | T2.3 | Full-file writes into `backend/` are not denied for every write-tool payload. | `scripts/hooks/privacy_guard.py` |
| High | T4.4 | Recursive AX traversal can exceed 1,500 because already-selected sibling recursion can continue after the count limit. | `tools/wailo-devtools-mcp/helpers/wailo-helper.swift` |
| High | R6.2, R6.10 | The duplicate-presentation guard fixes the observed retry race, but async vision uses guide generation rather than a step generation and can return after séance/advance. | `GuidanceDirector.swift` |
| Medium | R13.5, T4 | `backend_health` allows caller-selected HTTP(S) origins. | `tools/wailo-devtools-mcp/src/index.ts` |
| Medium | T3.2–T3.4 | Logger tests cover unset debug, but not non-`1` values or every typed event family. | `WailoDebugTests.swift` |
| Medium | T5.1–T5.2 | Five profiles exist, but were untracked at review time and named-profile hot-loading was blocked; reports still needed saving. | `.kiro/agents/`, `docs/agents/` |
| Medium | T6–T9 | CLI script, 1,000-case properties, Power and CI were not yet implemented. | Dev-tooling task list |
| Low | R14.4 | MCP CPU evidence is a ten-second mean, not the separate 30-second median acceptance protocol. | `docs/VISUAL_QA.md` |

## Requirement coverage snapshot

| Requirement | Implemented? | Tested/evidenced? |
|---|---|---|
| T1 steering modes | Yes | Front-matter plus journal evidence |
| T2 hooks | Mostly | Configured; demonstrations recorded; backend destination gap above |
| T3 debug logger | Mostly | Typed logger and 34-test suite; proof gaps above |
| T4 MCP and visual QA | Mostly | Eleven tools, smoke run and visual evidence; AX cap/origin gaps above |
| T5 agents | In progress | Profiles created; fallback reports returned to parent |
| T6 CLI gate | Not yet | No script at review time |
| T7 PBT | Not yet | Existing bounded loops are not 1,000-case seeded properties |
| T8 Power | Not yet | No package at review time |
| T9 CI | Not yet | No workflow at review time |
| R16–R22 visual QA | Observed scenarios passed | `docs/VISUAL_QA.md` and `/tmp/wailo-devtools/` |
| R14.3 multi-display/Spaces | Not established | Manual matrix remains blocked/unperformed |

## Parent follow-up

Fix the concrete T2/T4/R6 findings before the phase commit, preserve this report as review evidence,
and keep manual/remote checks marked unresolved rather than treating the passing unit suite as full
acceptance.
