# Профиль OT — АСУ ТП и промышленные сети

> Профиль для аудита, анализа, реагирования и проектирования сетей АСУ ТП.
> Модель: `anthropic/claude-sonnet-4-5`. Запуск: `ocp ot` или `oc-ot`.

## Режимы работы

| Режим | Когда | Ограничения |
|---|---|---|
| **Пассивный** (по умолчанию) | аудит, инвентаризация, анализ pcap, чтение конфигов | только чтение, без пакетов в сеть |
| **Активный** | лаборатория или окно работ | `OT_ALLOW_ACTIVE=1`, цель в scope-файле, окно времени, журнал |

Проверка перед любым сетевым действием:

```bash
scripts/ot-guard.sh passive --target 10.10.0.5
scripts/ot-guard.sh active  --target 10.10.0.5 --scope ./scope.yaml
```

## MCP

ssh, docker, filesystem, proxmox (лабораторные VM), playwright (веб SCADA/HMI), duckduckgo, brave-search (выключен).

Секреты — только `{env:...}`; значения хранятся в окружении или Vault.

## Агенты

- **ot-recon** — инвентаризация активов (read-only).
- **ot-protocol-analyst** — Modbus, S7, OPC UA, IEC 104, DNP3, EtherNet/IP, PROFINET.
- **ot-segmentation-reviewer** — зоны, кондуиты, ACL (read-only).
- **ot-vuln-researcher** — CVE, бюллетени, компенсирующие меры.
- **ot-incident-responder** — форензика и локализация без остановки процесса.
- **ot-network-designer** — проектирование сетей и документация.

## Документы

- `docs/ot/scope-template.md` — scope площадки.
- `docs/ot/checklist-passive-audit.md`, `checklist-network-audit.md`, `checklist-segmentation.md`, `checklist-kii-fstek.md`.
- `docs/ot/report-template.md`, `threat-model-template.md`, `zones-conduits.md`.

## Аудит NIC и egress перед подключением к АСУ ТП

- Скилл `ot-network-audit`: локальный/удалённый инвентарь интерфейса, baseline pcap,
  egress-анализ и план зеркала.
- Скрипт: `~/.config/opencode/skills/ot-network-audit/scripts/ot-net-audit.sh`.
- Локально: scope → `ot-guard.sh passive` → `inventory` → posture → baseline на SPAN/TAP → `analyze` → отчёт.
- Сторонний сервер: `remote-inventory` по SSH → `mirror-plan` → `remote-capture --direction out`
  или захват на mirror-destination → `egress --server-ip` → отчёт.
- Зеркало включается только в согласованное окно и снимается сразу после захвата.
- Только чтение и захват; `nmap`/`arp-scan`/ping sweep/packet injection запрещены.
- Чеклисты: `docs/ot/checklist-network-audit.md`, `docs/ot/checklist-third-party-egress.md`.

## Жёсткие правила

См. `instructions/ot-safety.md`: запрет записи в ПЛК, запрет сканов без guard, сохранение улик, согласование изменений с технологами.
