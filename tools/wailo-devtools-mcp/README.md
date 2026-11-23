# wailo-devtools MCP

A local-only Node 20+ stdio MCP server for Wailo visual and accessibility QA. It uses the official
`@modelcontextprotocol/sdk`. Runtime logs, state, helper binaries, and screenshots stay under
`/tmp/wailo-devtools/`; the server uploads nothing.

## Setup

```sh
cd tools/wailo-devtools-mcp
npm install
npm run build
npm run smoke
```

Kiro workspace configuration is in `.kiro/settings/mcp.json`. `WAILO_REPO` selects the repository.
Synthetic input is refused unless `WAILO_DEVTOOLS_ALLOW_INPUT=1` is explicitly present.

## Tools

- `launch_wailo`, `quit_wailo`
- `screenshot`
- `ax_dump`, capped at 1,500 nodes and never reading text-field values
- `dock_items`
- `cpu_sample`, `log_tail`
- `grimoire_read`, `backend_health`
- `test_window`, a separate throwaway app window
- `synthetic_drag`, explicitly gated local input

macOS may require Screen Recording for screenshots and Accessibility for AX or synthetic input. Grant
those permissions to the process Kiro uses to run this server. Permission-denied results must be
recorded as blocked, not as passes.
