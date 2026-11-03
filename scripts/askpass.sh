#!/usr/bin/env bash
# Secure sudo askpass for opencode
set -euo pipefail

ASKPASS_TIMEOUT=30

if command -v systemd-ask-password >/dev/null 2>&1; then
    exec systemd-ask-password --timeout="$ASKPASS_TIMEOUT" "[sudo] password for $(whoami): "
fi

TTY="/dev/tty"
if [ ! -c "$TTY" ]; then
    echo "askpass: no terminal available — use 'sudo -k' or run in a terminal" >&2
    exit 1
fi

printf "[sudo] password for %s: " "$(whoami)" > "$TTY"
stty -echo < "$TTY"
IFS= read -r -t "$ASKPASS_TIMEOUT" password < "$TTY"
stty echo < "$TTY"
echo > "$TTY"

if [ -z "${password:-}" ]; then
    echo "askpass: password input timed out or empty" >&2
    exit 1
fi

printf '%s\n' "$password"
