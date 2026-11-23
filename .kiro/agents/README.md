# Wailo custom agents

These workspace profiles use the JSON format installed with the current Kiro version. Kiro discovers them from `.kiro/agents/`. They are persistent custom-agent profiles; an ordinary one-off delegated subagent is not a persistent custom agent.

## Catalogue

| Agent | Delegate when | Effective access |
|---|---|---|
| `spec-guardian` | A spec task finishes or a commit is being prepared | Read plus shell for Git inspection and `swift test`; no MCP or writes |
| `visual-qa` | UI behavior needs screenshot, AX, coordinate, or multi-display verification | Read plus workspace MCP; no shell or writes |
| `haunt-designer` | Cozy visual polish is confined to the approved visual source subtrees | Read, write, and delegation; no direct MCP or shell |
| `perf-ghost` | Idle CPU or rendering cost needs measurement | Read, shell, and workspace MCP; no writes |
| `privacy-warden` | Changes touch logs, screenshots, AX data, networking, storage, or secrets | Read only; no shell, MCP, or writes |

Only `visual-qa` and `perf-ghost` set `includeMcpJson` to `true`. They receive the workspace `wailo-devtools` server from `.kiro/settings/mcp.json`. The other profiles do not import workspace MCP tools. No profile overrides the model, auto-approves tools, or includes Powers.

## Write boundary

`haunt-designer` is the only profile with the `write` tool. Its prompt permits writes only below:

- `app/Sources/Wailo/Haunting/**`
- `app/Sources/Wailo/Pet/**`
- `app/Sources/Wailo/Guidance/**`
- `app/Sources/Wailo/Cursor/**`

It must refuse every other write, including changes to `app/Sources/Wailo/Overlay/`, `app/Tests/`, `backend/`, `.kiro/specs/`, and `docs/`.

The V3 profile enforces these paths with `permissions.rules` for `fs_write`; no other profile
exposes the `write` tool. Normal workspace permissions still apply, and the stricter policy wins.

## Delegation boundary

`haunt-designer` exposes only `subagent/visual-qa` and allows that named target in its `subagent`
permission rule. It does not import MCP directly; `visual-qa` owns screenshot and AX verification.

Named custom-agent delegation can vary by Kiro surface or runtime. If `haunt-designer` cannot select `visual-qa` as the target, it must stop that step and return a `MAIN-AGENT ACTION` request. The main agent should then invoke `visual-qa` with the changed paths, acceptance criteria, and scenarios. This fallback must not be described as successful nested delegation.

Review profiles return reports to their caller. When T5.2 is performed later, the main agent is responsible for saving factual spec and privacy reports under `docs/agents/`. Creating these profiles does not run them and does not create evidence reports.

## Safe test prompts

Do not run these as part of profile creation. In a later Kiro session, use the available `invoke_sub_agent` tool or the equivalent current delegation UI:

```text
Invoke spec-guardian to review the current diff against all requirement IDs. Do not edit files. Return the report to me.
```

```text
Invoke privacy-warden to audit the current diff for PII, screenshot, AX-value, URL, email, and secret leaks. Do not edit files. Return the report to me.
```

```text
Invoke visual-qa to verify <scenario> against <requirement IDs>. Use wailo-devtools, preserve exact artifact paths, and report pass, fail, or blocked without editing files.
```

```text
Invoke haunt-designer for <focused visual issue> confined to the four approved subtrees, then have it delegate verification to visual-qa. Reject any out-of-scope write.
```

```text
Invoke perf-ghost to measure one-screen idle CPU against the <5% budget. Do not modify files.
```

Before relying on a profile, confirm that Kiro lists the workspace agent by its `name`, review its displayed tools, and use a harmless read-only request first. Do not infer a successful agent run from profile discovery alone.
