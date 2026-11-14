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
- [ ] Нативная секция `Context` (токены, % использования) — одна, без дубля.
- [ ] Блок `Usage (v2.6.0)`: секции `Cache`, `Session`, `Speed`, `Model`, `Agents`;
      **нет** `Context`, `Tools`, `Skills`.
- [ ] В sidebar нет оценочных процентов контекста (`contextBreakdownEstimate: false`).
- [ ] После ответа агента в футере видны **токены за ход** (`debug.turn_tokens`).
- [ ] Бейдж в футере: `default · build · MCP 0/0` (в default MCP нет).
- [ ] `/diff` открывается на **Last turn**; файлы показаны деревом.
- [ ] Заголовок терминала содержит имя/ID сессии.
- [ ] Новая вкладка не смешивает каталоги (`tabs.scope: cwd`), новая сессия наследует каталог.

## 2. Keybinds

Leader по умолчанию — `ctrl+x` (см. `ctrl+x d` в палитре `ctrl+p`).

- [ ] `<leader>v` (`ctrl+x v`) — список MCP.
- [ ] `<leader>d` (`ctrl+x d`) — diff.
- [ ] `<leader>h` (`ctrl+x h`) — переключение reasoning/thinking.
- [ ] `<leader>p` (`ctrl+x p`) — список плагинов.
- [ ] `<leader>o` (`ctrl+x o`) — usage.

Если биндинг молча не срабатывает — ID не существует в v2.3.0; сверить с `opencode --help` / keymap.
`session.toggle.thinking` срабатывает только при открытой сессии: на стартовом экране
`ctrl+x h` вставляет `h` в промпт.

## 3. Именные профили

Для каждого профиля — **новая** сессия (badge и `default_agent` не применяются к `--continue`).
Для честного счётчика MCP запускать `opencode --standalone` с нужным `OPENCODE_CONFIG`:
общий фоновый сервис может держать MCP-набор другого профиля.

| Команда | Ожидаемый бейдж | Примечание |
|---|---|---|
| `oc-dev` | `dev·build·N/M` | `brave-search` disabled → connected < total |
| `oc-infra` | `infra·infra-engineer·N/M` | |
| `oc-net` | `net·network-engineer·N/M` | |
| `oc-ot` | `ot·ot-protocol-analyst·N/M` | `brave-search` disabled |
| `oc-sec` | `sec·pentester·N/M` | |
| `oc-mgnt` | `mgnt·prd-writer·N/M` | |
| `oc-design` | `design·ui-designer·N/M` | профиль добавлен после плана |

- [ ] Активный агент в бейдже меняется при переключении агента в сессии (Tab).
- [ ] `N/M` обновляется после подключения/отключения сервера (подписка `mcp.status.changed`).
- [ ] Нижняя строка cockpit показывает git-diff, todo, статус сессии; `diagnostics` — только при проблемах MCP/LSP.
- [ ] Второго блока Context (дубля sidebar) нет.

## 4. Ожидаемые отклонения (не баги)

- `—` сразу после старта — бейдж ждёт первый `sync()`, через ~2 с станет `N/M`.
- `default_agent` не действует на `--continue` и на уже открытые вкладки.
- Тема `monokai`, `tabs.mode: on`, `prompt.paste: compact` — осознанные отличия от шаблона плана.
- Бейдж компактный (`профиль·агент·N/M`) намеренно: на v2.3.0 футер узкий и делит
  ширину с `supermemory`; формат с пробелами и словом `MCP` переносился на две строки.
- Нативный status bay v2.3.0 (`N MCP /mcps`, `1 plugin failed /plugins`) — не cockpit.
  `1 plugin failed` — дубль `supermemory` (v1-ключ `plugin` + `plugins`), исправлено
  2026-11-14: одна регистрация, badge должен показывать `0 plugin failed`.
- Нативные секции sidebar v2.3.0 (`Context`, `MCP`, `Usage`) и блок
  `opencode-tui-usage` (`Cache`, `Session`, `Speed`, `Model`). Дубль Context убран:
  у плагина `display.sections.context: false`, Context рисует нативная секция.
  `Usage` (баланс провайдера) и `Usage (v2.6.0)` (токены/стоимость сессии) —
  разные данные, не дубль.

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

## Результаты прогона 2026-11-14 (v2.3.0, tmux)

Проверено в `default` и `infra` (`--standalone`), а также в `dev` (общий сервис):

- Бейдж: `default·build·0/0`, `infra·infra-engineer·8/8`, `dev·build·9/9` — одна строка.
- Sidebar: нативный `Context` (одна секция) + блок `Usage (v2.6.0)` с секциями
  `Cache`, `Session`, `Speed`, `Model`; `Tools`/`Skills` отсутствуют.
- Токены за ход: `+ Tokens: 1 step · latest: … · cached · total`.
- Keybinds: `ctrl+x v/d/p/o` открывают MCP, diff, plugins, usage; `ctrl+x h`
  потребляется в сессии, на стартовом экране вставляется в промпт (см. §2).
- Cockpit: строка `id ses_…` рендерится; `git.diff`/`todo` пусты вне git/задач,
  `diagnostics` — только при нездоровых MCP/LSP.
- `default_agent`: infra-сессия стартует с `Infra-Engineer`.
- Наблюдения: нативная строка v2.3.0 `N MCP /mcps · 1 plugin failed`;
  Context не дублируется (`display.sections.context: false`), `Usage` (баланс)
  и `Usage (v2.6.0)` (токены сессии) показывают разные данные; счётчик MCP
  без `--standalone` отражает MCP фонового сервиса, а не профиля.

## Откат

```bash
bak=/tmp/opencode/tui-plan-20261114-124406   # последний известный бэкап
cp "$bak/cli.json" ~/.config/opencode/cli.json
for p in dev infra net sec ot mgnt design; do cp "$bak/$p.json" ~/.config/opencode-$p/opencode.json; done
opencode service restart
```

Профильные `default_agent` и плагины откатывать только если проблема воспроизводится
именно в них; `cli.json` достаточно в большинстве случаев.
