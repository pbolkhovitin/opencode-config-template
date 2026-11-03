#!/usr/bin/env bash
# ot-net-audit.sh — пассивный аудит NIC и egress-трафика.
#
# Локальный хост:
#   inventory --iface IF [--out FILE]
#   capture --iface IF [--duration SEC] [--direction out|in|both] [--out FILE] [--dry-run] [--force]
#
# Сторонний сервер (read-only по SSH):
#   remote-inventory --ssh TARGET --iface IF [--sudo] [--out FILE] [--dry-run]
#   remote-capture --ssh TARGET --iface IF [--duration SEC] [--direction out|both]
#                  [--method auto|dumpcap|tcpdump] [--sudo] [--out FILE] [--dry-run] [--force]
#
# L2-зеркало:
#   mirror-plan --source-port PORT[,PORT...] --dest-port PORT
#               [--direction out|in|both] [--vendor dlink|generic] [--out FILE]
#
# Анализ:
#   analyze --pcap FILE [--out FILE]
#   egress  --pcap FILE [--server-ip IP] [--server-mac MAC] [--out FILE]
#
# Ограничения: только пассивные действия. SPAN/TAP или изолированная лаборатория.
# Запрещены nmap/masscan/arp-scan/ping sweep/hping3/ARP spoofing/packet injection.
set -euo pipefail

IFACE=""
OUT=""
DURATION=600
DIRECTION="both"
DIRECTION_SET=0
METHOD="auto"
SSH_TARGET=""
USE_SUDO=0
DRY_RUN=0
FORCE=0
PCAP=""
SERVER_IP=""
SERVER_MAC=""
SOURCE_PORT=""
DEST_PORT=""
VENDOR="dlink"

usage() {
  cat <<'EOF'
usage: ot-net-audit.sh <mode> [options]

modes:
  inventory         локальный NIC: link, driver, offloads, routes, LLDP, posture
  capture           локальный захват (dumpcap), по умолчанию оба направления
  remote-inventory  read-only инвентарь NIC стороннего сервера по SSH
  remote-capture    egress-захват с интерфейса стороннего сервера по SSH
  mirror-plan       план SPAN/mirror на L2-коммутаторе (D-Link DGS-1210 / generic)
  analyze           анализ pcap: протоколы, endpoints, conversations, expert
  egress            анализ того, что сервер отправляет в сеть, и влияния на OT

common:
  --out FILE        сохранить отчёт (markdown) или pcap
  --dry-run         показать команды, ничего не выполнять
  --force           перезаписать pcap
  -h, --help        эта справка

inventory:
  --iface IF

capture:
  --iface IF --duration SEC --direction out|in|both

remote-inventory:
  --ssh [user@]host --iface IF [--sudo]

remote-capture:
  --ssh [user@]host --iface IF [--duration SEC] [--direction out|both]
  [--method auto|dumpcap|tcpdump] [--sudo]

mirror-plan:
  --source-port PORT[,PORT...] --dest-port PORT
  [--direction out|in|both] [--vendor dlink|generic]

analyze / egress:
  --pcap FILE
  egress: [--server-ip IP] [--server-mac MAC]

examples:
  ot-net-audit.sh inventory --iface enp2s0f0 --out inventory.md
  ot-net-audit.sh remote-inventory --ssh root@10.20.0.15 --iface eth0
  ot-net-audit.sh remote-capture --ssh root@10.20.0.15 --iface eth0 \
      --duration 600 --direction out --out server-egress.pcapng
  ot-net-audit.sh mirror-plan --source-port 1-8 --dest-port 24 \
      --direction out --vendor dlink
  ot-net-audit.sh egress --pcap server-egress.pcapng --server-ip 10.20.0.15

Ограничения:
  - захват только с SPAN/TAP или в изолированной лаборатории;
  - capture-NIC без IP и default route;
  - не менять offloads/speed/duplex/ring/FEC на production;
  - запрещены nmap, masscan, arp-scan, ping sweep, hping3,
    ARP spoofing, ettercap, yersinia и любая отправка пакетов;
  - pcap хранить с SHA-256, временем и точкой захвата.
EOF
}

die() { echo "ot-net-audit: $*" >&2; exit 2; }
have() { command -v "$1" >/dev/null 2>&1; }
need() { have "$1" || die "required tool not found: $1"; }

# shellcheck disable=SC2317
run() {
  printf '\n### %s\n\n```\n' "$*"
  "$@" 2>&1 || true
  printf '```\n'
}

# shellcheck disable=SC2317
run_optional() {
  printf '\n### %s\n\n```\n' "$*"
  "$@" 2>&1 || echo "(unavailable)"
  printf '```\n'
}

section() { printf '\n%s\n' "$*"; }

open_out() {
  [[ -n "$OUT" ]] || return 0
  exec > >(tee "$OUT") 2>&1
}

validate_iface() {
  [[ "$1" =~ ^[A-Za-z0-9_.:-]+$ ]] || die "invalid interface: $1"
}

validate_target() {
  [[ "$1" =~ ^[A-Za-z0-9_.@:-]+$ ]] || die "invalid ssh target: $1"
  [[ "$1" != -* ]] || die "invalid ssh target: $1"
}

validate_mac() {
  [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || die "invalid MAC: $1"
}

is_ipv4() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=.
  local -a o=($1)
  local x
  for x in "${o[@]}"; do (( x >= 0 && x <= 255 )) || return 1; done
}

is_ipv6() {
  [[ "$1" == *:* ]] && [[ "$1" =~ ^[0-9A-Fa-f:]+$ ]]
}

validate_ip() {
  is_ipv4 "$1" || is_ipv6 "$1" || die "invalid IP: $1"
}

validate_ports() {
  [[ "$1" =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]] || die "invalid port list: $1"
  local p
  local IFS=,
  for p in $1; do
    local a=${p%-*} b=${p#*-}
    (( a >= 1 && a <= 65535 )) || die "invalid port: $p"
    (( b >= 1 && b <= 65535 )) || die "invalid port: $p"
  done
}

port_or_list() {
  [[ "$1" =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]] || die "invalid port: $1"
}

direction_dumpcap() {
  case "$1" in
    out) echo out ;;
    in) echo in ;;
    both) echo inout ;;
    *) die "invalid direction: $1 (expected out|in|both)" ;;
  esac
}

direction_tcpdump() {
  case "$1" in
    out) echo out ;;
    in) echo in ;;
    both) echo inout ;;
    *) die "invalid direction: $1 (expected out|in|both)" ;;
  esac
}

direction_mirror() {
  case "$1" in
    out) echo tx ;;
    in) echo rx ;;
    both) echo both ;;
    *) die "invalid direction: $1 (expected out|in|both)" ;;
  esac
}

timestamp() { date +%Y%m%d-%H%M%S; }

default_pcap() {
  local prefix=$1
  printf '%s-%s.pcapng' "$prefix" "$(timestamp)"
}

sha_and_info() {
  local file=$1
  [[ -s "$file" ]] || die "capture is empty: $file"
  if have sha256sum; then
    printf '\n### SHA-256\n\n```\n'
    sha256sum "$file"
    printf '```\n'
  fi
  if have capinfos; then
    printf '\n### capture info\n\n```\n'
    capinfos "$file" 2>&1 || true
    printf '```\n'
  fi
}

inventory_local() {
  [[ -n "$IFACE" ]] || die "inventory requires --iface"
  validate_iface "$IFACE"
  ip link show dev "$IFACE" >/dev/null 2>&1 || die "interface not found: $IFACE"
  open_out

  section "# NIC audit inventory"
  section "## Interface $IFACE"
  printf '\n- date: `%s`\n- host: `%s`\n' "$(date -Is)" "$(uname -n)"

  section "## Link"
  run ip -br link
  run ip -d link show dev "$IFACE"
  run ip -s link show dev "$IFACE"
  run ip addr show dev "$IFACE"

  section "## Routes"
  run ip route
  run ip -6 route

  section "## Driver, firmware, offloads"
  run_optional ethtool "$IFACE"
  run_optional ethtool -i "$IFACE"
  run_optional ethtool -k "$IFACE"
  run_optional ethtool -S "$IFACE"
  run_optional ethtool --show-fec "$IFACE"
  run_optional ethtool --module-info "$IFACE"
  run_optional lspci -nnk
  run_optional networkctl status "$IFACE"
  run_optional nmcli device show "$IFACE"

  section "## L2 / LLDP"
  run_optional lldpcli show neighbors
  run_optional lldpcli show statistics
  run_optional bridge link show dev "$IFACE"

  section "## Listeners"
  run_optional ss -tulpen

  section "## Firewall"
  run_optional nft list ruleset

  section "## Host forwarding posture"
  for key in \
    net.ipv4.ip_forward \
    net.ipv6.conf.all.forwarding \
    net.ipv6.conf.all.accept_ra \
    net.ipv4.conf.all.rp_filter \
    net.ipv4.conf.all.send_redirects \
    net.ipv4.conf.all.accept_redirects; do
    printf '\n### %s\n\n```\n' "$key"
    sysctl "$key" 2>&1 || true
    printf '```\n'
  done

  section "## Time"
  run_optional timedatectl
  run_optional chronyc tracking

  section "## Capture plan"
  cat <<EOF

- Предпочтительно: SPAN/TAP на коммутаторе, capture-NIC без IP.
- Локально: \`ot-net-audit.sh capture --iface $IFACE --duration 600 --direction both\`.
- Для egress стороннего сервера используйте \`remote-capture\` или \`mirror-plan\`.
- Перед захватом: \`scripts/ot-guard.sh passive --target <segment>\`.
EOF
}

capture_local() {
  [[ -n "$IFACE" ]] || die "capture requires --iface"
  validate_iface "$IFACE"
  [[ "$DURATION" =~ ^[0-9]+$ ]] && (( DURATION > 0 )) || die "invalid duration: $DURATION"
  ip link show dev "$IFACE" >/dev/null 2>&1 || die "interface not found: $IFACE"

  local out=${OUT:-$(default_pcap "ot-baseline-$IFACE")}
  local dirflag
  dirflag=$(direction_dumpcap "$DIRECTION")

  if (( DRY_RUN )); then
    printf 'dumpcap -i %q -P %q -s 0 -B 64 -a duration:%q -f %q -w %q\n' \
      "$IFACE" "$dirflag" "$DURATION" "not port 22" "$out"
    return 0
  fi

  need dumpcap
  [[ -e "$out" && $FORCE -eq 0 ]] && die "file exists (use --force): $out"
  echo "WARNING: capture only on SPAN/TAP or isolated lab; press Ctrl-C to stop." >&2
  dumpcap -i "$IFACE" -P "$dirflag" -s 0 -B 64 -a "duration:$DURATION" \
    -f "not port 22" -w "$out"
  sha_and_info "$out"
}

remote_script_inventory() {
  cat <<'REMOTE'
set -u
IF="$1"
SUDO=""
[ "${2:-}" = "sudo" ] && SUDO="sudo -n"
run() {
  printf '\n### %s\n\n```\n' "$*"
  if [ -n "$SUDO" ]; then $SUDO "$@" 2>&1 || echo "(unavailable)"; else "$@" 2>&1 || echo "(unavailable)"; fi
  printf '```\n'
}
section() { printf '\n%s\n' "$*"; }
section "# NIC audit inventory"
section "## Interface $IF"
printf '\n- date: `%s`\n- host: `%s`\n' "$(date -Is)" "$(uname -n)"
section "## Link"
run ip -br link
run ip -d link show dev "$IF"
run ip -s link show dev "$IF"
run ip addr show dev "$IF"
section "## Routes"
run ip route
run ip -6 route
section "## Driver, firmware, offloads"
run ethtool "$IF"
run ethtool -i "$IF"
run ethtool -k "$IF"
run ethtool -S "$IF"
run ethtool --show-fec "$IF"
run lspci -nnk
run networkctl status "$IF"
run nmcli device show "$IF"
section "## L2 / LLDP"
run lldpcli show neighbors
run lldpcli show statistics
run bridge link show dev "$IF"
section "## Listeners"
run ss -tulpen
section "## Firewall"
run nft list ruleset
section "## Host forwarding posture"
for key in net.ipv4.ip_forward net.ipv6.conf.all.forwarding net.ipv6.conf.all.accept_ra \
  net.ipv4.conf.all.rp_filter net.ipv4.conf.all.send_redirects net.ipv4.conf.all.accept_redirects; do
  printf '\n### %s\n\n```\n' "$key"
  sysctl "$key" 2>&1 || true
  printf '```\n'
done
section "## Time"
run timedatectl
run chronyc tracking
REMOTE
}

ssh_base() {
  local -a cmd=()
  # shellcheck disable=SC2206
  cmd=(${OT_NET_AUDIT_SSH:-ssh})
  cmd+=(-o BatchMode=yes -o ConnectTimeout=10 -T)
  printf '%s\n' "${cmd[@]}"
}

remote_inventory() {
  [[ -n "$SSH_TARGET" ]] || die "remote-inventory requires --ssh"
  [[ -n "$IFACE" ]] || die "remote-inventory requires --iface"
  validate_target "$SSH_TARGET"
  validate_iface "$IFACE"
  open_out

  local sudo_flag=""
  (( USE_SUDO )) && sudo_flag="sudo"
  local -a sshcmd
  mapfile -t sshcmd < <(ssh_base)

  if (( DRY_RUN )); then
    printf '%q ' "${sshcmd[@]}" "$SSH_TARGET" "bash -s -- $IFACE $sudo_flag"
    printf '\n'
    return 0
  fi

  section "# NIC audit inventory"
  section "## Remote target"
  printf '\n- target: `%s`\n- interface: `%s`\n- date: `%s`\n' \
    "$SSH_TARGET" "$IFACE" "$(date -Is)"
  "${sshcmd[@]}" "$SSH_TARGET" "bash -s -- '$IFACE' '$sudo_flag'" < <(remote_script_inventory)
}

remote_capture() {
  [[ -n "$SSH_TARGET" ]] || die "remote-capture requires --ssh"
  [[ -n "$IFACE" ]] || die "remote-capture requires --iface"
  validate_target "$SSH_TARGET"
  validate_iface "$IFACE"
  [[ "$DURATION" =~ ^[0-9]+$ ]] && (( DURATION > 0 )) || die "invalid duration: $DURATION"
  case "$DIRECTION" in out|in|both) ;; *) die "invalid direction: $DIRECTION" ;; esac
  case "$METHOD" in auto|dumpcap|tcpdump) ;; *) die "invalid method: $METHOD" ;; esac

  local out=${OUT:-$(default_pcap "ot-egress-${SSH_TARGET//[^A-Za-z0-9_.-]/_}")}
  local dirflag
  dirflag=$(direction_dumpcap "$DIRECTION")
  local sudo_prefix=""
  (( USE_SUDO )) && sudo_prefix="sudo -n "

  local dump="dumpcap -i $IFACE -P $dirflag -s 0 -B 64 -a duration:$DURATION -f 'not port 22' -w -"
  local tcp="timeout $((DURATION + 10)) tcpdump -i $IFACE -Q $dirflag -s 0 -w - 'not port 22'"
  local remote_cmd
  case "$METHOD" in
    dumpcap) remote_cmd="$dump" ;;
    tcpdump) remote_cmd="$tcp" ;;
    auto) remote_cmd="if command -v dumpcap >/dev/null 2>&1; then $dump; else $tcp; fi" ;;
  esac
  remote_cmd="${sudo_prefix}${remote_cmd}"

  local -a sshcmd
  mapfile -t sshcmd < <(ssh_base)

  if (( DRY_RUN )); then
    printf '%q ' "${sshcmd[@]}" "$SSH_TARGET" "$remote_cmd"
    printf '> %q\n' "$out"
    return 0
  fi

  [[ -e "$out" && $FORCE -eq 0 ]] && die "file exists (use --force): $out"
  need capinfos
  echo "WARNING: egress capture must be authorized; mirror/SPAN only, no ARP spoofing." >&2
  local errfile="${out}.stderr"
  timeout $((DURATION + 45)) "${sshcmd[@]}" "$SSH_TARGET" "$remote_cmd" >"$out" 2>"$errfile" || {
    rc=$?
    [[ -s "$errfile" ]] && tail -20 "$errfile" >&2
    rm -f "$errfile"
    die "remote capture failed (rc=$rc)"
  }
  rm -f "$errfile"
  sha_and_info "$out"
}

mirror_plan() {
  [[ -n "$SOURCE_PORT" ]] || die "mirror-plan requires --source-port"
  [[ -n "$DEST_PORT" ]] || die "mirror-plan requires --dest-port"
  validate_ports "$SOURCE_PORT"
  port_or_list "$DEST_PORT"
  [[ "$DEST_PORT" != *,* && "$DEST_PORT" != *-* ]] || die "destination must be a single port"
  local dir
  dir=$(direction_mirror "$DIRECTION")
  open_out

  section "# SPAN/mirror plan"
  printf '\n- source ports: `%s`\n- destination port: `%s`\n- direction: `%s`\n- vendor: `%s`\n' \
    "$SOURCE_PORT" "$DEST_PORT" "$DIRECTION" "$VENDOR"
  cat <<EOF

## Before you start

- Согласуйте окно и точку подключения с владельцем сети и АСУ ТП.
- Destination port — выделенный порт для capture-хоста; он теряет обычную
  коммутацию, не используйте его для management/uplink.
- Capture-хост: отдельный NIC без IP и default route; management — через другой NIC.
- Не зеркалируйте management VLAN и uplink, если это увеличивает нагрузку.
- После захвата обязательно снимите mirror и проверьте обычную связность.

## Configuration
EOF
  if [[ "$VENDOR" == "dlink" ]]; then
    cat <<EOF

### D-Link DGS-1210 (CLI, проверьте синтаксис прошивки)

\`\`\`text
enable
configure terminal
mirror session 1 source interface $SOURCE_PORT $dir
mirror session 1 destination interface $DEST_PORT
show mirror
end
\`\`\`

Снятие:

\`\`\`text
configure terminal
no mirror session 1
show mirror
end
\`\`\`
EOF
  else
    cat <<EOF

### Generic L2 switch

\`\`\`text
monitor session 1 source interface $SOURCE_PORT $dir
monitor session 1 destination interface $DEST_PORT
show monitor session 1
\`\`\`

Снятие:

\`\`\`text
no monitor session 1
\`\`\`
EOF
  fi
  cat <<EOF

## Verification

- На capture-хосте: \`ip -br link\`, \`tcpdump -i IF -c 5\`.
- Убедитесь, что видны оба направления (если нужно): compare request/response.
- Проверьте, что mirror не перегружает CPU/backplane коммутатора.
- Зафиксируйте: коммутатор, порт источника, порт назначения, направление,
  время начала/окончания, кто снимал mirror.

## Rollback

- Выполните команду снятия mirror.
- Проверьте \`show mirror\` / \`show monitor\`.
- Проверьте связность source-портов и management.
EOF
}

scope_filter() {
  local parts=()
  if [[ -n "$SERVER_IP" ]]; then
    is_ipv4 "$SERVER_IP" && parts+=("ip.src == $SERVER_IP") || parts+=("ipv6.src == $SERVER_IP")
  fi
  if [[ -n "$SERVER_MAC" ]]; then
    parts+=("eth.src == $SERVER_MAC")
  fi
  if (( ${#parts[@]} == 0 )); then
    echo "frame"
  else
    local IFS=" || "
    echo "(${parts[*]})"
  fi
}

count_filter() {
  local label=$1 filter=$2 pcap=$3
  local n
  n=$(tshark -r "$pcap" -Y "$filter" -T fields -e frame.number 2>/dev/null | wc -l | tr -d ' ')
  printf '| %s | %s |\n' "$label" "$n"
}

analyze_pcap() {
  [[ -n "$PCAP" ]] || die "analyze requires --pcap"
  [[ -f "$PCAP" ]] || die "pcap not found: $PCAP"
  need capinfos
  need tshark
  open_out

  section "# PCAP analysis"
  printf '\n- file: `%s`\n- date: `%s`\n' "$PCAP" "$(date -Is)"
  run capinfos "$PCAP"
  run tshark -r "$PCAP" -q -z io,phs
  run tshark -r "$PCAP" -q -z endpoints,ip
  run tshark -r "$PCAP" -q -z conv,tcp
  run tshark -r "$PCAP" -q -z expert

  section "## Industrial protocols"
  local industrial='frame.protocols matches "(modbus|s7comm|dnp3|iec60870|opcua|enip|pn_io|goose|bacnet)"'
  printf '\n```\n'
  tshark -r "$PCAP" -Y "$industrial" -T fields -e frame.number -e _ws.col.Protocol 2>/dev/null | head -100 || true
  printf '```\n'

  section "## Manual checks"
  cat <<'EOF'

Проверьте вручную: STP/BPDU, ARP, DHCP, IPv6 RA, LLDP/CDP, IGMP, mDNS,
NBNS, SSDP, broadcast/multicast, one-way TCP, повторяющиеся SYN без ACK.
Для egress стороннего сервера используйте режим `egress`.
EOF
}

egress() {
  [[ -n "$PCAP" ]] || die "egress requires --pcap"
  [[ -f "$PCAP" ]] || die "pcap not found: $PCAP"
  [[ -z "$SERVER_IP" ]] || validate_ip "$SERVER_IP"
  [[ -z "$SERVER_MAC" ]] || validate_mac "$SERVER_MAC"
  need capinfos
  need tshark
  open_out

  local scope
  scope=$(scope_filter)

  section "# Egress analysis"
  printf '\n- file: `%s`\n- scope: `%s`\n- date: `%s`\n' "$PCAP" "$scope" "$(date -Is)"
  if [[ -z "$SERVER_IP" && -z "$SERVER_MAC" ]]; then
    echo ""
    echo "WARNING: server IP/MAC not set; analyzing all traffic, not only egress." >&2
  fi

  run capinfos "$PCAP"
  run tshark -r "$PCAP" -Y "$scope" -q -z io,phs
  run tshark -r "$PCAP" -Y "$scope" -q -z endpoints,ip
  run tshark -r "$PCAP" -Y "$scope" -q -z conv,tcp

  section "## L2 noise and discovery"
  printf '\n| Check | Packets |\n|---|---:|\n'
  count_filter "STP/BPDU" "$scope && stp" "$PCAP"
  count_filter "ARP" "$scope && arp" "$PCAP"
  count_filter "DHCP" "$scope && dhcp" "$PCAP"
  count_filter "IPv6 RA" "$scope && icmpv6.type == 134" "$PCAP"
  count_filter "LLDP" "$scope && lldp" "$PCAP"
  count_filter "CDP" "$scope && cdp" "$PCAP"
  count_filter "IGMP" "$scope && igmp" "$PCAP"
  count_filter "mDNS" "$scope && udp.port == 5353" "$PCAP"
  count_filter "NBNS" "$scope && udp.port == 137" "$PCAP"
  count_filter "SSDP" "$scope && udp.port == 1900" "$PCAP"
  count_filter "Broadcast" "$scope && eth.dst == ff:ff:ff:ff:ff:ff" "$PCAP"
  count_filter "IPv4 multicast" "$scope && ip.dst >= 224.0.0.0 && ip.dst <= 239.255.255.255" "$PCAP"

  section "## L3 routing and control"
  printf '\n| Check | Packets |\n|---|---:|\n'
  count_filter "ICMP redirect" "$scope && icmp.type == 5" "$PCAP"
  count_filter "VRRP" "$scope && vrrp" "$PCAP"
  count_filter "OSPF" "$scope && ospf" "$PCAP"
  count_filter "RIP" "$scope && rip" "$PCAP"
  count_filter "BGP" "$scope && bgp" "$PCAP"
  count_filter "DNS" "$scope && dns" "$PCAP"
  count_filter "NTP" "$scope && ntp" "$PCAP"

  section "## Scanning / connection attempts"
  printf '\n| Check | Packets |\n|---|---:|\n'
  count_filter "SYN without ACK" "$scope && tcp.flags.syn == 1 && tcp.flags.ack == 0" "$PCAP"
  count_filter "TCP RST" "$scope && tcp.flags.reset == 1" "$PCAP"
  count_filter "ICMP echo" "$scope && icmp.type == 8" "$PCAP"

  section "## OT protocols"
  printf '\n| Protocol | Packets |\n|---|---:|\n'
  count_filter "Modbus" "$scope && modbus" "$PCAP"
  count_filter "S7comm" "$scope && s7comm" "$PCAP"
  count_filter "DNP3" "$scope && dnp3" "$PCAP"
  count_filter "IEC 60870-5-104" "$scope && iec60870_104" "$PCAP"
  count_filter "OPC UA" "$scope && opcua" "$PCAP"
  count_filter "EtherNet/IP" "$scope && enip" "$PCAP"
  count_filter "PROFINET" "$scope && pn_io" "$PCAP"
  count_filter "GOOSE" "$scope && goose" "$PCAP"
  count_filter "BACnet" "$scope && bacnet" "$PCAP"

  section "## OT write/control candidates"
  printf '\n| Check | Packets |\n|---|---:|\n'
  count_filter "Modbus write coils (FC5/15)" "$scope && (modbus.func_code == 5 || modbus.func_code == 15)" "$PCAP"
  count_filter "Modbus write registers (FC6/16)" "$scope && (modbus.func_code == 6 || modbus.func_code == 16)" "$PCAP"
  count_filter "Modbus mask write (FC22/23)" "$scope && (modbus.func_code == 22 || modbus.func_code == 23)" "$PCAP"
  cat <<'EOF'

Для S7comm, DNP3, IEC 104, OPC UA, EtherNet/IP и PROFINET проверьте
write/control-операции вручную по декодированным полям. Не делайте вывод
«безопасно» только по отсутствию Modbus write.

## Top destinations

См. `endpoints,ip` выше. Для egress-сервера важны:
- внешние/чужие подсети;
- неожиданные DNS/NTP/HTTP/HTTPS;
- broadсast/multicast и discovery;
- высокая pps или резкие всплески.
EOF
}

parse_common() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --iface) IFACE=${2:-}; shift 2 ;;
      --out) OUT=${2:-}; shift 2 ;;
      --duration) DURATION=${2:-}; shift 2 ;;
      --direction) DIRECTION=${2:-}; DIRECTION_SET=1; shift 2 ;;
      --method) METHOD=${2:-}; shift 2 ;;
      --ssh) SSH_TARGET=${2:-}; shift 2 ;;
      --sudo) USE_SUDO=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --force) FORCE=1; shift ;;
      --pcap) PCAP=${2:-}; shift 2 ;;
      --server-ip) SERVER_IP=${2:-}; shift 2 ;;
      --server-mac) SERVER_MAC=${2:-}; shift 2 ;;
      --source-port) SOURCE_PORT=${2:-}; shift 2 ;;
      --dest-port) DEST_PORT=${2:-}; shift 2 ;;
      --vendor) VENDOR=${2:-}; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
}

main() {
  [[ $# -gt 0 ]] || { usage >&2; exit 2; }
  local mode=$1; shift
  case "$mode" in
    inventory) parse_common "$@"; inventory_local ;;
    capture) parse_common "$@"; capture_local ;;
    remote-inventory) parse_common "$@"; remote_inventory ;;
    remote-capture) parse_common "$@"; (( DIRECTION_SET )) || DIRECTION=out; remote_capture ;;
    mirror-plan) parse_common "$@"; mirror_plan ;;
    analyze) parse_common "$@"; analyze_pcap ;;
    egress) parse_common "$@"; egress ;;
    -h|--help|help) usage ;;
    *) die "unknown mode: $mode (see --help)" ;;
  esac
}

main "$@"
