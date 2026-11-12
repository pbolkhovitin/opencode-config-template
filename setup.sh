#!/usr/bin/env bash
set -euo pipefail

# ==============================================================
# setup.sh — opencode Multi-Profile Recovery Script
# ==============================================================
# One-command recovery for a clean system.
# Restores: opencode CLI, configs, profiles, plugins, aliases,
#           and all required CLI tools (pip, dnf/apt/brew, binary).
#
# Usage:
#   gh repo clone YOUR_ORG/my-opencode-config && cd my-opencode-config && bash setup.sh
#   # or with gh auth token:
#   curl -fsSL -H "Authorization: token \$(gh auth token)" https://raw.githubusercontent.com/YOUR_ORG/my-opencode-config/main/setup.sh | bash
#   # or locally (after clone):
#   bash setup.sh
#
# Requires: git, curl, Node.js >= 18, python3, sudo
# Install Node.js: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash && sudo apt install -y nodejs
# ==============================================================

REPO_URL="https://github.com/YOUR_ORG/my-opencode-config.git"
REPO_BRANCH="main"
REPO_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode-synced/repo"
OPENCODE_BIN="${HOME}/.opencode/bin/opencode"
OPENCODE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
LOCAL_BIN="${HOME}/.local/bin"

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '3,20p' "$0"; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# ---------- Colors ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }
step()  { echo; echo -e "${BLUE}━━━ $(printf '%2s' $1) ━━━${NC}"; }

if [ "$DRY_RUN" = 1 ]; then
    cat <<EOF
Dry run — no changes will be made.
  repo:      $REPO_DIR
  opencode:  $OPENCODE_BIN
  config:    $OPENCODE_CONFIG
  profiles:  dev infra net sec ot mgnt design
  actions:
    - install/verify opencode CLI
    - clone or update config repo
    - deploy default config, instructions and skills (config/skills)
    - deploy named profiles (.jsonc -> opencode.json)
    - install GitLab/GitHub MCP Vault launchers (gitlab-mcp-vault, github-mcp-vault)
    - install plugins and CLI tools
EOF
    exit 0
fi

mkdir -p "$LOCAL_BIN"

if [[ -f "$REPO_DIR/scripts/ocp" ]]; then
    install -m755 "$REPO_DIR/scripts/ocp" "$LOCAL_BIN/ocp"
    ok "ocp installed to $LOCAL_BIN"
fi

if [[ -f "$REPO_DIR/scripts/gitlab-mcp-vault" ]]; then
    install -m755 "$REPO_DIR/scripts/gitlab-mcp-vault" "$LOCAL_BIN/gitlab-mcp-vault"
    ok "gitlab-mcp-vault installed to $LOCAL_BIN"
fi

if [[ -f "$REPO_DIR/scripts/github-mcp-vault" ]]; then
    install -m755 "$REPO_DIR/scripts/github-mcp-vault" "$LOCAL_BIN/github-mcp-vault"
    ok "github-mcp-vault installed to $LOCAL_BIN"
fi

# ---------- Package manager detection ----------
detect_pm() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    else
        echo "unknown"
    fi
}

pm_install() {
    local pm=$(detect_pm)
    local logfile="/tmp/setup-install.log"
    case "$pm" in
        dnf)  sudo dnf install -y "$@" 2>>"$logfile" ;;
        apt)  sudo DEBIAN_FRONTEND=noninteractive apt install -y "$@" 2>>"$logfile" ;;
        brew) brew install "$@" 2>>"$logfile" ;;
        *)    warn "Unknown package manager. Install $* manually." ;;
    esac
}

# ---------- Preflight ----------
# ---------- WSL detection ----------
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
    echo -e "${BLUE}[WSL]${NC}  WSL environment detected — applying WSL-specific setup"
fi

step "1/12 — Dependency check"
for cmd in git curl node npm; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Missing: $cmd. Install via system package manager."
done

NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
[ "$NODE_VER" -ge 18 ] || fail "Node.js >= 18 required (current: $(node -v))"

command -v python3 >/dev/null 2>&1 && ok "python3 found" || warn "python3 not found — pip/uvx packages skipped"
command -v sudo >/dev/null 2>&1 && ok "sudo found" || warn "sudo not found — system packages skipped"
command -v unzip >/dev/null 2>&1 || warn "unzip not found — binary installs may fail"

ok "All base dependencies present"

# ---------- Install opencode CLI ----------
step "2/12 — Installing opencode CLI"
if command -v opencode >/dev/null 2>&1; then
    info "opencode already installed: $(opencode --version 2>/dev/null || echo 'unknown')"
    OPENCODE_BIN=$(command -v opencode)
else
    info "Downloading opencode..."
    curl -fsSL https://opencode.ai/install | bash
    command -v opencode >/dev/null 2>&1 || fail "Failed to install opencode CLI"
    OPENCODE_BIN=$(command -v opencode)
    ok "opencode $(opencode --version) installed"
fi

# Add paths for current session
for p in "$HOME/.opencode/bin" "$LOCAL_BIN"; do
    if ! echo "$PATH" | tr ':' '\n' | grep -q "$p"; then
        export PATH="$p:$PATH"
    fi
done

# ---------- Clone / update config repo ----------
step "3/12 — Cloning config repository"
AUTH_URL="https://YOUR_ORG:$(gh auth token)@github.com/YOUR_ORG/my-opencode-config.git"
if [ -d "$REPO_DIR/.git" ]; then
    info "Repository exists, updating..."
    git -C "$REPO_DIR" remote set-url origin "$AUTH_URL"
    git -C "$REPO_DIR" fetch origin "$REPO_BRANCH"
    git -C "$REPO_DIR" reset --hard "origin/$REPO_BRANCH"
    git -C "$REPO_DIR" remote set-url origin "$REPO_URL"
    ok "Repository updated"
else
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --branch "$REPO_BRANCH" "$AUTH_URL" "$REPO_DIR"
    ok "Repository cloned to $REPO_DIR"
fi

# ---------- Default profile + opencode-synced ----------
step "4/12 — Setting up default profile + opencode-synced"
mkdir -p "$OPENCODE_CONFIG/instructions"

if grep -q '"opencode-synced"' "$OPENCODE_CONFIG/opencode.json" 2>/dev/null; then
    info "opencode-synced already in default profile"
elif [ -f "$REPO_DIR/config/opencode.json" ]; then
    cp "$REPO_DIR/config/opencode.json" "$OPENCODE_CONFIG/opencode.json"
    ok "  default config deployed from repo"
else
    cat > "$OPENCODE_CONFIG/opencode.json" << 'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "plugins": ["opencode-synced"],
  "instructions": ["instructions/russian.md", "instructions/workflow.md", "instructions/rules.md"]
}
JSON
    info "Created minimal default config"
fi
if [ -d "$REPO_DIR/config/instructions" ]; then
    rsync -a "$REPO_DIR/config/instructions/" "$OPENCODE_CONFIG/instructions/"
    ok "  instructions/ deployed"
fi
if [ -d "$REPO_DIR/config/plugins" ]; then
    mkdir -p "$OPENCODE_CONFIG/plugins"
    cp -a "$REPO_DIR/config/plugins/." "$OPENCODE_CONFIG/plugins/"
    ok "  plugins/ deployed (shared by all profiles)"
fi

if [ ! -f "$OPENCODE_CONFIG/opencode-synced.jsonc" ]; then
    "$OPENCODE_BIN" plugin add opencode-synced 2>/dev/null || true
fi
cp "$REPO_DIR/opencode-synced.jsonc" "$OPENCODE_CONFIG/opencode-synced.jsonc" 2>/dev/null || true
[ -d "$REPO_DIR/config/command" ] && cp -r "$REPO_DIR/config/command" "$OPENCODE_CONFIG/" && ok "  command/ copied to default"
ok "Default profile configured"

# ---------- Install default plugins ----------
# v2-совместимые плагины (v1-only: vibeguard, swarm, websearch-cited, notify,
# worktree, antigravity-auth, firecrawl — убраны; opencode-notify retired);
# supermemory/pty/gemini-auth подключаются через сабпуть /server, /v2 в профилях.
step "5/12 — Installing default profile plugins"
PLUGINS_DEFAULT=(
    "opencode-supermemory@latest"
    "@tarquinen/opencode-dcp@latest"
)
for plugin in "${PLUGINS_DEFAULT[@]}"; do
    info "Installing: $plugin"
    "$OPENCODE_BIN" plugin add "$plugin" 2>/dev/null || warn "Failed to install $plugin"
done
ok "Default profile plugins installed"

# ---------- opencode-notify (RETIRED — v2-native настройки) ----------
# V1-плагин opencode-notify официально retired (v2-порт не планируется).
# В v2 уведомления — встроенные: cli.json → attention.notifications / attention.sound.
# Ниже — только совместимость-настройка для старых v1-профилей; создаём файл опционально.
NOTIFY_CONFIG="$OPENCODE_CONFIG/opencode-notify.json"
if [ ! -f "$NOTIFY_CONFIG" ]; then
    cat > "$NOTIFY_CONFIG" << 'JSON'
{
  "terminal": null,
  "notifyOnIdle": true
}
JSON
    info "opencode-notify.json created (legacy v1 — для v2 используйте cli.json attention.*)"
else
    info "opencode-notify.json exists — skipping"
fi

# ---------- shell-strategy ----------
# Instruction removed: upstream shell_strategy.md is no longer vendored, and an
# absolute path in `instructions` breaks portability. Re-add only with a repo-relative file.
# ---------- Setup named profiles ----------
step "6/12 — Setting up profiles: dev, infra, net, sec, ot, mgnt, design"
setup_profile() {
    local name="$1"
    local config_dir="${OPENCODE_CONFIG}-${name}"
    local repo_profile="$REPO_DIR/profiles/$name"
    info "Profile: $name -> $config_dir"
    mkdir -p "$config_dir"
    cp "$repo_profile/opencode.jsonc" "$config_dir/opencode.json" 2>/dev/null || warn "  No opencode.jsonc for $name"
    [ -f "$repo_profile/AGENTS.md" ] && cp "$repo_profile/AGENTS.md" "$config_dir/" || true
    [ -d "$repo_profile/prompts" ] && cp -r "$repo_profile/prompts" "$config_dir/" && ok "  prompts/ copied"
    [ -d "$repo_profile/instructions" ] && cp -r "$repo_profile/instructions" "$config_dir/" && ok "  instructions/ copied"
    [ -d "$repo_profile/command" ] && cp -r "$repo_profile/command" "$config_dir/" && ok "  command/ copied"
}
for profile in dev infra net sec ot mgnt design; do setup_profile "$profile"; done
ok "All profiles configured"

# ---------- Install profile plugins ----------
step "7/12 — Installing profile plugins"
install_profile_plugins() {
    local name="$1"
    local config_dir="${OPENCODE_CONFIG}-${name}"
    local config_file="$config_dir/opencode.json"
    [ ! -f "$config_file" ] && { warn "  No config for $name, skipping"; return; }
    local plugins
    plugins=$(python3 -c "
import json, sys, re
with open('$config_file') as f:
    content = f.read()
content = re.sub(r'//.*', '', content)
d = json.loads(content)
print('\n'.join(d.get('plugins', d.get('plugin', []))))
" 2>/dev/null || echo "")
    [ -z "$plugins" ] && { ok "  No plugins for $name"; return; }
    while IFS= read -r plugin; do
        [ -z "$plugin" ] && continue
        info "  [$name] Installing: $plugin"
        OPENCODE_CONFIG="$config_file" "$OPENCODE_BIN" plugin add "$plugin" 2>/dev/null || \
            warn "  [$name] Failed to install $plugin (will auto-install on first run)"
    done <<< "$plugins"
    ok "  Plugins for $name installed"
}
for profile in dev infra net sec ot mgnt design; do install_profile_plugins "$profile"; done
ok "All profile plugins installed"

# ================================================================
#   CLI Tools — from all 5 profile AGENTS.md + README.md
# ================================================================
step "8/12 — Installing CLI tools"
PM=$(detect_pm)
info "Package manager: $PM"

# --- 8a. System packages (dnf/apt/brew) ---
# Source: default + infra AGENTS.md ("Системные утилиты") + sec AGENTS.md ("Системные утилиты")
# + user's CTF install command
SYSTEM_PACKAGES=(
    # === Network scanning & recon ===
    nmap nmap-ncat masscan arp-scan hping3 gobuster
    # === Password auditing ===
    john hashcat hydra
    # === Reverse engineering & debugging ===
    gdb radare2 rizin
    # === Forensics & data recovery ===
    binwalk foremost steghide sleuthkit testdisk
    # === Network analysis / diagnostics ===
    wireshark tshark socat tcpdump mtr iperf3 ethtool lldpd nethogs iftop
    # === DNS / WHOIS ===
    bind-utils whois
    # === Anonymity & spoofing ===
    tor proxychains-ng macchanger
    # === Wireless ===
    aircrack-ng
    # === Sandbox / cleanup ===
    firejail bleachbit
    # === Dev / scripting ===
    jq
    # === CTF build toolchain ===
    ruby golang
)

info "Installing system packages (${#SYSTEM_PACKAGES[@]} total)..."
pm_install "${SYSTEM_PACKAGES[@]}" && ok "System packages installed" || warn "Some system packages failed (see /tmp/setup-install.log)"

# --- 8a2. v1 notify deps (only for legacy v1 profiles) ---
# opencode-notify retired; deps нужны только если остался v1-контур. Для v2 не требуются.
if [ "$IS_WSL" = false ] && [ -d "$HOME/.config/opencode/opencode-notify.json" ]; then
    info "Installing opencode-notify deps (legacy v1): xdotool wmctrl libdbus-1-dev..."
    pm_install xdotool wmctrl libdbus-1-dev && ok "opencode-notify deps installed" || \
        warn "Failed to install opencode-notify deps — focus detection / focusAfterAction won't work"

    # Best-effort: node-dbus-notifier даёт action-кнопки на попапах (вместо голого notify-send).
    NOTIFY_PKG_DIR="$HOME/.cache/opencode/packages/opencode-notify@latest/node_modules/opencode-notify"
    if [ -d "$NOTIFY_PKG_DIR" ] && [ ! -d "$NOTIFY_PKG_DIR/node_modules/node-dbus-notifier" ]; then
        info "Installing node-dbus-notifier (action buttons on popups)..."
        (cd "$NOTIFY_PKG_DIR" && npm install node-dbus-notifier --no-audit --no-fund >/dev/null 2>&1) && \
            ok "node-dbus-notifier installed (popup action buttons enabled)" || \
            warn "node-dbus-notifier install failed — popups shown without action buttons"
    fi
fi

# --- 8b. pip3 packages ---
# Source: dev + infra AGENTS.md
if command -v pip3 >/dev/null 2>&1; then
    info "Python packages (pip3)..."
    PIP_PACKAGES=(
        # === CTF exploit development ===
        pwntools
        # === Packet manipulation ===
        scapy
        # === SQL injection ===
        sqlmap
        # === HTTP / HTML ===
        requests beautifulsoup4
        # === Cryptography ===
        pycryptodomex
        # === Configuration management ===
        ansible ansible-mcp
    )
    for pkg in "${PIP_PACKAGES[@]}"; do
        python3 -c "import importlib.metadata; importlib.metadata.version('$pkg')" 2>/dev/null && \
            info "  $pkg already installed" || \
            { pip3 install --user "$pkg" 2>/dev/null && ok "  $pkg installed" || warn "  $pkg install failed"; }
    done
    ok "Python packages installed"
else
    warn "pip3 not found — Python packages skipped"
fi

# --- 8c. uv (for uvx proxmox-mcp-server, ssh-mcp) ---
# Source: default AGENTS.md (proxmox/ssh MCP tools use uvx)
if ! command -v uv >/dev/null 2>&1; then
    info "Installing uv (Python package installer)..."
    curl -fsSL https://astral.sh/uv/install.sh | sh
    if [ -f "$HOME/.local/bin/uv" ]; then
        export PATH="$HOME/.local/bin:$PATH"
        ok "uv $(uv --version) installed"
    else
        warn "uv install failed — needed for uvx proxmox-mcp-server"
    fi
else
    ok "uv already installed: $(uv --version)"
fi

# --- 8d. OpenTofu (binary) ---
# Source: infra AGENTS.md ("IaC")
if ! command -v tofu >/dev/null 2>&1; then
    info "Installing OpenTofu..."
    ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    TMPD=$(mktemp -d)
    TOFU_URL="https://github.com/opentofu/opentofu/releases/latest/download/tofu_${ARCH}.zip"
    if curl -fsSL "$TOFU_URL" -o "${TMPD}/tofu.zip" 2>/dev/null; then
        unzip -qo "${TMPD}/tofu.zip" -d "$TMPD" 2>/dev/null
        install -m755 "${TMPD}/tofu" "$LOCAL_BIN/tofu"
        rm -rf "${TMPD}"
        ok "OpenTofu $(tofu --version | head -1) installed"
    else
        rm -rf "${TMPD}"
        warn "OpenTofu download failed (infra profile)"
    fi
else
    ok "OpenTofu already installed: $(tofu --version | head -1)"
fi

# --- 8e. kubectl binary fallback (if dnf failed) ---
# Source: infra AGENTS.md (kubernetes MCP)
if ! command -v kubectl >/dev/null 2>&1; then
    info "Installing kubectl (binary fallback)..."
    ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    KUBE_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.32.0")
    curl -fsSL "https://dl.k8s.io/release/${KUBE_VER}/bin/linux/${ARCH}/kubectl" -o "$LOCAL_BIN/kubectl" && \
        chmod +x "$LOCAL_BIN/kubectl" && ok "kubectl installed" || warn "kubectl binary download failed"
fi

# --- 8f. Playwright (browser automation) ---
# Source: default + dev + mgnt + sec profiles (playwright MCP)
if ! npx playwright --version 2>/dev/null; then
    info "Installing Playwright (Firefox)..."
    npx playwright install firefox 2>/dev/null && ok "Playwright installed (Firefox)" || warn "Playwright install failed"
else
    ok "Playwright already installed"
fi

# --- Deploy askpass for secure sudo ---
info "Deploying secure askpass..."
ASKPASS_SRC="$REPO_DIR/scripts/askpass.sh"
ASKPASS_DST="$LOCAL_BIN/opencode-askpass"
if [ -f "$ASKPASS_SRC" ]; then
    cp "$ASKPASS_SRC" "$ASKPASS_DST"
    chmod 755 "$ASKPASS_DST"
    ok "askpass deployed to $ASKPASS_DST"
else
    warn "askpass.sh not found in repo"
fi

# --- Add paths to .zshrc ---
for entry in '$HOME/.local/bin' '$HOME/.opencode/bin'; do
    dir_eval=$(eval echo "$entry")
    if ! grep -qF "$dir_eval" "$HOME/.zshrc" 2>/dev/null; then
        echo "export PATH=\"$entry:\$PATH\"" >> "$HOME/.zshrc"
        info "Added $entry to PATH in .zshrc"
    fi
done

# --- Set SUDO_ASKPASS ---
if ! grep -q "SUDO_ASKPASS" "$HOME/.zshrc" 2>/dev/null; then
    {
        echo ""
        echo "# Secure sudo: askpass reads password from /dev/tty, never captured by opencode"
        echo "export SUDO_ASKPASS=\"$HOME/.local/bin/opencode-askpass\""
    } >> "$HOME/.zshrc"
    info "SUDO_ASKPASS added to .zshrc"
fi
export SUDO_ASKPASS="$HOME/.local/bin/opencode-askpass"

ok "CLI tools installed"

# ---------- WSL-specific setup ----------
if [ "$IS_WSL" = true ]; then
    step "9/12 — WSL-specific configuration"

    # Set WSL env vars
    RC_FILE="$HOME/.zshrc"
    WSL_BLOCK='
# ---------- opencode WSL ----------
export OPENCODE_PLATFORM="wsl"
export OPENCODE_HOME="$HOME"
export OPENCODE_ALLOWED_DIRS="$HOME"
'
    if ! grep -q "OPENCODE_PLATFORM" "$RC_FILE" 2>/dev/null; then
        echo "$WSL_BLOCK" >> "$RC_FILE"
        ok "WSL env vars added to .zshrc"
    fi
    export OPENCODE_PLATFORM="wsl"
    export OPENCODE_HOME="$HOME"
    export OPENCODE_ALLOWED_DIRS="$HOME"

    # SSH agent for WSL
    if ! grep -q "SSH_AUTH_SOCK" "$RC_FILE" 2>/dev/null; then
        cat >> "$RC_FILE" << 'SSH'

# SSH agent (WSL)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519_github_yandex 2>/dev/null || true
fi
SSH
        ok "SSH agent auto-start added to .zshrc"
    fi

    # Docker check
    if command -v docker &>/dev/null && docker ps &>/dev/null; then
        ok "Docker working (Docker Desktop WSL integration)"
    else
        warn "Docker not available. Enable: Docker Desktop → Settings → Resources → WSL Integration"
    fi

    # git autocrlf for WSL
    if [ "$(git config --global core.autocrlf 2>/dev/null || echo 'unset')" = "unset" ]; then
        git config --global core.autocrlf input 2>/dev/null || true
        ok "git core.autocrlf set to input (WSL)"
    fi

    ok "WSL configuration complete"
fi

# ---------- swarm.json (legacy v1 — swarm v2-порт отсутствует) ----------
step "10/12 — Setting up opencode-swarm.json (legacy v1)"
BACKUP_SWARM="$HOME/.config/opencode/opencode-swarm.json"
if [ -f "$BACKUP_SWARM" ]; then
    info "opencode-swarm.json exists ($(wc -l < "$BACKUP_SWARM") lines)"
else
    info "Generating default opencode-swarm.json..."
    mkdir -p "$(dirname "$BACKUP_SWARM")"
    cat > "$BACKUP_SWARM" << 'JSON'
{
  "$schema": "https://opencode.ai/swarm.json",
  "agents": {
    "architect": { "model": "opencode/big-pickle", "temperature": 0.1 },
    "coder": { "model": "opencode/big-pickle", "temperature": 0.2 },
    "reviewer": { "model": "opencode/big-pickle", "temperature": 0.1 },
    "explorer": { "model": "opencode/big-pickle", "temperature": 0.3 },
    "test-engineer": { "model": "opencode/big-pickle", "temperature": 0.1 },
    "sme": { "model": "opencode/big-pickle", "temperature": 0.1 },
    "docs": { "model": "opencode/big-pickle", "temperature": 0.1 }
  }
}
JSON
    ok "Default swarm.json created (customize with your 14 subagents later)"
fi

# ---------- skills ----------
step "11/12 — Syncing skills"
SKILLS_SRC="$REPO_DIR/config/skills"
SKILLS_DST="$OPENCODE_CONFIG/skills"
if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DST"
    rsync -a --delete "$SKILLS_SRC/" "$SKILLS_DST/"
    ok "Skills synced to $SKILLS_DST"
    if [ ! -e "$HOME/.agents/skills" ]; then
        mkdir -p "$HOME/.agents"
        ln -sfn "$SKILLS_DST" "$HOME/.agents/skills"
        info "Symlinked ~/.agents/skills -> $SKILLS_DST"
    fi
else
    warn "No skills directory found in repo (config/skills)"
fi

# ---------- zsh aliases ----------
# ---------- env vars check ----------
step "12/12 — Checking required env vars"
REQUIRED_ENV=(
    "DATABASE_URL"
    "PROXMOX_TOKEN_VALUE"
)
MISSING=()
for var in "${REQUIRED_ENV[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING+=("$var")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    warn "Missing environment variables:"
    for var in "${MISSING[@]}"; do
        echo "    $var"
    done
    echo ""
    info "Add them to your shell rc file, e.g.:"
    echo '    echo "export DATABASE_URL=\"postgresql://user:pass@host/db\"" >> ~/.zshrc'
    echo "    source ~/.zshrc"
    echo ""
else
    ok "All required env vars are set"
fi
info "GitLab/GitHub tokens are read from Vault (agent-vault, instance personal) — their env vars are not required."

# ---------- zsh aliases ----------
ZSHRC="$HOME/.zshrc"
ALIASES_BLOCK='
# ---------- opencode profile aliases (OPENCODE_CONFIG + --standalone + --continue) ----------
# oc: интерактивный запуск продолжает последнюю сессию; подкоманды — без флагов
oc() {
    case "${1:-}" in
        session|models|mcp|plugin|auth|debug|stats|api|serve|run|upgrade|uninstall|mini|reload|pair|service|acp)
            command opencode "$@" ;;
        *) command opencode --continue "$@" ;;
    esac
}
alias oc-dev="OPENCODE_CONFIG=~/.config/opencode-dev/opencode.json opencode --standalone --continue"
alias oc-infra="OPENCODE_CONFIG=~/.config/opencode-infra/opencode.json opencode --standalone --continue"
alias oc-net="OPENCODE_CONFIG=~/.config/opencode-net/opencode.json opencode --standalone --continue"
alias oc-mgnt="OPENCODE_CONFIG=~/.config/opencode-mgnt/opencode.json opencode --standalone --continue"
alias oc-sec="OPENCODE_CONFIG=~/.config/opencode-sec/opencode.json opencode --standalone --continue"
alias oc-ot="OPENCODE_CONFIG=~/.config/opencode-ot/opencode.json opencode --standalone --continue"
alias oc-design="OPENCODE_CONFIG=~/.config/opencode-design/opencode.json opencode --standalone --continue"
alias ocp="~/.local/bin/ocp"
'
if grep -q "alias oc-infra=" "$ZSHRC" 2>/dev/null; then
    info "Aliases already present"
else
    echo "$ALIASES_BLOCK" >> "$ZSHRC"
    ok "Aliases added to $ZSHRC"
    info "Apply: source $ZSHRC"
fi

# ================================================================
#   Summary
# ================================================================
echo ""
echo "=============================================================="
echo -e "${GREEN}  Setup complete!${NC}"
echo "=============================================================="
echo ""
echo "  Profiles:"
echo "    oc           - default (без MCP, встроенные build/plan)"
echo "    oc-dev       - dev (мультиязычная разработка + security tooling + TDD)"
echo "    oc-infra     - infra (Proxmox, Ansible, OpenTofu, K8s, MLOps, GitOps, SRE)"
echo "    oc-net       - net (сети, маршрутизация, firewall, VPN, MikroTik/OpenWrt/pfSense)"
echo "    oc-mgnt      - management (PRD, data analysis, UAT)"
echo "    oc-sec       - security (CTF, pentest, forensics, RE)"
echo "    oc-ot        - OT/ICS (АСУ ТП сети, пассивный режим по умолчанию)"
echo "    oc-design    - design (UI/UX, вёрстка, скриншот-приёмка, генерация картинок)"
echo ""
echo "  Security:"
echo "    Network:      nmap, nmap-ncat, masscan, arp-scan, hping3, gobuster, socat, wireshark"
echo "    DNS/WHOIS:    bind-utils, whois"
echo "    Password:     john, hashcat, hydra"
echo "    RE/DBG:       gdb, radare2, rizin"
echo "    Forensics:    binwalk, foremost, steghide, sleuthkit, testdisk"
echo "    Anonymity:    tor, proxychains-ng, macchanger"
echo "    Sandbox:      firejail, bleachbit"
echo "    Wireless:     aircrack-ng"
echo "    Toolchain:    jq, ruby, golang"
echo ""
echo "  Python (pip3):"
echo "    CTF:          pwntools, scapy, sqlmap, pycryptodomex"
echo "    HTTP/HTML:    requests, beautifulsoup4"
echo "    Infra:        ansible, ansible-mcp"
echo ""
echo "  Binary:         OpenTofu, kubectl, uv/uvx"
echo "  Npx:            Playwright (Firefox)"
echo "  Askpass:        opencode-askpass (secure sudo via /dev/tty)"
echo ""
echo "  Env vars (set before use):"
echo "    DATABASE_URL, PROXMOX_TOKEN_VALUE"
echo "    GITLAB_WORK_API_URL (optional; default https://gitlab.example.com/api/v4)"
echo "    GITLAB_OFFICIAL_YANDEX_API_URL, GITLAB_OFFICIAL_GMAIL_API_URL, GITLAB_PERSONAL_API_URL (optional)"
echo ""
echo "  GitLab MCP:     gitlab-mcp-vault <yandex|gmail|work|personal> [--check|--check-api]"
echo "  GitHub MCP:     github-mcp-vault [--check|--check-api] (PAT из Vault, Docker image)"
echo "  Manual:         API keys, swarm.json"
echo "  Skills:         synced from config/skills to ~/.config/opencode/skills (allowlist per profile)"
echo ""
echo "=============================================================="
