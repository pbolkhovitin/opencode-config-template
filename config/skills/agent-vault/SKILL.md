---
name: agent-vault
description: Работа с паролями, токенами и секретами через HashiCorp Vault (KV v2) — чтение учётных данных, генерация и сохранение новых, область secret/agent/<project>/<name>. Используй при любом упоминании Vault/HashiCorp Vault/agent-vault и словах «пароль», «секрет», «креды», «учётка», «токен», «ключ API», «возьми доступ из хранилища», «положи в Vault», «сгенерируй пароль», а также когда задаче нужен пароль к серверу/БД/сервису или пароль появился в чате. Вызывай и без упоминания Vault — секрет берётся отсюда. Bitwarden — человеко-ориентированное хранилище (браузер/клиент), агент с ним не работает.
---

# Vault (HashiCorp) как хранилище секретов агента

## Принцип

Секреты **не проходят через чат и не печатаются в вывод**. Обёртка `agent-vault` передаёт
значение только через **env внутри дочернего процесса** (`agent-vault use ... -- '<script>'`).
В контексте агента остаются только имена секретов, пути и длины.

Учётка агента — отдельный токен/роль с урезанными правами:
- **запись** — только `secret/agent/*` (проектные области агента);
- **чтение** — дополнительно только те пути, которые реально нужны (выдаются вручную).
Токены агента не знает и не должен знать — `vault login` выполняет пользователь в своём терминале.

## Железные правила

1. Никогда не выводить значение пароля/токена: ни `echo`, ни возврат из функции, ни
   `vault kv get -field=password`, ни `jq '.data.data.password'`. Значение доступно только
   через `use` (env в дочернем процессе) — там и использовать.
2. Никогда не просить пользователя прислать пароль в чат. Просить — **имя секрета** в Vault,
   либо чтобы пользователь сам положил секрет в своём терминале:
   `printf '%s' "$v" | agent-vault add '<имя>' --project <p>` или `agent-vault add ... --prompt`.
3. Если пароль всё-таки появился в чате — сразу положить в Vault
   (`printf '%s' "$v" | agent-vault add '<имя>' ...`), дальше ссылаться только по имени и
   **напомнить сменить**: транскрипт лежит на диске.
4. Не передавать секрет аргументом командной строки внешним процессам — виден в `ps`,
   history. Через stdin (`printf '%s' "$v" | ...`), env внутри `use`-скрипта или файл с chmod 600.
5. Секреты не пишутся в файлы проекта, AGENTS.md, память агента, коммиты. В файлах — только имя.
6. Для нового сервиса/учётки пароль **генерируется** (`agent-vault new`), не придумывается.
7. Не выводить даже частичную информацию, сужающую перебор: не «длина 24», не первые символы.

## Подключение

- Обёртка: `~/.local/bin/agent-vault` (в PATH). Требует `vault` CLI (`~/.local/bin/vault`),
  `jq`, `openssl`.
- Конфиг: `~/.config/agent-vault/config.json` — инстансы + `projectMap` (папка проекта → инстанс).
- Токены: `~/.config/agent-vault/tokens/<instance>` (chmod 600), создаются **пользователем**:

  ```bash
  agent-vault login <instance>      # vault login в своём терминале, токен копируется в tokens/
  ```

**Состояние оболочки не переживает между вызовами инструментов** — каждый вызов агента
начинается с `agent-vault status` / прямой команды.

`agent-vault status [instance]`:
- `token: OK` — работаем;
- `token: НЕТ / невалиден` — попросить пользователя запустить `agent-vault login <instance>`
  в **своём** терминале. Агент разблокировать не может и не должен.

## Область: где что лежит

| Параметр | Что означает |
|---|---|
| (без проекта) | имя текущей папки → `projectMap` → инстанс; область `secret/agent/<папка>/` |
| `--project <имя>` | явная проектная область `secret/agent/<имя>/` |
| `--instance <имя>` | принудительный инстанс (обход `projectMap`); `agent-vault project` показывает резолв |

**Проектная область** = локальный vault проекта. Имя по умолчанию — имя папки проекта.
Создаётся при первой записи (`new`/`add`). Политику на неё токену агента выдаёт владелец.

Именование секретов — `<хост или сервис> <учётка>`: `srv-1c USR1CV8`, `pve-lab root`,
`gitea token-claude`, `pg 1c postgres`. Поля секрета: `username`, `password`, `uri`, `notes`
+ произвольные поля (`--fields k=v,k2=v2`) для метаданных/API-токенов.

## Команды обёртки

```bash
agent-vault status [instance]        # инстанс, токен, политики, sealed
agent-vault login [instance]         # ТОЛЬКО пользователь в своём терминале
agent-vault project [--project P]    # проект/инстанс/путь
agent-vault list [--project P]       # имена секретов, без значений
agent-vault info <name> [--project P]  # username, uri, notes, поля — без password
agent-vault use <name> [--project P] -- '<script>'   # секрет только в env внутри блока

agent-vault new <name> [--username U] [--uri U] [--notes T] [--fields k=v,..]
              [--length N] [--project P] [--instance I]      # сгенерировать и сохранить
agent-vault add <name> [--username U] [--uri U] [--notes T] [--fields k=v,..]
              [--prompt] [--project P] [--instance I]        # сохранить известное значение (пароль — из stdin)
agent-vault set <name> [--length N] [--project P]            # ротация
agent-vault remove <name> [--project P]                      # удалить
```

## Шаблоны

```bash
# PostgreSQL — пароль только в env внутри блока
agent-vault use 'pg 1c postgres' --project bsz -- '
    PGPASSWORD="$VAULT_PASSWORD" psql -h 10.0.0.171 -U "$VAULT_USERNAME" -c "\l"
'

# REST с токеном из поля
agent-vault use 'pve-lab api-token' --project lab -- '
    curl -s -H "Authorization: PVEAPIToken=$VAULT_TOKEN_ID=$VAULT_PASSWORD" \
         https://192.0.2.10:8006/api2/json/nodes
'

# Новая сервисная учётка: сгенерировать, сохранить, применить — значение нигде не всплывает
agent-vault new 'svc-sync ad' --project example-project --username svc-sync@example.local --length 28
agent-vault use 'svc-sync ad' --project example-project -- 'smbpasswd -a -n svc-sync'   # пример

# Пароль всплыл в чате
printf '%s' 'то-что-прислали' | agent-vault add 'nas admin' --project lab --notes 'из чата, сменить'
# → дальше только по имени; напомнить пользователю о ротации
```

Отчёт пользователю — имя, путь (`secret/agent/<project>/<name>`), инстанс. Ничего сужающего
пространство перебора.

## Политика для токена агента (на каждом инстансе)

```hcl
path "secret/data/agent/*"      { capabilities = ["create","read","update","delete","list"] }
path "secret/metadata/agent/*"  { capabilities = ["create","read","update","delete","list"] }
path "secret/delete/agent/*"    { capabilities = ["update"] }
path "secret/destroy/agent/*"   { capabilities = ["update"] }
# дополнительное чтение (по необходимости):
# path "secret/data/infra/*"    { capabilities = ["read","list"] }
```

## Грабли

- `vault kv get -format=json` отдаёт KV v2 в `data.data`; `vault kv list -format=json` — в
  `data.keys`. Обёртка уже учитывает.
- Запись значений через `data=@файл` (не аргументами) — иначе значение видно в `ps`.
- Токен хранится per-instance; `vault login` пишет в `~/.vault-token`, обёртка копирует его в
  `tokens/<instance>`. При ротации/sudo-промптах токен не перезаписывать руками.
- Если инстанс запечатан (`sealed: true`) — просить пользователя рассекретить; агент не может.
- `--length` меньше 12 игнорируется (минимум 12). Пароль всегда содержит верхний/нижний
  регистр, цифру и спецсимвол.