#!/usr/bin/env bash
# doctor.sh — verify the landed install + hook wiring.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="${HOME}/.claude/settings.json"
HOOK="$SKILL_DIR/hooks/landed_check.py"
ok=0; warn=0; fail=0
green() { printf '\033[32m✓\033[0m %s\n' "$1"; ok=$((ok+1)); }
yellow(){ printf '\033[33m!\033[0m %s\n' "$1"; warn=$((warn+1)); }
red()   { printf '\033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }

printf 'landed doctor — %s\n\n' "$SKILL_DIR"

for f in SKILL.md README.md LICENSE hooks/landed_check.py hooks/install_hook.sh \
         references/destination-map.md references/examples.md; do
  if [ -f "$SKILL_DIR/$f" ]; then green "present: $f"; else red "missing: $f"; fi
done

if python3 -c "import ast; ast.parse(open('$HOOK').read())" 2>/dev/null; then
  green "hook parses: landed_check.py"
else
  red "hook has a syntax error: landed_check.py"
fi

if [ -f "$SETTINGS" ] && grep -q "landed_check.py" "$SETTINGS" 2>/dev/null; then
  green "hook wired into settings.json (proactive mode ON)"
else
  yellow "hook NOT wired — proactive blocking off. Enable: bash $SKILL_DIR/hooks/install_hook.sh"
fi

printf '\n%d ok, %d warn, %d fail\n' "$ok" "$warn" "$fail"
[ "$fail" -eq 0 ]
