# Context management

Четырёхслойная схема, чтобы длинные сессии не раздували контекст и не теряли
решения. Слои дополняют друг друга, а не заменяют.

## Слои

| Слой | Что делает | Где настроен | Когда срабатывает |
|------|-----------|--------------|-------------------|
| **Native compaction** | Сжимает старую историю диалога в резюме | `opencode.json` / профили → `compaction` | автоматически при заполнении окна модели; вручную — `/compact` |
| **DCP** (`@tarquinen/opencode-dcp`) | Обрезает устаревший tool-output, чистит ошибки, сжимает блоки | `~/.config/opencode/dcp.jsonc` | пороги по токенам, `turnProtection`, `purgeErrors` |
| **Lazy references** | Даёт агенту листинг каталога вместо содержимого | `opencode.json` → `references` | при явном обращении к reference |
| **Ledger** (`context/`) | Хранит objective/decisions/next step между сессиями и после компакции | `~/.config/opencode/context/` + `instructions/context-protocol.md` | агент читает `INDEX.md` на старте задачи |

Порядок действий на старте задачи: `context/INDEX.md` → `context/current.md`
→ только те playbook/archive, на которые указывает индекс. Крупные каталоги
(`docs/`, `context/`) подключены как references — их листинг не занимает контекст,
пока файл не открыт.

## Настройки default-профиля

`~/.config/opencode/opencode.json`:

```json
{
  "compaction": {
    "auto": true,
    "keep": { "tokens": 20000 },
    "buffer": 24000
  },
  "references": {
    "context": {
      "path": "~/.config/opencode/context",
      "description": "Context ledger. Read INDEX.md first, then only the needed file."
    },
    "docs": {
      "path": "~/.local/share/opencode/opencode-synced/repo/docs",
      "description": "Project docs; open only the relevant page."
    }
  },
  "instructions": ["...", "/home/<user>/.config/opencode/instructions/context-protocol.md"]
}
```

- `keep.tokens: 20000` — сколько последних токенов компакция оставляет нетронутыми.
- `buffer: 24000` — запас до лимита окна, при котором запускается авто-компакция.
- `instructions` содержит **абсолютный** путь: относительный путь не резолвится
  при запуске из другого каталога.

## DCP

`~/.config/opencode/dcp.jsonc` (синхронизируется через `extraConfigPaths`):

```jsonc
{
  "turnProtection": { "enabled": true, "turns": 4 },
  "compress": {
    "minContextLimit": 80000,
    "maxContextLimit": 140000,
    "nudgeFrequency": 3,
    "iterationNudgeThreshold": 10,
    "protectUserMessages": true
  },
  "strategies": { "purgeErrors": { "enabled": true, "turns": 3 } },
  "experimental": { "allowSubAgents": true }
}
```

Правило выбора порогов по окну активной модели (`MODEL_LIMIT`):

| `MODEL_LIMIT` | `minContextLimit` | `maxContextLimit` |
|---------------|-------------------|-------------------|
| ≤ 131 072 | 64 000 | 96 000 |
| > 131 072 | 80 000 | 140 000 |

`maxContextLimit` не больше 75 % окна. Для `anthropic/claude-sonnet-4-5`
(262 144) действуют 80 000 / 140 000 — это 53 % окна.

Команды в сессии: `/dcp` — статус и текущее потребление, `/dcp-compress` —
принудительное сжатие. `allowSubAgents: true` разрешает DCP работать в
подагентах; `purgeErrors.turns: 3` убирает старые ошибки инструментов.

State плагина: `~/.local/share/opencode/storage/plugin/dcp/*.json`
(по файлу на сессию, ~18 MB на десятки сессий). Плагин не чистит его сам:
удалять только при закрытых сессиях и после подтверждения.

## Ledger

```
~/.config/opencode/context/
├── INDEX.md              # точка входа: что читать и когда
├── current.md            # активная задача: objective/constraints/decisions/files/next step
├── current.template.md   # шаблон для новой задачи
├── decisions.md          # долговечные решения, одна строка на решение
├── playbooks/            # длинные how-to, вынесенные из AGENTS.md
└── archive/              # завершённые/приостановленные задачи
```

Правила ведения — `instructions/context-protocol.md` (подключён в `instructions`
всех профилей): держать `current.md` актуальным после каждой вехи, детали
уносить в topic-файл и добавлять одну строку в `INDEX.md`, `archive/` читать
только по ссылке из индекса.

## Профили

Все именные профили (`dev`, `infra`, `net`, `sec`, `ot`, `mgnt`) содержат
**явно** `compaction`, `references.context`/`references.docs` и абсолютный путь к
`context-protocol.md`. Не полагайтесь на неявный merge с default: профиль
запускается со своим `OPENCODE_CONFIG`, и глобальные ключи могут не примениться.

При добавлении профиля скопируйте эти три блока из существующего.

## Sync

Синхронизируются (`~/.config/opencode/opencode-synced.jsonc` → `extraConfigPaths`):

- `dcp.jsonc`, `cli.json`, `usage-monitor.json`
- `context/INDEX.md`, `context/decisions.md`, `context/current.template.md`
- `context/playbooks/`

**Не** синхронизируются: `context/current.md` (личная рабочая точка, меняется
каждый ход) и `context/archive/` (локальная история).

## Troubleshooting

**DCP не применился.** Проверьте, что плагин загружен (`/dcp` в сессии), что
`dcp.jsonc` валиден (`jq -e . dcp.jsonc` игнорируя JSONC-комментарии) и что
пороги меньше окна активной модели. После правки конфига нужен перезапуск
TUI/сервиса.

**Reference не найден.** Путь в `references` должен существовать на момент
старта; `~` раскрывается. Для default-профиля `docs` указывает в git-репо
`opencode-synced` — если репо не склонирован, reference молча пуст.

**Профиль потерял настройки.** Профильный конфиг не наследует глобальный:
проверьте наличие `compaction`/`references` в `~/.config/opencode-<profile>/opencode.json`
и в `repo/profiles/<profile>/opencode.jsonc`, затем `jq . <file>`.

**`instructions` не подхватился.** Путь относительный → замените на абсолютный.

**Контекст растёт несмотря на компакцию.** Проверьте размер always-loaded
файлов: `AGENTS.md` держим < 12 KB, детали — в `playbooks/`. Длинные выводы
инструментов уносите в файл и читайте через `grep`/`offset`.

## Ограничения

- `current.md` и `archive/` локальны: на другой машине их нужно переносить вручную.
- Ledger — обычные markdown-файлы без схемы: возможен drift (устаревшие записи,
  битые ссылки). Сверяйте `INDEX.md` при каждой вехе.
- DCP state не имеет TTL и может занимать десятки мегабайт.
- Compaction и DCP не сохраняют смысл: если решение не записано в
  `decisions.md`/`current.md`, после сжатия оно потеряно.
