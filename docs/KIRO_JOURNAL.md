# Kiro journal

Appended by the `journal` hook after each agent session. Source material for the write-up.

## 2026-11-21 18:32:10 IST
- Built a nine-commit history separating the spec critique, feature specs, Haunting v2, app layers, tests, and documentation.
- Used Kiro IDE file, shell, and Git tooling to turn the uncommitted build into reviewable evidence.
- Learned that overview links for Haunting v2 had to be staged separately so each historical commit contained only its claimed scope; `swift build` and all 32 tests passed afterward.
## 2026-11-22 11:05:30 IST
- Built the dev-tooling Spec with EARS requirements T1–T9, a trust-boundary design, and requirement-cited tasks for steering, hooks, logging, MCP, agents, CLI, PBT, Power, and CI.
- Used Kiro Specs to define proof requirements before creating developer tooling.
- Learned to distinguish configuration presence from execution evidence; the spec requires an actual hook output, MCP call, report, or test rather than treating a planned file as proof. The app build and all 32 tests passed.
