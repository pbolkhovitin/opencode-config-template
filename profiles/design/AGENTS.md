# Design Profile — UI/UX, вёрстка, визуальный контур

Профиль для задач «сайт + оформление»: арт-дирекшн, дизайн-система, вёрстка,
скриншот-приёмка, иллюстрации. Запуск: `ocp design` (алиас `oc-design`).

## Кастомные агенты (Tab)

- **@ui-designer** (primary) — арт-дирекшн → токены → каркас → реализация →
  приёмка скриншотами. Пишет код и запускает dev-сервер.
- **@visual-qa** (subagent) — read-only визуальная приёмка: адаптивность,
  контраст, состояния, консольные ошибки. Вызывать явно: «делегируй `visual-qa`».

## MCP

Набор закрывает визуальный контур: скриншоты, DOM и контраст (chrome-devtools,
`--isolated`), браузерные сценарии (playwright), компоненты shadcn, референсы
(duckduckgo), схемы (mermaid), макеты (penpot) и генерация ассетов (magic,
unsplash). Figma подключена, но выключена без токена — как и magic/unsplash.

Penpot: собственная инсталляция 2.18, remote MCP `http://localhost:9001/mcp/stream`
(stdio-прокси нет). Работа с макетами — через плагин в открытом файле, сначала
`high_level_overview`. Ключ идёт query-параметром `?userToken={env:PENPOT_MCP_TOKEN}`
(Vault: `secret/agent/YOUR_PROJECT/penpot-mcp-key`; `ocp design` подставляет сам). В браузере
нужен **тот же** ключ, иначе `No Penpot instance connected`.

Mermaid: нужен Chromium 1254 из `~/.cache/ms-playwright`
(`npx playwright@1.65 install chromium`, **без** `--with-deps`);
`npm_config_ignore_scripts=true` отключает падающий postinstall.

Точный состав и статус серверов — в [матрице](../../docs/profiles-agents-matrix.md).

Наборы MCP на сессию скрываются командой `/mcp` (плагин `opencode-mcp-sets`).

## Плагины

- **opencode-gpt-imagegen** — `gpt-image-2` через подписку ChatGPT, референсные
  изображения, прозрачный фон. Требует входа **Codex OAuth**: `/connect` → OpenAI →
  `Codex browser (legacy)` или `Codex device code (legacy)`. Опция
  «Sign in with ChatGPT» генерацию картинок не поддерживает.
- **opencode-supermemory** — память между сессиями.
- **@tarquinen/opencode-dcp** — обрезка устаревшего контекста.
- **opencode-gemini-auth** — OAuth для Google/Gemini.
- **opencode-handoff**, **opencode-usage-monitor** — передача сессии, учёт токенов.

Полный каталог плагинов/скиллов/MCP под визуальные задачи (включая то, что не
подключено) — `docs/design-toolkit.md`.

## Скиллы

- `design-toolkit` — как собрать визуальный контур: порядок шагов, инструменты,
  проверки. Начинать с него.
- `accessibility-a11y` — WCAG, клавиатура, aria, контраст.
- `kpi-dashboard-design` — дашборды и плотные интерфейсы.
- `nextjs-react-typescript` — App Router, RSC, Tailwind, shadcn/ui.
- `webapp-testing` — Playwright-проверки интерфейса.
- `web-scraping` — снять контент/структуру сайта-референса.
- Плюс общие: `brainstorming`, `writing-plans`, `verification-before-completion`,
  `systematic-debugging`, `code-review-and-quality`, `caveman*`.

## Правила профиля

1. Сначала токены и сетка, потом компоненты. «Магические» hex-цвета и пиксели —
   только через переменные.
2. Каждый экран проверяется скриншотом на 390/768/1440 до сдачи. Без скриншота
   задача не считается выполненной.
3. Доступность не опция: контраст, focus-visible, клавиатура, `prefers-reduced-motion`.
4. Figma-токена нет — источник истины это код и дизайн-система в нём, а не макет.
   Новые MCP с ключами добавляются выключенными (`disabled: true`) + `{env:...}`.
5. Секреты — только `agent-vault`; в конфиг и коммиты не попадают.
