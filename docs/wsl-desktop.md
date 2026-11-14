# WSL и OpenCode Desktop

Как установить конфигурацию в WSL и как пользоваться приложением OpenCode
Desktop на Windows, подключённым к WSL. Проверено на OpenCode **v2.3.0**
(ноябрь 2026).

Есть два равноправных способа работы:

| Способ | Где работает агент | Когда выбирать |
|---|---|---|
| CLI в WSL (`oc`, `ocp`) | WSL | привычный терминал, скрипты, профили, полный контроль окружения |
| Desktop на Windows + WSL-сервер | WSL (сервер), Windows (UI) | нужен GUI: вкладки сессий, диффы, встроенный браузер |

Оба способа используют одну и ту же установку OpenCode внутри WSL, один и тот
же конфиг и одну базу сессий. Различается только клиент.

---

## 1. Требования

- Windows 10 2004+ или Windows 11;
- **WSL 2** (WSL 1 не поддерживается Desktop-приложением — в списке дистрибутивов
  он помечен `Unsupported · Use WSL 2`);
- дистрибутив Linux с `bash` и `curl`;
- виртуализация включена в BIOS/UEFI;
- для Docker MCP — Docker Desktop с включённой интеграцией WSL.

Проверка в PowerShell:

```powershell
wsl --status
wsl -l -v          # STATE=Running, VERSION=2
```

Если дистрибутив на WSL 1:

```powershell
wsl --set-version Ubuntu 2
```

---

## 2. Установка: два порядка действий

### 2.1. Сначала Desktop, потом конфигурация (рекомендуется для GUI)

1. Установите **OpenCode Desktop** для Windows:
   [opencode.ai/desktop](https://opencode.ai/desktop).
2. Откройте **Settings → Servers**.
3. **Add server → Add WSL server**.
4. Выберите дистрибутив:
   - если WSL не установлен — кнопка **Install WSL** (потребуется перезагрузка
     Windows);
   - если нужного дистрибутива нет — **Need another distro?** и установка из
     каталога WSL;
   - если в дистрибутиве нет OpenCode — **Install OpenCode**.
5. В WSL установите конфигурацию:

   ```bash
   gh repo clone YOUR_ORG/my-opencode-config
   cd my-opencode-config
   bash setup.sh
   source ~/.zshrc    # или ~/.bashrc
   ```

6. Вернитесь в Desktop и перезапустите сервер: **Servers → More options →
   Retry start**. Конфиг и плагины читаются при старте сервера.

### 2.2. Сначала CLI, потом Desktop

```bash
gh repo clone YOUR_ORG/my-opencode-config
cd my-opencode-config
bash setup.sh
opencode --version      # должно быть 2.x
```

Затем в Desktop: **Add server → Add WSL server** → выбрать дистрибутив. Если
OpenCode уже стоит, статус будет `Ready`; иначе нажмите **Install OpenCode**.

> `setup.sh` ставит OpenCode v2 через `https://opencode.ai/v2/install` и
> определяет WSL автоматически. Node.js для самого OpenCode не нужен; он
> требуется только части плагинов и инструментов.

---

## 3. Что именно делает Desktop с WSL

При добавлении WSL-сервера приложение:

- запускает внутри выбранного дистрибутива `opencode serve`;
- стартует его из домашнего каталога (`$HOME`), а не из каталога проекта;
- выделяет случайный свободный порт и слушает `127.0.0.1`;
- генерирует случайный пароль на каждый запуск;
- выставляет `OPENCODE_CLIENT=desktop` и отключает файловый watcher;
- удаляет из `PATH` пути `/mnt/*` (Windows-пути внутри WSL).

Следствия, важные для конфигурации:

1. **Профили `ocp` не применяются.** Сервер запускается неинтерактивным
   `bash` и не читает `~/.zshrc` / `~/.bashrc`, поэтому `OPENCODE_CONFIG` из
   алиасов не выставляется. Desktop всегда использует глобальный
   `~/.config/opencode/opencode.json` (default-профиль) плюс проектный
   `opencode.jsonc`.
2. **Переменные окружения из shell-rc тоже не применяются.** Секреты и
   настройки, которые вы экспортировали в `.zshrc`, в Desktop-сессии не видны.
3. **Проектный конфиг работает.** Для проектов с несколькими ролями
   сгенерируйте `opencode.jsonc` внутри WSL (см. раздел 5).
4. **Файловый watcher отключён.** Полагайтесь на явное чтение файлов агентом;
   для больших проектов держите код на ext4, а не на `/mnt/c`.

---

## 4. Проверка установки

В WSL:

```bash
opencode --version                 # 2.x
opencode service status            # адрес фонового сервера, порт 49374
opencode debug config | jq -r '.model'
opencode mcp list
python3 tests/validate_configs.py config profiles
python3 -m pytest tests -q
```

В Desktop:

- **Settings → Servers**: у дистрибутива статус `Ready`, кнопка `Retry start`
  не нужна;
- откройте проект и проверьте модель, список MCP и агентов;
- **Settings → Projects**: переключатель сервера показывает имя дистрибутива.

Порты по умолчанию:

| Платформа | Порт фонового сервера |
|---|---|
| macOS, Linux, WSL | 49374 |
| Windows | 28894 |

Desktop для WSL-сервера порт не фиксирует — он выбирается динамически.

---

## 5. Профили и несколько ролей в Desktop

Поскольку `ocp` в Desktop не работает, есть три рабочих схемы.

### 5.1. Default + проектный конфиг (рекомендуется)

Оставьте глобальный конфиг default-профилем, а роли добавляйте на уровне
проекта:

```bash
cd ~/projects/my-service
oc-project-init.py --profiles dev,infra
```

Скрипт объединит MCP и агентов `dev` и `infra` в `<project>/opencode.jsonc`.
Desktop подхватит файл при открытии проекта. После правки — перезапуск сервера
или `opencode reload` в CLI.

### 5.2. Заменить глобальный конфиг профилем

Если весь Desktop должен работать, например, в `dev`:

```bash
cp ~/.config/opencode-dev/opencode.json ~/.config/opencode/opencode.json
```

Минус: CLI-профиль `oc` тоже станет `dev`. Держите резервную копию исходного
`~/.config/opencode/opencode.json`.

### 5.3. CLI для задач, которым нужен профиль

Desktop и терминал можно использовать параллельно. Задачи, которым нужен
конкретный профиль или переменные окружения, выполняйте в WSL через `ocp`:

```bash
ocp dev
ocp infra -s <session-id>
```

Desktop при этом остаётся на default + проектный конфиг. Это самый простой
способ совместить GUI и полный набор профилей.

---

## 6. Секреты и Vault

Desktop-сервер не читает `.zshrc`, поэтому проверяйте доступность секретов в
том же режиме, в котором работает Desktop:

```bash
wsl.exe -d Ubuntu -- bash -c 'agent-vault status central'
```

Если команда не работает без логин-шелла:

- держите `VAULT_ADDR` и способ аутентификации в файле, который читает сам
  `agent-vault`, а не в `.zshrc`;
- либо выполняйте Vault-зависимые операции через CLI (`ocp ...`), где
  окружение из shell-rc доступно;
- либо работайте с Vault-зависимыми MCP через CLI-профиль.

Никогда не записывайте значения секретов в `opencode.jsonc`, `AGENTS.md` или
проектный репозиторий.

---

## 7. Docker, SSH и Git в WSL

**Docker.** Включите Docker Desktop → Settings → Resources → WSL Integration →
нужный дистрибутив. Проверка:

```bash
docker ps
```

**SSH.** Агент Windows и агент WSL — разные. Для GitHub/GitLab из WSL:

```bash
ssh-add -l
ssh -T git@github.com
gh auth status
```

`setup.sh` добавляет автозапуск `ssh-agent` в shell-rc, но Desktop его не
читает; для Desktop-сессий ключ должен быть доступен без интерактивного
шелла (например, через `ssh-agent` systemd-юнита или `~/.ssh/config`).

**Git.** `setup.sh` выставляет `core.autocrlf=input`. Держите репозитории в
`~/projects` (ext4), а не в `/mnt/c/...`: иначе будут проблемы с правами,
производительностью и переводами строк.

---

## 8. Диагностика

| Симптом | Причина | Решение |
|---|---|---|
| `WSL not installed` | компонент WSL выключен | **Install WSL**, перезагрузка Windows |
| `WSL unavailable` | виртуализация или компонент WSL | `wsl --status`, включить Virtual Machine Platform |
| `Unsupported · Use WSL 2` | дистрибутив на WSL 1 | `wsl --set-version <distro> 2` |
| `Missing bash, curl` | минимальный образ | `sudo apt install bash curl` внутри дистрибутива |
| `OpenCode not installed` | CLI нет в дистрибутиве | **Install OpenCode** в диалоге |
| `Can't reach <distro>` | сервер не стартовал | **More options → Retry start**, затем логи |
| `WSL server exited after startup` | падение `opencode serve` | `wsl -d <distro> -- bash -c 'opencode --version'`, проверить порт и конфиг |
| Профиль не применился | Desktop не читает shell-rc | использовать проектный `opencode.jsonc` (раздел 5.1) |
| Vault MCP не работает | нет переменных окружения | проверить `bash -c`, раздел 6 |
| Медленно, ломаются права | проект на `/mnt/c` | перенести в `~/projects` |

Логи Desktop и сервера:

```text
~/.local/share/opencode/log/opencode.log   # внутри WSL
```

В Desktop: command palette → **Capture heap snapshots** (диагностика памяти),
**Settings → Servers** (состояние подключений).

---

## 9. Ограничения

- Desktop не переключает профили `ocp`; профиль задаётся глобальным конфигом
  или проектом.
- Desktop-сервер и CLI используют одну базу сессий в WSL. Не запускайте две
  долгие сессии в одном проекте без необходимости.
- WSL 1 не поддерживается.
- Пароль WSL-сервера генерируется приложением; вручную им управлять нельзя.
- Обновление OpenCode в дистрибутиве выполняет Desktop (**Update OpenCode**)
  или `setup.sh`; версии клиента и сервера должны совпадать.

---

## 10. Ссылки

- [OpenCode Desktop](https://opencode.ai/desktop)
- [Web и подключение клиентов](https://opencode.ai/docs/cli/web/)
- [Troubleshooting](https://opencode.ai/docs/troubleshooting/)
- [Установка OpenCode v2](https://opencode.ai/docs/)
- [Профили и матрица агентов](profiles-agents-matrix.md)
- [Проект на нескольких профилях](multi-profile-projects.md)
- [Сценарии работы](usage-scenarios.md)
