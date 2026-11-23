# Install Spooky macOS Overlays

1. Set `WAILO_DEVTOOLS_SERVER` to the absolute path of a built wailo-devtools MCP `index.js` and
   `WAILO_APP_PATH` to the repository containing the Swift app, or edit the imported MCP settings.
2. In Kiro IDE open **Powers → Add Custom Power → Import power from a folder**.
3. Select `powers/spooky-macos-overlays`.
4. Approve the local MCP only if visual QA is intended.
5. Type “make a click-through overlay window” to test keyword activation.

This is a current Agent Plugin (`plugin.json`, skill and MCP config). `POWER.md` is included only for
legacy compatibility. Kiro does not currently document hooks or steering as portable Power
components, so root `hooks/` and `steering/` are reviewable templates/references rather than
automatically installed configuration.
