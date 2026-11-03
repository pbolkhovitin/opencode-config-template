# my-opencode-config

Готовый к использованию шаблон конфигурации **OpenCode v2** для Linux (native/WSL):
default-профиль без MCP, шесть именных профилей, инструкции для агентов, ~100 скиллов,
локальные плагины, команды и установщики.

Репозиторий — обезличенный стартовый набор. Замените плейсхолдеры (`YOUR_ORG`,
`YOUR_PROJECT`, `YOURUSER`, модель) на свои значения, затем запустите `setup.sh`.

## Что внутри

| Компонент | Путь | Назначение |
|---|---|---|
| Default-профиль | `config/opencode.json` | общая работа, **без MCP** |
| Именные профили | `profiles/{dev,infra,net,sec,ot,mgnt}/` | роли, MCP, модели |
| Инструкции | `config/instructions/` | russian, workflow, rules, context-protocol |
| Скиллы | `config/skills/` | ~100 скиллов, один канонический источник |
| Плагины | `config/plugins/` | локальные: `profile-badge`, `opencode-mcp-sets`, `folder-switcher` |
| Команды | `config/command/` | `/grill-me` и профильные команды |
| Установка | `setup.sh`, `setup.ps1` | Linux/WSL и Windows native |
| Проверки | `tests/` | схема, гигиена репозитория, миграции |

## Профили и MCP

`default` (алиас `oc`) — базовый набор инструментов, MCP-серверы **не подключены**.
MCP живут в именных профилях:

| Профиль | Алиас | MCP |
|---|---|---|
| dev | `oc-dev` | docker, duckduckgo, filesystem, github, gitlab×4, playwright, postgres, ssh, brave-search (off) |
| infra | `oc-infra` | ansible, docker, gitlab×4, opentofu, postgres, proxmox, ssh |
| net | `oc-net` | docker, duckduckgo, filesystem, ssh |
| sec | `oc-sec` | docker, ssh |
| ot | `oc-ot` | docker, duckduckgo, filesystem, playwright, proxmox, ssh, brave-search (off) |
| mgnt | `oc-mgnt` | docker, playwright, postgres, ssh |

Алиасы профилей запускают `opencode --standalone --continue`: в v2 конфигурацией
владеет фоновый сервис, и без `--standalone` выбранный профиль не применяется.
`--continue` продолжает последнюю сессию проекта; новая сессия — `leader+n` в TUI.

Все профили по умолчанию используют `anthropic/claude-sonnet-4-5`. Поменять модель
можно в `config/opencode.json` и `profiles/*/opencode.jsonc` (`model` и `small_model`),
либо задать `PUBLIC_MODEL` при экспорте из приватного репозитория.

Секреты MCP передаются только через `{env:...}` или HashiCorp Vault; в репозитории
нет паролей и токенов.

Переключение профилей — `scripts/ocp`:

```bash
ocp            # fzf-меню
ocp infra      # запуск в профиле infra
ocp default    # лёгкий профиль без MCP
```

## Установка

```bash
git clone git@github.com:YOUR_ORG/my-opencode-config.git
cd my-opencode-config
bash setup.sh --dry-run     # посмотреть план
bash setup.sh               # Linux/WSL, интерактивно
```

Windows native: `.\setup.ps1` (рекомендуется WSL2).

Скрипт раскладывает конфиги в `~/.config/opencode/` и `~/.config/opencode-<profile>/`,
скиллы — в `~/.config/opencode/skills/`, настраивает алиасы `oc`, `oc-dev`, `oc-infra`,
`oc-net`, `oc-sec`, `oc-ot`, `oc-mgnt`.

## Плагины

| Плагин | Роль |
|---|---|
| `opencode-synced` | синхронизация конфига с вашим GitHub-репозиторием |
| `@tarquinen/opencode-dcp` | динамическое сокращение контекста |
| `opencode-supermemory` | постоянная память между сессиями |
| `opencode-handoff` | передача контекста в новую сессию |
| `opencode-gemini-auth` | OAuth для Google/Gemini |
| `opencode-usage-monitor` | квоты и балансы провайдеров |
| `opencode-mcp-sets` (local) | per-session видимость MCP: команда `/mcp` |

`opencode-mcp-sets` позволяет скрывать MCP-серверы в отдельной сессии, не отключая
их глобально: `/mcp off gitlab-official-*`, `/mcp only gitlab-work,github`,
`/mcp reset`. Подробности — [docs/mcp-sets.md](docs/mcp-sets.md).

Версии `@opencode-ai/plugin` и плагинов закреплены в `config/package.json` и профилях.

## Секреты

- В git запрещены: `.env`, ключи, cookies, БД, `session_diff`, история промптов, браузерные профили.
- Секреты — только `{env:...}` или HashiCorp Vault (скилл `agent-vault`).
- `opencode-synced` настроен так, что секреты, сессии и prompt-stash не синкаются.

## Проверка

```bash
python3 tests/validate_configs.py config profiles   # схема v2 + запрет абсолютных путей
python3 -m pytest tests -q                          # гигиена, миграции, default-профиль
```

## Документация

- [AGENTS.md](AGENTS.md) — как работать с репозиторием
- [config/AGENTS.md](config/AGENTS.md) — профиль агента по умолчанию
- [docs/config-migration.md](docs/config-migration.md) — legacy-ключи и почему они остались
- [docs/profiles-migration.md](docs/profiles-migration.md) — карта профилей
- [docs/profiles-agents-matrix.md](docs/profiles-agents-matrix.md) — кто доступен в каждом профиле
- [docs/context-management.md](docs/context-management.md) — compaction, DCP, references и ledger
- [docs/skill-management.md](docs/skill-management.md) — управление скиллами
- [docs/USAGE.md](docs/USAGE.md) — подробное руководство

## Происхождение

Шаблон собран из приватной рабочей конфигурации скриптом экспорта: личные и
корпоративные данные, внутренние адреса и документы удалены, идентификаторы
заменены плейсхолдерами. Публичная копия — build artifact, а не место для правок.
