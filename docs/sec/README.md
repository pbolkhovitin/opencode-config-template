# Security Profile — CTF & Penetration Testing

## Плагины
- **@tarquinen/opencode-dcp** — обрезка устаревшего контекста
- **supermemory** — persistent memory между сессиями
- **opencode-handoff** — передача сессии в новую сессию
- **shell-strategy** (инструкция) — non-interactive shell команды

## Кастомные агенты (Tab)
- `@ctf-reverse-engineer` (primary) — RE: Ghidra, IDA, radare2, обход антиотладки
- `@ctf-pwner` (primary) — Binary exploitation: ROP, heap, pwntools
- `@ctf-web-hacker` (primary) — Web CTF: SQLi, XSS, SSTI, JWT, GraphQL
- `@pentester` (primary) — PTES: recon, эксплуатация, отчёт
- `@appsec-auditor` (primary) — SAST: semgrep PHP/TS/JS, dependency audit
- `@threat-intel` (primary) — Threat intel: ATT&CK STIX, CVE/NVD, OSV.dev, Exploit-DB

## SAST / AppSec
- **semgrep** — SAST сканирование PHP, TS, JS (OWASP Top 10, CWE)
- `npm audit` / `composer audit` — аудит зависимостей

## Модель

Все профили, включая `sec`, работают на `anthropic/claude-sonnet-4-5`
(`model` и `small_model`). Отдельных моделей под CTF-задачи нет.

## Локальные модели (LM Studio)

LM Studio (`192.168.1.185:1234`) остаётся локальным OpenAI-совместимым
провайдером, но отдельного профиля `sec-lm` больше нет: все профили работают
на `anthropic/claude-sonnet-4-5`. Локальную модель можно подключить
в любом профиле через `provider` (`lm-studio/...`) и `--model`.

## Доступные MCP

| MCP | Возможности |
|-----|-------------|
| **ssh** | Remote exec, sessions, port forward, file sync |
| **docker** | Изоляция, анализ образов, запуск инструментов |

## Сценарии

### Penetration Test
```bash
# 1. Recon — system tools (nmap, masscan)
nmap -sC -sV -p- target.com

# 2. OSINT — встроенный websearch / duckduckgo-скиллы
# 3. Directory busting — gobuster (bash)
# 4. Web scan — nikto (bash/docker)
# 5. Exploitation — ctf-web / ctf-pwn / exploit-dev-expert skills
# 6. Post-exploitation — SSH for pivoting
ssh_ssh_forward target=target.com direction=local local_port=8888 remote_host=internal.corp remote_port=8080
```

### CTF Challenge
```bash
# 1. Определить тип: web / pwn / reverse / crypto / forensics / osint
# 2. Загрузить skill: skill name=ctf-{type}
# 3. Анализировать:
#    - Docker для изоляции бинарников
#    - встроенный websearch для поиска writeups
# 4. Разработать эксплоит
# 5. Получить флаг → /tmp/flags.txt
```

### Forensics (образ диска / memory dump)
```bash
# 1. Изоляция — работать с копией через Docker
# 2. Disk forensics — sleuthkit / binwalk / foremost (system tools)
# 3. Memory forensics — memory-forensics-volatility skill
# 4. Network traffic — traffic-analysis-pcap / wireshark-analysis
```

### Malware Analysis
```bash
# 1. Изоляция в Docker
# 2. Reverse engineering — ctf-reverse / reverse-engineer skills
# 3. Network capture — tcpdump в docker
# 4. YARA rules — malware-analyst skill
```

## Безопасность
- **bash, edit** — с подтверждением (ask)
- Секреты — только `{env:VAR}` или Vault (`agent-vault`), без плагинов-маскировщиков
- Флаги CTF → `/tmp/flags.txt`, не коммитить в git
- Для sandbox → firejail / Docker
- Для анонимности → Tor + proxychains

## Workflow
1. Определить тип задачи (pentest / CTF / forensics)
2. Загрузить соответствующий skill
3. Разведка → анализ → эксплуатация
4. Флаг/отчёт → `/tmp/` или документ
5. `verification-before-completion`

## Permissions
- bash=ask, edit=ask (все destructive операции с подтверждением)

## Слияние sec-lm (2026-10-25)

Профиль `sec-lm` удалён: все профили работают на `anthropic/claude-sonnet-4-5`,
отдельный LM-профиль больше не нужен. Allowlist `sec` объединён с `sec-lm`
(добавлен `threat-intel` и общие скиллы). Локальная модель при необходимости
подключается проектным `provider` с `baseURL` LM Studio.

Запуск: `oc-sec` или `ocp sec`.
