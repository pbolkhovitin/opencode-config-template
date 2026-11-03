# Management Profile — PM / Product / Support

> Модель: `anthropic/claude-sonnet-4-5` (`model` и `small_model`)

## Плагины
- **supermemory** — persistent memory между сессиями (контекст проектов)
- **dcp** — Dynamic Context Pruning
- **opencode-handoff** — передача контекста в новую сессию
- **opencode-gemini-auth** — OAuth для Gemini
- **shell-strategy** (инструкция) — non-interactive shell команды
- Веб-поиск — встроенный `websearch` (плагин `websearch-cited` не используется, v1-only)

## Кастомные агенты (Tab)
- `@prd-writer` (primary) — PRD, user stories, OKR, спецификации
- `@incident-commander` (primary) — Incident response, triage, post-mortem
- `@data-analyst` (primary) — SQL-аналитика, метрики, дашборды. Read-only.

## Доступные MCP

| MCP | Возможности |
|-----|-------------|
| **ssh** | Мониторинг серверов, логи, статус сервисов |
| **postgres** | Только SELECT / read-only запросы |
| **playwright** | UAT, скриншоты, мониторинг сайтов |
| **docker** | Временные контейнеры, утилиты |

## Сценарии

### Инцидент: сервис недоступен
```bash
# 1. Сбор данных — SSH
ssh_ssh_exec target=192.168.1.100 command="systemctl status nginx"
ssh_ssh_exec target=192.168.1.100 command="journalctl -u nginx --no-pager -n 50"

# 2. Проверка метрик — Postgres
postgres_pg_health
postgres_pg_inspect_locks

# 3. UI check — Playwright
playwright_browser_navigate url=https://status.example.com
playwright_browser_screenshot type=png

# 4. Анализ через systematic-debugging
```

### Мониторинг и аналитика
```bash
postgres_pg_top_queries orderBy=total_time
postgres_pg_table_bloat schema=public
postgres_pg_seq_scan_tables
playwright_browser_navigate url=https://example.com
playwright_browser_console_messages level=error
```

### Создание PRD для новой фичи
```bash
# 1. Brainstorming + встроенный websearch для рыночного контекста
# 2. PRD через to-prd / breakdown-epic-pm
# 3. План через writing-plans
# 4. Делегирование через dispatching-parallel-agents
# 5. Контроль через requesting-code-review
# 6. Приёмка через verification-before-completion + playwright
```

### UAT / Приёмка
```bash
playwright_browser_navigate url=https://staging.example.com
playwright_browser_snapshot
playwright_browser_click target="button:has-text('Submit')"
```

## Permissions
- bash=ask, edit=ask (destructive — с подтверждением)
- Postgres — только read-only транзакции
- Нет доступа к инфраструктурным MCP (proxmox, ansible, opentofu)
