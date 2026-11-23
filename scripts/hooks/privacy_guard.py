#!/usr/bin/env python3
"""Blocking pre-tool privacy check for file-writing tools."""
import json
import re
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool = str(payload.get("toolName") or payload.get("tool_name") or payload.get("name") or "").lower()
write_tool = any(name in tool for name in ("write", "str_replace", "strreplace", "execute_bash", "bash"))
if not write_tool:
    sys.exit(0)

inputs = payload.get("toolInput") or payload.get("tool_input") or payload.get("arguments") or payload.get("input") or {}
if not isinstance(inputs, dict):
    inputs = {}

# Inspect only content being added. This lets a later edit remove prohibited old content.
if "str_replace" in tool or "strreplace" in tool:
    candidate = str(inputs.get("newStr") or inputs.get("new_str") or "")
elif "bash" in tool:
    candidate = str(inputs.get("command") or "")
else:
    candidate = str(inputs.get("text") or inputs.get("content") or json.dumps(inputs, ensure_ascii=False))
context = json.dumps(inputs, ensure_ascii=False)
raw = candidate.lower()
context_lower = context.lower()
reasons = []

if "backend/" in context_lower:
    mutation = any(token in raw for token in ("rm ", "mv ", "cp ", "sed -i", "tee ",
                                               "> backend", "touch ", "cat >", "write_text", "unlink("))
    direct_write = any(token in tool for token in ("write", "str_replace", "strreplace"))
    if direct_write or mutation:
        reasons.append("privacy.md: backend/ is read-only unless the user explicitly requests a backend change")

if re.search(r"\bnsapp\s*\.\s*hide\b", raw):
    reasons.append("windows-and-perf.md: never call NSApp.hide because it hides every overlay")

secret_patterns = [r"sk-[a-z0-9]{12,}", r"api[_-]?key\s*[:=]\s*['\"][^'\"]+",
                   r"secret\s*[:=]\s*['\"][^'\"]+"]
if any(re.search(pattern, candidate, re.I) for pattern in secret_patterns):
    reasons.append("privacy.md: secrets and API keys must never be added to code or logs")

logging = bool(re.search(r"\b(nslog|print|os_log)\s*\(|\b(logger|log)\s*\.\s*[a-z_][a-z0-9_]*\s*\(", raw))
sensitive_reference_patterns = [
    r"window\s+title", r"screen\s+text", r"ax\s+value", r"email\s+content",
    r"screenshot\s+bytes", r"image_base64", r"\.\s*title\b", r"kaxtitleattribute",
    r"kaxvalueattribute", r"axvalue", r"\.\s*localizedname\b",
    r"\b(url|uri)\b", r"[a-z_][a-z0-9_]*url\b", r"absolutestring", r"email(address|value)?\b", r"mailaddress"
]
if logging and any(re.search(pattern, raw) for pattern in sensitive_reference_patterns):
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
    sys.stderr.write("PRIVACY-GUARD DENIED\n- " + "\n- ".join(dict.fromkeys(reasons)) + "\n")
    sys.exit(2)
sys.exit(0)
