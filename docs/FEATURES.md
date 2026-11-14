# Функционал и возможности

## Платформа

Конфигурация работает на **Linux** (native или WSL) и **macOS** (Apple Silicon и Intel).

| Платформа | Установщик | Shell |
|-----------|-----------|-------|
| 🐧 Linux | `bash setup.sh` | bash/zsh |
| 🪟🐧 WSL (CLI) | `bash setup.sh` (автоопределение WSL 1/2) | zsh или bash |
| 🖥️ WSL + Desktop | OpenCode Desktop → Add WSL server | GUI в Windows, сервер в WSL |
| 🍎 macOS (arm64/x64) | `bash setup.sh` (Darwin, brew) | zsh (по умолчанию) или bash |

Установка:
```bash
gh repo clone YOUR_ORG/opencode-config-template
cd opencode-config-template && bash setup.sh
```

> **Windows-native** — `setup.ps1` (PowerShell 7+). Для GUI рекомендуется
> OpenCode Desktop на Windows с WSL-сервером: инструменты и секреты остаются в
> Linux, интерфейс — в Windows. См. [wsl-desktop.md](wsl-desktop.md).
>
> **macOS** — Apple Silicon: Xcode CLT + Homebrew, затем `bash setup.sh`.
> Linux-only пакеты пропускаются, OpenTofu ставится из brew, kubectl — под
> darwin/arm64. Desktop: `brew install --cask opencode-desktop`.
> См. [macos.md](macos.md).

---

## 8 профилей opencode

Все профили: `model` и `small_model` = `anthropic/claude-sonnet-4-5`.

### default (`oc`) — Базовый
Без MCP. Общие задачи, текст, планирование, быстрые правки.
Permissions: bash=ask, edit=ask.

### dev (`oc-dev`) — Мультиязычная разработка
14 агентов (dev + fullstack): `@feature-planner`, `@code-architect`, `@senior-{python,js-ts,php,cpp,java,go,rust,nextjs}-dev`,
`@appsec-auditor`, `@security-tool-developer`, `@code-reviewer`, `@platform-engineer`.
12 языковых инструкций. MCP: см. [матрицу](profiles-agents-matrix.md).

### infra (`oc-infra`) — Инфраструктура и эксплуатация
6 агентов: `@infra-engineer`, `@sre`, `@mlops-engineer`, `@gitops-engineer`,
`@security-auditor`, `@devops-reviewer`.
Все изменения — через dry-run / --check. MCP: см. [матрицу](profiles-agents-matrix.md).

### net (`oc-net`) — Сети
4 агента: `@network-engineer`, `@network-security`, `@bgp-ospf-analyst`, `@packet-analyst`.
MCP: см. [матрицу](profiles-agents-matrix.md). Оборудование: MikroTik, pfSense, OpenWrt, UniFi, D-Link, TP-Link, Dahua, Trassir.

### sec (`oc-sec`) — Безопасность
6 агентов: `@ctf-reverse-engineer`, `@ctf-pwner`, `@ctf-web-hacker`, `@pentester`,
`@appsec-auditor`, `@threat-intel`. Destructive операции — с подтверждением (bash/edit/write=ask).
MCP: см. [матрицу](profiles-agents-matrix.md).

### ot (`oc-ot`) — АСУ ТП / ICS
6 агентов: 3 primary + 3 subagent. Активные действия — только через `scripts/ot-guard.sh`.
MCP: см. [матрицу](profiles-agents-matrix.md).

### mgnt (`oc-mgnt`) — Management
3 агента: `@prd-writer`, `@incident-commander`, `@data-analyst`.
MCP: см. [матрицу](profiles-agents-matrix.md).

### design (`oc-design`) — UI/UX и визуальная приёмка
2 агента: `@ui-designer` (primary), `@visual-qa` (subagent).
MCP: см. [матрицу](profiles-agents-matrix.md); инструменты и сценарии — [design-toolkit.md](design-toolkit.md).

---

## Context management

Четыре слоя, чтобы длинные сессии не теряли решения и не упирались в окно модели:

| Слой | Что делает | Где |
|------|-----------|-----|
| Native compaction | сжимает старую историю диалога (`keep 20 000`, `buffer 24 000`) | `compaction` в default и всех профилях |
| DCP (`@tarquinen/opencode-dcp`) | обрезает устаревший tool-output, чистит ошибки, сжимает блоки | `~/.config/opencode/dcp.jsonc` |
| Lazy references | листинг каталога вместо содержимого: `context`, `docs` | `references` в default и профилях |
| Ledger | `context/INDEX.md` → `current.md` → playbook/archive по ссылке | `~/.config/opencode/context/` |

- **Пороги DCP** привязаны к окну активной модели: 80 000 / 140 000 токенов
  для окна 262 144 (`maxContextLimit` ≤ 75 % окна).
- **Ledger**: `current.md` (активная задача) и `archive/` — локальные;
  `INDEX.md`, `decisions.md`, `current.template.md`, `playbooks/` синхронизируются.
- **AGENTS.md** держится < 12 KB: always-loaded только правила, детали — в playbooks.
- SuperMemory: `captureEveryNTurns: 0`, recall только по теме задачи.

Детали и troubleshooting — [context-management.md](context-management.md).

---

## MCP инструменты

| Инструмент | Назначение | Команда |
|------------|------------|---------|
| **proxmox** | Управление PVE | `uvx proxmox-mcp-server` |
| **ansible** | Playbooks, инвентари | `ansible-mcp serve` |
| **opentofu** | IaC: plan, apply | `npx @opentofu/opentofu-mcp-server` |
| **docker** | Контейнеры, образы | `npx mcp-docker-server` |
| **ssh** | Сессии, exec, port-forward | `uvx --from slepp-ssh-mcp ssh-mcp` |
| **postgres** | Запросы, explain, индексы | `npx @yawlabs/postgres-mcp` |
| **playwright** | Браузер: клики, скриншоты | `npx @playwright/mcp@latest --browser=firefox` |
| **filesystem** | Чтение/запись файлов | `npx @modelcontextprotocol/server-filesystem` |
| **duckduckgo** | Бесплатный веб-поиск | `npx ddg-mcp-search` |
| **github** | PR, issues, code review (официальный сервер) | `github-mcp-vault` (Vault `central` + `ghcr.io/github/github-mcp-server`) |
| **gitlab-work** | Рабочий GitLab: MR, issues, pipelines, wiki, releases | `gitlab-mcp-vault work` (Vault `central`) |
| **gitlab-official-yandex** | GitLab.com, аккаунт Yandex (API 200) | `gitlab-mcp-vault yandex` |
| **gitlab-personal** | Локальный GitLab в podman (disabled) | `gitlab-mcp-vault personal` |

---

## Плагины (v2-совместимые)

| Плагин | Назначение | Профили |
|--------|------------|---------|
| opencode-synced | Авто-синхронизация с GitHub | default |
| opencode-supermemory (`/server`) | Persistent memory | все |
| @tarquinen/opencode-dcp | Dynamic Context Pruning | все |
| opencode-handoff | Передача контекста в новую сессию | все |
| opencode-usage-monitor | Квоты и балансы провайдеров | все |
| opencode-gemini-auth | OAuth для Google/Gemini | default, dev, infra, net, mgnt |
| opencode-tui-usage | TUI-sidebar: cache, context, токены, стоимость, скорость | все (cli.json) |
| @opencode-cockpit/status | Нижняя строка TUI: git.diff, todo, diagnostics, статус сессии | все (cli.json) |
| profile-badge (local) | Бейдж `профиль·агент·N/M` (MCP connected/active) в футере | все (plugins/) |

**TUI (`cli.json`):** `opencode-tui-usage` (sidebar снизу, без Tools/Skills/Context —
Context рисует нативная секция v2.3.0), `@opencode-cockpit/status` (нижняя строка),
локальный `profile-badge` (`config/plugins/profile-badge/tui.tsx`), `debug.turn_tokens`,
`diffs.source: turn`, `diffs.tree`, `session.grouping`, `prompt.editor`, `terminal.title`,
`scroll.acceleration`, `attention.volume: 0.4`; keybinds `<leader>v/d/h/p/o`.
Квоты — `usage-monitor.json` v2 (DeepSeek) во всех профилях.

**Убрано (v1-only, в v2 не работают):** opencode-swarm, opencode-vibeguard,
opencode-websearch-cited, @lyculs/opencode-firecrawl, opencode-notify (retired),
opencode-worktree, opencode-antigravity-auth, opencode-pty (v2-энтрипоинт
не загружается), opencode-morph-plugin, @plannotator/opencode, opencode-goal-plugin.

> Полный каталог плагинов экосистемы (наблюдаемость, память, провайдеры, сессии),
> правила установки и API V2 — в [docs/plugins-ecosystem.md](plugins-ecosystem.md).

---

## Кастомные агенты

| Профиль | Default agent | Primary (Tab) | Subagent |
|---------|---------------|--------------|----------|
| **default** | build | — | — |
| **dev** | build | feature-planner, code-architect, senior-{python,js-ts,php,cpp,java,go,rust,nextjs}, appsec-auditor, security-tool-developer | code-reviewer, platform-engineer |
| **infra** | infra-engineer | infra-engineer, sre, mlops-engineer, gitops-engineer, security-auditor | devops-reviewer |
| **net** | network-engineer | network-engineer, network-security, bgp-ospf-analyst | packet-analyst |
| **sec** | pentester | ctf-reverse-engineer, ctf-pwner, ctf-web-hacker, pentester, appsec-auditor, threat-intel | — |
| **ot** | ot-protocol-analyst | ot-protocol-analyst, ot-incident-responder, ot-network-designer | ot-recon, ot-segmentation-reviewer, ot-vuln-researcher |
| **mgnt** | prd-writer | prd-writer, incident-commander, data-analyst | — |

---

## Permissions

| Профиль | bash | edit | write |
|---------|------|------|-------|
| default | ask | ask | — |
| dev | ask | ask | — |
| infra | ask | ask | — |
| net | ask | ask | — |
| sec | ask | ask | ask |
| ot | ask | ask | — |
| mgnt | ask | ask | — |

---

## CLI инструменты (устанавливает setup.sh)

| Категория | Инструменты |
|-----------|-------------|
| **Сеть** | nmap, nmap-ncat, masscan, gobuster, socat, wireshark/tshark |
| **Пароли** | john, hashcat, hydra |
| **Reverse Engineering** | gdb, radare2, rizin |
| **Форензика** | binwalk, foremost, steghide, sleuthkit, testdisk |
| **Анонимность** | tor, proxychains-ng, macchanger |
| **Беспроводные сети** | aircrack-ng |
| **Песочница** | firejail, bleachbit |
| **Python** | pwntools, scapy, sqlmap, pycryptodomex, requests, bs4, ansible, ansible-mcp |
| **IaC/Cloud** | OpenTofu, kubectl, uv/uvx |
| **Dev** | jq, ruby, golang |
| **Браузер** | Playwright (Firefox) |

---

## Безопасность

- **VibeGuard** — удалён (v1-only, не работает в V2); секреты только через `{env:VAR}`
- **bash/edit=ask** — все профили с подтверждением
- **sec** — дополнительно write=ask
- **infra** — обязательный dry-run / --check
- **net** — read-only first, изменения после backup и подтверждения
- API-ключи только через `{env:VAR}` в конфигах
- **Linux**: `sudo -A` (askpass), никогда `sudo -S`
