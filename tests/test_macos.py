from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def test_profiles_use_env_home():
    for path in sorted((ROOT / "profiles").glob("*/opencode.json*")):
        text = path.read_text(encoding="utf-8")
        assert "/home/" not in text, f"{path.relative_to(ROOT)} содержит жёсткий Linux-путь"
    for name in ("dev", "net", "ot"):
        text = (ROOT / "profiles" / name / "opencode.jsonc").read_text(encoding="utf-8")
        assert '"{env:HOME}"' in text, f"profiles/{name} не использует {{env:HOME}}"


def test_setup_supports_macos():
    text = (ROOT / "setup.sh").read_text(encoding="utf-8")
    required = [
        "IS_MACOS",
        "Darwin",
        "/opt/homebrew/bin",
        "sysctl.proc_translated",
        "opencode-desktop",
        "brew install opentofu",
        "bin/${KUBE_OS}/${ARCH_GO}/kubectl",
        "install -m 755",
    ]
    for needle in required:
        assert needle in text, f"setup.sh: отсутствует {needle!r}"
    assert "install -m755" not in text, "setup.sh: BSD install не любит слитные -m755"


def test_macos_doc_exists_and_linked():
    doc = ROOT / "docs" / "macos.md"
    assert doc.exists()
    text = doc.read_text(encoding="utf-8")
    for needle in ("Apple Silicon", "Xcode", "Homebrew", "Rosetta", "opencode-desktop", "{env:HOME}"):
        assert needle in text, f"docs/macos.md: отсутствует {needle!r}"

    for rel in ("README.md", "AGENTS.md"):
        assert "docs/macos.md" in (ROOT / rel).read_text(encoding="utf-8"), f"{rel} не ссылается на docs/macos.md"
