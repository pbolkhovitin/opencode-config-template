# Миграция профилей OpenCode (2026-10-25)

Набор профилей приведён к виду: **default, dev, infra, net, sec, ot, mgnt**.
Удалены `devops`, `fullstack`, `sec-lm`; создан `net`.

## Карта переноса

| Было | Стало | Что перенесено |
|---|---|---|
| `dev` | `dev` | feature-planner, senior-python-dev, appsec-auditor, security-tool-developer, code-reviewer; MCP postgres/docker/playwright/filesystem/github/duckduckgo/ssh/brave-search |
| `fullstack` | `dev` | code-architect, senior-{java,go,rust,nextjs}-dev, platform-engineer; 11 языковых инструкций; MCP filesystem/github |
| — (новые) | `dev` | senior-js-ts-dev, senior-php-dev, senior-cpp-dev, instructions/php.md |
| `devops` | `infra` | infra-engineer, security-auditor, devops-reviewer; MCP proxmox/ansible/opentofu/docker/ssh/postgres; allowlist IaC-скиллов |
| — (новые) | `infra` | sre, mlops-engineer, gitops-engineer |
| — (новый профиль) | `net` | network-engineer, network-security, bgp-ospf-analyst, packet-analyst; MCP ssh/docker/filesystem/duckduckgo |
| `sec` | `sec` | 6 агентов CTF/pentest; MCP ssh/docker |
| `sec-lm` | `sec` | allowlist (`threat-intel` и др.) объединён; отдельный LM-профиль больше не нужен |
| `mgnt` | `mgnt` | без изменений по составу |
| `ot` | `ot` | без изменений (6 агентов, ot-guard, docs/ot) |

## Что удалено

- `profiles/devops/`, `profiles/fullstack/`, `profiles/sec-lm/` — целиком.
- `profiles/sec-lm/AGENTS-lm.md` и `profiles/sec-lm/test_agents_lm.py` — LM-специфика.
- `profiles/*/package-lock.json` — не использовались при деплое, устарели.
- `docs/devops/`, `docs/fullstack/` — заменены на `docs/infra/` и обновлённый `docs/dev/`.

## Модели

Во всех профилях: `model` и `small_model` = `anthropic/claude-sonnet-4-5`.
LM Studio больше не является частью профилей; локальная модель подключается проектным
`provider` с `baseURL` (см. `docs/config-migration.md`).

## Алиасы и переключение

| Было | Стало |
|---|---|
| `oc-devops` | `oc-infra` |
| `oc-fullstack` | `oc-dev` |
| `oc-sec-lm` | `oc-sec` |
| — | `oc-net` |

`ocp` знает только `default dev infra net sec ot mgnt`. `ocp` без аргумента открывает fzf-меню.
Старые каталоги `~/.config/opencode-{devops,fullstack,sec-lm}` можно удалить: деплой новых
профилей их не использует.

## Как перейти

```bash
# 1. Обновить репозиторий
git -C ~/.local/share/opencode/opencode-synced/repo pull

# 2. Развернуть все профили
for p in default dev infra net sec ot mgnt design; do
  bash ~/.local/share/opencode/opencode-synced/repo/scripts/deploy-config.sh "$p"
done

# 3. Удалить устаревшие каталоги (после проверки, что новые работают)
rm -rf ~/.config/opencode-devops ~/.config/opencode-fullstack ~/.config/opencode-sec-lm

# 4. Обновить алиасы (setup.sh добавляет блок, если его ещё нет)
#    или вручную: oc-infra / oc-net вместо oc-devops / oc-fullstack / oc-sec-lm
```

Профильные алиасы должны запускать `opencode --standalone`: в v2 конфигом
владеет фоновый сервис, и без `--standalone` выбранный профиль игнорируется
(симптом — 0 MCP в статус-баре). То же делает `ocp`.

Алиасы и `ocp` также передают `--continue`: при запуске продолжается последняя
сессия проекта, а не создаётся новая. Новая сессия — `leader+n` в TUI.

## Проверка после миграции

```bash
python3 tests/validate_configs.py config profiles
python3 -m pytest tests -q
bash tests/run.sh
for p in default dev infra net sec ot mgnt design; do
  bash scripts/deploy-config.sh --dry-run "$p"
done
```

Ожидается: все проверки зелёные, каждый профиль разворачивается без ошибок,
`ocp` показывает ровно восемь профилей (канонический набор + `design`, добавленный
2026-11-11 отдельно от миграции).

## Откат

Изменения обратимы через git: профили `devops`, `fullstack`, `sec-lm` восстановимы
из коммита до миграции (`git log --oneline -- profiles/devops`). Живые конфиги
пересоздаются `deploy-config.sh` из соответствующей ревизии репозитория.
