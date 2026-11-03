# Security toolchain: Kali vs native (decision record)

Статус: **принято** (2026-09-20)
Область: профиль `sec` (сетевые инструменты также в `net`), хост-окружение агента

## Контекст

Агент opencode выполняет security-задачи (CTF, pentest, SAST, forensics)
через `bash` **в текущей ОС хоста**. Профиль `sec` уже описывает набор
системных утилит, но фактический инвентарь хоста ему не соответствовал.
Требовалось решить: ставить ли Kali Linux / Kali Purple как отдельную ОС,
либо ограничиться инструментарием.

Хост: Linux (native, не WSL). Доступны: Docker, Podman, Go, cargo, uvx, ruby/gem.

## Ключевое ограничение

Инструмент полезен агенту только если он **доступен из того же shell**, где
работает агент. Отдельная ОС (bare-metal Kali) агенту недостижима без
перезагрузки — сессия opencode живёт в текущей ОС. Следовательно bare-metal
Kali не решает задачу.

## Решение

Bare-metal **Kali Linux и Kali Purple не устанавливаются**. Принята
трёхуровневая схема:

| Уровень | Роль | Когда |
|---|---|---|
| **1. Native на Fedora** | основной: всё CLI-нужное в shell агента | по умолчанию |
| **2. Kali в Docker/Podman** | арсенал «по требованию», изоляция | тяжёлые/редкие инструменты, недоверенные бинарники |
| **3. Kali VM в Proxmox** | GUI и агрессивные сценарии | Burp, monitor-mode Wi-Fi, kernel-модули, snapshot-откат |

Приоритет выбора: **native → контейнер → VM**.

### Почему не bare-metal Kali / Kali Purple

- **Kali bare-metal** — ломает сессию агента (другая ОС), дублирует систему,
  расход диска; не даёт ничего сверх контейнера.
- **Kali Purple** — blue-team/SOC-дистрибутив (Elastic, Suricata, Zeek),
  тяжёлый и GUI-ориентированный; плохо совпадает с offensive-скиллами
  профиля `sec`. Оправдан только как отдельная лаборатория
  detection-engineering — и то в виде VM, а не на хосте.

## Пример инвентаря

### Установлено на хосте (пример)

`nmap`, `masscan`, `sqlmap`, `gobuster`, `hydra`, `john`, `hashcat`,
`wireshark`, `tshark`, `aircrack-ng`, `smbclient`, `semgrep`, `binwalk`,
`foremost`, `steghide`, `sleuthkit` (`fls`/`mmls`), `radare2`/`rizin`,
`gdb`, `socat`, `proxychains4`, `tor`, `macchanger`, `firejail`, `ncat`,
`scapy`, `whois`, `dig`.

### Отсутствует — маршруты установки

| Инструмент | Источник |
|---|---|
| `ffuf`, `nuclei` | `dnf` (есть в репозитории Fedora) |
| `impacket`, `netexec`, `volatility3` | `pipx` |
| `pwntools` | `dnf install python3-pwntools` или `pip` |
| `wpscan` | `gem` |
| `subfinder`, `httpx`, `dnsx`, `naabu` | `go install` (projectdiscovery) |
| `rustscan` | `cargo` / RPM Fusion |
| `metasploit` | официальный Rapid7-installer (в базовом репо Fedora нет) |
| `searchsploit` | git `exploitdb` |
| `responder`, `evil-winrm`, `bloodhound`, `enum4linux`, `nikto` | Kali-контейнер |

## Kali-контейнер: рабочий шаблон

```sh
docker pull kalilinux/kali-rolling
docker run --rm -it --net=host -v "$PWD:/work" kalilinux/kali-rolling \
  bash -lc 'apt update && apt install -y <tool> && <tool>'
```

Изоляция: недоверенные бинарники запускать в контейнере, а не на хосте.

## Следствия

- Обновлять профиль `sec/AGENTS.md` при изменении фактического инвентаря.
- Установка инструментов — отдельный план (см. issue/план реализации),
  выполняется с подтверждением пользователя (sudo).
- Kali Purple — только по отдельному запросу под blue-team лабораторию (VM).
