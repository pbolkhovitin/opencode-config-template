# macOS (Apple Silicon)

Конфигурация поддерживает macOS на Apple Silicon (M1–M4) и Intel. Основной
сценарий — arm64: Homebrew в `/opt/homebrew`, нативные arm64-бинарники, без
Rosetta.

## Что работает

- CLI `opencode` v2, профили `ocp`, алиасы `oc`, `oc-dev`, …
- MCP: `docker`, `postgres`, `ssh`, `filesystem`, `playwright`, `github`,
  `gitlab-*`, `proxmox` (через `uvx`), `ansible`.
- OpenCode Desktop для macOS (Apple Silicon): `.dmg` или
  `brew install --cask opencode-desktop`.
- Vault и обёртки `agent-vault`, `gitlab-mcp-vault`, `github-mcp-vault`.
- Скиллы, команды, агенты и контекст-леджер.

Не работает на macOS напрямую:

- `firejail`, `macchanger`, `systemd-ask-password`, `bind-utils`, `nmap-ncat` —
  Linux-only; для полного security toolchain используйте контейнер или VM
  (см. [security-toolchain.md](security-toolchain.md)).
- WSL-специфичные сценарии — только на Windows.

## Требования

| Компонент | Зачем | Установка |
|---|---|---|
| macOS 13+ | среда | — |
| Xcode Command Line Tools | git, python3, компиляторы | `xcode-select --install` |
| Homebrew | пакеты | <https://brew.sh> |
| git, curl | базовые | входят в CLT |
| `gh` | клонирование приватного репо | `brew install gh` |
| Node.js ≥ 18 | часть плагинов и `npx`-MCP | `brew install node` (опционально) |
| Python 3 | тесты, `uvx`-MCP | `brew install python` или CLT |
| `fzf` | меню `ocp` без аргументов | `brew install fzf` |

`setup.sh` не устанавливает Homebrew сам — только проверяет и подсказывает.

## Быстрый старт

```bash
# 1. базовые инструменты
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git gh jq fzf ripgrep

# 2. авторизация и клон
gh auth login
gh repo clone YOUR_ORG/opencode-config-template ~/opencode-config-template
cd ~/opencode-config-template

# 3. установка
bash setup.sh --dry-run
bash setup.sh
source ~/.zshrc

# 4. проверка
oc --version
ocp dev
```

Если репозиторий уже синхронизирован через opencode-synced:

```bash
opencode_sync pull
```

## Что делает setup.sh на macOS

- определяет `Darwin` и архитектуру (`arm64` / `x86_64`);
- предупреждает, если терминал запущен под Rosetta;
- добавляет `/opt/homebrew/bin` в `PATH`, если Homebrew не виден;
- проверяет Xcode CLT и Homebrew;
- ставит только кроссплатформенные пакеты (`jq`, `fzf`, `ripgrep`, `fd`,
  `nmap`, `masscan`, `socat`, `mtr`, `iperf3`, `go`, `ruby`);
- ставит OpenTofu через `brew install opentofu`;
- скачивает `kubectl` для `darwin/arm64` (или `darwin/amd64`);
- раскладывает конфиги, профили, скиллы и алиасы;
- настраивает `SUDO_ASKPASS` (на macOS работает через `/dev/tty`);
- подсказывает про Docker Desktop/Colima, Desktop и SSH-keychain.

Linux-only пакеты (`firejail`, `bind-utils`, `nmap-ncat`, `aircrack-ng` и т.п.)
на macOS не устанавливаются.

## Пути

| Что | Где |
|---|---|
| Глобальный конфиг | `~/.config/opencode/opencode.json` |
| Профили | `~/.config/opencode-<profile>/opencode.json` |
| Репозиторий конфига | `~/.local/share/opencode/opencode-synced/repo` |
| Локальные скрипты | `~/.local/bin` |
| Homebrew (arm64) | `/opt/homebrew` |
| Системный конфиг OpenCode | `/Library/Application Support/opencode` |

Каталоги filesystem MCP задаются как `{env:HOME}` — на macOS это
`/Users/<user>`, на Linux — `/home/<user>`. Жёстких путей в профилях нет.

## Профили

```bash
ocp            # fzf-меню
ocp dev        # разработка
ocp infra      # инфраструктура
ocp design     # UI/UX (нужен Vault-ключ Penpot)
```

Алиасы `oc-dev`, `oc-infra`, … добавляются в `~/.zshrc`. Профили запускаются
через `--standalone`, поэтому не конфликтуют с фоновым сервисом.

Для проекта с несколькими ролями:

```bash
cd ~/projects/my-service
oc-project-init.py --profiles dev,infra
ocp dev
```

## OpenCode Desktop

Desktop для macOS — нативное приложение, сервер запускается локально.

```bash
brew install --cask opencode-desktop
# или скачать:
# https://opencode.ai/update/api/latest/desktop/opencode/opencode-desktop-mac-arm64.dmg
```

Профили в Desktop: приложение не читает shell-rc и не видит `OPENCODE_CONFIG`
из `ocp`. Используйте проектный конфиг:

```bash
cd ~/projects/my-service
oc-project-init.py --profiles dev,infra
```

и откройте проект в Desktop. Либо замените глобальный
`~/.config/opencode/opencode.json` на нужный профиль (с бэкапом), но это
затронет и CLI, и следующий `opencode_sync pull`.

## Docker и MCP

Варианты:

- **Docker Desktop** — `brew install --cask docker`, запустить один раз;
- **Colima** — `brew install colima docker && colima start`.

Проверка:

```bash
docker context ls
docker ps
```

MCP `docker` использует стандартный сокет; при Colima он создаётся
автоматически. Если `docker ps` работает в терминале, MCP тоже увидит Docker.

## Секреты

```bash
brew install hashicorp/tap/vault
agent-vault status central
agent-vault login central
```

Значения не печатать в чат и не писать в файлы. Проверка наличия секрета:

```bash
agent-vault use 'db password' --project YOUR_PROJECT -- 'test -n "$VAULT_PASSWORD" && echo ok'
```

## Security toolchain на macOS

Нативно доступны `nmap`, `masscan`, `socat`, `tcpdump`, `openssl`, `radare2`,
`binwalk`, `hashcat`, `john`, `hydra` (через brew). Ограничения:

- `gdb` на arm64 требует подписи и entitlements — используйте `lldb`;
- `tcpdump`/`masscan` требуют `sudo` (raw sockets);
- `aircrack-ng` работает ограниченно и зависит от драйвера;
- `firejail`, `macchanger`, `bind-utils` недоступны.

Полный набор — в Linux-контейнере (`docker run --rm -it kalilinux/kali-rolling`)
или в VM. Схема выбора — [security-toolchain.md](security-toolchain.md).

## Apple Silicon: частые нюансы

- Проверить, не под Rosetta ли терминал:
  ```bash
  sysctl -in sysctl.proc_translated   # 1 = Rosetta, 0 = native
  ```
- Homebrew arm64: `/opt/homebrew/bin/brew`; Intel-версия в `/usr/local` может
  конфликтовать — держите одну.
- Node и Python ставьте arm64-сборками (`brew install node python`).
- `arch -arm64 <command>` помогает запустить нативную версию.
- Gatekeeper: если приложение не открывается, `xattr -d com.apple.quarantine <app>`.

## Проверка установки

```bash
oc --version
opencode debug config | head -20
opencode mcp list
ocp dev

python3 tests/validate_configs.py config profiles
python3 -m pytest tests -q
```

Ожидаемо: профиль `dev` видит свои MCP, `default` — без MCP, тесты зелёные.

## Диагностика

| Симптом | Причина | Решение |
|---|---|---|
| `command not found: opencode` | не в `PATH` | `export PATH="$HOME/.opencode/bin:$PATH"`, перезайти в shell |
| `brew: command not found` | Homebrew не в PATH | `eval "$(/opt/homebrew/bin/brew shellenv)"` |
| `pip3 install` → `externally-managed-environment` | PEP 668 | `uv tool install <pkg>` или `pipx install <pkg>` |
| `fzf не найден` у `ocp` | нет fzf | `brew install fzf` |
| MCP `docker` не стартует | Docker не запущен | открыть Docker Desktop / `colima start` |
| `gdb` падает | arm64 и подпись | использовать `lldb` |
| Desktop не видит профиль | нет `OPENCODE_CONFIG` | проектный `opencode.jsonc` |
| Медленно / странные ошибки | Rosetta | переустановить arm64-версии |

## Ограничения

- Нет WSL-специфичных функций и `setup.ps1`.
- Часть скиллов и скриптов ориентирована на Linux-утилиты; при запуске
  проверяйте наличие команды (`command -v`).
- `agent-vault` и Vault-обёртки требуют установленного Vault CLI и доступа к
  хранилищу.
- Проектный конфиг, сгенерированный `oc-project-init.py`, содержит абсолютные
  пути к промптам — при переносе проекта на другую машину перегенерируйте его
  или используйте `--no-agents`.

## Ссылки

- [usage-scenarios.md](usage-scenarios.md) — сценарии работы
- [profiles-agents-matrix.md](profiles-agents-matrix.md) — профили и агенты
- [wsl-desktop.md](wsl-desktop.md) — Windows + WSL + Desktop
- [security-toolchain.md](security-toolchain.md) — security toolchain
- [OpenCode Desktop](https://opencode.ai/desktop)
- [OpenCode config](https://opencode.ai/docs/config/)
