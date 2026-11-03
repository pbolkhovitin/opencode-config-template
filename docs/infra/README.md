# Infra Profile — Инфраструктура, платформы, эксплуатация

Объединяет бывший `devops` и роли MLOps / GitOps / SRE.
Конфиг: `profiles/infra/opencode.jsonc`. Запуск: `oc-infra` или `ocp infra`.

## Агенты
- `@infra-engineer` (primary) — Proxmox, Ansible, Terraform/OpenTofu, Docker, K8s
- `@sre` (primary) — SLO/SLI, инциденты, observability, capacity planning
- `@mlops-engineer` (primary) — ML-пайплайны, registry, inference, GPU
- `@gitops-engineer` (primary) — Argo CD/Flux, Helm/Kustomize, secrets
- `@security-auditor` (primary) — аудит безопасности инфраструктуры
- `@devops-reviewer` (subagent) — ревью IaC, read-only

## MCP

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

### VM в Proxmox
```bash
proxmox_create_vm node=pve1 vmid=301 name=app-server memory=4096 cores=4
proxmox_update_vm_cloudinit node=pve1 vmid=301 ciuser=deploy ipconfig0="ip=192.168.1.50/24,gw=192.168.1.1"
proxmox_create_vm_snapshot node=pve1 vmid=301 snapname=initial
proxmox_create_backup_job storage=pbs schedule=daily vmid=301
```

### Ansible / OpenTofu
```bash
ansible_lint path=playbooks/
ansible_playbook_run playbook_path=playbooks/deploy.yml inventory_path=inventory/prod.yml check=true
tofu init && tofu plan      # затем apply
```

### GitOps
```bash
kubectl -n argocd get applications
argocd app diff <app> && argocd app sync <app>
flux get kustomizations && flux reconcile kustomization <name> --with-source
```

### MLOps
- Пайплайн: данные → обучение → валидация → registry → деплой → drift-мониторинг.
- Версионирование: DVC/LakeFS для данных, model registry (MLflow) для моделей.
- Inference: vLLM/Triton/Ollama, батчинг, quantization, canary/shadow.
- GPU: очередь, утилизация, стоимость; MIG для совместного использования.

### Инцидент: сервис недоступен
```bash
proxmox_get_node_status node=pve1
ssh_ssh_exec target=192.168.1.50 command="systemctl status app"
postgres_pg_health && postgres_pg_inspect_locks
docker_container_logs id=app-backend tail=100
```

## Скиллы
IaC: `terraform-skill`, `ansible-validator`, `proxmox-admin`, `docker-kubernetes`, `docker-build-strategies`.
Эксплуатация: `devops-troubleshooter`, `devops-rollout-plan`, `incident-runbook-templates`,
`postmortem-writer`, `alerting-oncall`, `oncall-irm`, `log-analysis`, `kpi-dashboard-design`.
Базы: `postgresql-table-design`, `postgresql-optimization`, `supabase-postgres-best-practices`.
Безопасность: `security-audit`, `security-secrets`, `security-docker`.
Сеть: `traffic-analysis-pcap`, `wireshark-analysis`.

## Правила
- **Dry-run / --check перед изменениями:** `tofu plan`, `ansible-playbook --check`
- Всё — через IaC; GitOps-изменения — через PR, не `kubectl apply` в прод
- Rollback-план обязателен; секреты — Vault/SOPS/External Secrets
- После изменений — `verification-before-completion`
- `sudo` — только `sudo -A`, никогда `sudo -S`
