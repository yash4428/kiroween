---
inclusion: fileMatch
fileMatchPattern: "app/Tests/**"
---
# Test rules

## Testing
- Pure logic goes in small types with XCTest coverage:
  - coordinate conversions (fake multi-screen layouts, including a screen *above* the primary)
  - footprint path: the last print always lands inside the target
  - ghost state-machine transitions, including the danger override and restore
  - task routing
  - scam-URL keyword check
  - Grimoire text matching
  - plan parsing (with markdown fences)
- After every task: `swift build` then `swift test` must pass.
