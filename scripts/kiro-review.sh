#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p docs/agents

if ! command -v kiro-cli >/dev/null 2>&1; then
  echo "Kiro CLI is not installed. Install/login to Kiro CLI, then rerun this script." >&2
  exit 127
fi

# Syntax verified against `kiro-cli 3.5.0 chat --help` on 2026-11-23.
run_agent() {
  local agent="$1"
  local output="$2"
  local prompt="$3"
  local temporary="${output}.tmp"
  echo "Running ${agent}..."
  if kiro-cli chat --v3 --agent "$agent" --no-interactive --trust-workspace "$prompt" >"$temporary"; then
    mv "$temporary" "$output"
  else
    local status=$?
    rm -f "$temporary"
    echo "${agent} failed with exit ${status}; ${output} was not fabricated." >&2
    return "$status"
  fi
}

run_agent "spec-guardian" "docs/agents/spec-guardian-cli.md" \
  "Review the current repository against all requirement IDs. Run swift test if useful. Do not edit files. Return the required traceability table and factual blocked/manual checks."

run_agent "privacy-warden" "docs/agents/privacy-warden-cli.md" \
  "Audit the current app and developer tooling against privacy.md. Do not edit files or reveal secret values. Return confirmed findings, risks, verified controls, and minimal remediations with file and line evidence."

echo "CLI review reports written under docs/agents/. Review them before committing."
