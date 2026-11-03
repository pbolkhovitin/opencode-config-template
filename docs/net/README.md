# Net Profile — Сети, маршрутизация, firewall, VPN

Профиль для проектирования и эксплуатации сетей. Конфиг: `profiles/net/opencode.jsonc`.
Запуск: `oc-net` или `ocp net`.

## Оборудование и платформы
MikroTik RouterOS · pfSense/OPNsense · OpenWrt · Ubiquiti UniFi · D-Link · TP-Link ·
Dahua · Trassir · FRR/BIRD · nftables/iptables · WireGuard/IPsec/OpenVPN

## Агенты
- `@network-engineer` (primary) — L2/L3, VLAN, STP, LACP, маршрутизация, NAT, firewall, VPN
- `@network-security` (primary) — сегментация, аудит ACL/firewall, IDS, защита management plane
- `@bgp-ospf-analyst` (primary) — BGP/OSPF/IS-IS: best-path, фильтрация, сходимость
- `@packet-analyst` (subagent) — pcap/tshark/Zeek, таймлайны, извлечение артефактов

## MCP
- **ssh** — доступ к роутерам и коммутаторам (основной канал)
- **docker** — лаборатории: containerlab, FRR, tshark, Zeek
- **filesystem** — конфиги, дампы, документация
- **duckduckgo** — документация вендоров, RFC, CVE

## Скиллы
- `routeros-fundamentals`, `mikrotik-routeros-rsc` — RouterOS v7, `.rsc`, REST API
- `configuring-pfsense-firewall-rules` — правила, NAT, IPsec/OpenVPN, QoS
- `homelab-vlan-segmentation` — VLAN IoT/guest/trusted/server
- `openwrt-config`, `openwrt-procd-init`, `openwrt-image-build`, `podkop-openwrt-guide`
- `network-101`, `enumerating-network-services` — теория и перечисление сервисов
- `active-network-recon` — активная разведка `nmap`/`masscan`/`arp-scan`/`hping3` в согласованном scope
- `wireshark-analysis`, `traffic-analysis-pcap`, `analyzing-network-traffic-with-wireshark`
- `docker-kubernetes` — контейнерные лаборатории

## Типовые задачи

### Диагностика доступности
```bash
ping -c 4 10.0.0.1
mtr -rwzc 20 10.0.0.1
tcpdump -ni any -c 200 'host 10.0.0.1 and not port 22'
conntrack -L | grep 10.0.0.1
```

### Активная разведка
Только в согласованном scope и окне; OT/ICS не сканировать.
```bash
nmap -sn -PE -PS22,80,443 --max-retries 2 --host-timeout 30s 192.0.2.0/24 -oA recon-discovery
nmap -sT -Pn --top-ports 1000 --max-rate 500 --host-timeout 5m 192.0.2.10 -oA recon-tcp
masscan 192.0.2.0/24 -p80,443 --rate 1000 --wait 5 -oL recon-masscan.txt
arp-scan --interface=eth0 --localnet --retry=3
hping3 -S -p 443 -c 3 192.0.2.10
```
`ettercap`/`yersinia` — только лаборатория, в профиль не входят. Подробности — скилл `active-network-recon`.

### MikroTik: безопасное изменение
```routeros
/system backup save name=before-change
/ip firewall filter print stats
# safe mode: Ctrl+X в терминале; выход без сохранения — Ctrl+D
```

### RouterOS .rsc
```bash
scp config.rsc admin@router:/tmp/
ssh admin@router '/import file-name=config.rsc'
```

### OSPF/BGP
```bash
vtysh -c 'show ip ospf neighbor'
vtysh -c 'show ip bgp summary'
vtysh -c 'show ip bgp 203.0.113.0/24'
```

### pcap
```bash
capinfos capture.pcap
tshark -r capture.pcap -q -z io,phs
tshark -r capture.pcap -Y 'dns.flags.rcode != 0'
```

## Правила
- **Read-only first**: конфиг, топология, логи, счётчики — потом изменения
- Перед изменением — backup конфигурации и rollback-план
- MikroTik — `safe mode`; удалённое оборудование — второй путь доступа или таймер отката
- Активные действия (сканирование, инъекция) — только в согласованном scope/окне, с rate limit; OT/ICS не сканировать
- Проверяй результат по счётчикам и логам, а не только по коду возврата
- Пароли — только из Vault (`agent-vault`)
