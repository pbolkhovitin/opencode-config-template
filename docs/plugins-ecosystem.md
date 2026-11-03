# Плагины экосистемы OpenCode

Справочник по плагинам OpenCode **V2**: как они устроены, как устанавливаются и
что доступно в экосистеме. Дополняет раздел «Плагины» в
[FEATURES.md](FEATURES.md) и [USAGE.md](USAGE.md).

> Плагин — это расширение самого OpenCode (хуки, трансформы, инструменты,
> события). Он отличается от **MCP-сервера** (внешний процесс с инструментами)
> и от **скилла** (инструкции/воркфлоу для модели).

---

## API V2: чем плагин V2 отличается от V1

В V2 плагин обязан экспортировать default-определение:

```ts
import { Plugin } from "@opencode/plugin"

export default Plugin.define({
  id: "my-plugin",
  setup(ctx) {
    // регистрация хуков, инструментов, событий
  },
})
```

**V1-форма больше не грузится:**

```ts
// ❌ V1: вызывается как функция, возвращает объект хуков
export const MyPlugin = async ({ $ }) => ({
  "tool.execute.before": async (input, output) => { /* ... */ },
})
```

При загрузке V1-плагина в V2 в логе появляется:

```
PluginModule.LoadError: Plugin must export a default definition
with an id and an effect or setup function.
```

Симптомы: `opencode plugin check` → `check failed`, в `opencode plugin list`
ID/version = `-`. Проверяйте плагины на V2-совместимость перед установкой.

---

## Установка и управление (V2)

```bash
opencode plugin add <npm-пакет|github:owner/repo|/путь>
opencode plugin list          # список + версии
opencode plugin check         # проверка совместимости
opencode plugin update        # обновление
opencode plugin remove <name> # удаление
```

Эквивалентно можно править массив `plugins` в `opencode.json(c)`:

```jsonc
{
  "plugins": [
    "opencode-synced",
    "@tarquinen/opencode-dcp",
    "opencode-supermemory/server",   // суффикс — subpath-энтрипоинт пакета
    "opencode-gemini-auth/server",
    "github:acme/opencode-plugin",   // установка из Git
    "file:///abs/path/plugin.js",    // локальный путь
    { "package": "some-plugin", "options": { /* ... */ } }
  ]
}
```

- Поддерживаются npm-пакеты, версии/теги, scoped-имена, локальные пути,
  `file://` и объект с `options`.
- Файлы из `.opencode/plugins/` подхватываются автоматически.
- CLI-only плагины (расширяющие TUI) конфигурируются отдельно в `cli.json`.
- Плагины, зависящие от нативных модулей, ставятся через `setup.sh` /
  `opencode plugin`, бинарные зависимости платформозависимы.

### Встроенные (builtin) плагины

Ядро OpenCode включает ~70 builtin-плагинов, которые не нужно ставить вручную
(список: `opencode plugin list --builtin`):

- `opencode.config.*` — policy, skill, provider, mcp, reference, shell, snapshot,
  agent, command, compaction, compatibility, formatter, image, instruction,
  location-watcher, tool-output, websearch, worktree
- `opencode.provider.*` — openai, anthropic, ollama, lmstudio, openrouter, azure,
  amazon.bedrock, google.vertex, github.copilot, gitlab, xai, perplexity,
  cerebras, cohere, cloudflare.*, digitalocean, nvidia, poe, venice, vercel,
  vllm, kilo, modal, sap.ai.core, snowflake.cortex, zenmux, gateway и др.
- `opencode.tool.*` — edit, glob, grep, patch, question, read, shell, skill,
  subagent, webfetch, websearch, write, input.repair
- `opencode.prompt.*` — anthropic, arcee, identity, kimi, meta, openai, verbosity
- `opencode.websearch.*` — exa, firecrawl, parallel, tavily, tinyfish
- прочие — `opencode.agent`, `opencode.browser`, `opencode.command`,
  `opencode.compaction.native`, `opencode.plan`, `opencode.vcs.git`, `opencode.vcs.hg`,
  `opencode.warming`, `opencode.wellknown`, `opencode.models.dev`

> `opencode.config.policy` и `opencode.provider.opencode` игнорируют отключение —
> это enforcement, их нельзя выключить из репозитория.

---

## Установлено в этом конфиге

| Плагин | Пакет | Назначение | Профили |
|--------|-------|------------|---------|
| opencode-synced | `opencode-synced` | Авто-синхронизация конфига с GitHub | default |
| Dynamic Context Pruning | `@tarquinen/opencode-dcp` | Авто-обрезка устаревшего контекста (экономия токенов) | все |
| Persistent memory | `opencode-supermemory` (`/server`) | Память между сессиями | все |
| Gemini OAuth | `opencode-gemini-auth` (`/server`) | OAuth для Google/Gemini | default, dev, infra, net, mgnt |
| shell-strategy | `opencode-shell-strategy` | Предотвращение зависаний от TTY-команд (инструкция) | все |

> `opencode-pty` удалён: в OpenCode 2.x он не загружается (subpath `/v2`
> трактуется как отдельный пакет, корневой entrypoint — v1). См. `config-migration.md`.

---

## Каталог экосистемы (npm: `opencode-plugin`)

Собран поиском по npm (`npm search opencode-plugin`). Часть пакетов может быть
устаревшей или не поддерживать V2 — проверяйте через `opencode plugin check`.

### Наблюдаемость / телеметрия
| Пакет | Назначение |
|-------|------------|
| `@langfuse/opencode-observability-plugin` | Трейсинг в Langfuse |
| `@langchain/langsmith-opencode` | Трейсинг в LangSmith |
| `@2digits/opencode-plugin` | PostHog-аналитика |
| `@softprobe/opencode-plugin` | Наблюдаемость |
| `opencode-otel` | OTLP-логи/метрики |
| `@scrylog/opencode-plugin` | Логирование |

### Память / контекст
| Пакет | Назначение |
|-------|------------|
| `opencode-supermemory` | Persistent memory (используется) |
| `opencode-mem` | Векторная память (Turso/libSQL) |
| `@cortexkit/opencode-magic-context` | Управление контекстом |
| `opencode-rag-plugin` | Локальный RAG |
| `@mastra/opencode` | Интеграция с Mastra |
| `@tarquinen/opencode-dcp` | Dynamic Context Pruning (используется) |
| `openrtk` | сжатие вывода команд (V1-only, см. кейс ниже) |

### Провайдеры / аутентификация
| Пакет | Назначение |
|-------|------------|
| `opencode-claude-auth` | OAuth для Claude |
| `opencode-with-claude` | Claude Max / Meridian |
| `opencode-google-antigravity-auth` | Google Antigravity OAuth |
| `@servoy/opencode-kiro-auth` | AWS Kiro auth |
| `opencode-models-discovery` | Автодискавери моделей |
| `@smart-coders-hq/opencode-model-fallback` | Fallback моделей |
| `opencode-gemini-auth` | OAuth Google/Gemini (используется) |
| `opencode-plugin-keyring` | Хранение ключей |

### Сессии / автоматизация
| Пакет | Назначение |
|-------|------------|
| `opencode-pty` | Интерактивный PTY (не используется, V1-only) |
| `opencode-telegram`, `opencode-telegram-session-control` | Управление из Telegram |
| `opencode-scheduler` | Планировщик задач |
| `opencode-auto-resume` | Автовозобновление сессий |
| `opencode-command-hooks` | Хуки на команды |
| `opencode-atuin-history` | История в atuin |
| `opencode-conductor` | Оркестрация |

### Коллаборация / инструменты
| Пакет | Назначение |
|-------|------------|
| `@sven1103/opencode-worktree-workflow` | Worktree-workflow |
| `opencode-plugin-openspec` | OpenSpec-интеграция |
| `opencode-subagent-statusline` | Статус субагентов |
| `opencode-browser` | Browser MCP |
| `deveco-harness` | HarmonyOS toolchain |
| `opencode-plugin-updates` | Проверка обновлений |
| `opencode-lazy-loader` | Ленивая загрузка |
| `opencode-claude-hooks` | Claude-хуки |

### Устаревшее (v1-only, в V2 не работают)
opencode-swarm, opencode-vibeguard, opencode-websearch-cited,
`@lyculs/opencode-firecrawl`, opencode-notify (retired), opencode-worktree,
opencode-antigravity-auth, opencode-pty (старая форма → `/v2`),
opencode-morph-plugin, `@plannotator/opencode`, opencode-goal-plugin.

> Уведомления в V2 — нативные: `cli.json` → `attention.notifications` /
> `attention.sound`. Встроенный websearch — `ctx.websearch`.

---

## Кейс: RTK (Rust Token Killer)

**RTK** (`rtk-ai/rtk`, сайт `rtk-ai.app`) — CLI-прокси, сжимающий вывод команд на
60–90%, чтобы экономить контекст модели. Плагин-обёртка `openrtk` в npm **сломан**:
он реализует V1-хук `"tool.execute.before"` и в V2 не загружается. Сгенерированный
`rtk init --global --opencode` файл `plugins/rtk.ts` тоже использует V1 API.

**Чтобы подключить RTK в V2** нужен порт под `Plugin.define({ id, setup })`.
Сам бинарник ставится отдельно: `brew install rtk`, `winget install rtk-ai.rtk`
или установочный скрипт с GitHub.

> Внимание: крейт `rtk` на crates.io — другой проект («Rust Type Kit»); не
> используйте `cargo install rtk`.

---

## См. также

- [FEATURES.md](FEATURES.md) — плагины по профилям
- [USAGE.md](USAGE.md) — установка, конфигурация, sync
- [skill-management.md](skill-management.md) — управление скиллами
- Документация V2: <https://opencode.ai/v2/docs/build/plugins>
