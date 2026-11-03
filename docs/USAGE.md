# opencode Multi-Profile Setup — Usage Guide

## Overview

Multi-profile конфигурация для opencode CLI. Каждый профиль — изолированный набор MCP
инструментов, плагинов, кастомных агентов, скиллов и разрешений под конкретную задачу.

**Платформа**: Linux (native или WSL). Windows native — через `setup.ps1` (рекомендуется WSL2).

Синхронизация с GitHub — через opencode-synced (автоматический push локальных изменений
в репозиторий `YOUR_ORG/my-opencode-config`).

---

## Installation

### Требования
- Git, curl
- **Node.js >= 18** (необходим для opencode CLI и всех npx-инструментов)
- Python 3, pip3
- `gh` (GitHub CLI) — аутентифицирован

**Установка Node.js:**
```bash
# Через NodeSource (рекомендуется)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash
sudo apt install -y nodejs

# Или через nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bashrc
nvm install 22
```

### Linux / WSL
```bash
# Способ 1 — через clone
gh repo clone YOUR_ORG/my-opencode-config ~/.local/share/opencode/opencode-synced/repo
bash ~/.local/share/opencode/opencode-synced/repo/setup.sh

# Способ 2 — curl с токеном
curl -fsSL -H "Authorization: token $(gh auth token)" \
  https://raw.githubusercontent.com/YOUR_ORG/my-opencode-config/main/setup.sh | bash

# Способ 3 — из уже склонированного репозитория
cd /path/to/my-opencode-config && bash setup.sh
```

После установки:
```bash
source ~/.zshrc  # применить алиасы
opencode_sync pull
```

**WSL**: скрипт определяет WSL по `/proc/version` автоматически.
На WSL рекомендуется zsh — все env-переменные и SSH-agent прописываются в `~/.zshrc`.

---

## Directory Structure

```
~/.config/opencode/                       # Runtime default profile
├── opencode.json                         # Main config (плагины, MCP, агенты)
├── AGENTS.md                             # Profile inventory + rules
├── instructions/                         # Модульные инструкции
└── skills/                               # Канонические скиллы (общие для профилей)

~/.config/opencode-<profile>/             # Runtime именного профиля
├── opencode.json
├── AGENTS.md
├── prompts/personas/
└── instructions/

~/.local/share/opencode/opencode-synced/repo/   # Git sync repo
├── config/
├── profiles/{dev,infra,net,sec,ot,mgnt}/
├── docs/
```

---

## Profiles

Канонический набор: `default`, `dev`, `infra`, `net`, `sec`, `ot`, `mgnt`.
Все профили работают на `anthropic/claude-sonnet-4-5` (main и small).

### 1. default (`oc`) — Базовый

| Аспект | Детали |
|--------|--------|
| MCP | — (MCP живут в именных профилях) |
| Плагины | synced, dcp, gemini-auth, handoff, usage-monitor, supermemory |
| Default agent | build |
| Permissions | bash=ask, edit=ask |
| Назначение | общие задачи, текст, планирование, быстрые правки без MCP |

### 2. dev (`oc-dev`) — Мультиязычная разработка

| Аспект | Детали |
|--------|--------|
| MCP | postgres, docker, playwright, filesystem, github, gitlab-work, gitlab-official-yandex/gmail (+ personal off), ssh, duckduckgo, brave-search (off) |
| Агенты | feature-planner, code-architect, senior-{python,js-ts,php,cpp,java,go,rust,nextjs}, appsec-auditor, security-tool-developer, code-reviewer, platform-engineer |
| Default agent | build |
| Инструкции | 12 модульных файлов по языкам/доменам |
| Назначение | архитектура → TDD → реализация → ревью на любом стеке |

### 3. infra (`oc-infra`) — Инфраструктура и эксплуатация

| Аспект | Детали |
|--------|--------|
| MCP | proxmox, ansible, opentofu, docker, ssh, postgres |
| Агенты | infra-engineer, sre, mlops-engineer, gitops-engineer, security-auditor, devops-reviewer |
| Default agent | infra-engineer |
| Правило | перед любыми изменениями — dry-run / --check |
| Назначение | IaC, Proxmox, Kubernetes, GitOps, MLOps, инциденты |

### 4. net (`oc-net`) — Сети

| Аспект | Детали |
|--------|--------|
| MCP | ssh, docker, filesystem, duckduckgo |
| Агенты | network-engineer, network-security, bgp-ospf-analyst, packet-analyst |
| Default agent | network-engineer |
| Правило | read-only first; изменения — только после backup и подтверждения |
| Назначение | MikroTik/pfSense/OpenWrt/UniFi, VLAN, маршрутизация, firewall, VPN, pcap |

### 5. sec (`oc-sec`) — Безопасность

| Аспект | Детали |
|--------|--------|
| MCP | ssh, docker |
| Агенты | ctf-reverse-engineer, ctf-pwner, ctf-web-hacker, pentester, appsec-auditor, threat-intel |
| Default agent | pentester |
| Назначение | CTF, pentest, forensics, reverse engineering |

### 6. ot (`oc-ot`) — АСУ ТП / ICS

| Аспект | Детали |
|--------|--------|
| MCP | ssh, docker, filesystem, proxmox, playwright, duckduckgo, brave-search (off) |
| Агенты | ot-protocol-analyst, ot-incident-responder, ot-network-designer, ot-recon, ot-segmentation-reviewer, ot-vuln-researcher |
| Default agent | ot-protocol-analyst |
| Правило | активные действия — только через `scripts/ot-guard.sh` |
| Назначение | пассивный аудит, сегментация, pcap, КИИ/ФСТЭК |

### 7. mgnt (`oc-mgnt`) — Management

| Аспект | Детали |
|--------|--------|
| MCP | ssh, postgres, playwright, docker |
| Агенты | prd-writer, incident-commander, data-analyst |
| Default agent | prd-writer |
| Назначение | PRD, инциденты, аналитика |

---

## Environment Variables

### Платформенные (устанавливаются автоматически)

| Переменная | Linux | WSL |
|-----------|-------|-----|
| `OPENCODE_PLATFORM` | `linux` | `wsl` |
| `OPENCODE_HOME` | `/home/YOURUSER` | `/home/YOURUSER` |
| `OPENCODE_ALLOWED_DIRS` | `/home/YOURUSER` | `/home/YOURUSER` |

Устанавливаются в `~/.zshrc` / `~/.bashrc`.

### API-ключи (указать свои значения)

| Variable | Profiles | Purpose |
|----------|----------|---------|
| `GITLAB_WORK_API_URL` | dev, infra | Рабочий GitLab; по умолчанию `https://gitlab.example.com/api/v4`, в локальной сети — `https://gitlab.internal.example.com/api/v4` |
| `GITLAB_OFFICIAL_YANDEX_API_URL` | dev, infra | GitLab.com, аккаунт Yandex (опционально, по умолчанию `https://gitlab.com/api/v4`) |
| `GITLAB_OFFICIAL_GMAIL_API_URL` | dev, infra | GitLab.com, аккаунт Gmail (опционально, по умолчанию `https://gitlab.com/api/v4`) |
| `GITLAB_PERSONAL_API_URL` | dev, infra | Личный GitLab API (опционально, по умолчанию `https://gitlab.com/api/v4`) |
| `DATABASE_URL` | dev, infra, mgnt | Postgres MCP connection string |
| `PROXMOX_TOKEN_VALUE` | infra, ot | Proxmox API token |
| `BRAVE_API_KEY` | dev, ot | brave-search (по умолчанию `disabled: true`) |

Shodan MCP в конфигурации не подключён — `SHODAN_API_KEY` не требуется.

GitLab MCP работает с четырьмя инстансами (`gitlab-work`, `gitlab-official-yandex`,
`gitlab-official-gmail`, `gitlab-personal`). Токены **не задаются через env** — они лежат в личном Vault
(`instance personal`, проект `YOUR_PROJECT`) и подставляются лаунчером
`gitlab-mcp-vault` только в окружение MCP-процесса:

| Сервер | Vault-секрет | Состояние |
|---|---|---|
| `gitlab-work` | `gitlab.example.com PAT` | включён |
| `gitlab-official-yandex` | `gitlab official yandex pat` | включён |
| `gitlab-official-gmail` | `gitlab official gmail pat` | включён |
| `gitlab-personal` | `gitlab personal pat` | выключен (личный, позже) |

Права ограничиваются scope PAT (`api`, либо `read_api` + `read_repository`).
Проверка наличия токена без его вывода: `gitlab-mcp-vault work --check`;
проверка валидности: `gitlab-mcp-vault work --check-api` (HTTP 200; 401 —
токен отозван или просрочен).
Для работы из локальной сети организации:

```bash
export GITLAB_WORK_API_URL="https://gitlab.internal.example.com/api/v4"
```

Лаунчер — bash-скрипт с `agent-vault` (Linux/WSL). На Windows native
используйте WSL: нативный контур не поддерживает Vault-обёртку.

GitHub MCP (`dev`) использует официальный сервер
`ghcr.io/github/github-mcp-server` через `github-mcp-vault`: PAT лежит в Vault
(`github YOUR_ORG pat`) и передаётся только в env MCP-процесса. Нужен
Docker/podman; проверка — `github-mcp-vault --check` и `--check-api`.

Добавить в `~/.zshrc`:
```bash
export GITLAB_WORK_API_URL="https://gitlab.internal.example.com/api/v4"  # опционально
export DATABASE_URL="postgresql://user:pass@host/db"
export PROXMOX_TOKEN_VALUE="xxx"
```

---

## Aliases

Все алиасы в `~/.zshrc` / `~/.bashrc`:

```zsh
oc                   # default profile
oc-dev               # dev profile
oc-infra             # infra profile
oc-net               # net profile
oc-sec               # sec profile
oc-ot                # ot profile
oc-mgnt              # mgnt profile
```

Алиасы запускают `opencode --standalone --continue`: в v2 конфигом владеет
фоновый сервис, и без приватного сервера профиль не применяется (подробнее —
`docs/config-migration.md`, раздел «Профили в v2»). `ocp` делает то же самое.

`--continue` продолжает последнюю сессию текущего проекта — при обычном запуске
новая сессия не создаётся. Так же ведёт себя `oc` (default); его подкоманды
(`oc session list`, `oc models`, `oc mcp` и т.п.) работают без изменений.
Новая сессия: `leader+n` в TUI. Продолжить конкретную: `oc-net -s <session-id>`.
Чистый `opencode` без алиаса по-прежнему начинает новую сессию.

---

## Custom Agents (Persona-based)

Каждый профиль имеет набор кастомных агентов. **Primary** — переключение через Tab
в начале сессии. **Subagent** — вызов через `@mention` в любом сообщении.

```zsh
# Примеры вызова subagent
@code-reviewer проверь последние изменения
@data-analyst покажи метрики за неделю
@security-auditor проверь Dockerfile на уязвимости
```

Полный список агентов — в `AGENTS.md` каждого профиля или в `docs/custom-agents.md`.

---

## MCP Servers

| MCP | Профили | Команда | Зависимости |
|-----|---------|---------|-------------|
| proxmox | infra, ot | `uvx proxmox-mcp-server` | PROXMOX_TOKEN_VALUE |
| ansible | infra | `ansible-mcp serve` | ansible-mcp (pip) |
| opentofu | infra | `npx @opentofu/opentofu-mcp-server` | Node.js |
| docker | dev, infra, net, sec, ot, mgnt | `npx mcp-docker-server` | Docker, Node.js |
| ssh | dev, infra, net, sec, ot, mgnt | `uvx --from slepp-ssh-mcp ssh-mcp` | Python/uv |
| postgres | dev, infra, mgnt | `npx @yawlabs/postgres-mcp` | DATABASE_URL |
| playwright | dev, mgnt, ot | `npx @playwright/mcp@latest --browser=firefox` | Firefox |
| filesystem | dev, net, ot | `npx @modelcontextprotocol/server-filesystem` | Node.js |
| duckduckgo | dev, net, ot | `npx ddg-mcp-search` | — |
| github | dev | `github-mcp-vault` | Vault: `github YOUR_ORG pat`, Docker image |
| gitlab-work | dev, infra | `gitlab-mcp-vault work` | Vault: `gitlab.example.com PAT` |
| gitlab-official-yandex | dev, infra | `gitlab-mcp-vault yandex` | Vault: `gitlab official yandex pat` |
| gitlab-official-gmail | dev, infra | `gitlab-mcp-vault gmail` | Vault: `gitlab official gmail pat` |
| gitlab-personal | dev, infra (off) | `gitlab-mcp-vault personal` | Vault: `gitlab personal pat` |
| brave-search | dev, ot (off) | `npx @modelcontextprotocol/server-brave-search` | BRAVE_API_KEY |

В `default` MCP нет.

---

## Plugins (v2-совместимые)

| Plugin | Функция | Профили |
|--------|---------|---------|
| opencode-synced | Синхронизация конфига с GitHub | default |
| @tarquinen/opencode-dcp | Dynamic Context Pruning (экономия токенов) | все |
| opencode-supermemory (`/server`) | Persistent memory между сессиями | все |
| opencode-handoff | Передача контекста в новую сессию | все |
| opencode-usage-monitor | Квоты и балансы провайдеров (OpenAI, Z.AI, DeepSeek, OpenCode Go) | все |
| opencode-gemini-auth | OAuth для Google/Gemini | default, dev, infra, net, mgnt |
| opencode-tui-usage | TUI-sidebar: cache, context, токены, стоимость, скорость | все (cli.json) |
| @opencode-cockpit/status | Нижняя строка TUI: git.diff, todo, diagnostics, статус сессии | все (cli.json) |
| profile-badge (local) | Бейдж `профиль · агент · MCP N/M` в футере | все (plugins/) |
| opencode-mcp-sets (local) | Per-session видимость MCP: `/mcp list/off/on/only/reset` | все (plugins/) |

> **Убрано (v1-only, в v2 не работают):** opencode-swarm, opencode-websearch-cited,
> opencode-vibeguard, @lyculs/opencode-firecrawl, opencode-notify (retired),
> opencode-worktree, opencode-antigravity-auth, opencode-pty (v2-энтрипоинт
> не загружается загрузчиком 2.1.4), opencode-morph-plugin, @plannotator/opencode,
> opencode-goal-plugin.
> Уведомления в v2 — нативные (`cli.json` → `attention.*`).

Правила установки, встроенные плагины, каталог экосистемы и API V2 — в
[docs/plugins-ecosystem.md](plugins-ecosystem.md).

---

## TUI

Настройки TUI — глобальный `~/.config/opencode/cli.json` (синхронизируется через
`extraConfigPaths`). Он не зависит от профиля: профиль меняет агента и MCP, но не TUI.

- **Sidebar**: `opencode-tui-usage` — Cache, Context, Usage, Model, Speed, Agents;
  панель снизу, без рамки и без оценочного context breakdown.
- **Нижняя строка**: `@opencode-cockpit/status` — `git.diff`, `todo`, `diagnostics`,
  статус сессии; diagnostics показывает нездоровые MCP/LSP.
- **Бейдж профиля**: локальный плагин `config/plugins/profile-badge/tui.tsx` —
  `infra · infra-engineer · MCP 2/6` в `prompt.footer.status`.
- **Токены за ход**: `debug.turn_tokens: true`.
- **Diff**: `diffs.source: turn`, `diffs.tree: true`.
- **Keybinds**: `<leader>v` — MCP, `<leader>d` — diff, `<leader>h` — thinking,
  `<leader>p` — плагины, `<leader>o` — usage.
- **Квоты**: `~/.config/opencode/usage-monitor.json` (v2, DeepSeek; файл
  синхронизируется). Панель квот включена во всех профилях.

После изменения `cli.json` или серверных плагинов перезапусти TUI и, при необходимости,
`opencode service restart`.

---

## Skills

Все профили используют единый каталог `~/.config/opencode/skills/` (`skills.paths`),
allowlist скиллов задаётся в `permission.skill` каждого профиля. Всего **98** скиллов
в `config/skills/`; в контекст профиля попадают только разрешённые (15–46).

Набор **caveman** (8 скиллов):
- `caveman` — ultra-compressed режим (экономия ~75% токенов)
- `caveman-commit` — короткие коммиты
- `caveman-review` — краткие ревью
- `caveman-compress` / `compress` — сжатие файлов памяти
- `caveman-stats` — статистика токенов
- `caveman-help` — шпаргалка
- `cavecrew` — делегирование подзадачам

Добавление скилла: положить каталог в `config/skills/<name>/` и добавить имя
в allowlist профилей — см. [skill-management.md](skill-management.md).

---

## Context management

Контекст ограничен, поэтому конфигурация использует четыре слоя: native
compaction, DCP, lazy references и ledger. Полная схема, пороги и
troubleshooting — [docs/context-management.md](context-management.md).

**Ledger** — `~/.config/opencode/context/` (подключён как reference `context`):

| Файл | Что внутри | Синкается |
|------|-----------|-----------|
| `INDEX.md` | точка входа: что читать и когда | да |
| `current.md` | активная задача: objective/constraints/decisions/files/next step | нет |
| `decisions.md` | долговечные решения, одна строка на решение | да |
| `current.template.md` | шаблон новой задачи | да |
| `playbooks/` | длинные how-to, вынесенные из `AGENTS.md` | да |
| `archive/` | завершённые и приостановленные задачи | нет |

Порядок чтения на старте задачи — `INDEX.md` → `current.md` → только те
playbook/archive, на которые указывает индекс. `docs/` репозитория подключён
вторым reference (`docs`), поэтому открывайте нужную страницу, а не каталог.

**Команды в сессии:**

- `/dcp` — состояние DCP: применённые стратегии и текущее потребление контекста.
- `/dcp-compress` — принудительное сжатие, если сессия разрослась до порога.
- `/compact` — ручная компакция истории (то же, что делает `compaction.auto`).

**Настройки.** `compaction` (`auto: true`, `keep.tokens: 20000`, `buffer: 24000`),
`references` и абсолютный путь к `instructions/context-protocol.md` прописаны
явно в default и во всех шести профилях — профиль не наследует глобальные ключи.

**DCP.** `~/.config/opencode/dcp.jsonc`: `turnProtection 4`, `compress
80000/140000`, `purgeErrors 3`, `allowSubAgents: true`. Пороги выбраны под окно
активной модели (262 144) и не превышают 75 % окна. State плагина —
`~/.local/share/opencode/storage/plugin/dcp/` (~18 MB); сам он не чистится,
удалять только при закрытых сессиях.

**SuperMemory.** `captureEveryNTurns: 0` (без авто-захвата), `recallMode: "direct"`.
Recall — только по теме текущей задачи, не весь store.

---

## Sync Mechanism (opencode-synced)

Работает в режиме LOCAL → REMOTE:

1. Изменения вносятся в runtime config: `~/.config/opencode/`
2. opencode-synced копирует их в локальный git-репозиторий
3. Sync создаёт коммит и пушит в GitHub

Для профилей (`opencode-dev`, `opencode-infra` и т.д.) — изменения вносятся
в `~/.config/opencode-{name}/`, затем копируются в `repo/profiles/{name}/` и коммитятся
вручную через `git commit` в репо.

---

## Security

- **VibeGuard** удалён (v1-only, не работает в V2); ключи — только через `{env:VAR}` или Vault
- **bash/edit=ask** — все профили с подтверждением
- **infra** — обязательный dry-run / --check перед изменениями
- **net** — read-only first, изменения только после backup и подтверждения
- API-ключи только через `{env:VAR}` в конфигах, реальные значения в `~/.zshrc`
- **Linux**: `sudo -n` (без промпта); при запросе пароля — `sudo -v` в терминале пользователя, никогда `sudo -S`
