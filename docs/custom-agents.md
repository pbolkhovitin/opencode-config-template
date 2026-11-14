# Custom Agents — Persona-based Prompts

## Что это

Именные профили имеют набор кастомных агентов с заранее написанными системными промптами.
Всего 39 агентов в шести профилях: senior-разработчики, архитекторы, security-аудиторы,
сетевые инженеры, SRE/MLOps/GitOps и т.д. В `default` кастомных агентов нет.

**Primary** — переключение через Tab в начале сессии. Сессия работает в режиме этого агента.
**Subagent** — вызов через `@mention`. Агент выполнит задачу и вернёт результат.

```zsh
# Primary: Tab → @senior-python-dev
# Subagent: @code-reviewer проверь последние изменения
```

---

## Агенты по профилям

### default — без кастомных агентов

В `config/opencode.json` секции `agent` нет: доступны только встроенные
`build` и `plan`. Для ролевых агентов переключитесь на именной профиль.

### dev — 14 агентов (dev + fullstack)

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@feature-planner` | primary | Анализ требований и план реализации. Read-only |
| `@code-architect` | primary | Архитектура, ADR, trade-offs. Не пишет код |
| `@senior-python-dev` | primary | Python: FastAPI, SQLAlchemy, asyncio, pytest |
| `@senior-js-ts-dev` | primary | JS/TS: React, Next.js, Node.js, TypeScript strict |
| `@senior-php-dev` | primary | PHP: Symfony/Laravel, PHPStan max, безопасные SQL/шаблоны |
| `@senior-cpp-dev` | primary | C/C++: C++20/23, RAII, sanitizers, embedded |
| `@senior-java-dev` | primary | Java: Spring Boot 3, Hibernate, Kafka |
| `@senior-go-dev` | primary | Go: chi/gRPC, sqlx, K8s-native |
| `@senior-rust-dev` | primary | Rust: Axum/tokio, SQLx |
| `@senior-nextjs-dev` | primary | Next.js: App Router, RSC, Server Actions, Tailwind |
| `@appsec-auditor` | primary | SAST: semgrep PHP/TS/JS, dependency audit |
| `@security-tool-developer` | primary | Python security tooling: pwntools, scapy, async scanning |
| `@code-reviewer` | subagent | Ревью на любом языке. Read-only |
| `@platform-engineer` | subagent | K8s, Docker, CI/CD. Bash=allow |

### infra — 6 агентов (devops + MLOps/GitOps/SRE)

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@infra-engineer` | primary | Proxmox, Ansible, Terraform/OpenTofu, Docker, K8s. IaC всё |
| `@sre` | primary | SLO/SLI, инциденты, observability, capacity planning |
| `@mlops-engineer` | primary | ML-пайплайны, registry, inference, GPU |
| `@gitops-engineer` | primary | Argo CD/Flux, Helm/Kustomize, secrets, progressive delivery |
| `@security-auditor` | primary | Инфраструктурный security audit: CVE, hardening |
| `@devops-reviewer` | subagent | Ревью IaC (Terraform, Ansible, Dockerfile). Read-only |

### net — 4 агента

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@network-engineer` | primary | L2/L3, VLAN, маршрутизация, firewall, VPN, MikroTik/OpenWrt/pfSense |
| `@network-security` | primary | Сегментация, аудит ACL/firewall, IDS, усиление VPN |
| `@bgp-ospf-analyst` | primary | BGP/OSPF/IS-IS: best-path, фильтрация, сходимость |
| `@packet-analyst` | subagent | pcap, tshark/Zeek, таймлайны, артефакты |

### sec — 6 агентов

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@ctf-reverse-engineer` | primary | RE: Ghidra, IDA, radare2, обход антиотладки |
| `@ctf-pwner` | primary | Binary exploitation: ROP, heap, pwntools |
| `@ctf-web-hacker` | primary | Web CTF: SQLi, XSS, SSTI, JWT, GraphQL |
| `@pentester` | primary | PTES: recon, эксплуатация, отчёт |
| `@appsec-auditor` | primary | SAST: semgrep PHP/TS/JS, dependency audit |
| `@threat-intel` | primary | Threat intel: ATT&CK, CVE/NVD, OSV.dev, Exploit-DB |

### ot — 6 агентов

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@ot-protocol-analyst` | primary | Modbus, S7, OPC UA, IEC 104, DNP3, EtherNet/IP, PROFINET |
| `@ot-incident-responder` | primary | Инциденты и форензика АСУ ТП |
| `@ot-network-designer` | primary | VLAN, кольца, резервирование, документация |
| `@ot-recon` | subagent | Инвентаризация и пассивный recon |
| `@ot-segmentation-reviewer` | subagent | Зоны/кондуиты, firewall/ACL, Purdue |
| `@ot-vuln-researcher` | subagent | CVE и бюллетени вендоров, компенсирующие меры |

### mgnt — 3 агента

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@prd-writer` | primary | PRD, user stories, спеки, OKR |
| `@incident-commander` | primary | Триаж, локализация, post-mortem |
| `@data-analyst` | primary | SQL, метрики, дашборды, read-only БД |

### design — 2 агента

| Агент | Тип | Что делает |
|-------|-----|------------|
| `@ui-designer` | primary | Арт-дирекшн, дизайн-система, вёрстка |
| `@visual-qa` | subagent | Скриншот-приёмка, адаптивность, контраст, ошибки консоли (read-only) |

---

## Swarm subagent'ы — история (v1-only)

`opencode-swarm` был v1-плагином и в OpenCode v2 **не работает** (v2-порт
отсутствует). Ролевые агенты теперь описаны обычной секцией `agent` в
`opencode.jsonc`, без плагина. Историческую схему ролей (`@coder`, `@reviewer`,
`@test_engineer`, `@explorer`, `@sme`, `@critic`, `@docs` и др.) не используем.

---

## Техническая реализация

Каждый агент определён в `opencode.jsonc` через секцию `agent {}`:

```jsonc
"agent": {
  "senior-python-dev": {
    "description": "Senior Python developer — code review, architecture, implementation",
    "mode": "primary",
    "temperature": 0.1,
    "prompt": "{file:./prompts/personas/senior-python-dev.md}",
    "permission": { "edit": "allow", "bash": "allow" }
  },
  "code-reviewer": {
    "description": "Code review on any language — read-only",
    "mode": "subagent",
    "temperature": 0.1,
    "prompt": "{file:./prompts/personas/code-reviewer.md}",
    "permission": { "edit": "deny", "bash": "deny" }
  }
}
```

Промпты лежат копиями в `profiles/<profile>/prompts/personas/` — при деплое
они попадают в `~/.config/opencode-<profile>/prompts/personas/`. Симлинков и
общего каталога `~/.agents/prompts/` нет; оригиналы для справки — в
`prompts/personas/` корня репозитория.
