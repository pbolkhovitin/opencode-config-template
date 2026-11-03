from pathlib import Path

from tests.validate_configs import load_jsonc

NEW_SKILLS = [
    "active-network-recon",
    "analyzing-network-traffic-with-wireshark",
    "ansible-validator",
    "code-review-and-quality",
    "configuring-pfsense-firewall-rules",
    "debugging-and-error-recovery",
    "docker-build-strategies",
    "enumerating-network-services",
    "homelab-vlan-segmentation",
    "mikrotik-routeros-rsc",
    "network-101",
    "openwrt-config",
    "openwrt-image-build",
    "openwrt-procd-init",
    "ot-network-audit",
    "podkop-openwrt-guide",
    "postgresql-table-design",
    "proxmox-admin",
    "routeros-fundamentals",
    "security-audit",
    "terraform-skill",
    "traffic-analysis-pcap",
    "wireshark-analysis",
]


def test_new_skills_are_vendored():
    for name in NEW_SKILLS:
        assert (Path("config/skills") / name / "SKILL.md").is_file(), name


def test_allowlists_cover_profile_skills():
    expected = {
        "infra": {"proxmox-admin", "ansible-validator", "terraform-skill"},
        "dev": {"security-audit", "postgresql-table-design"},
        "net": {"active-network-recon", "mikrotik-routeros-rsc", "openwrt-config", "network-101"},
        "sec": {"security-audit"},
    }
    for profile, names in expected.items():
        allow = load_jsonc(Path(f"profiles/{profile}/opencode.jsonc"))["permission"]["skill"]
        assert allow["*"] == "deny"
        for name in names:
            assert allow.get(name) == "allow", f"{profile}: {name}"
