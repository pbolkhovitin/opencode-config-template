# opencode-config-template

Репозиторий конфигурации OpenCode v2: default-профиль, семь именных профилей, общие
инструкции, скиллы и установщики. Платформа: Linux (native или WSL).

## Структура

```
├── AGENTS.md              ← этот файл (как работать с репозиторием)
├── config/
│   ├── opencode.json      ← default-профиль (без MCP)
│   ├── AGENTS.md          ← профильный документ (инструкции агентам)
│   ├── instructions/      ← russian.md, workflow.md, rules.md, context-protocol.md
│   ├── skills/            ← ~100 скиллов, канонический источник
│   └── command/           ← слэш-команды
├── profiles/<name>/       ← dev, infra, net, sec, design, ot, mgnt
├── scripts/               ← askpass, миграция конфигов, deploy-config
├── setup.sh / setup.ps1   ← установка (Linux/WSL, Windows native)
└── docs/                  ← документация
```

## Профили

`default` (каталог `config/`) намеренно **без MCP**. MCP-серверы подключаются в именных
профилях — см. `profiles/*/opencode.jsonc`.

| Алиас | Профиль | Назначение |
|---|---|---|
| `oc` | default | Разработка и общие задачи, без MCP |
| `oc-dev` | dev | Разработка + security tooling |
| `oc-infra` | infra | Инфраструктура, IaC, K8s, GitOps, MLOps, SRE |
| `oc-net` | net | Сети, маршрутизация, firewall, VPN |
| `oc-mgnt` | mgnt | PM / product / support |
| `oc-sec` | sec | CTF и pentest |
| `oc-ot` | ot | АСУ ТП / ICS, пассивный режим по умолчанию |
| `oc-design` | design | UI/UX, вёрстка, визуальная приёмка (Penpot, Figma, Mermaid) |

## Установка

```bash
bash setup.sh              # Linux/WSL, интерактивно
bash setup.sh --dry-run    # показать действия без изменений
.\setup.ps1                # Windows native
```

`setup.sh` раскладывает конфиги профилей, инструкции, команды и скиллы в
`~/.config/opencode*/` и `~/.config/opencode/skills/`, настраивает алиасы.

## Синхронизация

Конфиг может синхронизироваться плагином opencode-synced (`opencode_sync push|pull`).
Секреты и история промптов **не синкаются** (`includeSecrets: false`,
`includePromptStash: false`). Секреты — только `{env:...}` или Vault; в git не должно
попадать ничего из `~/.local/share/opencode`, `~/.local/state/opencode`,
`~/.agents/context/**`, браузерных профилей.

## Проверка перед коммитом

```bash
python3 tests/validate_configs.py config profiles   # схема v2 + политика путей
python3 -m pytest tests -q                          # гигиена, миграции, дефолт
```

## Правила разработки

- Один источник истины: скиллы — `config/skills/`, персонажи — `prompts/personas/`,
  конфиг — `config/opencode.json`.
- Не возвращать в git: браузерные профили, cookies, `.env`, БД, `session_diff`,
  историю промптов.
- Legacy-ключи (`provider`, `agent`, `permission`) сохранены осознанно — см.
  `docs/config-migration.md`.
- Изменения схемы сопровождаются тестом в `tests/`.

## Документация

- [config/AGENTS.md](config/AGENTS.md) — профиль агента по умолчанию
- [docs/config-migration.md](docs/config-migration.md) — почему часть ключей осталась v1
- [docs/skill-management.md](docs/skill-management.md) — управление скиллами
- [docs/context-management.md](docs/context-management.md) — контекст и DCP
- [docs/usage-scenarios.md](docs/usage-scenarios.md) — сценарии: новый проект, подключение существующего, перенос, передача
- [docs/macos.md](docs/macos.md) — macOS (Apple Silicon): установка, профили, Docker, Desktop
- [docs/wsl-desktop.md](docs/wsl-desktop.md) — WSL 2 и OpenCode Desktop: установка, профили, диагностика
