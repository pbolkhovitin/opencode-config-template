#!/usr/bin/env bash
# Тесты деплоя конфигурации: скрипт не должен требовать sudo/сеть
# и не должен оставлять следов в чистом HOME при --dry-run.
# Запуск: bash tests/test-install-profile-skills.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $name"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"; FAIL=$((FAIL + 1))
    fi
}

expect_file() { [ -f "$1" ]; }
expect_dir()  { [ -d "$1" ]; }
expect_absent() { [ ! -e "$1" ]; }
expect_empty_dir() { [ -z "$(ls -A "$1" 2>/dev/null)" ]; }
grep_q() { grep -q "$1" "$2"; }

WORK1=$(mktemp -d); WORK2=$(mktemp -d); WORK3=$(mktemp -d)
trap 'rm -rf "$WORK1" "$WORK2" "$WORK3"' EXIT

echo ""
echo "========================================"
echo "  deploy-config.sh — Test Suite"
echo "========================================"

echo ""
echo "--- Test 1: dry-run leaves clean HOME untouched ---"
HOME="$WORK1" bash "$REPO_DIR/scripts/deploy-config.sh" --dry-run default >/dev/null
check "1a: HOME остаётся пустым" expect_empty_dir "$WORK1"

echo ""
echo "--- Test 2: default deploy ---"
HOME="$WORK2" bash "$REPO_DIR/scripts/deploy-config.sh" default >/dev/null
check "2a: opencode.json создан"        expect_file "$WORK2/.config/opencode/opencode.json"
check "2b: AGENTS.md создан"            expect_file "$WORK2/.config/opencode/AGENTS.md"
check "2c: instructions/russian.md"     expect_file "$WORK2/.config/opencode/instructions/russian.md"
check "2d: skills/grill-me/SKILL.md"    expect_file "$WORK2/.config/opencode/skills/grill-me/SKILL.md"
check "2e: нет ~/.agents/context"       expect_absent "$WORK2/.agents/context"
check "2f: mcp.servers в конфиге"       grep_q '"servers"' "$WORK2/.config/opencode/opencode.json"

echo ""
echo "--- Test 3: profile deploy ---"
HOME="$WORK3" bash "$REPO_DIR/scripts/deploy-config.sh" infra >/dev/null
check "3a: opencode-infra/opencode.json" expect_file "$WORK3/.config/opencode-infra/opencode.json"
check "3b: профиль содержит mcp.servers"  grep_q '"servers"' "$WORK3/.config/opencode-infra/opencode.json"
check "3c: общие скиллы задеплоены"       expect_file "$WORK3/.config/opencode/skills/grill-me/SKILL.md"
check "3d: нет ~/.agents/context"         expect_absent "$WORK3/.agents/context"

echo ""
echo "--- Test 4: setup.sh --dry-run ---"
HOME="$WORK1" bash "$REPO_DIR/setup.sh" --dry-run >/dev/null
check "4a: dry-run не создаёт файлов" expect_empty_dir "$WORK1"

echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"
[ "$FAIL" -eq 0 ]
