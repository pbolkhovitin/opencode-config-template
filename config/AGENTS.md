# Default Profile

> MCP-серверы в default-профиле **не подключены**. Они доступны в именных профилях
> (`dev`, `infra`, `net`, `sec`, `ot`, `mgnt`) — см. `profiles/*/opencode.jsonc`.

## Кастомные агенты

В `default` кастомных агентов нет: работают встроенные `build`/`plan`.
Агенты с персонами (`senior-*`, `code-reviewer`, `infra-engineer`,
`network-engineer` и др.) подключены в именных профилях — см.
`docs/profiles-agents-matrix.md` в репозитории конфигурации.

## MCP по профилям

`default` — MCP отсутствует (только встроенные инструменты). В именных профилях
состав и статус серверов — в [матрице](../docs/profiles-agents-matrix.md);
MCP-колонка генерируется из `profiles/*/opencode.jsonc`.

Секреты MCP — только `{env:...}`; значения хранятся в окружении или Vault.

## Плагины
### Профильные (v2-совместимые)
- **opencode-synced** — синхронизация конфига с GitHub
- **opencode-supermemory** — persistent memory между сессиями
- **@tarquinen/opencode-dcp** — Dynamic Context Pruning: авто-обрезка устаревшего контекста
- **opencode-gemini-auth** — OAuth для Google/Gemini

### Устаревшее (v1-only, в v2 не работают)
- ~~opencode-swarm, opencode-vibeguard, opencode-websearch-cited, opencode-notify, opencode-worktree, opencode-antigravity-auth, opencode-firecrawl~~
- `opencode-notify` официально **retired** автором (v2-порт не планируется). В v2 уведомления — нативные: `cli.json` → `attention.notifications` / `attention.sound`
- `opencode-websearch-cited` → у v2 встроенный websearch (`ctx.websearch`)
- `opencode-shell-strategy` (инструкция, работает) — non-interactive shell команды, предотвращает зависания

## Доступные скиллы
- `grill-me` — интервьюирование плана/дизайна по одной ветке решений за ход
- `find-skills` — поиск и установка новых скиллов из чата
- `writing-plans` — составление плана перед реализацией
- `verification-before-completion` — верификация перед завершением задачи
- Все `caveman/*` — сжатый режим, коммиты, ревью
- `devops-rollout-plan` — генератор планов раскатки (preflight, phased deploy, rollback)
- `agent-vault` — секреты агента в HashiCorp Vault. Авто-триггер при словах «пароль», «секрет», «креды», «токен»

**Авто-триггер grill-me**: при фразах «grill me», «стресс-тест плана», «проинтервьюируй план», «проби план» — автоматически активируй скилл `grill-me`.

## Секреты — только через Vault

Секреты — только через `agent-vault` (HashiCorp Vault, `secret/agent/<project>/<name>`);
значения не печатать, не писать в файлы и не коммитить.

## SAST / AppSec
- **semgrep** — SAST сканирование PHP, TS, JS (OWASP Top 10, CWE)
- `jwt-security` — безопасность JWT
- `security-secrets` — поиск секретов в коде
- `security-docker` — аудит Dockerfile/контейнеров
- `npm audit` / `composer audit` — аудит зависимостей

## Security toolchain (решение)

Bare-metal **Kali / Kali Purple не ставим**: агент работает в shell хоста.
Схема: **native → Kali-контейнер (docker/podman) → Kali VM в Proxmox**.
Инвентарь и маршруты установки — `docs/security-toolchain.md` (профиль `sec`).

## Методология работы (общие подходы)

SuperMemory на старте, compress по вехам, multi-model split.

## Правила работы

См. `instructions/rules.md` (включая политику sudo/askpass).

## Workflow

См. `instructions/workflow.md`.

## Субагенты: когда параллельно, когда inline

Inline — 1–2 правки; субагент — обзор, аудит или изолированная задача; параллельно — независимые области.

## Context protocol

At task start read `context/INDEX.md`, then `context/current.md`; update `current.md` after each milestone. Keep durable decisions in `decisions.md`, long details in `playbooks/` with one line in `INDEX.md`, and do not load `archive/*` without an index reference. Prefer `grep` + `read` with `offset`/`limit`; when compressing, preserve objective, decisions, touched files, next step, and links to context files.

## Docs

Пути указаны относительно корня репозитория `opencode-config-template`
(в runtime-каталоге `~/.config/opencode/` их нет):

- `docs/profiles-agents-matrix.md` — матрица профилей и агентов
- `docs/project-config-template.json` — шаблон конфига проекта
- `docs/default/README.md` — сценарии default-профиля
