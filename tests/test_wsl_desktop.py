from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
SETUP = (ROOT / "setup.sh").read_text(encoding="utf-8")
DOC = ROOT / "docs" / "wsl-desktop.md"


def test_setup_uses_v2_installer():
    assert "https://opencode.ai/v2/install" in SETUP
    assert not re.search(r"opencode\.ai/install", SETUP), "setup.sh must not use the v1 installer"


def test_setup_does_not_write_legacy_platform_env():
    legacy = re.findall(r"^\s*export OPENCODE_(?:PLATFORM|HOME|ALLOWED_DIRS)=", SETUP, re.M)
    assert not legacy, "v1 platform variables are ignored by OpenCode v2"


def test_setup_detects_wsl_version_and_shell_rc():
    assert "IS_WSL1" in SETUP
    assert "microsoft-standard" in SETUP
    assert "RC_FILE" in SETUP
    assert ".bashrc" in SETUP and ".zshrc" in SETUP


def test_wsl_desktop_doc_exists_and_is_linked():
    assert DOC.exists()
    for name in ("README.md", "AGENTS.md"):
        assert "docs/wsl-desktop.md" in (ROOT / name).read_text(encoding="utf-8")


def test_wsl_desktop_doc_covers_key_scenarios():
    text = DOC.read_text(encoding="utf-8")
    for needle in (
        "Add WSL server",
        "WSL 2",
        "Unsupported · Use WSL 2",
        "ocp",
        "opencode.jsonc",
        "49374",
        "Retry start",
    ):
        assert needle in text, f"missing in wsl-desktop.md: {needle}"
