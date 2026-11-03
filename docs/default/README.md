# Default Profile — без MCP

`default` (алиас `oc`) — базовый профиль для общих задач: текст, планирование,
быстрые правки, работа со скиллами. MCP-серверы и кастомные агенты сюда
**намеренно не подключены** — они живут в именных профилях.

## Что доступно

| Компонент | Состав |
|---|---|
| MCP | — |
| Плагины | `opencode-synced`, `@tarquinen/opencode-dcp`, `opencode-supermemory`, `opencode-handoff`, `opencode-usage-monitor`, `opencode-gemini-auth` |
| Инструкции | `AGENTS.md`, `instructions/russian.md`, `workflow.md`, `rules.md` |
| Скиллы | единый каталог `~/.config/opencode/skills/` (`skills.paths`) |
| Permissions | `bash=ask`, `edit=ask` |

Встроенные инструменты OpenCode (read/write/edit/bash, поиск по файлам) доступны
всегда; веб-поиск — встроенный `websearch`, без отдельного MCP.

## Сценарии

### Планирование и текст
- PRD, спеки, письма, документация — без MCP.
- Сложный план: `/grill-me <path>` или скилл `writing-plans`.
- Декомпозиция: `dispatching-parallel-agents`.

### Быстрые правки в коде
- Одиночные файлы и небольшие изменения — встроенные read/edit/bash.
- Ревью — скилл `code-review-and-quality`.
- Проверка перед завершением — `verification-before-completion`.

### Секреты
- Только `{env:...}` или Vault через скилл `agent-vault`.
- Пароль не печатать в чат и не писать в файлы проекта.

## Когда нужен именной профиль

Переключение — `ocp <profile>` (fzf-меню — просто `ocp`):

| Задача | Профиль |
|---|---|
| БД, Docker, браузер, GitHub, разработка | `dev` |
| Proxmox, Ansible, OpenTofu, K8s, SRE/MLOps/GitOps | `infra` |
| Сети, MikroTik/pfSense/OpenWrt, firewall, VPN, pcap | `net` |
| CTF, pentest, AppSec | `sec` |
| АСУ ТП / ICS | `ot` |
| PRD, инциденты, аналитика | `mgnt` |

Агенты и MCP по профилям — [../profiles-agents-matrix.md](../profiles-agents-matrix.md).
