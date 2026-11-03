#!/usr/bin/env bash
# Локальный агрегатор проверок. CI запускает те же команды.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== schema & policy =="
python3 tests/validate_configs.py config profiles

echo "== pytest =="
python3 -m pytest tests -q

echo "== shell syntax =="
bash -n scripts/*.sh setup.sh

echo "== deploy dry-run =="
bash tests/test-install-profile-skills.sh

echo "ALL CHECKS PASSED"
