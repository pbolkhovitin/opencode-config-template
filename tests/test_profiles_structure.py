"""Структурные инварианты профилей OpenCode.

Проверяет канонический набор профилей после реструктуризации
(default/dev/infra/net/sec/ot/mgnt), модели, скиллы, агентов и документацию.
"""

import re
from pathlib import Path

from tests.validate_configs import load_jsonc

ROOT = Path(__file__).resolve().parents[1]
PROFILES_DIR = ROOT / "profiles"
SKILLS_DIR = ROOT / "config" / "skills"

CANONICAL = {"dev", "infra", "net", "sec", "ot", "mgnt", "design"}
REMOVED = {"devops", "fullstack", "sec-lm"}

REQUIRED_AGENTS = {
    "dev": {
        "feature-planner",
        "code-architect",
        "senior-python-dev",
        "senior-js-ts-dev",
        "senior-php-dev",
        "senior-cpp-dev",
        "senior-java-dev",
        "senior-go-dev",
        "senior-rust-dev",
        "senior-nextjs-dev",
        "appsec-auditor",
        "security-tool-developer",
        "code-reviewer",
        "platform-engineer",
    },
    "infra": {
        "infra-engineer",
        "sre",
        "mlops-engineer",
        "gitops-engineer",
        "security-auditor",
        "devops-reviewer",
    },
    "net": {
        "network-engineer",
        "network-security",
        "bgp-ospf-analyst",
        "packet-analyst",
    },
    "sec": {
        "ctf-reverse-engineer",
        "ctf-pwner",
        "ctf-web-hacker",
        "pentester",
        "appsec-auditor",
        "threat-intel",
    },
    "ot": {
        "ot-recon",
        "ot-protocol-analyst",
        "ot-segmentation-reviewer",
        "ot-vuln-researcher",
        "ot-incident-responder",
        "ot-network-designer",
    },
    "mgnt": {"prd-writer", "incident-commander", "data-analyst"},
    "design": {"ui-designer", "visual-qa"},
}

REQUIRED_MCP = {
    "dev": {
        "docker",
        "filesystem",
        "gitlab-official-yandex",
        "gitlab-work",
        "gitlab-personal",
        "github",
        "playwright",
        "postgres",
        "ssh",
        "duckduckgo",
    },
    "infra": {
        "proxmox",
        "ansible",
        "gitlab-official-yandex",
        "gitlab-work",
        "gitlab-personal",
        "opentofu",
        "docker",
        "ssh",
        "postgres",
    },
    "net": {"ssh", "docker", "filesystem", "duckduckgo"},
    "sec": {"ssh", "docker"},
    "ot": {"ssh", "docker", "filesystem", "proxmox"},
    "mgnt": {"docker", "playwright", "postgres", "ssh"},
    "design": {"chrome-devtools", "playwright", "shadcn", "mermaid", "duckduckgo", "figma"},
}

# name -> (launcher instance, disabled by default)
GITLAB_SERVERS = {
    "gitlab-official-yandex": ("yandex", False),
    "gitlab-work": ("work", False),
    "gitlab-personal": ("personal", True),
}

REQUIRED_NET_SKILLS = {
    "active-network-recon",
    "network-101",
    "mikrotik-routeros-rsc",
    "routeros-fundamentals",
    "configuring-pfsense-firewall-rules",
    "homelab-vlan-segmentation",
    "openwrt-config",
    "openwrt-procd-init",
    "openwrt-image-build",
    "podkop-openwrt-guide",
    "enumerating-network-services",
    "analyzing-network-traffic-with-wireshark",
    "traffic-analysis-pcap",
    "wireshark-analysis",
}


def _profile_dirs() -> set[str]:
    return {p.name for p in PROFILES_DIR.iterdir() if p.is_dir()}


def _cfg(profile: str) -> dict:
    return load_jsonc(PROFILES_DIR / profile / "opencode.jsonc")


def test_canonical_profile_set():
    assert _profile_dirs() == CANONICAL


def test_removed_profiles_are_gone():
    assert not (_profile_dirs() & REMOVED)
    for name in REMOVED:
        assert not (PROFILES_DIR / name).exists(), name


def test_every_profile_uses_same_model():
    models = set()
    for profile in CANONICAL:
        cfg = _cfg(profile)
        assert cfg["model"] == cfg["small_model"], profile
        models.add(cfg["model"])
    assert len(models) == 1, f"profiles must share one model, got {sorted(models)}"


def test_every_profile_has_shared_skills_path_and_allowlist():
    for profile in CANONICAL:
        cfg = _cfg(profile)
        assert cfg["skills"]["paths"] == ["~/.config/opencode/skills"], profile
        allow = cfg["permission"]["skill"]
        assert allow["*"] == "deny", profile


def test_allowlist_entries_point_to_vendored_skills():
    vendored = {p.name for p in SKILLS_DIR.iterdir() if (p / "SKILL.md").is_file()}
    for profile in CANONICAL:
        allow = _cfg(profile)["permission"]["skill"]
        missing = {name for name in allow if name != "*" and name not in vendored}
        assert not missing, f"{profile}: allowlist references unknown skills: {sorted(missing)}"


def test_required_agents_and_personas_exist():
    for profile, expected in REQUIRED_AGENTS.items():
        cfg = _cfg(profile)
        agents = set(cfg["agent"])
        assert expected <= agents, f"{profile}: missing agents {sorted(expected - agents)}"
        for name in agents:
            prompt = cfg["agent"][name].get("prompt", "")
            match = re.search(r"\{file:\./(.+?)\}", prompt)
            if match:
                assert (PROFILES_DIR / profile / match.group(1)).is_file(), (
                    f"{profile}/{name}: prompt file {match.group(1)} not found"
                )


def test_required_mcp_servers():
    for profile, expected in REQUIRED_MCP.items():
        servers = set(_cfg(profile)["mcp"]["servers"])
        assert expected <= servers, f"{profile}: missing MCP {sorted(expected - servers)}"


def test_gitlab_servers_are_configured_for_dev_and_infra():
    for profile in ("dev", "infra"):
        servers = _cfg(profile)["mcp"]["servers"]
        for name, (instance, disabled) in GITLAB_SERVERS.items():
            server = servers[name]
            assert server["type"] == "local", f"{profile}/{name}"
            assert server["disabled"] is disabled, f"{profile}/{name}"
            assert server["command"] == ["gitlab-mcp-vault", instance], f"{profile}/{name}"
            assert not any(
                token.startswith("glpat-") for token in server.get("environment", {}).values()
            ), f"{profile}/{name}: token must come from Vault, not config"
    for profile in CANONICAL - {"dev", "infra"}:
        assert not {n for n in _cfg(profile)["mcp"]["servers"] if n.startswith("gitlab")}, profile


def test_gitlab_vault_launcher_uses_central_vault():
    launcher = ROOT / "scripts" / "gitlab-mcp-vault"
    assert launcher.is_file()
    assert launcher.stat().st_mode & 0o111, "gitlab-mcp-vault must be executable"

    text = launcher.read_text(encoding="utf-8")
    assert 'use "$secret"' in text
    assert "agent-vault" in text
    assert "--project" in text and "--instance" in text
    assert "central" in text
    assert "gitlab official yandex pat" in text
    assert "gitlab official gmail pat" in text
    assert "gitlab personal pat" in text
    assert "gitlab.internal.example.com" in text or "GITLAB_WORK_API_URL" in text
    assert "--check" in text
    assert "--check-api" in text
    assert "PRIVATE-TOKEN" in text
    # launcher must never echo the token value
    assert 'echo "$VAULT_PASSWORD"' not in text
    assert "printf '%s' \"$VAULT_PASSWORD\"" not in text

    setup = (ROOT / "setup.sh").read_text(encoding="utf-8")
    assert "gitlab-mcp-vault" in setup, "setup.sh must install the Vault launcher"


def test_gitlab_docs_cover_all_instances():
    text = (ROOT / "docs" / "profiles-agents-matrix.md").read_text(encoding="utf-8")
    for name in GITLAB_SERVERS:
        assert name in text, name
    assert "central" in text


def test_github_mcp_uses_official_server_via_vault():
    server = _cfg("dev")["mcp"]["servers"]["github"]
    assert server["type"] == "local"
    assert server["disabled"] is False
    assert server["command"] == ["github-mcp-vault"]
    assert "environment" not in server, "GitHub PAT must come from Vault, not config"

    launcher = ROOT / "scripts" / "github-mcp-vault"
    assert launcher.is_file()
    assert launcher.stat().st_mode & 0o111, "github-mcp-vault must be executable"

    text = launcher.read_text(encoding="utf-8")
    assert "github" in text and "pat" in text.lower()
    assert "agent-vault" in text
    assert "--project" in text and "--instance" in text
    assert "ghcr.io/github/github-mcp-server" in text
    assert "GITHUB_PERSONAL_ACCESS_TOKEN" in text
    assert "docker" in text
    assert 'echo "$VAULT_PASSWORD"' not in text

    setup = (ROOT / "setup.sh").read_text(encoding="utf-8")
    assert "github-mcp-vault" in setup, "setup.sh must install the Vault launcher"

    for profile in CANONICAL - {"dev"}:
        assert "github" not in _cfg(profile)["mcp"]["servers"], profile



def test_net_profile_skill_coverage():
    allow = _cfg("net")["permission"]["skill"]
    assert REQUIRED_NET_SKILLS <= set(allow), sorted(REQUIRED_NET_SKILLS - set(allow))


def test_net_profiles_agents_are_correctly_moded():
    agents = _cfg("net")["agent"]
    assert agents["network-engineer"]["mode"] == "primary"
    assert agents["network-security"]["mode"] == "primary"
    assert agents["bgp-ospf-analyst"]["mode"] == "primary"
    assert agents["packet-analyst"]["mode"] == "subagent"


def test_instructions_exist():
    for profile in CANONICAL:
        for instruction in _cfg(profile)["instructions"]:
            assert (PROFILES_DIR / profile / instruction).is_file(), f"{profile}/{instruction}"


def test_profile_docs_exist():
    assert (ROOT / "docs" / "profiles-agents-matrix.md").is_file()
    assert (ROOT / "docs" / "profiles-migration.md").is_file()
    assert (ROOT / "docs" / "infra" / "README.md").is_file()
    assert (ROOT / "docs" / "net" / "README.md").is_file()


def test_migration_doc_covers_removed_profiles():
    text = (ROOT / "docs" / "profiles-migration.md").read_text(encoding="utf-8")
    for name in REMOVED:
        assert name in text, name
    for name in CANONICAL:
        assert name in text, name


def test_ocp_lists_canonical_profiles():
    text = (ROOT / "scripts" / "ocp").read_text(encoding="utf-8")
    match = re.search(r"^PROFILES=\((.*?)\)$", text, re.M)
    assert match, "PROFILES array not found in scripts/ocp"
    listed = set(match.group(1).split())
    assert listed == {"default"} | CANONICAL
    assert "sec-lm" not in listed


def test_setup_aliases_match_profiles():
    text = (ROOT / "setup.sh").read_text(encoding="utf-8")
    assert "oc-infra" in text
    assert "oc-net" in text
    assert "oc-devops" not in text
    assert "oc-fullstack" not in text
    assert "oc-sec-lm" not in text


def test_deploy_script_lists_only_canonical_profiles():
    text = (ROOT / "scripts" / "deploy-config.sh").read_text(encoding="utf-8")
    usage = text.splitlines()[1]
    assert "infra" in usage and "net" in usage and "sec" in usage
    for name in REMOVED:
        assert name not in usage, name
