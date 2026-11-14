# Net Profile — Сети, маршрутизация, коммутация, firewall, VPN

Профиль для проектирования, настройки и диагностики сетей: MikroTik RouterOS,
pfSense/OPNsense, D-Link, TP-Link, Ubiquiti UniFi, OpenWrt, Dahua, Trassir.

## Плагины (v2-совместимые)
- **opencode-supermemory** — persistent memory между сессиями
- **@tarquinen/opencode-dcp** — Dynamic Context Pruning
- **opencode-gemini-auth** — OAuth для Google/Gemini
- **opencode-handoff** — передача контекста в новую сессию

## Кастомные агенты (Tab)
- **@network-engineer** (primary) — L2/L3, VLAN, маршрутизация, firewall, VPN, RouterOS/OpenWrt/pfSense
- **@network-security** (primary) — сегментация, аудит ACL/firewall, IDS, усиление VPN
- **@bgp-ospf-analyst** (primary) — BGP/OSPF/IS-IS: best-path, фильтрация, сходимость
- **@packet-analyst** (subagent) — pcap, tshark/Zeek, таймлайны, артефакты

## Доступные MCP инструменты
- **ssh** — доступ к роутерам, коммутаторам, серверам (основной канал)
- **docker** — лаборатории (containerlab, GNS3, FRR, tshark) и анализ
- **filesystem** — конфиги, дампы, документация
- **duckduckgo** — документация вендоров, RFC, базы уязвимостей

## Оборудование и платформы
MikroTik RouterOS · pfSense/OPNsense · OpenWrt · Ubiquiti UniFi · D-Link · TP-Link ·
Dahua · Trassir · FRR/BIRD · nftables/iptables · WireGuard/IPsec/OpenVPN

## Скиллы
- `network-101`, `enumerating-network-services` — базовая теория и перечисление сервисов
- `active-network-recon` — активная разведка `nmap`/`masscan`/`arp-scan`/`hping3` в согласованном scope
- `mikrotik-routeros-rsc`, `routeros-fundamentals` — RouterOS v7, `.rsc`, REST API
- `configuring-pfsense-firewall-rules` — правила, NAT, VPN, QoS
- `homelab-vlan-segmentation` — VLAN для IoT/guest/trusted/server
- `openwrt-config`, `openwrt-procd-init`, `openwrt-image-build`, `podkop-openwrt-guide`
- `wireshark-analysis`, `traffic-analysis-pcap`, `analyzing-network-traffic-with-wireshark`
- `docker-kubernetes` — контейнерные лаборатории

## Правила
- **Read-only first**: сначала факты (конфиг, топология, логи, счётчики), потом изменения
- Перед изменением — backup конфигурации и rollback-план
- На MikroTik — `safe mode`; на удалённом оборудовании — второй путь доступа или таймер отката
- Активные действия (сканирование, инъекция трафика) — только в согласованном scope и окне; rate limit, запрет OT/ICS, `ettercap`/`yersinia` — только lab
- Пароли — только из Vault (`agent-vault`)
- **sudo**: только `sudo -A`, никогда `sudo -S`

## Workflow
1. **Инвентаризация** — что за устройство, прошивка, роль, текущая конфигурация
2. **Диагностика** — ping/mtr, tcpdump, conntrack, логи firewall, SNMP, LLDP
3. **План** — минимальное изменение + rollback
4. **Применение** — safe mode / окно / подтверждение пользователя
5. **Верификация** — счётчики правил, таблицы маршрутизации, доступность сервисов
6. **Документация** — схема, адресация, матрица доступа

## Docs

Пути относительно корня репозитория `opencode-config-template`:

- `docs/net/README.md` — сценарии сетевого профиля
- `docs/profiles-agents-matrix.md` — матрица профилей
