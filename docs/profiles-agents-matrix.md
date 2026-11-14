# Матрица «профиль → агенты и MCP»

Кто доступен в каждом профиле и когда его запускать. Переключение — `ocp <profile>`.
Канонический набор: `default`, `dev`, `infra`, `net`, `sec`, `ot`, `mgnt`, `design`.

## Сводка

| Профиль | Алиас | Модель | MCP | Агенты (primary) | Агенты (subagent) | Когда использовать |
|---|---|---|---|---|---|---|
| `default` | `oc` | `anthropic/claude-sonnet-4-5` | — | — | — | Общие задачи, текст, планирование, быстрые правки без MCP |
| `dev` | `oc-dev` | `anthropic/claude-sonnet-4-5` | postgres, docker, playwright, filesystem, brave-search (off), duckduckgo, ssh, github, gitlab-official-yandex, gitlab-work, gitlab-personal (off) | `feature-planner`, `code-architect`, `senior-python-dev`, `senior-js-ts-dev`, `senior-php-dev`, `senior-cpp-dev`, `senior-java-dev`, `senior-go-dev`, `senior-rust-dev`, `senior-nextjs-dev`, `appsec-auditor`, `security-tool-developer` | `code-reviewer`, `platform-engineer` | Разработка на любом стеке: архитектура → TDD → реализация → ревью |
| `infra` | `oc-infra` | `anthropic/claude-sonnet-4-5` | proxmox, ansible, opentofu, docker, ssh, postgres, gitlab-official-yandex, gitlab-work, gitlab-personal (off) | `infra-engineer`, `sre`, `mlops-engineer`, `gitops-engineer`, `security-auditor` | `devops-reviewer` | Инфраструктура, IaC, Kubernetes, GitOps, MLOps, эксплуатация и инциденты |
| `net` | `oc-net` | `anthropic/claude-sonnet-4-5` | ssh, docker, filesystem, duckduckgo | `network-engineer`, `network-security`, `bgp-ospf-analyst` | `packet-analyst` | Сети: VLAN, маршрутизация, firewall, VPN, RouterOS/OpenWrt/pfSense, pcap |
| `sec` | `oc-sec` | `anthropic/claude-sonnet-4-5` | ssh, docker | `ctf-reverse-engineer`, `ctf-pwner`, `ctf-web-hacker`, `pentester`, `appsec-auditor`, `threat-intel` | — | Пентест, CTF, AppSec-аудит, форензика |
| `ot` | `oc-ot` | `anthropic/claude-sonnet-4-5` | ssh, docker, filesystem, proxmox, playwright, duckduckgo, brave-search (off) | `ot-protocol-analyst`, `ot-incident-responder`, `ot-network-designer` | `ot-recon`, `ot-segmentation-reviewer`, `ot-vuln-researcher` | АСУ ТП/ICS: пассивный аудит, сегментация, разбор pcap, КИИ/ФСТЭК; активные действия — только через `ot-guard` |
| `mgnt` | `oc-mgnt` | `anthropic/claude-sonnet-4-5` | ssh, postgres, playwright, docker | `prd-writer`, `incident-commander`, `data-analyst` | — | PRD, инциденты, аналитика |
| `design` | `oc-design` | `anthropic/claude-sonnet-4-5` | chrome-devtools, playwright, penpot, shadcn, mermaid, duckduckgo, figma (off), magic (off), unsplash (off) | `ui-designer` | `visual-qa` | Сайт и оформление: арт-дирекшн, дизайн-система, вёрстка, скриншот-приёмка, иллюстрации |

## Агенты по ролям

### Разработка (`dev`)
- `feature-planner` — требования → план, без кода.
- `code-architect` — архитектура, ADR, trade-off analysis, без кода.
- `senior-*` — реализация и ревью на конкретном языке (Python, JS/TS, PHP, C/C++, Java, Go, Rust, Next.js).
- `appsec-auditor` — SAST (semgrep), аудит зависимостей.
- `security-tool-developer` — Python-инструменты безопасности.
- `code-reviewer` (subagent) — кросс-языковое ревью, read-only.
- `platform-engineer` (subagent) — K8s, Docker, CI/CD.

### Инфраструктура (`infra`)
- `infra-engineer` — Proxmox, Ansible, OpenTofu, Docker, K8s.
- `sre` — SLO/SLI, инциденты, observability, capacity planning, postmortem.
- `mlops-engineer` — ML-пайплайны, registry, inference, GPU-планирование.
- `gitops-engineer` — Argo CD/Flux, Helm/Kustomize, секреты, progressive delivery.
- `security-auditor` — аудит инфраструктуры и конфигураций.
- `devops-reviewer` (subagent) — ревью IaC, read-only.

### Сети (`net`)
- `network-engineer` — L2/L3, VLAN, маршрутизация, firewall, VPN, конфиги оборудования.
- `network-security` — сегментация, аудит ACL/firewall, IDS, усиление VPN.
- `bgp-ospf-analyst` — BGP/OSPF/IS-IS: best-path, фильтрация, сходимость.
- `packet-analyst` (subagent) — pcap/tshark/Zeek, таймлайны, артефакты.

### Безопасность (`sec`)
- `ctf-reverse-engineer`, `ctf-pwner`, `ctf-web-hacker` — CTF-дисциплины.
- `pentester` — PTES-методология, отчётность.
- `appsec-auditor` — SAST и аудит зависимостей.
- `threat-intel` — MITRE ATT&CK, CVE, Exploit-DB.

### АСУ ТП (`ot`)
- `ot-protocol-analyst`, `ot-incident-responder`, `ot-network-designer` (primary).
- `ot-recon`, `ot-segmentation-reviewer`, `ot-vuln-researcher` (subagent).
- Активные действия — только через `scripts/ot-guard.sh`.

### Управление (`mgnt`)
- `prd-writer`, `incident-commander`, `data-analyst`.

### Дизайн (`design`)
- `ui-designer` — арт-дирекшн → токены → каркас → реализация → приёмка скриншотами.
- `visual-qa` (subagent) — визуальная приёмка: адаптивность, контраст, состояния, консоль.

Инструменты и полный каталог (скиллы, плагины, MCP) — [design-toolkit.md](design-toolkit.md).

## Как вызывать субагентов

- **Явно по имени** — упомянуть агента в запросе: «делегируй `code-reviewer` проверку диффа».
- **Через `task`/`subagent`** — модель сама вызывает субагента, если задача соответствует его описанию.
- **Параллельно** — 2–4 субагента на независимые области (ревью + безопасность + тесты).
- **Режимы**: `primary` можно выбрать в Tab; `subagent` вызывается только делегированием.

## Кого нет в профиле

Агенты не переносятся между профилями автоматически. Если нужен `network-engineer` в `infra` —
переключитесь на `net` или добавьте агента в проектный конфиг (см. `docs/project-config-template.json`).

## MCP и секреты

- Секреты — только `{env:...}`; значения в окружении или Vault (`agent-vault`).
- Проектные MCP лучше держать в `<project>/opencode.json`, а не в глобальном профиле.
- `brave-search` отключён по умолчанию и присутствует только в `dev` и `ot`:
  включается установкой `BRAVE_API_KEY` и `disabled: false`.

### MCP-наборы на сессию

Плагин `opencode-mcp-sets` (команда `/mcp`) скрывает MCP-серверы в отдельной сессии,
не отключая общие соединения:

```text
/mcp list
/mcp off gitlab-official-*
/mcp only gitlab-work,github
/mcp reset
```

Это session-scoped permissions + fallback-хук на контекст; другие сессии и вкладки
сохраняют свой набор. Подробности и ограничения — [mcp-sets.md](mcp-sets.md).

### GitLab MCP (dev, infra)

Три инстанса, все токены — в Vault (`instance central`, проект `YOUR_PROJECT`):

| MCP-сервер | URL по умолчанию | Секрет Vault | Состояние |
|---|---|---|---|
| `gitlab-work` | `https://gitlab.example.com/api/v4` | `gitlab.example.com PAT` | включён |
| `gitlab-official-yandex` | `https://gitlab.com/api/v4` | `gitlab official yandex pat` | включён |
| `gitlab-personal` | `https://gitlab.com/api/v4` | `gitlab personal pat` | выключен (личный, позже) |

Запуск — через `scripts/gitlab-mcp-vault` (ставится в `~/.local/bin`), токен
передаётся только в env дочернего процесса. Проверка без вывода секрета:
`gitlab-mcp-vault work --check` (наличие) и `--check-api` (валидность токена,
HTTP 200; 401 — токен отозван/просрочен).

### GitHub MCP (dev)

Один сервер — официальный `ghcr.io/github/github-mcp-server`, запускается через
`scripts/github-mcp-vault` (Docker/podman). PAT лежит в Vault
(`secret/agent/YOUR_PROJECT/github YOUR_ORG pat`, instance `personal`) и передаётся
только в env MCP-процесса; в конфиге секретов нет. Проверка:
`github-mcp-vault --check` (наличие) и `--check-api` (HTTP 200).

В локальной сети организации рабочий GitLab доступен как `gitlab.internal.example.com`:

```bash
export GITLAB_WORK_API_URL="https://gitlab.internal.example.com/api/v4"
```

Для официальных API URL переопределяется через
`GITLAB_OFFICIAL_YANDEX_API_URL`, для личного — `GITLAB_PERSONAL_API_URL`. Полный доступ к API
ограничивается scope PAT; read-only можно включить отдельно.

## История изменений набора профилей

`devops`, `fullstack`, `sec-lm` удалены, их содержимое слито в `dev`, `infra`, `sec`.
Карта переноса — [profiles-migration.md](profiles-migration.md).

## Vault и MCP

GitLab/GitHub MCP используют Vault instance **central** (`http://127.0.0.1:8204`, project `YOUR_PROJECT`), а не `personal` (8201). `gitlab-personal` зарезервирован под локальный GitLab в podman и сейчас `disabled: true`.
