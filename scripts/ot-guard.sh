#!/usr/bin/env bash
# ot-guard.sh — разрешает или запрещает действие в OT/ICS-сети.
#
# Пассивный режим (pcap, SPAN/TAP, чтение конфигов) разрешён всегда.
# Активный режим требует одновременно:
#   1) OT_ALLOW_ACTIVE=1
#   2) scope-файл (--scope или OT_SCOPE_FILE)
#   3) цель входит в TARGETS и не входит в FORBIDDEN
#   4) текущее время внутри WINDOW_START..WINDOW_END
#
# Коды возврата: 0 — разрешено, 2 — ошибка аргументов, 3 — запрещено.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: ot-guard.sh <passive|active> --target <IP> [--scope <file>]

  passive   пассивные действия (pcap, чтение конфигов) — разрешены всегда
  active    активные действия — только при OT_ALLOW_ACTIVE=1 и scope в окне работ

Переменные окружения:
  OT_ALLOW_ACTIVE=1     включить активный режим
  OT_SCOPE_FILE=<path>  scope-файл (по умолчанию)
  OT_ACTIONS_LOG=<path> журнал решений (по умолчанию ~/.local/share/opencode/ot-actions.log)
EOF
}

mode=""
target=""
scope="${OT_SCOPE_FILE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    passive|active) mode="$1"; shift ;;
    --target) target="${2:-}"; shift 2 || true ;;
    --scope) scope="${2:-}"; shift 2 || true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$mode" || -z "$target" ]]; then
  usage >&2
  exit 2
fi

LOG="${OT_ACTIONS_LOG:-$HOME/.local/share/opencode/ot-actions.log}"
mkdir -p "$(dirname "$LOG")"

decision="$(
python3 - "$mode" "$target" "$scope" "${OT_ALLOW_ACTIVE:-0}" <<'PY'
import datetime
import ipaddress
import os
import re
import sys

mode, target, scope, allow = sys.argv[1:5]


def deny(reason):
    print(f"deny {reason}")
    sys.exit(3)


def parse_scope(path):
    data = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            data[key.strip().upper()] = value.strip().strip('"').strip("'")
    return data


def networks(value):
    return [n for n in re.split(r"[,\s]+", value or "") if n]


if mode == "passive":
    print("allow passive mode")
    sys.exit(0)

if allow != "1":
    deny("active mode requires OT_ALLOW_ACTIVE=1")

if not scope or not os.path.isfile(scope):
    deny(f"scope file not found: {scope or '(unset)'}")

try:
    ip = ipaddress.ip_address(target)
except ValueError:
    deny(f"invalid target: {target}")

data = parse_scope(scope)

for item in networks(data.get("FORBIDDEN", "")):
    try:
        if ip in ipaddress.ip_network(item, strict=False):
            deny(f"target {target} is forbidden by {item}")
    except ValueError:
        deny(f"invalid FORBIDDEN entry: {item}")

def _in(address, item):
    return address in ipaddress.ip_network(item, strict=False)


targets = networks(data.get("TARGETS", ""))
if not targets:
    deny("scope has no TARGETS")
if not any(_in(ip, item) for item in targets):
    deny(f"target {target} is outside TARGETS")


start = data.get("WINDOW_START", "")
end = data.get("WINDOW_END", "")
if not start or not end:
    deny("scope has no WINDOW_START/WINDOW_END")

try:
    fmt = "%H:%M"
    t_start = datetime.datetime.strptime(start, fmt).time()
    t_end = datetime.datetime.strptime(end, fmt).time()
except ValueError:
    deny(f"invalid window: {start}..{end}")

now = datetime.datetime.now().time().replace(second=0, microsecond=0)
inside = (t_start <= now < t_end) if t_start <= t_end else (now >= t_start or now < t_end)
if not inside:
    deny(f"outside change window {start}..{end} (now {now.strftime(fmt)})")

print(f"allow active mode within {start}..{end}")
PY
)" || rc=$?

rc="${rc:-0}"
echo "$(date -Is) mode=$mode target=$target scope=${scope:-none} $decision" >> "$LOG"

if [[ "$rc" -ne 0 ]]; then
  echo "$decision" >&2
  exit 3
fi
echo "$decision"
