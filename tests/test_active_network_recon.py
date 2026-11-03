from pathlib import Path

from tests.validate_configs import load_jsonc


def test_skill_documents_safe_active_recon():
    text = Path("config/skills/active-network-recon/SKILL.md").read_text()
    assert text.startswith("---\n")
    assert "name: active-network-recon" in text
    for tool in ("nmap", "masscan", "arp-scan", "hping3"):
        assert tool in text
    assert "OT/ICS" in text
    assert "--max-rate" in text
    assert "ettercap" in text and "yersinia" in text


def test_net_profile_allows_active_recon():
    config = load_jsonc(Path("profiles/net/opencode.jsonc"))
    allow = config["permission"]["skill"]
    assert allow["*"] == "deny"
    assert allow["active-network-recon"] == "allow"


def test_net_safety_has_active_scanning_rules():
    text = Path("profiles/net/instructions/net-safety.md").read_text()
    assert "### Активное сканирование" in text
    assert "OT/ICS" in text
    assert "--max-rate" in text
    assert "ettercap" in text and "yersinia" in text


def test_setup_installs_passive_scanners_only():
    text = Path("setup.sh").read_text()
    assert "nmap nmap-ncat masscan arp-scan hping3 gobuster" in text
    packages = text.split("SYSTEM_PACKAGES=(", 1)[1].split(")", 1)[0]
    assert "ettercap" not in packages
    assert "yersinia" not in packages


def test_net_docs_describe_active_recon():
    text = Path("docs/net/README.md").read_text()
    assert "active-network-recon" in text
    assert "### Активная разведка" in text
    assert "OT/ICS" in text
