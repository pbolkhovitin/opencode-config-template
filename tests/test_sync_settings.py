import json
from pathlib import Path

import pytest


def test_sync_does_not_export_prompts_secrets_or_agents():
    cfg = json.loads(Path("config/opencode-synced.jsonc").read_text())
    assert cfg["includeSecrets"] is False
    assert cfg["includeMcpSecrets"] is False
    assert cfg["includePromptStash"] is False
    assert cfg["includeAgentsDir"] is False
    assert cfg["includeSessions"] is False


def test_login_helper_keeps_profile_outside_repo_and_home_independent():
    helper = Path("config/tooling/gl_login.py")
    if not helper.is_file():
        pytest.skip("private tooling is not part of the public copy")
    src = helper.read_text()
    assert "/home/" not in src
    assert "GL_PROFILE" in src
