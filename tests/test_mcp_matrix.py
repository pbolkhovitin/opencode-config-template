import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def test_mcp_matrix_matches_profiles():
    """The MCP column must stay generated from profiles/*/opencode.jsonc."""
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "gen-mcp-matrix.py"), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (result.stdout + result.stderr).strip()


def test_every_profile_has_a_matrix_row():
    text = (ROOT / "docs" / "profiles-agents-matrix.md").read_text()
    profiles = sorted(p.name for p in (ROOT / "profiles").iterdir() if p.is_dir())
    for profile in ["default", *profiles]:
        assert f"| `{profile}` |" in text, f"{profile} missing from matrix"
