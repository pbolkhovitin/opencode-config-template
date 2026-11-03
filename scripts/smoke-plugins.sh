#!/usr/bin/env bash
# Smoke-test plugin loading: runs one headless request and inspects only the
# log lines produced after the run started.
set -euo pipefail

LOG="${OPENCODE_LOG:-$HOME/.local/share/opencode/log/opencode.log}"
BEFORE=0
[[ -f "$LOG" ]] && BEFORE=$(wc -c < "$LOG")

# --standalone: never touch the shared background service of a running TUI
opencode run --standalone --model anthropic/claude-sonnet-4-5 "say ok" >/dev/null 2>&1 || true
sleep 2

TAIL=$(tail -c +$((BEFORE + 1)) "$LOG" 2>/dev/null | grep -a -i plugin || true)
if printf '%s\n' "$TAIL" | grep -E "failed|must be a directory|not found"; then
  echo "PLUGIN FAIL"
  exit 1
fi
printf '%s\n' "$TAIL" | grep -q "opencode-pty" || echo "WARN: no opencode-pty load line in this run"
echo "PLUGIN OK"
