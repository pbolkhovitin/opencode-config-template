#!/usr/bin/env bash
# Profiles: default dev infra net sec ot mgnt design
# Deploy opencode config from this repo into a (possibly clean) HOME.
# Usage: deploy-config.sh [--dry-run] <default|dev|infra|net|sec|ot|mgnt>
# Never calls sudo or the network; safe to run twice.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=0
PROFILE=default

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 2 ;;
        *) PROFILE="$arg" ;;
    esac
done

sync_tree() {
    local src="$1" dst="$2"
    [ -d "$src" ] || { echo "skip (missing): $src"; return 0; }
    if [ "$DRY_RUN" = 1 ]; then
        echo "would sync: $src -> $dst"
    else
        mkdir -p "$dst"
        rsync -a --delete "$src/" "$dst/"
        echo "synced: $src -> $dst"
    fi
}

copy_file() {
    local src="$1" dst="$2"
    [ -f "$src" ] || return 0
    if [ "$DRY_RUN" = 1 ]; then
        echo "would copy: $src -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "copied: $src -> $dst"
    fi
}

copy_tree() {
    local src="$1" dst="$2"
    [ -d "$src" ] || { echo "skip (missing): $src"; return 0; }
    if [ "$DRY_RUN" = 1 ]; then
        echo "would copy tree: $src -> $dst"
    else
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
        echo "copied tree: $src -> $dst"
    fi
}

if [ "$PROFILE" = "default" ]; then
    DEST="$CONFIG_HOME/opencode"
    copy_file "$REPO_DIR/config/opencode.json" "$DEST/opencode.json"
    copy_file "$REPO_DIR/config/AGENTS.md" "$DEST/AGENTS.md"
    sync_tree "$REPO_DIR/config/instructions" "$DEST/instructions"
    sync_tree "$REPO_DIR/config/command" "$DEST/command"
    sync_tree "$REPO_DIR/config/skills" "$DEST/skills"
else
    SRC="$REPO_DIR/profiles/$PROFILE"
    [ -d "$SRC" ] || { echo "Unknown profile: $PROFILE" >&2; exit 2; }
    DEST="$CONFIG_HOME/opencode-$PROFILE"
    copy_file "$SRC/opencode.jsonc" "$DEST/opencode.json"
    copy_file "$SRC/AGENTS.md" "$DEST/AGENTS.md"
    copy_file "$SRC/package.json" "$DEST/package.json"
    sync_tree "$SRC/instructions" "$DEST/instructions"
    sync_tree "$SRC/prompts" "$DEST/prompts"
    sync_tree "$SRC/command" "$DEST/command"
    # Shared skills and instructions live once in the default profile.
    sync_tree "$REPO_DIR/config/skills" "$CONFIG_HOME/opencode/skills"
    sync_tree "$REPO_DIR/config/instructions" "$CONFIG_HOME/opencode/instructions"
fi

# Local plugins live in the global config dir and are shared by all profiles.
copy_tree "$REPO_DIR/config/plugins" "$CONFIG_HOME/opencode/plugins"
