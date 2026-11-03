# Infra Profile — Инфраструктура, платформы и эксплуатация

Объединяет бывший `devops` и роли MLOps / GitOps / SRE.

## Плагины (v2-совместимые)
- **opencode-supermemory** — persistent memory между сессиями
- **@tarquinen/opencode-dcp** — Dynamic Context Pruning
- **opencode-gemini-auth** — OAuth для Google/Gemini
- **opencode-handoff** — передача контекста в новую сессию
- ~~vibeguard, websearch-cited, notify~~ — v1-only, в v2 не работают

## Кастомные агенты (Tab)
- **@infra-engineer** (primary) — Proxmox, Ansible, Terraform/OpenTofu, Docker, K8s
- **@sre** (primary) — SLO/SLI, инциденты, observability, capacity planning
- **@mlops-engineer** (primary) — ML-пайплайны, registry, inference, GPU
- **@gitops-engineer** (primary) — Argo CD/Flux, Helm/Kustomize, secrets, progressive delivery
- **@security-auditor** (primary) — аудит безопасности инфраструктуры
- **@devops-reviewer** (subagent) — ревью IaC. Read-only.

## Доступные MCP

| MCP | Возможности |
|-----|-------------|
| **proxmox** | VM/CT lifecycle, cluster, storage, backup, HA, SDN |
| **ansible** | Playbooks, inventory, lint, roles, collections |
| **opentofu** | Terraform-compatible IaC: plan/apply, modules |
| **docker** | Containers, compose, images, logs |
| **ssh** | Remote exec, persistent sessions, port forward, file sync |
| **postgres** | Admin: health, replication, locks, bloat, sequence |
| **gitlab-work** | Рабочий GitLab (MR, issues, pipelines, wiki, releases); токен из Vault |
| **gitlab-official-yandex** / **gitlab-official-gmail** | Официальные аккаунты GitLab.com — включены |
| **gitlab-personal** | Личный GitLab — выключен до добавления токена |

## Сценарии

### Развёртывание VM в Proxmox
```bash
proxmox_create_vm node=pve1 vmid=301 name=app-server memory=4096 cores=4
proxmox_update_vm_cloudinit node=pve1 vmid=301 ciuser=deploy ipconfig0="ip=192.168.1.50/24,gw=192.168.1.1"
proxmox_create_vm_snapshot node=pve1 vmid=301 snapname=initial
proxmox_create_backup_job storage=pbs schedule=daily vmid=301
proxmox_create_ha_resource sid=vm:301 group=prod
```

### Ansible provisioning
```bash
ansible_lint path=playbooks/
ansible_playbook_run playbook_path=playbooks/deploy.yml inventory_path=inventory/prod.yml check=true
```

### OpenTofu
```bash
tofu init && tofu plan && tofu apply
opentofu_search-opentofu-registry query=vpc type=module
```

### GitOps (Argo CD / Flux)
```bash
kubectl -n argocd get applications
argocd app diff <app> && argocd app sync <app>
flux get kustomizations && flux reconcile kustomization <name> --with-source
```

### Инцидент: сервис недоступен
```bash
proxmox_get_node_status node=pve1
ssh_ssh_exec target=192.168.1.50 command="systemctl status app"
postgres_pg_health && postgres_pg_inspect_locks
docker_container_logs id=app-backend tail=100
```

## Правила
- **Dry-run / --check перед изменениями:** `ansible-playbook --check`, `tofu plan`
- Всё — через IaC; ручные изменения в проде только как аварийная мера с последующей фиксацией в коде
- GitOps: изменения в кластер — через PR и синхронизацию, не через `kubectl apply -f` в прод
- Идемпотентность и rollback plan обязательны
- Секреты — Vault / SOPS / External Secrets, не в git
- После изменений — `verification-before-completion`
- **sudo**: только `sudo -A`, никогда `sudo -S`

## Workflow
1. **Диагностика** — `systematic-debugging` / `devops-troubleshooter`
2. **План** — `writing-plans`, затем `devops-rollout-plan` (preflight → phased → rollback)
3. **Dry-run** — `tofu plan` / `ansible --check`
4. **Применение** — идемпотентно, с наблюдаемостью
5. **Верификация** — health checks, метрики, алерты
6. **Документация** — runbook / ADR / postmortem при инциденте

## Docs

Пути относительно корня репозитория `my-opencode-config`:

- `docs/infra/README.md` — сценарии инфраструктуры
- `docs/profiles-agents-matrix.md` — матрица профилей
