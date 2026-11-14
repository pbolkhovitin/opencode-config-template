# TUI smoke-test checklist (OpenCode v2.3.0)

Ручная проверка после изменений TUI-конфига или обновления OpenCode.
План, который закрывает этот чек-лист: `docs/superpowers/plans/2026-10-26-tui-improvements.md`.

## Подготовка

```bash
opencode --version          # ожидается 2.x (проверено на 2.3.0)
opencode plugin check       # tui-usage и cockpit — без "check failed"
opencode service restart    # cockpit грузится только после рестарта сервиса
```

Выйти из всех открытых TUI перед проверкой: конфиг и плагины читаются при старте.

## 1. `default` (`oc`)

Запустить `oc` и создать **новую** сессию (не `--continue`).

- [ ] Sidebar расположен **снизу**, без рамки.
- [ ] Секции: `Cache`, `Context`, `Session`, `Model`, `Speed`, `Agents`; **нет** `Tools` и `Skills`.
- [ ] В sidebar нет оценочных процентов контекста (`contextBreakdownEstimate: false`).
- [ ] После ответа агента в футере видны **токены за ход** (`debug.turn_tokens`).
- [ ] Бейдж в футере: `default · build · MCP 0/0` (в default MCP нет).
- [ ] `/diff` открывается на **Last turn**; файлы показаны деревом.
- [ ] Заголовок терминала содержит имя/ID сессии.
- [ ] Новая вкладка не смешивает каталоги (`tabs.scope: cwd`), новая сессия наследует каталог.

## 2. Keybinds

- [ ] `<leader>v` — список MCP.
- [ ] `<leader>d` — diff.
- [ ] `<leader>h` — переключение reasoning/thinking.
- [ ] `<leader>p` — список плагинов.
- [ ] `<leader>o` — usage/sidebar.

Если биндинг молча не срабатывает — ID не существует в v2.3.0; сверить с `opencode --help` / keymap.

## 3. Именные профили

Для каждого профиля — **новая** сессия (badge и `default_agent` не применяются к `--continue`).

| Команда | Ожидаемый бейдж | Примечание |
|---|---|---|
| `oc-dev` | `dev · build · MCP N/M` | `brave-search` disabled → connected < total |
| `oc-infra` | `infra · infra-engineer · MCP N/M` | |
| `oc-net` | `net · network-engineer · MCP N/M` | |
| `oc-ot` | `ot · ot-protocol-analyst · MCP N/M` | `brave-search` disabled |
| `oc-sec` | `sec · pentester · MCP N/M` | |
| `oc-mgnt` | `mgnt · prd-writer · MCP N/M` | |
| `oc-design` | `design · ui-designer · MCP N/M` | профиль добавлен после плана |

- [ ] Активный агент в бейдже меняется при переключении агента в сессии (Tab).
- [ ] `MCP N/M` обновляется после подключения/отключения сервера (подписка `mcp.status.changed`).
- [ ] Нижняя строка cockpit показывает git-diff, todo, статус сессии; `diagnostics` — только при проблемах MCP/LSP.
- [ ] Второго блока Context (дубля sidebar) нет.

## 4. Ожидаемые отклонения (не баги)

- `MCP —` сразу после старта — бейдж ждёт первый `sync()`, через ~2 с станет `MCP N/M`.
- `default_agent` не действует на `--continue` и на уже открытые вкладки.
- Тема `monokai`, `tabs.mode: on`, `prompt.paste: compact` — осознанные отличия от шаблона плана.

## 5. Диагностика при провале

```bash
opencode plugin check                 # плагин не загрузился?
opencode service status               # cockpit требует живого сервиса
jq . ~/.config/opencode/cli.json      # валиден ли JSON
git -C ~/.local/share/opencode/opencode-synced/repo status -sb
```

- Sidebar без секций → проверить `plugins[].options.display` в `cli.json`.
- Нет нижней строки → `opencode service restart`, затем новый TUI.
- Нет бейджа → `opencode plugin list` (должен быть `profile-badge`); fallback —
  добавить `"./plugins/profile-badge"` в `plugins` и перезапустить.

## Откат

```bash
bak=/tmp/opencode/tui-plan-20261114-124406   # последний известный бэкап
cp "$bak/cli.json" ~/.config/opencode/cli.json
for p in dev infra net sec ot mgnt design; do cp "$bak/$p.json" ~/.config/opencode-$p/opencode.json; done
opencode service restart
```

Профильные `default_agent` и плагины откатывать только если проблема воспроизводится
именно в них; `cli.json` достаточно в большинстве случаев.
