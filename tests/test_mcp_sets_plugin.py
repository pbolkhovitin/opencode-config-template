"""Tests for the per-session MCP sets plugin."""

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "config" / "plugins" / "opencode-mcp-sets"


def test_plugin_files_exist():
    assert (PLUGIN / "index.ts").is_file()
    assert (PLUGIN / "lib.ts").is_file()
    index = (PLUGIN / "index.ts").read_text(encoding="utf-8")
    assert 'id: "opencode-mcp-sets"' in index
    assert 'name: "mcp"' in index
    assert 'ctx.session.hook("context"' in index
    assert "ctx.session.update" in index
    assert "ctx.session.synthetic" in index


def test_library_logic():
    script = f"""
import assert from "node:assert/strict"
import {{
  applyDeny,
  formatServerList,
  globMatch,
  normalizeRules,
  normalizeState,
  parseServers,
  selectServers,
  splitArgs,
  stripMcpInstructions,
}} from "{PLUGIN.as_uri()}/lib.ts"

assert.deepEqual(splitArgs(" only gitlab-*, github "), ["only", "gitlab-*", "github"])
assert.equal(globMatch("gitlab-*", "gitlab-work"), true)
assert.equal(globMatch("gitlab-*", "github"), false)
assert.equal(globMatch("*", "anything"), true)

const selected = selectServers(["gitlab-*"], ["gitlab-work", "gitlab-official-gmail", "github"])
assert.deepEqual(selected.matched, ["gitlab-work", "gitlab-official-gmail"])
assert.deepEqual(selected.unknown, [])

assert.deepEqual(normalizeState({{ disabled: ["b", "a", "a"], rules: [] }}).disabled, ["a", "b"])
assert.deepEqual(normalizeRules([{{action:"edit",resource:"**",effect:"deny"}}]).length, 1)

const base = [{{ action: "edit", resource: "src/**", effect: "deny" }}]
const first = applyDeny(base, [], ["gitlab-work", "github"])
assert.equal(first.added.length, 2)
assert.equal(first.permissions.length, 3)

const second = applyDeny(first.permissions, first.added, ["github"])
assert.equal(second.added.length, 1)
assert.equal(second.permissions.length, 2)
assert.deepEqual(second.permissions[0], base[0])

const cleared = applyDeny(second.permissions, second.added, [])
assert.equal(cleared.added.length, 0)
assert.deepEqual(cleared.permissions, base)

const servers = parseServers({{ data: [
  {{ name: "b", status: {{ status: "connected" }} }},
  {{ name: "a", status: "disabled" }},
] }})
assert.deepEqual(servers.map((s) => s.name), ["a", "b"])
assert.equal(formatServerList(servers, {{disabled:["b"],rules:[]}}).includes("off  b"), true)

const system = [{{ type: "text", text: "x <mcp_instructions><server name=\\"gitlab-work\\">secret</server><server name=\\"github\\">gh</server></mcp_instructions>" }}]
stripMcpInstructions(system, ["gitlab-work"])
assert.equal(system[0].text.includes("gitlab-work"), false)
assert.equal(system[0].text.includes("github"), true)
console.log("ok")
"""
    result = subprocess.run(
        ["node", "--experimental-strip-types", "--input-type=module", "-e", script],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr


def test_plugin_is_deployed_and_documented():
    deploy = (ROOT / "scripts" / "deploy-config.sh").read_text(encoding="utf-8")
    setup = (ROOT / "setup.sh").read_text(encoding="utf-8")
    assert "config/plugins" in deploy
    assert "config/plugins" in setup
    assert (PLUGIN / "index.ts").is_file()

    docs = (ROOT / "docs" / "mcp-sets.md").read_text(encoding="utf-8")
    for needle in ("/mcp list", "/mcp off", "/mcp only", "/mcp reset"):
        assert needle in docs
    assert "session permissions" in docs.lower()
