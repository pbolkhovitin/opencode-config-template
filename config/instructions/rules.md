# Rules

- Always use parallel tools where possible
- Confirm destructive operations before execution
- For infra changes (proxmox, terraform, ansible), always dry-run first with --check
- Write code and commit messages in English
- Write comments in Russian only when needed
- Write user-facing messages in Russian; code/identifiers and commit messages in English.
- **Sudo:** only `sudo -n`; never `sudo -S`/askpass and never ask for a password in chat. Full procedure: `context/playbooks/sudo.md`.
