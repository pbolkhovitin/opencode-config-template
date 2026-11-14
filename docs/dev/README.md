# Dev Profile — Мультиязычная разработка

Объединяет бывшие `dev` и `fullstack`. Конфиг: `profiles/dev/opencode.jsonc`.
Запуск: `oc-dev` или `ocp dev`.

## Агенты
- `@feature-planner` (primary) — требования → план, read-only
- `@code-architect` (primary) — архитектура, ADR, trade-offs, без кода
- `@senior-python-dev`, `@senior-js-ts-dev`, `@senior-php-dev`, `@senior-cpp-dev`,
  `@senior-java-dev`, `@senior-go-dev`, `@senior-rust-dev`, `@senior-nextjs-dev` (primary)
- `@appsec-auditor` (primary) — SAST, dependency audit
- `@security-tool-developer` (primary) — Python security tooling
- `@code-reviewer` (subagent) — кросс-языковое ревью, read-only
- `@platform-engineer` (subagent) — K8s, Docker, CI/CD

## Поддерживаемые языки

| Язык | Инструкция | Агент |
|---|---|---|
| Python | `instructions/python.md` | `senior-python-dev` |
| JavaScript/TypeScript | `instructions/js-ts.md` | `senior-js-ts-dev` |
| Next.js / React | `instructions/js-ts.md` | `senior-nextjs-dev` |
| PHP | `instructions/php.md` | `senior-php-dev` |
| C/C++ | `instructions/c-cpp.md` | `senior-cpp-dev` |
| Java | `instructions/java.md` | `senior-java-dev` |
| Go | `instructions/golang.md` | `senior-go-dev` |
| Rust | `instructions/rust.md` | `senior-rust-dev` |
| Bash | `instructions/bash.md` | — |
| Kubernetes | `instructions/kubernetes.md` | `platform-engineer` |
| ELK | `instructions/elk.md` | — |
| Низкий уровень (ASM, embedded) | `instructions/low-level.md` | `senior-cpp-dev` |

## MCP
- **postgres** — запросы, explain, индексы
- **docker** — контейнеры для разработки и тестов
- **playwright** — браузерные тесты (Firefox)
- **filesystem** — работа с файлами
- **github** — PR, issues, review (официальный сервер через `github-mcp-vault`, PAT из Vault, Docker)
- **gitlab-work** — рабочий GitLab: merge requests, issues, pipelines, wiki (Vault, `gitlab.example.com PAT`)
- **gitlab-official-yandex** — официальный аккаунт GitLab.com, включён
- **gitlab-personal** — личный GitLab, выключен до добавления токена
- **duckduckgo** — бесплатный поиск
- **brave-search** — отключён, нужен `BRAVE_API_KEY`
- **ssh** — staging и отладка

## Сценарии

### TDD-цикл
```
1. Написать падающий тест
2. Запустить тесты — убедиться, что красный
3. Минимальная реализация — зелёный
4. Рефакторинг под тестами
5. verification-before-completion
```

### Postgres
```bash
postgres_pg_describe_table schema=public table=users
postgres_pg_explain sql="SELECT * FROM orders WHERE user_id = $1 AND status = $2" params=[42,active]
postgres_pg_unused_indexes schema=public
```

### GitHub PR
```bash
gh pr create --title "feat: add pagination" --body "Cursor-based pagination"
gh pr checks 42
```

### Docker
```bash
docker start_container id=test-postgres
docker_exec_command id=my-app command=["npm","test"]
docker_container_logs id=my-app tail=100
```

## Скиллы
Разработка: `test-driven-development`, `writing-plans`, `brainstorming`, `systematic-debugging`,
`verification-before-completion`, `requesting-code-review`, `finishing-a-development-branch`,
`code-review-and-quality`, `dispatching-parallel-agents`.
Стек: `python`, `fastapi-python`, `nextjs-react-typescript`, `accessibility-a11y`,
`postgresql-table-design`, `postgresql-optimization`, `supabase-postgres-best-practices`,
`docker-kubernetes`, `docker-build-strategies`, `webapp-testing`, `web-scraping`.
Безопасность: `security-audit`, `security-secrets`, `security-docker`, `jwt-security`,
`python-cybersecurity-tool-development`, `log-analysis`.

## Правила
- Тесты и типы — до коммита; линтер — часть цикла
- Код на английском, сообщения и комментарии — на русском
- Прод-инфраструктуру не менять — профиль `infra`
- Секреты — `agent-vault` / `{env:...}`
- `sudo` — только `sudo -A`

## Governance
Добавление языка и правки инструкций — [GOVERNANCE.md](GOVERNANCE.md).
