import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "profiles" / "ot"
GUARD = ROOT / "scripts" / "ot-guard.sh"


def _run(mode, target, scope=None, allow_active=False, tmp_path=None):
    env = {**os.environ, "OT_ACTIONS_LOG": str(tmp_path / "actions.log")}
    env.pop("OT_ALLOW_ACTIVE", None)
    if allow_active:
        env["OT_ALLOW_ACTIVE"] = "1"
    cmd = ["bash", str(GUARD), mode, "--target", target]
    if scope:
        env["OT_SCOPE_FILE"] = str(scope)
    return subprocess.run(cmd, env=env, capture_output=True, text=True)


def test_profile_shape():
    cfg = json.loads((PROFILE / "opencode.jsonc").read_text())
    assert cfg["model"] == "anthropic/claude-sonnet-4-5"
    assert cfg["small_model"] == "anthropic/claude-sonnet-4-5"
    assert len(cfg["agent"]) == 6
    assert {"ssh", "docker", "filesystem", "proxmox"} <= set(cfg["mcp"]["servers"])
    assert cfg["mcp"]["servers"]["brave-search"]["disabled"] is True
    for instruction in cfg["instructions"]:
        assert (PROFILE / instruction).is_file()
    for name in cfg["agent"]:
        assert (PROFILE / "prompts" / "personas" / f"{name}.md").is_file()


def test_guard_is_executable():
    assert GUARD.is_file()
    assert os.access(GUARD, os.X_OK)


def test_passive_is_allowed_without_scope(tmp_path):
    result = _run("passive", "10.0.0.5", tmp_path=tmp_path)
    assert result.returncode == 0


def test_active_denied_without_flag(tmp_path):
    scope = tmp_path / "scope.conf"
    scope.write_text("TARGETS=10.0.0.0/24\nWINDOW_START=00:00\nWINDOW_END=23:59\n")
    result = _run("active", "10.0.0.5", scope=scope, tmp_path=tmp_path)
    assert result.returncode == 3


def test_active_allowed_inside_scope_and_window(tmp_path):
    scope = tmp_path / "scope.conf"
    scope.write_text("TARGETS=10.0.0.0/24\nWINDOW_START=00:00\nWINDOW_END=23:59\n")
    result = _run("active", "10.0.0.5", scope=scope, allow_active=True, tmp_path=tmp_path)
    assert result.returncode == 0


def test_active_denied_outside_scope(tmp_path):
    scope = tmp_path / "scope.conf"
    scope.write_text("TARGETS=10.0.0.0/24\nWINDOW_START=00:00\nWINDOW_END=23:59\n")
    result = _run("active", "10.0.1.5", scope=scope, allow_active=True, tmp_path=tmp_path)
    assert result.returncode == 3


def test_active_denied_for_forbidden_target(tmp_path):
    scope = tmp_path / "scope.conf"
    scope.write_text(
        "TARGETS=10.0.0.0/24\nFORBIDDEN=10.0.0.9\nWINDOW_START=00:00\nWINDOW_END=23:59\n"
    )
    result = _run("active", "10.0.0.9", scope=scope, allow_active=True, tmp_path=tmp_path)
    assert result.returncode == 3
