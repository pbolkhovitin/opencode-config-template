---
name: ot-network-audit
description: Passive audit of a server NIC and its egress traffic before connecting to an OT/ICS network. Covers local and remote inventory over SSH, link/driver/offloads, VLAN/MTU, LLDP, host forwarding posture, SPAN/mirror planning, baseline pcap, egress analysis and industrial protocol inventory. Use when preparing a host or a third-party server for an OT segment, validating SPAN/TAP or switch mirror capture, or reviewing what a server sends into the OT network.
---

# OT Network Audit (passive)

Аудит сетевого интерфейса и **egress-трафика** сервера, который будет подключён
к сети АСУ ТП. Работает как с локальным хостом, так и со сторонним сервером:
инвентарь по SSH, захват с SPAN/TAP или зеркала L2-коммутатора.

Только чтение и пассивный захват. Никаких активных сканов и отправки пакетов.

## Когда использовать

- сервер готовят к подключению к OT-сегменту;
- нужно проверить NIC, драйвер, offloads, MTU/VLAN, LLDP и маршруты;
- сервер сторонний, доступа к нему нет или он ограничен, но нужно понять,
  что он посылает в сеть;
- нужно снять baseline pcap на SPAN/TAP или зеркале L2-коммутатора;
- нужно оценить, как egress сервера может повлиять на АСУ ТП:
  STP/BPDU, ARP, DHCP/RA, LLDP/CDP, multicast/broadcast, сканирование,
  OT-протоколы и write-операции;
- нужно подтвердить, что на хосте нет forwarding, DHCP/RA, лишних listeners
  и неожиданного default route.

## Жёсткие ограничения

- Захват — только с SPAN/TAP, зеркала L2-коммутатора или в изолированной
  лаборатории, после согласования с владельцем сети.
- Зеркало на коммутаторе — только в согласованное окно; после аудита
  обязательно снять mirror-сессию.
- Capture-NIC без IP и без default route; не включать bridging/forwarding.
- Не менять offloads, speed, duplex, ring, FEC на production.
- Запрещены `nmap`, `masscan`, `arp-scan`, ping sweep, `hping3`,
  packet injection, `ettercap`, `yersinia`.
- SSH — только `BatchMode=yes`, без пароля в чате и в аргументах командной
  строки; `sudo` — только `sudo -n`.
- pcap — копия улики: SHA-256, время, точка захвата, направление SPAN.
- Перед серией действий — `scripts/ot-guard.sh passive --target <IP>`.

## Инструмент

```bash
# локальный инвентарь (read-only)
config/skills/ot-network-audit/scripts/ot-net-audit.sh inventory \
  --iface enp2s0f0 --out nic-inventory.md

# локальный пассивный захват (SPAN/TAP или лаборатория)
config/skills/ot-network-audit/scripts/ot-net-audit.sh capture \
  --iface enp2s0f0 --duration 600 --direction both --out baseline.pcapng

# инвентарь стороннего сервера по SSH (read-only)
config/skills/ot-network-audit/scripts/ot-net-audit.sh remote-inventory \
  --ssh user@server --iface eth0 --out server-inventory.md

# egress стороннего сервера: по умолчанию только исходящий трафик
config/skills/ot-network-audit/scripts/ot-net-audit.sh remote-capture \
  --ssh user@server --iface eth0 --duration 600 --direction out \
  --out server-egress.pcapng

# план зеркала на D-Link DGS-1210 или аналоге
config/skills/ot-network-audit/scripts/ot-net-audit.sh mirror-plan \
  --source-port 1-8 --dest-port 24 --direction out --vendor dlink \
  --out mirror-plan.md

# анализ egress и влияния на OT
config/skills/ot-network-audit/scripts/ot-net-audit.sh egress \
  --pcap server-egress.pcapng --server-ip 10.10.0.50 --out egress.md
```

В deployed-профиле скрипт лежит в
`~/.config/opencode/skills/ot-network-audit/scripts/ot-net-audit.sh`.
`--dry-run` показывает команду без запуска. `remote-capture` исключает SSH
(`not port 22`), чтобы не захватывать собственный канал управления.

## Порядок аудита

### A. Локальный сервер

1. **Scope и разрешение.** Зафиксировать площадку, окно, ответственного.
   Выполнить `ot-guard.sh passive`.
2. **Инвентарь.** `inventory --iface IF`: link, driver/firmware, offloads,
   MTU/VLAN, LLDP, маршруты, listeners, firewall, sysctl, NTP.
3. **Проверка posture.** Один NIC в OT, нет forwarding/NAT/DHCP/RA,
   нет default route в OT, firewall default deny, только согласованные порты.
4. **Baseline.** 5–10 минут на SPAN/TAP; проверить оба направления.
5. **Анализ.** `analyze --pcap`: protocol hierarchy, endpoints, conversations,
   expert, industrial hits, STP/BPDU, DHCP, ARP, broadcast/multicast.
6. **Отчёт.** Заполнить `docs/ot/checklist-network-audit.md` и раздел
   «Сетевой интерфейс и baseline» в `docs/ot/report-template.md`.

### B. Сторонний сервер / egress

1. **Scope.** Согласовать окно, точку зеркала, порт коммутатора, ответственного.
2. **Инвентарь по SSH.** `remote-inventory --ssh ... --iface ...`; если доступ
   ограничен — только зеркало и пассивный анализ.
3. **Зеркало.** `mirror-plan` → согласовать → включить SPAN/mirror на время окна.
4. **Захват.** `remote-capture --direction out` (egress) или `capture` на
   mirror-destination порту; не захватывать лишний трафик.
5. **Снятие зеркала.** Сразу после окна; зафиксировать в отчёте.
6. **Анализ влияния.** `egress --pcap ... --server-ip ...`:
   L2 noise, L3-протоколы, сканирование, OT-протоколы и write-операции,
   top destinations, pps, broadcast/multicast.
7. **Отчёт.** Заполнить `docs/ot/checklist-third-party-egress.md` и раздел 9
   отчёта.

## Критерии готовности

- один NIC в OT-сегменте, без dual-homing;
- `net.ipv4.ip_forward=0`, `net.ipv6.conf.all.forwarding=0`,
  `accept_ra=0`, без NAT/DHCP-сервера;
- нет default route, ведущего в OT или из OT;
- firewall default deny; открыты только согласованные порты;
- LLDP показывает ожидаемого соседа; VLAN/MTU/speed/duplex/FEC соответствуют проекту;
- в baseline только ожидаемые OT-протоколы; нет STP/BPDU, широковещательных
  штормов и посторонних talkers;
- egress стороннего сервера не содержит неожиданных ARP/DHCP/RA/STP,
  сканирования, широковещательных storm-паттернов и OT write-операций;
- pcap и отчёт сохранены с SHA-256, временем и точкой захвата.

## Чего не делать

- не запускать `nmap`/`masscan`/`arp-scan` «для проверки связности»;
- не отправлять ARP/DHCP/STP/RA и не провоцировать протоколы;
- не менять настройки NIC и коммутатора на production вне окна;
- не оставлять mirror-сессию включённой после аудита;
- не подключать сервер к рабочей сети до baseline и согласования.

## Связанные документы

- `docs/ot/checklist-network-audit.md`
- `docs/ot/checklist-third-party-egress.md`
- `docs/ot/checklist-passive-audit.md`
- `docs/ot/report-template.md`
- `docs/ot/scope-template.md`
- `instructions/ot-safety.md`
