# Kiro capability evidence

| Capability | How it was used | Repository evidence | Commit |
|---|---|---|---|
| Kiro IDE | Main spec, implementation, delegation, build/test, visual QA, Git and documentation control room | `.kiro/`, `app/`, `docs/KIRO_JOURNAL.md` | Full history from `f0945df` onward |
| Specs | Initial critique; three feature split; Haunting v2; tooling requirements T1–T9 with traceable tasks | `.kiro/specs/wailo-app/critique.md`, `.kiro/specs/{haunting-foundation,ghost-pet,guidance-and-safety,haunting-v2,dev-tooling}/` | `f0945df`, `1d625fe`, `de6fa77`, `c51c28a` |
| Steering modes | Always-on product/structure/privacy, file-matched technical/cozy/test/backend context, manual journal procedure | `.kiro/steering/` front matter | `eedaebc` |
| Agent hooks | Seven current-format hooks for build, tests, privacy, assets, task sync, journal and Cozy checks; compile repair and blocking-handler evidence | `.kiro/hooks/`, `scripts/hooks/privacy_guard.py`, journal | `bb1173a` |
| Hook regression testing | Property-access leak fixed; 19 allow/deny fixtures cover `.title`, AX values, URL/email, pixels, hosts, secrets, `NSApp.hide`, and backend writes | `scripts/hooks/tests/test_privacy_guard.py` | `98dad4c`, follow-up in `905db7b` |
| Debug evidence | Typed `WAILO_DEBUG=1` events with no free-form UI payload | `WailoDebug.swift`, `WailoDebugTests.swift` | `5020562` |
| MCP | Official SDK stdio server with 11 tools used for six-check local visual QA | `.kiro/settings/mcp.json`, `tools/wailo-devtools-mcp/`, `docs/VISUAL_QA.md` | `12fe205` |
| Custom agents | Five V3 least-privilege workspace profiles recognized by `kiro-cli agent list` | `.kiro/agents/*.json`, `.kiro/agents/README.md` | `905db7b` |
| Sub-agents | Parallel build agents; custom-agent creator; IDE fallback spec/privacy audits with limitations disclosed | `docs/agents/*-ide.md`, journal | `905db7b` |
| Kiro CLI | Version/help and profile discovery used to author exact script syntax; review gate intentionally not executed by the IDE agent | `scripts/kiro-review.sh` | `905db7b` |
| Property-based testing | Stable seed, nine 1,000-case methods, failure context, and retained floating-point regression | `app/Tests/WailoTests/Properties/`, `CoordinateSpaceTests.swift` | `4bcbf81` |
| Power | Current Agent Plugin plus skill, MCP configuration, generalized references, legacy compatibility, and hook templates | `powers/spooky-macos-overlays/` | `38805e4` |
| CI | macOS 14 GitHub workflow runs `swift build` and `swift test` | `.github/workflows/ci.yml` | `38805e4` |
| Vibe/spec experiment | Timed Ghost Mail v2 compared with spec-first shake-to-find using real rework and test evidence | `docs/VIBE_VS_SPEC.md` | `dabfdb0` |

## Manual follow-up

1. Run `bash scripts/kiro-review.sh`, review the generated CLI reports, and commit them with the
   requested `kiro(cli)` message.
2. In a fresh IDE session, invoke the named `spec-guardian` and `privacy-warden` profiles directly.
   The current reports truthfully document that this session used isolated profile-based fallbacks
   because its registry could not hot-load new names.
3. Import `powers/spooky-macos-overlays` in the Powers panel, type “make a click-through overlay
   window,” and capture activation evidence.
4. Confirm the pushed macOS CI job passes on GitHub. Local validation is not remote CI evidence.
5. Create the two Kiro Web issues, preserve the PR links, and merge only reviewed changes.
6. Optionally run Kiro Crew for the long-lived performance goal.
7. Capture screenshots of a hook firing, privacy denial, MCP tools, agents list, CLI run, Power
   activation, visual QA, and Kiro Web PR for the judging write-up.
8. Run the remaining R14 multi-display, Spaces, full-screen, VoiceOver, and Reduce Motion manual
   matrix.
9. Resolve or explicitly accept the privacy review's remaining app redirect risk: `URLSession.shared`
   may follow a same-request redirect, while project steering forbids creating a delegated session.
