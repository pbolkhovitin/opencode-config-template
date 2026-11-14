# Подбор скиллов

Скиллы лежат в `config/skills/` — это единственный источник истины.
`scripts/deploy-config.sh` и `setup.sh` раскладывают их в
`~/.config/opencode/skills/`; профили подключают каталог через
`skills.paths` и ограничивают видимость allowlist'ом `permission.skill`.

Актуальная модель, правила добавления и полный список по профилям —
[docs/skill-management.md](skill-management.md). Этот файл — про принципы
подбора: что и зачем включено.

## Принцип: least privilege по профилям

- `"*": "deny"` в каждом профиле — иначе в контекст попадают описания всех
  **100** скиллов на каждый turn.
- В allowlist — только имена, реально существующие в `config/skills/`;
  это проверяют `tests/test_skills.py` и `tests/test_profiles_structure.py`.
- Общее ядро (15 скиллов) одинаково во всех профилях: `cavecrew`, `caveman*`
  (7), `code-review-and-quality`, `compress`, `debugging-and-error-recovery`,
  `dispatching-parallel-agents`, `grill-me`, `systematic-debugging`,
  `verification-before-completion`, `writing-plans`.
- Остальное — профильные наборы (см. таблицу ниже). Пересечения осознанные:
  `security-audit`, `docker-*`, `postgresql-*` нужны в нескольких ролях.

## Профильные наборы

| Профиль | Скиллов | Дополнительно к общему ядру |
|---|---|---|
| `dev` | 39 | языки и фреймворки (`python`, `nextjs-react-typescript`, `fastapi-python`, `accessibility-a11y`, `webapp-testing`, `web-scraping`), TDD/ревью (`test-driven-development`, `requesting-code-review`, `finishing-a-development-branch`, `brainstorming`), AppSec (`security-audit`, `security-secrets`, `security-docker`, `jwt-security`, `python-cybersecurity-tool-development`), данные (`postgresql-optimization`, `postgresql-table-design`, `supabase-postgres-best-practices`), контейнеры (`docker-kubernetes`, `docker-build-strategies`), `log-analysis`, `devops-rollout-plan` |
| `infra` | 38 | IaC (`proxmox-admin`, `ansible-validator`, `terraform-skill`), эксплуатация (`devops-troubleshooter`, `devops-rollout-plan`, `log-analysis`), on-call (`oncall-irm`, `alerting-oncall`, `incident-runbook-templates`, `postmortem-writer`, `kpi-dashboard-design`), сеть/пакеты (`traffic-analysis-pcap`, `wireshark-analysis`), AppSec и данные |
| `net` | 35 | оборудование и прошивки (`mikrotik-routeros-rsc`, `routeros-fundamentals`, `openwrt-config`, `openwrt-procd-init`, `openwrt-image-build`, `podkop-openwrt-guide`), firewall/VLAN (`configuring-pfsense-firewall-rules`, `homelab-vlan-segmentation`), диагностика (`active-network-recon`, `network-101`, `enumerating-network-services`, `wireshark-analysis`, `traffic-analysis-pcap`, `analyzing-network-traffic-with-wireshark`), `security-audit`, `security-secrets` |
| `sec` | 46 | CTF (`ctf-web`, `ctf-pwn`, `ctf-reverse`, `ctf-crypto`, `ctf-forensics`, `ctf-osint`, `ctf-malware`), pentest (`pentest-expert`, `penetration-testing`, `mode-pentest`, `sqlmap-database-pentesting`, `smtp-penetration-testing`, `web-security-expert`), exploit/RE (`exploit-dev-expert`, `mode-exploit`, `reverse-engineer`), malware/forensics (`malware-analyst`, `memory-forensics-volatility`, `steganography-techniques`), threat intel, pcap |
| `ot` | 20 | `analyzing-network-traffic-with-wireshark`, `traffic-analysis-pcap`, `wireshark-analysis`, `ot-network-audit` + `security-audit`; набор намеренно узкий (least privilege для АСУ ТП) |
| `mgnt` | 21 | `to-prd`, `breakdown-epic-pm`, `brainstorming`, `requesting-code-review` |
| `design` | 27 | вёрстка и a11y (`accessibility-a11y`, `nextjs-react-typescript`, `webapp-testing`), дизайн (`design-toolkit`, `kpi-dashboard-design`), поиск и ревью (`find-skills`, `requesting-code-review`, `finishing-a-development-branch`, `test-driven-development`), `brainstorming`, `web-scraping`, `agent-vault` |

Точный список — в `permission.skill` соответствующего `opencode.jsonc`.

## Что сознательно не установлено

- **`handoff` (mattpocock/skills)** — дублирует плагин `opencode-handoff@0.6.1`.
- **`security-threat-model` (openai/skills)** — пересекается с `security-audit`;
  держим один скилл, чтобы не раздувать описание инструментов.
- **`alerting-irm` (grafana/skills)** — нет Grafana IRM/OnCall в контуре;
  вернёмся при внедрении (есть `alerting-oncall`/`oncall-irm` в `infra`).
- **`postgresql-optimization`** — включён в `dev`/`infra`; в остальных покрыт
  `supabase-postgres-best-practices` и `postgresql-table-design`.

## Происхождение части скиллов (история, 2026-10)

| Скилл | Источник |
|---|---|
| `proxmox-admin` | bastos/skills |
| `ansible-validator` | akin-ozer/cc-devops-skills |
| `terraform-skill` | antonbabenko/terraform-skill |
| `postgresql-table-design` | wshobson/agents |
| `docker-build-strategies` | docker/skills |
| `security-audit` | cloudflare/security-audit-skill |
| `code-review-and-quality` | addyosmani/agent-skills |
| `debugging-and-error-recovery` | addyosmani/agent-skills |
| `network-101`, `enumerating-network-services` | CTF/network-наборы |
| `mikrotik-routeros-rsc`, `routeros-fundamentals`, `openwrt-*`, `podkop-openwrt-guide`, `configuring-pfsense-firewall-rules`, `homelab-vlan-segmentation` | сетевые/OpenWrt-наборы (2026-10) |

Установка внешних скиллов — вручную: положить каталог в `config/skills/`,
добавить имя в allowlist профилей и прогнать тесты (см. `skill-management.md`).
Массового `rsync` из `~/.agents/skills` больше нет — этот каталог устарел.

## Безопасность скиллов

Каждый скилл — это инструкции с полными правами агента. Перед добавлением
проверяйте `SKILL.md` и `references/` на команды скачивания/удаления и
«забудь предыдущие инструкции». Скиллы не должны содержать секретов и
машинных путей — это проверяют `tests/test_repo_hygiene.py` и
`tests/validate_configs.py`.
