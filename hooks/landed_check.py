#!/usr/bin/env python3
"""landed — Stop hook.

Scans the assistant's final message for a *ship-claim* about a remote destination
(published / deployed / released / merged / sent / "it's live"). If the current turn
contains NO evidence of a destination check — a `gh run`/`gh release`/`gh api` call, a
`curl`/WebFetch to an http URL, a registry install, or a read of an install path —
it BLOCKS the stop and forces a verification at the destination first.

Calibrated for precision: blocks only on a strong ship-claim with zero evidence. A
vague "that's done" about a local edit does not trip it. Evidence is read from actual
tool calls in the transcript, not from the model's claim that it checked. One block
per stop chain (stop_hook_active guard prevents loops). Exit 0 otherwise.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# ── A strong claim that something shipped to a destination outside the workbench.
SHIP_RX = re.compile(
    r"\b("
    r"published|deployed|released|shipped|"
    r"(it'?s|is|now|went) live|gone live|"
    r"merged (it|the pr|to main|into main)|"
    r"pushed to (prod|production)|live in production|"
    r"sent (the |you the )?(email|message|mail|invite)|"
    r"publiquei|fiz (o )?deploy|deployei|est[áa] (no ar|live|publicad[oa]|em produ[çc][ãa]o)|"
    r"foi (publicad[oa]|entregue|enviad[oa])|enviei (o |a )?(email|mensagem|mail)|"
    r"no ar agora|publicad[oa] (em|no)|lan[çc]ad[oa]"
    r")\b",
    re.IGNORECASE,
)

# ── Evidence (in tool calls this turn) that the destination was actually checked.
EVIDENCE_RX = re.compile(
    r"(gh run (watch|view|list)|gh release (view|list|create)|gh api |gh pr (view|checks)|"
    r"gh repo view|gh workflow|"
    r"\bcurl\b|\bwget\b|\bhttp_code\b|"
    r"npm (install|view|ping)|pip (install|show|index)|npx |cargo (install|search)|"
    r"/\.claude/skills|/usr/local/bin|/opt/homebrew/bin|\bwhich \w|command -v |"
    r"--version\b|\bdoctor\.sh\b|"
    r"\bdig \w|\bnslookup\b|status_code|response\.status)",
    re.IGNORECASE,
)
# Tool names that are themselves destination checks (web fetch / search).
EVIDENCE_TOOLS = {"WebFetch", "mcp__fetch__imageFetch"}


def extract_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = [c.get("text", "") for c in content
                 if isinstance(c, dict) and c.get("type") == "text"]
        return " ".join(parts)
    return ""


def load_turn(transcript_path: Path):
    """Return (last_assistant_text, evidence_seen_bool) for the current turn."""
    records: list[dict] = []
    last_user_idx = -1
    try:
        with transcript_path.open() as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue
                records.append(rec)
                if rec.get("type") == "user" and isinstance(rec.get("message"), dict):
                    content = rec["message"].get("content")
                    if isinstance(content, str) and content.strip() and not content.startswith("<"):
                        last_user_idx = len(records) - 1
    except OSError:
        return "", False
    if last_user_idx < 0:
        turn = records
    else:
        turn = records[last_user_idx:]

    last_text = ""
    evidence = False
    for rec in turn:
        if rec.get("type") != "assistant":
            continue
        msg = rec.get("message") or {}
        content = msg.get("content") if isinstance(msg, dict) else None
        txt = extract_text(content)
        if txt:
            last_text = txt
        if isinstance(content, list):
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                if block.get("name") in EVIDENCE_TOOLS:
                    evidence = True
                # Scan the tool input (command, url, file_path, prompt) for evidence.
                blob = json.dumps(block.get("input") or {}, ensure_ascii=False)
                if EVIDENCE_RX.search(blob):
                    evidence = True
    return last_text, evidence


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if payload.get("stop_hook_active"):
        return 0
    transcript = payload.get("transcript_path")
    if not transcript:
        return 0
    last_text, evidence = load_turn(Path(transcript))
    if not last_text or not SHIP_RX.search(last_text):
        return 0  # no ship-claim → nothing to enforce
    if evidence:
        return 0  # claim is backed by a destination check → allow
    print(json.dumps({
        "decision": "block",
        "reason": (
            "You claimed something shipped (published / deployed / released / sent / "
            "live) but this turn shows NO evidence you verified it at its destination. "
            "Local-green ≠ landed. Check the product where it actually lives — green CI "
            "(`gh run watch --exit-status`), the live URL (curl/fetch → status + content), "
            "the remote default branch (`gh api .../contents`), the install path, the "
            "registry, or the Sent folder — read it back from there, then report. Do not "
            "say done until it has landed."
        ),
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
