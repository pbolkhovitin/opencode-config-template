# Design toolkit — всё для визуала: скиллы, плагины, MCP

Каталог для профиля `design`: графика, оформление, UI/UX, вёрстка, скриншот-приёмка.
Данные по звёздам GitHub и пакетам npm — на 11.11.2026. Здесь и то, что подключено,
и то, что сознательно оставлено «на полке», чтобы профиль можно было расширять.

- Профиль: `profiles/design/` → `~/.config/opencode-design/`
- Запуск: `ocp design`
- Канонический скилл-инструкция: `config/skills/design-toolkit/SKILL.md`

## Что подключено сейчас

| Компонент | Тип | Роль |
|---|---|---|
| `chrome-devtools` | MCP, local | скриншоты, DOM, контраст, performance, консоль |
| `playwright` (firefox) | MCP, local | сценарии с кликами, регрессия форм |
| `shadcn` | MCP, local | компоненты из реестров |
| `mermaid` | MCP, local | схемы и графики в документации |
| `duckduckgo` | MCP, local | референсы |
| `figma`, `magic`, `unsplash` | MCP, local | **выключены**, нужен ключ |
| `opencode-gpt-imagegen` | плагин | `gpt-image-2` через подписку ChatGPT |
| `design-toolkit`, `accessibility-a11y`, `kpi-dashboard-design`, `nextjs-react-typescript`, `webapp-testing` | скиллы | рабочий контур |

Почему Figma выключена: токена нет. Пока его нет, источник истины — токены и код
в проекте; макеты идут как референс «приёма», а не как спецификация.

## 1. Скиллы (SKILL.md)

Ставятся копированием каталога в `~/.config/opencode/skills/<id>/`, затем добавляются
в allowlist профиля (`permission.skill`) и в `config/skills/` репозитория.

| Репозиторий | ★ | Что даёт |
|---|---|---|
| `anthropics/skills` | 192.8k | эталонный набор: `canvas-design` (постеры/графика в PNG/PDF), `theme-factory` (темы, палитры, шрифтовые пары), `brand-guidelines`, `artifacts-builder`, `slack-gif-creator` |
| `nextlevelbuilder/ui-ux-pro-max-skill` | 148k | «дизайн-интеллект»: стили, палитры, типографика, правила под web/mobile; самый широкий охват UI/UX |
| `vercel-labs/agent-skills` | 33.9k | официальные фронтенд-практики Vercel (React/Next, композиция) |
| `superdesigndev/superdesign-skill` | 978 | арт-дирекшн, варианты лейаутов, борьба с «AI-slop». Сам продукт: `superdesigndev/superdesign` ★7.6k |
| `master5d/claude-design-skills` | 42 | UI/UX, интерфейс, типографика, motion |
| `hueyexe/frontend-agent-skills` | 24 | фронтенд-скиллы «чтобы выглядело хорошо» |
| `Ormus-Solutions/LibreUIUX-Claude-Code` | 125 | большой пак: 71 плагин, 93 агента, 74 скилла, a11y |
| `robonuggets/excalidraw-skill` | 87 | диаграммы в стиле Excalidraw, 10 визуальных техник |
| `arjun988/blender-skills` ★2.5k, `EL4CTEO/blender-skills` ★972 | — | 3D-пайплайн Blender |
| `PPT Design Skill` (awesome-opencode) | — | редактируемые .pptx, 40k+ стилей |
| `Krishna-Modi12/frontend-design-pro`, `dhruvjainin/pristine`, `Moddingflow/better-design` | 14–51 | «критика и полировка» UI, DESIGN.md, реестр правил |

Установка (пример):

```bash
git clone --depth 1 https://github.com/anthropics/skills /tmp/as
cp -r /tmp/as/canvas-design /tmp/as/theme-factory ~/.config/opencode/skills/
```

После установки — добавить ID в `permission.skill` профиля, иначе скилл будет
скрыт (`"*": "deny"`).

Полный список скиллов-источников: `awesome-skills`, `lingxling/awesome-skills-cn` ★331.

## 2. Плагины OpenCode

Ставятся в `plugins` профиля (v2), затем `npm install` в каталоге профиля (setup.sh
делает это автоматически).

| Пакет | Что делает | Заметки |
|---|---|---|
| `opencode-gpt-imagegen` | `gpt-image-2` через подписку ChatGPT, до 5 референсов, прозрачный фон | нужен Codex OAuth (`/connect` → OpenAI → Codex browser/device code legacy); «Sign in with ChatGPT» картинки не умеет |
| `@openpets/imagegen` | мульти-провайдер: FAL (Flux, SD), видео | ключи FAL |
| `oc-multi-imagegen` | Codex + OpenAI Images API + Nano Banana | альтернатива при наличии API-ключа |
| `opencode-dashscope-imagegen` | text-to-image через Alibaba DashScope | ключ DashScope |
| `@makcimbx/opencode-gpt-imagegen` | то же + MCP-режим для Claude Code | v0.3.1 |
| `typeui.sh` / `@independent-software/typeui` | генерирует дизайн-систему и style guide как skill-файлы | стыкуется с Tailwind/shadcn |
| `different-ai/opencode-browser` ★612 | автоматизация Chrome из OpenCode, доступ к профилю браузера | пересекается с Playwright MCP |
| `@max10240/opencode-plugin-unicorn` | сборник утилит | смотреть по составу |
| `GPT Imagegen` (awesome-opencode) | то же семейство GPT-Image | без стоимости API при подписке |
| `Opencode Visualizer` | 2D pixel-art офис агентов | развлечение/мониторинг |

Каталог: `awesome-opencode/awesome-opencode` ★10.9k (198 плагинов, темы, агенты).

## 3. MCP-серверы

### Дизайн → код

| Сервер | ★ | Тип | Заметки |
|---|---|---|---|
| Figma official (`figma/mcp-server-guide`) | 2.2k | remote/local | dev mode + запись на канвас, Code Connect, «design from live UI»; запись вне драфтов требует Full seat |
| `GLips/Figma-Context-MCP` | 16.2k | local (`figma-developer-mcp`) | layout+стили в компактном виде, работает по REST-ключу |
| `awdr74100/figwright` | 1.4k | local | двусторонний: код → канвас |
| `gethopp/figma-mcp-bridge` | 913 | plugin+MCP | обход лимитов API |
| `penpot/penpot-mcp` | 535 | remote/local | официальный. В Penpot 2.18 — сервис `penpotapp/mcp:2.18` в docker-compose, frontend проксирует `/mcp/stream` (Streamable HTTP) и `/mcp/ws`. Развёрнуто локально: `http://localhost:9001/mcp/stream?userToken={env:PENPOT_MCP_TOKEN}` |
| shadcn MCP (`shadcn@latest mcp`) | — | local | поиск/установка компонентов; `shadcn mcp init --client opencode` |
| `21st-dev/magic-mcp` | 6.5k | local | 10k+ React/Tailwind компонентов, генерация по описанию; новый setup: `npx @21st-dev/cli@latest init` |
| `mcpland/storybook-mcp`, `freema/mcp-design-system-extractor` | 46/73 | local | вытащить реальные компоненты и токены из Storybook |
| `southleft/story-ui` | 239 | — | генерация story для Storybook |

### Проверка интерфейса

| Сервер | ★ | Заметки |
|---|---|---|
| `ChromeDevTools/chrome-devtools-mcp` | 55k | screenshot, DOM, network, performance trace; `--isolated` не трогает профиль |
| `microsoft/playwright-mcp` | 39.5k | сценарии, доступность-снапшоты, codegen |
| `screenshot-*` / `agent-render` | 0–152 | рендер HTML/TSX/URL в картинку |

### Диаграммы и канвас

| Сервер | ★ | Заметки |
|---|---|---|
| `excalidraw/excalidraw-mcp` | 5.7k | MCP App + remote `https://mcp.excalidraw.com`; требует поддержки MCP Apps клиентом — проверять |
| `yctimlin/mcp_excalidraw` | 2.6k | stdio-тулкит + скилл, безопаснее для обычного клиента |
| `DayuanJiang/next-ai-draw-io` | 36.9k | draw.io через чат, отдаёт редактируемый файл |
| `simonkurtz-MSFT/drawio-mcp-server` | 82 | программная генерация draw.io |
| `hustcc/mcp-mermaid` | 649 | mermaid → картинка (подключён). Postinstall делает `playwright install --with-deps chromium` и падает без sudo (`npx` выходит с кодом 1) — поэтому в профиле `npm_config_ignore_scripts=true`, а Chromium ставится отдельно: `npx playwright@1.65 install chromium` |
| `MR901/mcp-plots`, `marzukia/charted` | — | графики/плоты |

### Изображения, иконки, 3D

| Сервер | ★ | Заметки |
|---|---|---|
| `ahujasid/mcp-for-blender` | 34k | управление Blender из LLM |
| `iconify-mcp` / `mcp-iconify` | 2 | 200k+ иконок Iconify |
| `glincker/thesvg` | 3k | 7.6k бренд-логотипов SVG (AWS/Azure/GCP) |
| `homarr-labs/dashboard-icons` | 9.1k | 3.4k иконок для дашбордов |
| `hellokaton/unsplash-mcp-server` | 239 | стоковые фото + атрибуция |
| `shinpr/mcp-image` | 190 | генерация/правка изображений, авто-оптимизация промпта |
| `mrafaeldie12/nano-banana-pro-mcp`, `trevoruptain/gemini-image-mcp` | 11–18 | Nano Banana Pro / Gemini |
| `mcpware/logoloom` | 56 | лого → SVG → бренд-кит |

### Прочее по теме

- `freema/mcp-design-system-extractor` — дизайн-система из Storybook.
- `lyse-labs/lyse` — drift-сканер токенов/компонентов/a11y.
- `penpot-mcp` (self-host) — бесплатная замена Figma для макетов. Локальный инстанс: `~/penpot`, UI `http://localhost:9001`, MCP `http://localhost:9001/mcp/stream`, mailpit `http://localhost:8025`.
- `superdesign` ★7.6k — внешний агент-дизайнер (не MCP).

## 4. Как расширять профиль

1. **Новый MCP.** Добавить в `mcp.servers` профиля **выключенным**
   (`"disabled": true`) с ключом из `{env:...}`, затем проверить:
   `OPENCODE_CONFIG=~/.config/opencode-design/opencode.json opencode mcp list`.
   Включённый сервер добавляет свои инструменты в каждый запрос — держите активным
   минимум.
2. **Новый скилл.** Копия в `config/skills/<id>/SKILL.md` + строка в
   `permission.skill` профиля. Тест `tests/test_profiles_structure.py` проверяет,
   что allowlist ссылается только на существующие скиллы.
3. **Новый плагин.** `plugins` профиля + `package.json` (setup.sh ставит пакеты),
   затем перезапуск сервиса: `opencode service restart`.
4. **Новый агент.** `agent.<id>` с `mode: primary|subagent` и файлом персоны в
   `profiles/design/prompts/personas/`.

Проверки репозитория:

```bash
python3 tests/validate_configs.py
bash tests/run.sh
```

## 5. Ограничения и подводные камни

- **Контекст.** Каждый MCP-сервер раздувает системный промпт. 4–5 активных —
  практический предел; остальные держите `disabled` и включайте под задачу или
  скрывайте через `/mcp`.
- **MCP Apps.** Excalidraw/draw.io-канвасы рассчитаны на клиентов с поддержкой
  MCP Apps (Claude, ChatGPT, VS Code). В OpenCode надёжнее stdio-варианты.
- **Figma Full seat.** Запись на канвас и «design from live UI» требуют remote-сервера
  и платного seat; REST-ключ даёт только чтение.
- **ChatGPT Images.** Генерация идёт через Codex OAuth; вариант «Sign in with ChatGPT»
  (token sharing) изображения не поддерживает — это ограничение OpenAI.
- **Лицензии.** Скиллы сторонних репозиториев имеют свои лицензии; при vendoring
  в `config/skills/` фиксируйте источник и лицензию.
- **Секреты.** Только `{env:...}` + `agent-vault`. В конфигах и коммитах — имена
  переменных, не значения.
- **MCP с postinstall.** Пакеты, чей `postinstall` требует root (`playwright
  install --with-deps`), ломают `npx` целиком. Лечится `npm_config_ignore_scripts=true`
  плюс ручной установкой браузеров.
