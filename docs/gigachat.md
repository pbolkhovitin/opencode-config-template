# GigaChat (Сбер) как провайдер OpenCode

Статус: работает с 2026-11-10 (OpenCode v2.2.6+; проверено на 2.3.0, фоновый сервис).
API base: `https://api.giga.chat/v1` (OpenAI-совместимый диалект).

## Из чего состоит

| Часть | Где |
|---|---|
| Провайдер + список моделей | `~/.config/opencode/opencode.json` → `provider.gigachat` |
| Плагин (Bearer-токен на запрос) | `~/.config/opencode/plugins/gigachat/{index.ts,token.mjs}` |
| Секрет (Authorization Key) | Vault `secret/agent/YOUR_PROJECT/gigachat api` (`agent-vault`) |
| Корневой CA Минцифры | `~/.local/share/certs/russian-trusted/russian_trusted_root_ca_pem.crt` |
| CA в окружении сервиса | `opencode service set env NODE_EXTRA_CA_CERTS <путь>` |

## Как работает авторизация

GigaChat требует `Authorization: Bearer <access_token>`, живущий 30 минут и
выпускаемый по OAuth из долгоживущего Authorization Key (`Basic <key>`).

- `token.mjs` запускается плагином как ребёнок
  `agent-vault use 'gigachat api' --project YOUR_PROJECT -- node token.mjs`.
  Ключ существует только в env этого процесса (`VAULT_PASSWORD`), наружу уходит
  лишь короткоживущий токен.
- Плагин кэширует токен до `expires_at` и подставляет заголовок через
  `ctx.session.hook("http.request", …, { providerID: "gigachat" })`.
- В лог/на диск ничего не пишется.

Проверенные тупики (не повторять):
- v1-плагин (`chat.headers`) в v2 не грузится — нужен `Plugin.define`.
- `ctx.aisdk.hook("sdk"|"language")` регистрируется, но не вызывается.
- `ctx.provider.transform` + подмена `settings.fetch` **ломает** состояние
  сервиса (провайдер исчезает из `opencode models`) — лечится
  `opencode service restart`.

## TLS

Сертификат подписан Russian Trusted Root CA, которого нет в системном store, поэтому:

```bash
mkdir -p ~/.local/share/certs/russian-trusted
curl -k -o ~/.local/share/certs/russian-trusted/russian_trusted_root_ca_pem.crt \
  https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt
opencode service set env NODE_EXTRA_CA_CERTS \
  ~/.local/share/certs/russian-trusted/russian_trusted_root_ca_pem.crt
opencode service restart
```

- Достаточно **только root CA**; добавление sub CA в общий bundle ломает curl
  (error 77), в `NODE_EXTRA_CA_CERTS` их смешивать не нужно.
- Env, выставленный в shell, до фонового сервиса не доходит — только через
  `opencode service set env`.
- `token.mjs` грузит тот же CA по пути из `GIGACHAT_CA_PATH` (по умолчанию —
  тот же файл), поэтому OAuth к `ngw.devices.sberbank.ru:9443` работает.
- Системная установка CA (`update-ca-trust`, нужен sudo) не требуется.

## Модели

`GigaChat-3-Ultra`, `GigaChat-3-Pro`, `GigaChat-3-Lightning`, `GigaChat-2-Max`,
`GigaChat-2-Pro`, `GigaChat-2`. Embeddings в конфиг не заведены.

```bash
opencode run -m gigachat/GigaChat-2 "Привет"
```

## Ротация секрета

Authorization Key был передан в чате 2026-11-10 — считать скомпрометированным.
После выпуска нового ключа в личном кабинете GigaChat:

```bash
agent-vault set 'gigachat api' --project YOUR_PROJECT   # или add с новым значением из stdin
```

Плагин подхватит новое значение при следующем запросе токена (кэш ≤ 30 мин),
перезапуск сервиса не нужен.

## Профили

Провайдер и плагин лежат в default-конфиге (`config/opencode.json`,
`config/plugins/gigachat/`) и раскатываются `setup.sh` во все профили.
Env `NODE_EXTRA_CA_CERTS` — машинно-специфичный, в git не попадает.

## Вариант без Vault (свой Authorization Key)

Если Vault/agent-vault нет, плагин берёт ключ из окружения:

```bash
export GIGACHAT_AUTH_KEY='<Authorization Key: base64(client_id:client_secret)>'
export GIGACHAT_CA_PATH="$HOME/.local/share/certs/russian-trusted/russian_trusted_root_ca_pem.crt"
# optional: export GIGACHAT_SCOPE=GIGACHAT_API_PERS
```

`GIGACHAT_AUTH_KEY` должен быть именно Authorization Key (Basic-ключ), а не
`client_secret` по отдельности: `token.mjs` сам делает OAuth-обмен на access_token.
Провайдер `gigachat` не использует `apiKey` напрямую — плагин подставляет
`Authorization: Bearer <access_token>` в `http.request`.

Для Vault-варианта можно переопределить проект/секрет:
`GIGACHAT_VAULT_PROJECT`, `GIGACHAT_VAULT_SECRET`.
