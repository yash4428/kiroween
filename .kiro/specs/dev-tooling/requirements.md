# Requirements: Kiro developer tooling

## Purpose

This spec turns Wailo's Kiro workflow into executable, reviewable project infrastructure. Evidence
means a committed configuration file plus a factual journal, report, test, or command output. Tooling
must not modify `backend/` or weaken Wailo's privacy rules.

## T1. Context-sensitive steering

1. WHEN Kiro loads the workspace THE SYSTEM SHALL always include product, structure, and privacy
   steering.
2. WHEN a matching source or test path is active THE SYSTEM SHALL include only the relevant
   coordinate, window/performance, backend, testing, or cozy-design steering using current `fileMatch`
   front-matter.
3. WHEN the journal procedure is explicitly requested THE SYSTEM SHALL make manual journal steering
   available without injecting it into unrelated work.
4. WHEN T1 is complete THE SYSTEM SHALL contain valid front-matter in every steering file and the
   journal SHALL record the inclusion modes that were inspected.

## T2. Event-driven hooks

1. WHEN a Swift source file is saved THE SYSTEM SHALL invoke the configured incremental build hook.
2. WHEN pure logic or a test is saved THE SYSTEM SHALL invoke the configured test hook and associate
   failures with requirement IDs where available.
3. BEFORE a file-writing tool changes protected data flow or `backend/` THE SYSTEM SHALL deny the
   operation and explain the matching privacy rule.
4. WHEN an asset is created THE SYSTEM SHALL check its source and licence record.
5. WHEN a spec task or agent session completes THE SYSTEM SHALL synchronize tasks and append a factual
   journal entry.
6. WHEN Cozy-sensitive UI is saved THE SYSTEM SHALL check palette, motion, copy, and Reduce Motion.
7. WHEN hooks are demonstrated THE SYSTEM SHALL preserve a build-repair result and a privacy denial in
   the journal without leaving the deliberate bad edit in source.

## T3. Privacy-safe debug evidence

1. WHILE `WAILO_DEBUG=1` THE SYSTEM SHALL emit `NSLog` events prefixed `WAILO ` for approved states,
   identifiers, counts, coordinates, and lifecycle timestamps, including pumpkin Dock arrival needed
   to verify its two-second expiry.
2. WHILE `WAILO_DEBUG` is absent or not `1` THE SYSTEM SHALL emit no debug event.
3. THE SYSTEM SHALL NOT put task text, UI text, AX values, window titles, URLs, email content,
   screenshots, secrets, or personal data in a debug event.
4. WHEN debug logging is tested THE SYSTEM SHALL prove silence while disabled and field redaction for
   representative events.

## T4. Local visual-verification MCP

1. WHEN Kiro starts `wailo-devtools` over stdio THE SYSTEM SHALL expose the documented launch, quit,
   screenshot, AX, Dock, CPU, log, Grimoire, backend-health, test-window, and synthetic-drag tools.
2. THE SYSTEM SHALL use Node 20 and the official MCP TypeScript SDK and SHALL write runtime artifacts
   only below `/tmp/wailo-devtools/`.
3. WHEN synthetic input is requested without `WAILO_DEVTOOLS_ALLOW_INPUT=1` THE SYSTEM SHALL refuse it.
4. WHEN an AX dump runs THE SYSTEM SHALL cap output at 1,500 nodes and SHALL not print text-field AX
   values.
5. WHEN visual QA runs THE SYSTEM SHALL write `docs/VISUAL_QA.md` with real paths, measurements, and
   pass/fail results; it SHALL not invent unavailable permission-dependent evidence.

## T5. Specialized agents

1. WHEN the workspace agent catalogue is loaded THE SYSTEM SHALL provide current-format profiles for
   `spec-guardian`, `visual-qa`, `haunt-designer`, `perf-ghost`, and `privacy-warden` with least-privilege
   tools and relevant steering resources.
2. WHEN the main agent delegates a spec or privacy review THE SYSTEM SHALL save the factual IDE report
   under `docs/agents/`.
3. WHEN agent usage is documented THE SYSTEM SHALL explain the delegation boundary and SHALL not call
   an ordinary delegated agent a persistent custom agent.

## T6. CLI review gate

1. WHEN `scripts/kiro-review.sh` runs in an environment with Kiro CLI THE SYSTEM SHALL use syntax taken
   from the installed CLI help, run both review agents, and write separate CLI reports.
2. WHEN Kiro CLI is unavailable THE SYSTEM SHALL exit with a clear installation/manual action rather
   than create fake reports.

## T7. Property-based correctness

1. WHEN T7 runs THE SYSTEM SHALL execute 1,000 deterministic generated cases per selected property,
   print the seed on failure, and report a reduced or minimal counterexample where practical.
2. THE SYSTEM SHALL cover coordinate round trips, footprint endpoints, ghost safety transitions,
   router totality/case behavior, bbox validation, tombstone placement, title-bar eligibility, throw
   clamping, bin radius, and shake rejection.
3. WHEN a generated counterexample fails THE SYSTEM SHALL fix the implementation, add a named
   regression test, and record it in the journal.

## T8. Reusable overlay Power

1. WHEN the local `spooky-macos-overlays` Power is inspected THE SYSTEM SHALL provide current-format
   metadata, activation terms, generalized coordinate/window steering, wailo-devtools MCP
   configuration, and build/privacy hooks.
2. WHEN installation is requested THE SYSTEM SHALL document the exact local path and the UI action the
   user must perform.

## T9. macOS CI

1. WHEN GitHub Actions runs on the repository THE SYSTEM SHALL use a macOS 14 runner and execute
   `swift build` followed by `swift test` from `app/`.
2. WHEN CI configuration is complete THE SYSTEM SHALL contain `.github/workflows/ci.yml` and the
   journal SHALL record that local validation passed separately from remote CI status.
