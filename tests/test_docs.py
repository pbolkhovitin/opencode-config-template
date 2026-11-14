import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOC_FILES = [
    ROOT / "README.md",
    ROOT / "AGENTS.md",
    ROOT / "config" / "AGENTS.md",
    *sorted((ROOT / "docs").rglob("*.md")),
]

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
FENCE = re.compile(r"```.*?```", re.S)


def _broken_links(path: Path):
    text = FENCE.sub("", path.read_text(errors="ignore"))
    for match in LINK.finditer(text):
        target = match.group(1).split("#")[0]
        if not target or target.startswith(("http://", "https://", "mailto:", "tel:", "/")):
            continue
        if not (path.parent / target).resolve().exists():
            yield target


def test_doc_links_resolve():
    broken = [
        (path.relative_to(ROOT), target)
        for path in DOC_FILES
        if path.exists()
        for target in _broken_links(path)
    ]
    assert not broken, "\n".join(f"{path} -> {target}" for path, target in broken)


def test_every_profile_is_documented():
    profiles = sorted(p.name for p in (ROOT / "profiles").iterdir() if p.is_dir())
    guides = {
        "FEATURES.md": (ROOT / "docs" / "FEATURES.md").read_text(),
        "USAGE.md": (ROOT / "docs" / "USAGE.md").read_text(),
        "custom-agents.md": (ROOT / "docs" / "custom-agents.md").read_text(),
        "profiles-agents-matrix.md": (ROOT / "docs" / "profiles-agents-matrix.md").read_text(),
    }
    for name, text in guides.items():
        for profile in profiles:
            assert f"`{profile}`" in text or f" {profile} " in text, (
                f"profile '{profile}' missing from docs/{name}"
            )
