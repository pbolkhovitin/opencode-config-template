# Аудит старых скиллов (2026-10-25)

Проверены все `config/skills/*/SKILL.md` (88 шт.) на ссылки на v1-only плагины:
`opencode-pty`, `vibeguard`, `opencode plugin add`, `opencode-swarm`,
`websearch-cited`, `opencode-notify`, `opencode-worktree`, `antigravity`, `firecrawl`.

## Результат

Затронуто 15 из 88 скиллов:

| Скилл(ы) | Ссылка | Статус |
|---|---|---|
| `firecrawl-*` (14 шт.: crawl, scrape, search, map, download, parse, interact, agent, build-*) | CLI `firecrawl` | рабочие, требуют установленный CLI и `FIRECRAWL_API_KEY`; плагин `opencode-firecrawl` не нужен |
| `threat-intel` | `websearch-cited`, `firecrawl` | исправлен на встроенный websearch + CLI |
| `web-scraping` | `firecrawl` | рабочий, CLI-зависимость |

## Выводы

- Скиллы — это инструкции, а не плагины: `firecrawl-*` не ломаются от отсутствия
  одноимённого плагина, но и не работают без CLI/ключа. Держим как опциональные.
- Единственная реальная v1-зависимость (`websearch-cited`) удалена из `threat-intel`.
- Остальные 73 скилла ссылок на v1-плагины не содержат.
