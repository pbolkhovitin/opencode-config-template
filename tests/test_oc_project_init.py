import json
import subprocess
import sys
from pathlib import Path

from tests.validate_configs import load_jsonc

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "oc-project-init.py"


def write_profile(home: Path, name: str, payload: dict) -> None:
    directory = home / ("opencode" if name == "default" else f"opencode-{name}")
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "opencode.json").write_text(json.dumps(payload))


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True, cwd=ROOT)


def profiles_home(tmp_path: Path) -> Path:
    home = tmp_path / "home"
    write_profile(
        home,
        "dev",
        {
            "mcp": {"servers": {"docker": {"command": ["dev"]}, "postgres": {"command": ["pg"]}}},
            "agent": {"reviewer": {"mode": "subagent", "prompt": "r"}},
        },
    )
    write_profile(
        home,
        "infra",
        {
            "mcp": {"servers": {"docker": {"command": ["infra"]}, "proxmox": {"command": ["pve"]}}},
            "agent": {"sre": {"mode": "subagent", "prompt": "s"}},
        },
    )
    return home


def test_generates_union_with_later_profile_winning(tmp_path: Path) -> None:
    home = profiles_home(tmp_path)
    project = tmp_path / "project"
    result = run("--profiles", "dev,infra", "--config-home", str(home), "--dir", str(project))
    assert result.returncode == 0, result.stderr

    config = load_jsonc(project / "opencode.jsonc")
    servers = config["mcp"]["servers"]
    assert set(servers) == {"docker", "postgres", "proxmox"}
    assert servers["docker"]["command"] == ["infra"]
    assert set(config["agent"]) == {"reviewer", "sre"}
    assert "conflict server 'docker'" in result.stderr


def test_agent_prompt_paths_are_absolute(tmp_path: Path) -> None:
    home = tmp_path / "home"
    write_profile(
        home,
        "dev",
        {
            "agent": {
                "reviewer": {
                    "prompt": "{file:./prompts/personas/reviewer.md}",
                    "plain": "./prompts/reviewer.md",
                }
            }
        },
    )
    project = tmp_path / "project"
    assert run("--profiles", "dev", "--config-home", str(home), "--dir", str(project)).returncode == 0

    agent = load_jsonc(project / "opencode.jsonc")["agent"]["reviewer"]
    base = (home / "opencode-dev").resolve()
    assert agent["prompt"] == f"{{file:{base / 'prompts/personas/reviewer.md'}}}"
    assert agent["plain"] == str(base / "prompts/reviewer.md")


def test_check_detects_drift(tmp_path: Path) -> None:
    home = profiles_home(tmp_path)
    project = tmp_path / "project"
    assert run("--profiles", "dev,infra", "--config-home", str(home), "--dir", str(project)).returncode == 0
    assert run("--profiles", "dev,infra", "--config-home", str(home), "--dir", str(project), "--check").returncode == 0

    write_profile(home, "infra", {"mcp": {"servers": {"changed": {"command": ["x"]}}}})
    assert run("--profiles", "dev,infra", "--config-home", str(home), "--dir", str(project), "--check").returncode == 1


def test_refuses_foreign_file_without_force(tmp_path: Path) -> None:
    home = profiles_home(tmp_path)
    project = tmp_path / "project"
    project.mkdir()
    (project / "opencode.jsonc").write_text("{}\n")

    assert run("--profiles", "dev", "--config-home", str(home), "--dir", str(project)).returncode == 1
    assert run("--profiles", "dev", "--config-home", str(home), "--dir", str(project), "--force").returncode == 0
