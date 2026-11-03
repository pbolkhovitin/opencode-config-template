# Security Profile — CTF & Penetration Testing

## Плагины (v2-совместимые)
- **opencode-supermemory** (`opencode-supermemory/server`) — persistent memory между CTF-сессиями
- **opencode-shell-strategy** (инструкция) — non-interactive shell команды
- ~~vibeguard, websearch-cited, swarm, notify, antigravity-auth, firecrawl~~ — v1-only, в v2 не работают
  (websearch → встроенный; секреты → Vault, не отправлять в LLM)

## Кастомные агенты (Tab)
- **@ctf-reverse-engineer** (primary) — RE: Ghidra, IDA, radare2, обход антиотладки
- **@ctf-pwner** (primary) — Binary exploitation: ROP, heap, pwntools
- **@ctf-web-hacker** (primary) — Web CTF: SQLi, XSS, SSTI, JWT, GraphQL
- **@pentester** (primary) — PTES: recon, эксплуатация, отчёт

## Доступные MCP инструменты
- **ssh** — удалённое подключение к серверам
- **docker** — контейнеры (изоляция, анализ образов)

## CTF Skills (skills.sh)
### Reverse Engineering
- `ctf-reverse` — PE-файлы, UPX, IDA/Ghidra, антиотладка
- `reverse-engineer` — общий RE-процесс
- `mode-exploit` — exploitation mode

### PWN / Binary Exploitation
- `ctf-pwn` — stack/BOF, ROP, heap, format string
- `exploit-dev-expert` — разработка эксплоитов

### Web Security
- `ctf-web` — SQLi, XSS, SSTI, JWT, LFI
- `web-security-expert` — экспертиза веб-безопасности
- `jwt-security` — атаки на JWT
- `sqlmap-database-pentesting` — automated SQLi

### Cryptography
- `ctf-crypto` — RSA, AES, XOR, hash length extension

### Forensics & Stego
- `ctf-forensics` — PCAP, disk images
- `memory-forensics-volatility` — Volatility memory dump analysis
- `steganography-techniques` — стеганография (LSB, metadata и т.д.)
- `traffic-analysis-pcap` — Wireshark/tshark анализ трафика
- `analyzing-network-traffic-with-wireshark` — chain of custody, отчёты

### OSINT
- `ctf-osint` — Google dorks, shodan, metadata

### Malware
- `ctf-malware` — reverse malware, obfuscation, unpacking
- `malware-analyst` — анализ вредоносного ПО

### Pentesting
- `pentest-expert` — общий пентест
- `mode-pentest` — pentest mode
- `penetration-testing` — методология
- `smtp-penetration-testing` — SMTP атаки
- `log-analysis` — анализ логов

## Системные утилиты
- **nmap/ncat** — сканирование, netcat
- **masscan** — массовое сканирование
- **gobuster** — directory busting
- **hydra** — brute force
- **john/hashcat** — взлом хешей
- **aircrack-ng** — wireless
- **sqlmap** — SQL injection (pip)
- **pwntools** — CTF exploit library (pip)
- **scapy** — packet manipulation (pip)
- **binwalk** — firmware analysis
- **foremost** — file carving
- **steghide** — стеганография
- **sleuthkit/testdisk** — дисковая форензика
- **gdb/radare2/rizin** — дебаггинг/RE
- **wireshark** — анализ трафика
- **socat** — networking relay
- **bind-utils/whois** — DNS, whois
- **tor/proxychains** — анонимизация
- **macchanger** — MAC-spoofing
- **firejail** — sandbox

## Связанные навыки

**Авто-триггер**: при фразах «grill me», «стресс-тест плана», «проинтервьюируй план», «пробей план» — автоматически активируй скилл `grill-me` (без явной команды).

Установка: `find-skills --skills "grill-me web-security-expert webapp-testing analyzing-network-traffic-with-wireshark wireshark-analysis traffic-analysis-pcap memory-forensics-volatility malware-analyst steganography-techniques reverse-engineer smtp-penetration-testing"`

Связанные навыки для автоматической установки:
- `grill-me` — стресс-тест плана интервью по веткам решений
- `sqlmap-database-pentesting` — SQLmap database pentesting
- `web-security-expert` — экспертиза веб-безопасности
- `webapp-testing` — тестирование веб-приложений
- `analyzing-network-traffic-with-wireshark` — анализ трафика Wireshark
- `wireshark-analysis` — анализ сетевых дампов
- `traffic-analysis-pcap` — анализ pcap-дампов
- `memory-forensics-volatility` — форензика памяти Volatility
- `malware-analyst` — анализ вредоносного ПО
- `steganography-techniques` — техники стеганографии
- `reverse-engineer` — обратная разработка
- `smtp-penetration-testing` — пентест SMTP

## Режим безопасности
- **Все destructive операции требуют подтверждения** (bash, write, edit — ask)
- **Секреты маскируются** — держать в Vault (agent-vault), не отправлять в LLM
- Перед любым сканированием получи подтверждение от пользователя
- Для каждого действия сначала explain, потом execute

## Правила маскировки и защиты
1. Все API-ключи, токены, флаги — хранить в Vault (agent-vault), не в чате
2. Для подозрительных бинарников используй `firejail`
3. Tor + proxychains для анонимного доступа в сеть
4. `macchanger` перед подключением к недоверенным сетям
5. Флаги CTF сохраняй в `/tmp/flags.txt`, не коммить в git
6. Для secure-delete: `bleachbit` или `shred`
7. Работай в `/tmp/workspace/` для CTF-челленджей
8. **Безопасность sudo**: никогда не используй `sudo -S` (пароль через stdin). Только `sudo -A` — askpass читает пароль напрямую с `/dev/tty`, пароль НЕ попадает в LLM.

## Workflow: CTF Challenge
1. **Разведка** — `ctf-osint` / `ctf-web`: собери информацию
2. **Классификация** — определи тип: RE / web / pwn / crypto / forensics / stego
3. **Загрузка скилла** — активируй соответствующий skill
4. **Анализ** — используй системные утилиты (nmap, binwalk, gdb и т.д.)
5. **Эксплуатация** — `exploit-dev-expert` / `ctf-pwn` для разработки
6. **Верификация** — `verification-before-completion`
7. **Флаг** — запиши флаг, задокументируй решение

## Workflow: Pentest
1. **Recon** — `nmap -sC -sV target`, `masscan`, `gobuster`
2. **OSINT** — `ctf-osint`, dig, whois
3. **Сканирование** — sqlmap, hydra, nikto (через ssh/docker MCP)
4. **Эксплуатация** — `pentest-expert`, `exploit-dev-expert`
5. **Пост-эксплуатация** — сбор данных, pivoting (tor + proxychains)
6. **Отчёт** — документирование находок

## Workflow: Forensics
1. **Изоляция** — работай с копией, не оригиналом
2. **Сбор** — binwalk, foremost, sleuthkit, volatility
3. **Анализ** — wireshark/tshark для pcap, stego-детект
4. **Документация** — chain of custody

## Примечание: слияние sec-lm

Профиль `sec-lm` удалён 2026-10-25. Все профили переведены на одну модель
`anthropic/claude-sonnet-4-5`, поэтому отдельный профиль под LM Studio больше не нужен.
Allowlist скиллов `sec-lm` (включая `threat-intel`) объединён с `sec`; локальные модели
при необходимости подключаются проектно через `provider` с `baseURL` LM Studio.
