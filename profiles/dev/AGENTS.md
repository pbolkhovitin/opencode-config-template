# Dev Profile — Разработка, мультиязычный стек и security tooling

Объединяет бывший `dev` и `fullstack`.

## Плагины (v2-совместимые)
- **opencode-supermemory** — persistent memory между сессиями
- **@tarquinen/opencode-dcp** — Dynamic Context Pruning
- **opencode-gemini-auth** — OAuth для Google/Gemini
- **opencode-handoff** — передача контекста в новую сессию
- ~~vibeguard, swarm, websearch-cited, notify, worktree, antigravity-auth~~ — v1-only, в v2 не работают

## Кастомные агенты (Tab)

### Планирование и архитектура
- **@feature-planner** (primary) — анализ требований и план реализации. Read-only.
- **@code-architect** (primary) — архитектура, ADR, trade-off analysis. Не пишет код.

### Языки
- **@senior-python-dev** (primary) — FastAPI, SQLAlchemy, asyncio, pytest
- **@senior-js-ts-dev** (primary) — React, Next.js, Node.js, TypeScript
- **@senior-php-dev** (primary) — Symfony/Laravel, PHPStan max, безопасный SQL/шаблоны
- **@senior-cpp-dev** (primary) — C++20/23, RAII, sanitizers, embedded
- **@senior-java-dev** (primary) — Spring Boot 3, Hibernate, Kafka
- **@senior-go-dev** (primary) — chi/gRPC, sqlx, K8s-native
- **@senior-rust-dev** (primary) — Axum/tokio, SQLx
- **@senior-nextjs-dev** (primary) — App Router, RSC, Server Actions, Tailwind

### Качество и безопасность
- **@appsec-auditor** (primary) — SAST (semgrep), dependency audit
- **@security-tool-developer** (primary) — Python security tooling (pwntools, scapy, async)
- **@code-reviewer** (subagent) — ревью на любом языке. Read-only.
- **@platform-engineer** (subagent) — K8s, Docker, CI/CD.

## Доступные MCP инструменты
- **postgres** — базы данных PostgreSQL
- **docker** — контейнеры для разработки и тестов
- **playwright** — браузерное тестирование (Firefox)
- **filesystem** — доступ к файловой системе
- **github** — GitHub API (PR, issues, code review), PAT из Vault, официальный сервер в Docker
- **gitlab-work** — рабочий GitLab (merge requests, issues, pipelines, wiki), токен из Vault
- **gitlab-official-yandex** / **gitlab-official-gmail** — официальные аккаунты GitLab.com, включены
- **gitlab-personal** — личный GitLab, выключен до добавления токена
- **duckduckgo** — бесплатный поиск
- **brave-search** — поиск (отключён, нужен `BRAVE_API_KEY`)
- **ssh** — удалённое подключение (staging, отладка)

## Поддерживаемые языки
Frontend: JavaScript/TypeScript, React, Next.js. Backend: Python, PHP, Java, Go, Rust, C/C++.
Scripting: Bash. Низкий уровень: ASM, embedded, firmware. Инфраструктура: Kubernetes, ELK, Docker.

## Инструкции по языкам
`instructions/{core,bash,python,php,java,golang,rust,js-ts,c-cpp,kubernetes,elk,low-level}.md` —
загружаются все; используй релевантные разделу.

## Правила
- Запускай тесты после изменений: `pytest` / `npm test` / `bun test` / `cargo test` / `go test ./...`
- Проверяй типы: `mypy --strict`, `tsc --noEmit`, `phpstan`, `cargo clippy`
- Код на английском, сообщения и комментарии — на русском
- Прод-инфраструктуру не меняй — для этого профиль `infra`
- Секреты — только через `agent-vault` (Vault) или `{env:...}`
- **sudo**: только `sudo -n`; при запросе пароля — `sudo -v` в терминале пользователя, никогда `sudo -S` и не просить пароль в чате

## Workflow
1. **Анализ** — пойми задачу, найди код через grep/glob
2. **План** — `writing-plans` / `brainstorming` для сложных задач
3. **TDD** — `test-driven-development`: красный → зелёный → рефакторинг
4. **Реализация** — используй MCP (postgres, docker, playwright, github, gitlab-work)
5. **Верификация** — `verification-before-completion`: тесты, типы, линтер
6. **Ревью** — `requesting-code-review` / `@code-reviewer`
7. **Закрытие** — `finishing-a-development-branch`

## Docs

Пути относительно корня репозитория `my-opencode-config`:

- `docs/dev/README.md` — сценарии разработки
- `docs/dev/GOVERNANCE.md` — governance языковых инструкций
- `docs/profiles-agents-matrix.md` — матрица профилей
