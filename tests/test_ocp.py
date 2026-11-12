import json
import os
from pathlib import Path


def test_ocp_script_is_executable_and_knows_profiles():
    script = Path("scripts/ocp")
    assert script.exists()
    assert os.access(script, os.X_OK)
    text = script.read_text()
    for profile in ("default", "dev", "infra", "net", "sec", "ot", "mgnt", "design"):
        assert profile in text
    for removed in ("devops", "fullstack", "sec-lm"):
        assert removed not in text


def test_ocp_uses_standalone_server():
    """v2: конфигом владеет фоновый сервис, профиль применяется только с --standalone."""
    script = Path("scripts/ocp").read_text()
    assert "OPENCODE_CONFIG" in script
    assert "opencode --standalone" in script


def test_ocp_continues_last_session_by_default():
    """Запуск не должен создавать новую сессию каждый раз."""
    script = Path("scripts/ocp").read_text()
    assert "resume=(--continue)" in script
    assert "exec opencode --standalone \"${resume[@]}\"" in script
    # явный выбор сессии отключает автоматический --continue
    for flag in ("-c", "--continue", "-s", "--session", "--session=*"):
        assert flag in script


def test_profile_aliases_use_standalone_server_and_continue():
    setup_sh = Path("setup.sh").read_text()
    assert 'opencode --standalone --continue"' in setup_sh
    assert (
        "OPENCODE_CONFIG=~/.config/opencode-net/opencode.json "
        "opencode --standalone --continue" in setup_sh
    )
    setup_ps1 = Path("setup.ps1").read_text()
    assert "& opencode --standalone --continue @ForwardArgs" in setup_ps1


def test_default_alias_continues_but_keeps_subcommands():
    """oc продолжает сессию, но session/models/mcp и др. работают как раньше."""
    setup_sh = Path("setup.sh").read_text()
    assert "command opencode --continue" in setup_sh
    for sub in ("session", "models", "mcp", "plugin", "debug", "serve", "run"):
        assert sub in setup_sh


def test_delegation_docs_exist():
    assert Path("docs/profiles-agents-matrix.md").is_file()
    assert Path("docs/project-config-template.json").is_file()
    agents = Path("config/AGENTS.md").read_text()
    assert "Субагенты: когда параллельно, когда inline" in agents


def test_project_config_template_is_valid_json():
    cfg = json.loads(Path("docs/project-config-template.json").read_text())
    assert "servers" in cfg["mcp"]
    assert cfg["agent"]["project-reviewer"]["mode"] == "subagent"
