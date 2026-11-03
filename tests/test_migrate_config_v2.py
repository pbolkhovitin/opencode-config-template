import json
from pathlib import Path

from scripts.migrate_config_v2 import migrate


def test_migrate_mcp_and_commands():
    cfg = {
        "command": {"profile": {"template": "x"}},
        "mcp": {
            "local": {"type": "local", "command": ["x"], "enabled": True},
            "remote": {"type": "remote", "url": "http://x", "enabled": False},
        },
    }
    out = migrate(cfg)
    assert "command" not in out and "commands" in out
    assert "servers" in out["mcp"]
    assert out["mcp"]["servers"]["local"]["disabled"] is False
    assert out["mcp"]["servers"]["remote"]["disabled"] is True
    assert "enabled" not in out["mcp"]["servers"]["local"]


def test_legacy_keys_preserved_when_schema_cannot_express_them():
    cfg = {
        "provider": {"x": {"npm": "pkg", "options": {"baseURL": "http://x"}}},
        "agent": {"a": {"prompt": "p", "temperature": 0.2, "permission": {"bash": "ask"}}},
    }
    out = migrate(cfg)
    assert out["provider"] == cfg["provider"]
    assert out["agent"] == cfg["agent"]


def test_migrate_profiles_dir(tmp_path):
    src = tmp_path / "p.jsonc"
    src.write_text(json.dumps({"$schema": "https://opencode.ai/config.json",
                               "mcp": {"ssh": {"type": "local", "command": ["ssh-mcp"], "enabled": True}}}))
    out = migrate(json.loads(src.read_text()))
    assert out["mcp"]["servers"]["ssh"]["disabled"] is False
