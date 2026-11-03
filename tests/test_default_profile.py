from pathlib import Path

from tests.validate_configs import load_jsonc


def test_default_profile_is_v2():
    cfg = load_jsonc(Path("config/opencode.json"))
    assert "mcp" in cfg and "servers" in cfg["mcp"]  # explicit empty section
    assert cfg["mcp"]["servers"] == {}  # MCP lives in profiles
    assert "opencode-handoff@0.6.1" in cfg["plugins"]
    assert not any(p.startswith("opencode-pty") for p in cfg["plugins"])
    assert not any(p.startswith("/") for p in cfg["plugins"])
    assert all((Path("config") / p).exists() for p in cfg["instructions"])
