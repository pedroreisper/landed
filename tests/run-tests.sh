#!/usr/bin/env bash
# run-tests.sh — assert the landed Stop hook blocks/allows correctly.
# Builds tiny transcript fixtures and feeds them to the hook via a Stop payload.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$DIR/../hooks/landed_check.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

# build_transcript <file> <assistant_text> <tool_command_or_empty>
build_transcript() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
path, text, cmd = sys.argv[1], sys.argv[2], sys.argv[3]
recs = [{"type": "user", "message": {"content": "do the thing"}}]
content = [{"type": "text", "text": text}]
if cmd:
    content.append({"type": "tool_use", "name": "Bash", "input": {"command": cmd}})
recs.append({"type": "assistant", "message": {"content": content}})
with open(path, "w") as f:
    for r in recs:
        f.write(json.dumps(r) + "\n")
PY
}

# run_hook <transcript> [stop_hook_active] -> prints hook stdout
run_hook() {
  local t="$1" active="${2:-false}"
  printf '{"transcript_path":"%s","stop_hook_active":%s}' "$t" "$active" | python3 "$HOOK" 2>/dev/null
}

assert_block() {  # <name> <transcript> <active>
  local out; out="$(run_hook "$2" "${3:-false}")"
  if printf '%s' "$out" | grep -q '"decision": *"block"'; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); printf '\033[31mFAIL\033[0m %s — expected BLOCK, got: %s\n' "$1" "${out:-<empty>}"
  fi
}
assert_allow() {  # <name> <transcript> <active>
  local out; out="$(run_hook "$2" "${3:-false}")"
  if printf '%s' "$out" | grep -q '"decision": *"block"'; then
    fail=$((fail+1)); printf '\033[31mFAIL\033[0m %s — expected ALLOW, got block\n' "$1"
  else
    pass=$((pass+1))
  fi
}

# 1. ship-claim, NO evidence → block
build_transcript "$TMP/t1.jsonl" "Published to GitHub — done." ""
assert_block "claim-no-evidence" "$TMP/t1.jsonl"

# 2. ship-claim WITH gh-run evidence → allow
build_transcript "$TMP/t2.jsonl" "Published, CI is green." "gh run watch 123 --exit-status"
assert_allow "claim-with-gh-evidence" "$TMP/t2.jsonl"

# 3. ship-claim WITH curl evidence → allow
build_transcript "$TMP/t3.jsonl" "Deployed and it's live." "curl -sS -w '%{http_code}' https://app.example.com"
assert_allow "claim-with-curl-evidence" "$TMP/t3.jsonl"

# 4. PT ship-claim, no evidence → block
build_transcript "$TMP/t4.jsonl" "Já publiquei o repo, está no ar." ""
assert_block "claim-pt-no-evidence" "$TMP/t4.jsonl"

# 5. no ship-claim (local edit) → allow
build_transcript "$TMP/t5.jsonl" "Fixed the typo in the header." ""
assert_allow "no-claim-local" "$TMP/t5.jsonl"

# 6. ship-claim but stop_hook_active guard → allow (no loop)
build_transcript "$TMP/t6.jsonl" "Published — done." ""
assert_allow "stop-hook-active-guard" "$TMP/t6.jsonl" "true"

# 7. ship-claim with install-path read evidence → allow
build_transcript "$TMP/t7.jsonl" "Installed and shipped." "ls ~/.claude/skills/landed/SKILL.md"
assert_allow "claim-with-installpath-evidence" "$TMP/t7.jsonl"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
