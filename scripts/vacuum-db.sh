#!/usr/bin/env bash
# VACUUM the OpenCode SQLite database.
#
# VACUUM rewrites the whole DB and needs exclusive access, so it must run
# while no opencode server/TUI is using the file. The script refuses to run
# if a `serve --service` process is alive.
#
# Usage: scripts/vacuum-db.sh [--dry-run]
set -euo pipefail

DB="${OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}"
BACKUP_DIR="${OPENCODE_BACKUP_DIR:-$HOME/backups/opencode-db}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,9p' "$0"; exit 0
fi

if pgrep -f 'opencode serve --service' >/dev/null; then
  echo "error: opencode server is running; close the TUI and retry" >&2
  exit 1
fi

[[ -f "$DB" ]] || { echo "error: database not found: $DB" >&2; exit 1; }
command -v sqlite3 >/dev/null || { echo "error: sqlite3 not installed" >&2; exit 1; }

before=$(stat -c%s "$DB")
freelist=$(sqlite3 "$DB" 'PRAGMA freelist_count;')
pages=$(sqlite3 "$DB" 'PRAGMA page_count;')
echo "db=$DB size=$((before/1024/1024))MiB pages=$pages freelist=$freelist"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "dry-run: would check integrity, back up, then VACUUM"; exit 0
fi

mkdir -p "$BACKUP_DIR"
backup="$BACKUP_DIR/opencode-$(date +%Y%m%d-%H%M%S).db"
echo "backup: $backup"
sqlite3 "$DB" ".backup '$backup'"

echo "integrity: $(sqlite3 "$DB" 'PRAGMA integrity_check;')"
sqlite3 "$DB" 'VACUUM;'
after=$(stat -c%s "$DB")
echo "done: $((before/1024/1024))MiB -> $((after/1024/1024))MiB, freelist=$(sqlite3 "$DB" 'PRAGMA freelist_count;')"
