#!/usr/bin/env python3
"""Table-driven regression tests for the blocking privacy hook."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GUARD = ROOT / "scripts/hooks/privacy_guard.py"

CASES = [
    ("allow typed coordinate log", "NSLog(\"WAILO point=(1,2)\")", 0),
    ("allow state logger", "logger.debug(\"state=idle count=2\")", 0),
    ("allow title assignment without logging", "window.title = \"Wailo\"", 0),
    ("allow AX title lookup without logging", "let title = kAXTitleAttribute", 0),
    ("allow configured backend request", "URLSession.shared.data(for: WAILO_BACKEND_URL)", 0),
    ("allow documentation URL without network call", "let docs = \"https://kiro.dev/docs\"", 0),
    ("deny window title property regression", "NSLog(\"%@\", window.title)", 2),
    ("deny localized app name", "print(app.localizedName)", 2),
    ("deny AX title attribute", "os_log(\"%@\", kAXTitleAttribute)", 2),
    ("deny AX value attribute", "logger.info(element[kAXValueAttribute])", 2),
    ("deny AXValue", "print(AXValueGetValue(value))", 2),
    ("deny URL variable", "NSLog(\"%@\", currentURL)", 2),
    ("deny absolute URL string", "logger.debug(url.absoluteString)", 2),
    ("deny email value", "print(userEmail)", 2),
    ("deny pixel persistence", "screenshotData.write(to: fileURL)", 2),
    ("deny NSApp hide", "NSApp.hide(nil)", 2),
    ("deny external network host", "URLSession.shared.data(from: URL(string: \"https://tracker.example\")!)", 2),
    ("deny secret literal", "let apiKey = \"sk-abcdefghijklmnop\"", 2),
]

failures = []
for name, new_source, expected in CASES:
    payload = {
        "toolName": "functions.str_replace",
        "toolInput": {
            "path": "app/Sources/Wailo/Pet/GhostPet.swift",
            "oldStr": "safe old source",
            "newStr": new_source,
        },
    }
    result = subprocess.run([sys.executable, str(GUARD)], input=json.dumps(payload), text=True,
                            capture_output=True, cwd=ROOT)
    if result.returncode != expected:
        failures.append(f"{name}: expected {expected}, got {result.returncode}; stderr={result.stderr!r}")
    status = "PASS" if result.returncode == expected else "FAIL"
    print(f"{status}: {name} -> exit {result.returncode}")

backend_payload = {
    "toolName": "functions.fs_write",
    "toolInput": {"path": "backend/index.js", "text": "export const safeLookingSource = true;"},
}
backend_result = subprocess.run([sys.executable, str(GUARD)], input=json.dumps(backend_payload), text=True,
                                capture_output=True, cwd=ROOT)
if backend_result.returncode != 2:
    failures.append(f"deny full backend write: expected 2, got {backend_result.returncode}")
print(f"{'PASS' if backend_result.returncode == 2 else 'FAIL'}: deny full backend write -> exit {backend_result.returncode}")

if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
print(f"Executed {len(CASES) + 1} privacy-guard cases with 0 failures")
