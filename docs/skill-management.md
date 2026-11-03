# Управление скиллами

Скиллы — единый каталог в репозитории (`config/skills/`), который раскладывается
в `~/.config/opencode/skills/` и подключается профилями через `skills.paths`
и allowlist `permission.skill`.

## Модель

| Что | Где |
|---|---|
| Канонический источник | `config/skills/<name>/SKILL.md` (+ `scripts/`, `references/`) |
| Куда ставится | `~/.config/opencode/skills/<name>/` |
| Как подключается | `skills.paths: ["~/.config/opencode/skills"]` в каждом профиле |
| Кто видит скилл | только профили, где имя есть в allowlist `permission.skill` |
| Валидация | `tests/test_skills.py`, `tests/test_profiles_structure.py`, `tests/validate_configs.py` |

Скиллы лежат в git и синкаются вместе с конфигом — отдельного установщика
(`install-profile-skills.sh`, `~/.agents/skills`, `.skill-lock.json`) больше нет.

## Allowlist в профиле

В `opencode.jsonc` каждого профиля:

```jsonc
{
  "skills": {
    "paths": ["~/.config/opencode/skills"]
  },
  "permission": {
    "skill": {
      "*": "deny",
      "writing-plans": "allow",
      "verification-before-completion": "allow"
    }
  }
}
```

Правила:

- `"*": "deny"` обязателен — иначе в сессию попадут все 99 описаний скиллов,
  это лишние токены и риск случайной активации.
- В allowlist попадают **только существующие** имена из `config/skills/`.
  Валидатор и тесты падают, если указан несуществующий скилл.

## Наборы по профилям

Общее ядро (15 скиллов) одинаково во всех именных профилях: `cavecrew`,
`caveman*` (7), `code-review-and-quality`, `compress`,
`debugging-and-error-recovery`, `dispatching-parallel-agents`, `grill-me`,
`systematic-debugging`, `verification-before-completion`, `writing-plans`.

| Профиль | Всего | Дополнительно к ядру |
|---|---|---|
| `dev` | 39 | `accessibility-a11y`, `agent-vault`, `brainstorming`, `devops-rollout-plan`, `docker-build-strategies`, `docker-kubernetes`, `fastapi-python`, `find-skills`, `finishing-a-development-branch`, `jwt-security`, `log-analysis`, `nextjs-react-typescript`, `postgresql-optimization`, `postgresql-table-design`, `python`, `python-cybersecurity-tool-development`, `requesting-code-review`, `security-audit`, `security-docker`, `security-secrets`, `supabase-postgres-best-practices`, `test-driven-development`, `web-scraping`, `webapp-testing` |
| `infra` | 38 | `agent-vault`, `alerting-oncall`, `ansible-validator`, `devops-rollout-plan`, `devops-troubleshooter`, `docker-build-strategies`, `docker-kubernetes`, `find-skills`, `incident-runbook-templates`, `kpi-dashboard-design`, `log-analysis`, `oncall-irm`, `postgresql-optimization`, `postgresql-table-design`, `postmortem-writer`, `proxmox-admin`, `security-audit`, `security-docker`, `security-secrets`, `supabase-postgres-best-practices`, `terraform-skill`, `traffic-analysis-pcap`, `wireshark-analysis` |
| `net` | 35 | `active-network-recon`, `agent-vault`, `analyzing-network-traffic-with-wireshark`, `configuring-pfsense-firewall-rules`, `docker-kubernetes`, `enumerating-network-services`, `find-skills`, `homelab-vlan-segmentation`, `log-analysis`, `mikrotik-routeros-rsc`, `network-101`, `openwrt-config`, `openwrt-image-build`, `openwrt-procd-init`, `podkop-openwrt-guide`, `routeros-fundamentals`, `security-audit`, `security-secrets`, `traffic-analysis-pcap`, `wireshark-analysis` |
| `sec` | 46 | `agent-vault`, `analyzing-network-traffic-with-wireshark`, `ctf-crypto`, `ctf-forensics`, `ctf-malware`, `ctf-osint`, `ctf-pwn`, `ctf-reverse`, `ctf-web`, `exploit-dev-expert`, `find-skills`, `jwt-security`, `log-analysis`, `malware-analyst`, `memory-forensics-volatility`, `mode-exploit`, `mode-pentest`, `penetration-testing`, `pentest-expert`, `python-cybersecurity-tool-development`, `reverse-engineer`, `security-audit`, `security-docker`, `security-secrets`, `smtp-penetration-testing`, `sqlmap-database-pentesting`, `steganography-techniques`, `threat-intel`, `traffic-analysis-pcap`, `web-security-expert`, `wireshark-analysis` |
| `ot` | 20 | `analyzing-network-traffic-with-wireshark`, `security-audit`, `traffic-analysis-pcap`, `wireshark-analysis`, `ot-network-audit` (набор намеренно узкий: least privilege) |
| `mgnt` | 21 | `agent-vault`, `brainstorming`, `breakdown-epic-pm`, `find-skills`, `requesting-code-review`, `to-prd` |

Точный список — в `permission.skill` соответствующего `opencode.jsonc`;
это единственный источник истины.

## Добавить скилл

1. Положить каталог в `config/skills/<name>/SKILL.md` (frontmatter: `name`,
   `description`).
2. Добавить имя в allowlist нужных профилей.
3. (Опционально) добавить в `NEW_SKILLS` в `tests/test_skills.py` и в
   `REQUIRED_NET_SKILLS` в `tests/test_profiles_structure.py`, если скилл
   обязателен для профиля.
4. Прогнать проверки:

```bash
python3 tests/validate_configs.py config profiles
python3 -m pytest tests -q
bash tests/run.sh
```

5. Задеплоить профиль: `bash scripts/deploy-config.sh <profile>`.

## Раскладка по машинам

- `scripts/deploy-config.sh <profile>` копирует общий `config/skills` в
  `~/.config/opencode/skills` при деплое любого профиля.
- `setup.sh` (шаг «Syncing skills») делает то же через `rsync --delete`
  и создаёт симлинк `~/.agents/skills -> ~/.config/opencode/skills` для
  обратной совместимости со старыми путями.
- Скиллы попадают в git и в `opencode_sync push` — отдельных lock-файлов
  или клонирования из внешних репозиториев не требуется.

## Почему не все скиллы сразу

Описание каждого скилла грузится в `available_skills` при старте. При 80+
скиллах это заметный overhead на каждый turn. Allowlist по профилям держит
в контексте только релевантное подмножество (обычно 15–30 скиллов).

## Ссылки

- [Матрица профилей и агентов](profiles-agents-matrix.md)
- [Миграция профилей](profiles-migration.md)
- `config/skills/` — канонический источник
- `tests/test_skills.py`, `tests/test_profiles_structure.py`
