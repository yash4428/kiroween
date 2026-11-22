#!/usr/bin/env python3
"""Blocking pre-tool privacy check for file-writing tools."""
import json
import re
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

raw = json.dumps(payload, ensure_ascii=False).lower()
tool = str(payload.get("toolName") or payload.get("tool_name") or payload.get("name") or "").lower()
write_tool = any(name in tool for name in ("write", "str_replace", "execute_bash", "bash"))
if not write_tool:
    sys.exit(0)

reasons = []
# Backend is read-only. Permit commands that only inspect or run it.
if "backend/" in raw:
    mutation = any(token in raw for token in ("fs_write", "str_replace", "rm ", "mv ", "cp ",
                                               "sed -i", "tee ", "> backend", "touch "))
    if mutation:
        reasons.append("privacy.md: backend/ is read-only unless the user explicitly requests a backend change")

if "nsapp.hide" in raw:
    reasons.append("windows-and-perf.md: never call NSApp.hide because it hides every overlay")

secret_patterns = [r"sk-[a-z0-9]{12,}", r"api[_-]?key\s*[:=]\s*['\"][^'\"]+",
                   r"secret\s*[:=]\s*['\"][^'\"]+"]
if any(re.search(pattern, raw, re.I) for pattern in secret_patterns):
    reasons.append("privacy.md: secrets and API keys must never be added to code or logs")

logging = any(token in raw for token in ("nslog", "logger.", "print(", "os_log"))
sensitive = any(token in raw for token in ("window title", "kaxvalueattribute", "ax value",
                                            "screen text", "email content", "screenshot bytes",
                                            "image_base64"))
if logging and sensitive:
    reasons.append("privacy.md: never log screen text, AX values, window titles, URLs, emails, or pixels")

networking = any(token in raw for token in ("urlsession", "curl ", "fetch(", "httprequest"))
external_url = re.search(r"https?://(?!localhost(?::\d+)?(?:[/\"']|$))", raw)
if networking and external_url and "wailo_backend_url" not in raw:
    reasons.append("privacy.md: app network calls may go only to WAILO_BACKEND_URL")

persist_pixels = any(token in raw for token in ("screenshot", "image_base64", "cgimage")) and any(
    token in raw for token in ("write(to", "data.write", "filehandle", "createfile", "userdefaults")
)
if persist_pixels:
    reasons.append("privacy.md: screenshots must remain in memory for one consented request")

if reasons:
    sys.stderr.write("PRIVACY-GUARD DENIED\n- " + "\n- ".join(reasons) + "\n")
    sys.exit(2)
sys.exit(0)
