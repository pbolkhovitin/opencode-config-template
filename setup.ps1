#!/usr/bin/env pwsh
# ==============================================================
# setup.ps1 — opencode Multi-Profile Setup for Windows native
# ==============================================================
# Windows-native analog of setup.sh.
# Restores: opencode CLI, default config, named profiles, plugins,
#           PowerShell functions (oc, oc-dev, ...).
#
# Usage (PowerShell, any version 5.1+):
#   .\setup.ps1
#   # or keep a log + result marker for agent control:
#   .\setup.ps1 *> setup.log
#
# Requires: git, gh (GitHub CLI), Node.js + npm.
#   winget install Git.Git GitHub.cli OpenJS.NodeJS.LTS
#   gh auth login   <- required for opencode-synced
# ==============================================================

param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoUrl    = 'https://github.com/YOUR_ORG/my-opencode-config.git'
$DataDir    = Join-Path $env:LOCALAPPDATA 'opencode'
$RepoDir    = Join-Path $DataDir 'opencode-synced\repo'
$ConfigDir  = Join-Path $env:APPDATA 'opencode'
$LogPath    = Join-Path $DataDir 'setup.log'
$ResultPath = Join-Path $DataDir 'setup.result.json'
$Profiles   = @('dev', 'infra', 'net', 'sec', 'ot', 'mgnt')
$Marker     = '# ==== opencode profile aliases ===='
$MarkerEnd  = '# ==== end opencode profile aliases ===='

if ($DryRun) {
    Write-Host 'Dry run — no changes will be made.'
    Write-Host "  repo:   $RepoDir"
    Write-Host "  config: $ConfigDir"
    Write-Host "  profiles: $($Profiles -join ', ')"
    exit 0
}

$script:Status    = 'RUNNING'
$script:ExitCode  = 0
$script:ErrorMsg  = $null

function Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    Write-Host $line
    Add-Content -Path $LogPath -Value $line -Encoding utf8
}

function RefreshPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function WriteResult {
    $res = [ordered]@{
        status     = $script:Status
        exitCode   = $script:ExitCode
        finishedAt = Get-Date -Format o
        error      = $script:ErrorMsg
    }
    $res | ConvertTo-Json | Set-Content -Path $ResultPath -Encoding utf8
    Log "Result marker written: $ResultPath (status=$($script:Status))"
}

function EnsureTool {
    param([string]$Name, [string]$WingetId)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return $true }
    Log "WARN  $Name not found. Try: winget install $WingetId"
    return $false
}

try {
    New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
    Log "=== opencode setup.ps1 (Windows native) ==="
    Log "Repo dir : $RepoDir"
    Log "Config   : $ConfigDir"

    # ---------- Prerequisites ----------
    EnsureTool 'git' 'Git.Git' | Out-Null
    EnsureTool 'gh'  'GitHub.cli' | Out-Null
    EnsureTool 'npm' 'OpenJS.NodeJS.LTS' | Out-Null
    if (-not (Get-Command 'npm' -ErrorAction SilentlyContinue)) {
        Log 'FAIL  Node.js/npm is required. Install and re-run.'
        throw 'npm not found'
    }

    # ---------- opencode CLI ----------
    if (-not (Get-Command 'opencode' -ErrorAction SilentlyContinue)) {
        Log 'opencode not found — installing via npm -g opencode-ai...'
        & npm install -g opencode-ai
        if ($LASTEXITCODE -ne 0) { throw "npm install opencode-ai failed (exit $LASTEXITCODE)" }
        RefreshPath
    }
    $OpenCodeBin = (Get-Command 'opencode' -ErrorAction Stop).Source
    Log "opencode  : $(& opencode --version)  @ $OpenCodeBin"

    # ---------- gh auth ----------
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Log 'WARN  gh is not authenticated. Run "gh auth login" (needed for opencode-synced).'
    } else {
        Log 'gh auth : OK'
    }

    # ---------- Sync repo ----------
    if (Test-Path (Join-Path $RepoDir '.git')) {
        Log 'Syncing existing repo clone...'
        Push-Location $RepoDir
        & git pull --ff-only origin main
        Pop-Location
    } else {
        Log "Cloning repo -> $RepoDir"
        New-Item -ItemType Directory -Force -Path (Split-Path $RepoDir -Parent) | Out-Null
        Push-Location (Split-Path $RepoDir -Parent)
        & git clone --depth 1 $RepoUrl $RepoDir
        Pop-Location
    }
    if ($LASTEXITCODE -ne 0) { throw 'repo clone/pull failed' }

    # ---------- Default profile ----------
    Log 'Configuring default profile...'
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $ConfigDir 'instructions') | Out-Null
    foreach ($f in @('opencode.json', 'opencode.jsonc', 'AGENTS.md')) {
        $src = Join-Path $RepoDir "config\$f"
        if (Test-Path $src) { Copy-Item $src (Join-Path $ConfigDir $f) -Force }
    }
    $srcInstr = Join-Path $RepoDir 'config\instructions'
    if (Test-Path $srcInstr) {
        Copy-Item (Join-Path $srcInstr '*') (Join-Path $ConfigDir 'instructions') -Recurse -Force
    }
    $srcSyncCfg = Join-Path $RepoDir 'opencode-synced.jsonc'
    if (Test-Path $srcSyncCfg) { Copy-Item $srcSyncCfg (Join-Path $ConfigDir 'opencode-synced.jsonc') -Force }

    # ---------- Named profiles ----------
    foreach ($p in $Profiles) {
        $dst = "$ConfigDir-$p"
        $src = Join-Path $RepoDir "profiles\$p"
        if (-not (Test-Path $src)) { Log "SKIP  profile $p (not in repo)"; continue }
        Log "Profile: $p -> $dst"
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        if (Test-Path (Join-Path $src 'opencode.jsonc')) {
            Copy-Item (Join-Path $src 'opencode.jsonc') (Join-Path $dst 'opencode.json') -Force
        }
        if (Test-Path (Join-Path $src 'AGENTS.md')) { Copy-Item (Join-Path $src 'AGENTS.md') $dst -Force }
        foreach ($d in @('prompts', 'instructions')) {
            $srcD = Join-Path $src $d
            if (Test-Path $srcD) { Copy-Item $srcD (Join-Path $dst $d) -Recurse -Force }
        }
    }

    # ---------- Install plugins ----------
    Log 'Installing plugins (per profile via OPENCODE_CONFIG)...'
    $savedCfg = $env:OPENCODE_CONFIG
    try {
        # default profile
        & $OpenCodeBin plugin opencode-synced 2>$null
        # named profiles
        foreach ($p in $Profiles) {
            $cfgFile = "$ConfigDir-$p\opencode.json"
            if (-not (Test-Path $cfgFile)) { continue }
            $raw = Get-Content -Path $cfgFile -Raw -ErrorAction SilentlyContinue
            if (-not $raw) { continue }
            $clean = [regex]::Replace($raw, '(?m)^\s*//.*$', '')
            try { $cfg = $clean | ConvertFrom-Json } catch { Log "WARN  cannot parse $cfgFile"; continue }
            if (-not $cfg.plugin) { continue }
            $env:OPENCODE_CONFIG = $cfgFile
            foreach ($plug in $cfg.plugin) {
                Log "  [$p] plugin $plug"
                & $OpenCodeBin plugin $plug 2>$null
            }
        }
    } finally {
        if ($null -eq $savedCfg) { Remove-Item Env:OPENCODE_CONFIG -ErrorAction SilentlyContinue }
        else { $env:OPENCODE_CONFIG = $savedCfg }
    }

    # ---------- Platform env var ----------
    [Environment]::SetEnvironmentVariable('OPENCODE_PLATFORM', 'windows', 'User')
    $env:OPENCODE_PLATFORM = 'windows'

    # ---------- PowerShell functions ----------
    $profilePath = $PROFILE
    New-Item -ItemType Directory -Force -Path (Split-Path $profilePath -Parent) | Out-Null
    if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath | Out-Null }
    $body = @"
$Marker
function oc      { & opencode @args }
function oc-dev      { & opencodeProfile 'dev' @args }
function oc-infra    { & opencodeProfile 'infra' @args }
function oc-net      { & opencodeProfile 'net' @args }
function oc-mgnt     { & opencodeProfile 'mgnt' @args }
function oc-sec      { & opencodeProfile 'sec' @args }
function opencodeProfile {
    param([string]`$ProfileName, [Parameter(ValueFromRemainingArguments = `$true)]`$ForwardArgs)
    `$old = `$env:OPENCODE_CONFIG
    `$env:OPENCODE_CONFIG = "`$env:APPDATA\opencode-`$ProfileName\opencode.json"
    try { & opencode --standalone --continue @ForwardArgs } finally {
        if (`$null -eq `$old) { Remove-Item Env:OPENCODE_CONFIG -ErrorAction SilentlyContinue }
        else { `$env:OPENCODE_CONFIG = `$old }
    }
}
$MarkerEnd
"@
    $profileContent = if (Test-Path $profilePath) { Get-Content -Path $profilePath -Raw } else { '' }
    if ($profileContent -match [regex]::Escape($Marker)) {
        $pattern = "(?s)$([regex]::Escape($Marker)).*?$([regex]::Escape($MarkerEnd))"
        $profileContent = [regex]::Replace($profileContent, $pattern, { param($m) $body })
    } else {
        $profileContent = ($profileContent.TrimEnd()) + "`n`n" + $body
    }
    Set-Content -Path $profilePath -Value $profileContent -Encoding utf8
    Log "PowerShell functions added to $profilePath"

    # ---------- Verify ----------
    Log '=== Verification ==='
    Log "opencode : $(& opencode --version)"
    foreach ($p in $Profiles) {
        $cfg = "$ConfigDir-$p\opencode.json"
        Log ("  profile {0,-10} {1}" -f $p, $(if (Test-Path $cfg) { 'OK' } else { 'MISSING' }))
    }

    $script:Status = 'OK'
    Log '=== setup.ps1 finished OK ==='
}
catch {
    $script:Status   = 'FAIL'
    $script:ExitCode = 1
    $script:ErrorMsg = $_.Exception.Message
    Log "ERROR $($_.Exception.Message)"
    Write-Host "See log: $LogPath" -ForegroundColor Yellow
}
finally {
    WriteResult
}
exit $script:ExitCode
