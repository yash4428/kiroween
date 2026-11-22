# Design: Kiro developer tooling

## Architecture

The tooling has four trust zones:

1. `.kiro/steering`, Specs, agents, hooks, and the Power are declarative Kiro configuration.
2. `app/` contains one opt-in privacy-safe logger used to correlate visual behavior.
3. `tools/wailo-devtools-mcp/` is a local stdio MCP server. It shells out only to allow-listed local
   build, process, screenshot, AX-helper, `ps`, and health-check operations.
4. `docs/` stores human-readable evidence. Runtime images and logs remain in `/tmp`.

## Steering

Existing prose is preserved while `tech.md` is split by concern. Front-matter uses Kiro's documented
`inclusion` values. File-match patterns target only source areas that need each rule. `privacy.md`
remains always loaded because every tool can cross a data boundary.

## Hooks

Hook files are created through Kiro's hook tooling so event names and schemas are not guessed. Command
hooks build/test. Prompt hooks inspect privacy, licensing, task traceability, journal evidence, and Cozy
rules. Blocking is used only for privacy-sensitive pre-tool checks.

A hook demonstration is evidence only when actual hook output appears. A planned configuration or a
manual build does not count as a hook execution.

## Debug logger

`WailoDebug` accepts typed events rather than arbitrary strings. Rendering to `NSLog` occurs only when
the environment value is exactly `1`. Event payloads expose numeric IDs, bundle IDs, enum reasons,
rectangles, points, states, and counts. Call sites cannot pass free-form UI content.

## MCP server

The TypeScript server uses `@modelcontextprotocol/sdk` with `StdioServerTransport` and Zod schemas.
All paths derive from `WAILO_REPO`; process state lives in `/tmp/wailo-devtools/state.json`. Inputs are
validated and passed to `spawn`/`execFile`, never interpolated into a shell command. Screenshot data is
returned as an MCP image plus a local path and is never uploaded.

The AX/test-window helper is a small compiled Swift executable in the MCP package. It has explicit
modes, bounds traversal, and text-field value redaction. Synthetic input is separately gated by an
environment variable.

## Agents and CLI

Custom profiles use least privilege. Review agents are read-only; visual QA gets only MCP and read;
haunt-designer has a source-subtree write allow-list; perf and privacy agents cannot edit. The CLI
script checks installed help before selecting syntax and refuses unsupported installations.

## Property harness

A small seeded generator in `Tests/WailoTests/Properties` uses a stable PRNG, 1,000 loops, and assertion
messages containing the seed and generated values. Fixed regression examples remain beside generated
properties.

## Power and CI

The Power packages generalized overlay expertise without Wailo product copy. It references a
configurable app path. CI is intentionally small and uses the same two local commands as every phase.

## Verification

Each task names its proof: front-matter output, hook output, logger tests, MCP initialize/tools calls,
agent reports, CLI refusal/run output, 1,000-case tests, Power contents, or CI YAML. Permission-blocked
MCP checks are recorded as blocked rather than passed.
