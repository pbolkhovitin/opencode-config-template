---
name: active-network-recon
description: Authorized active network reconnaissance with nmap, masscan, arp-scan and hping3 - host discovery, port and service inventory, local L2 ARP inventory, path/MTU checks, safe rate limits and evidence capture. Use for approved LAN/WAN audits. Never use active scanning on OT/ICS segments; use passive ot-network-audit there.
---

# Active Network Reconnaissance

Active recon sends packets and is visible to IDS/IPS, firewalls and operators.
Use it only inside an approved scope and time window.

## Hard rules

- Written scope: target CIDRs/hosts, ports, protocol, allowed techniques, window,
  contact person, and stop conditions.
- Never scan OT/ICS, safety systems, medical or third-party networks without
  explicit written authorization. For OT use `ot-network-audit` in passive mode.
- Start small: discovery first, then top ports, then targeted services.
- Rate-limit everything. Default budget: <= 500 packets/s for nmap,
  <= 1000 pps for masscan; lower on fragile links.
- No spoofing, ARP poisoning, MITM, floods, or DoS techniques in production.
  `ettercap` and `yersinia` are lab-only tools and are not part of the `net` profile.
- Log every command with timestamp, source, target, rate and output file.
- Stop immediately on packet loss, CPU/queue growth, routing flaps, IDS alerts,
  operator complaints, or unexpected broadcast storms.

## Tool selection

| Goal | Tool | Notes |
|---|---|---|
| Host discovery | `nmap -sn` | ARP on local L2, ICMP/TCP elsewhere |
| TCP port inventory | `nmap -sT` | Unprivileged connect scan |
| TCP SYN scan | `nmap -sS` | Needs raw-socket capability/root |
| Service/version | `nmap -sV --version-light` | Targeted ports only |
| UDP services | `nmap -sU --top-ports` | Slow; expect false negatives |
| Large IPv4 ranges | `masscan` | Stateless; hard rate limit required |
| Local L2 inventory | `arp-scan` | Only the local broadcast domain |
| Path/MTU/firewall probes | `hping3` | Crafted packets; lab/approved scope |
| Packet evidence | `tcpdump`/`dumpcap` | Capture while scanning if needed |

## Safe examples

Set variables first:

```bash
TARGET=192.0.2.10
CIDR=192.0.2.0/24
IFACE=eth0
OUT=recon-$(date +%Y%m%d-%H%M%S)
```

Host discovery:

```bash
nmap -sn -PE -PS22,80,443 --max-retries 2 --host-timeout 30s "$CIDR" -oA "$OUT-discovery"
```

TCP top ports, unprivileged:

```bash
nmap -sT -Pn --top-ports 1000 --max-rate 500 --host-timeout 5m \
  "$TARGET" -oA "$OUT-tcp"
```

Targeted service/version:

```bash
nmap -sT -sV --version-light -p 22,80,443,445,3389 \
  --max-rate 300 "$TARGET" -oA "$OUT-services"
```

Safe NSE checks only:

```bash
nmap -sT -p 80,443 --script banner,http-title,ssl-cert \
  "$TARGET" -oA "$OUT-banner"
```

Avoid `--script vuln`, `--script intrusive`, `-T4/-T5`, `-A` and full port
ranges on production without approval.

masscan (large ranges only, never OT):

```bash
masscan "$CIDR" -p80,443 --rate 1000 --wait 5 -oL "$OUT-masscan.txt"
```

arp-scan (local segment only):

```bash
arp-scan --interface="$IFACE" --localnet --retry=3
```

hping3 (approved scope/lab; no flood, no spoofing):

```bash
hping3 -S -p 443 -c 3 "$TARGET"
hping3 --traceroute -S -p 443 -c 1 "$TARGET"
```

## Workflow

1. Confirm scope, window, contacts and rollback/stop plan.
2. Capture baseline: existing pcap, interface counters, logs if available.
3. Discovery, then targeted ports, then service/version.
4. Verify findings manually; do not trust a single scan.
5. Save raw output and a short report with command, time, target, rate, result.
6. Remove temporary files or store them according to the evidence policy.

## Report fields

- Scope and authorization reference
- Window, source host/interface, target ranges
- Tool and exact command, rate limit
- Open ports/services and evidence
- Anomalies, false positives, IDS/firewall reactions
- Stop conditions triggered (if any)
- Raw output paths and SHA-256

## Related

- `network-101`, `enumerating-network-services` - service enumeration
- `ot-network-audit` - passive OT/NIC audit
- `traffic-analysis-pcap`, `wireshark-analysis` - packet evidence
