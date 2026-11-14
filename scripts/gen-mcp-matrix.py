#!/usr/bin/env python3
"""Regenerate the MCP column of docs/profiles-agents-matrix.md from profiles.

The source of truth for MCP servers is profiles/*/opencode.jsonc
(``mcp.servers``). The summary table in the matrix must not be edited by hand:
change the profile, then run this script.

    scripts/gen-mcp-matrix.py           # rewrite the MCP column
    scripts/gen-mcp-matrix.py --check   # exit 1 if the column is out of date
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from tests.validate_configs import load_jsonc  # noqa: E402

MATRIX = ROOT / "docs" / "profiles-agents-matrix.md"
PROFILES = ["default", "dev", "infra", "net", "sec", "ot", "mgnt", "design"]

ROW = re.compile(r"^\| `(?P<profile>[a-z]+)` \|")
MCP_CELL = 4  # cells[0] is empty, then profile, alias, model, MCP, ...


def mcp_names(profile: str) -> list[str]:
    if profile == "default":
        return []
    config = load_jsonc(ROOT / "profiles" / profile / "opencode.jsonc")
    servers = (config.get("mcp") or {}).get("servers") or {}
    names = []
    for name, server in servers.items():
        disabled = isinstance(server, dict) and server.get("disabled") is True
        names.append(f"{name} (off)" if disabled else name)
    return names


def render(profile: str) -> str:
    names = mcp_names(profile)
    return ", ".join(names) if names else "—"


def rewrite(text: str) -> tuple[str, list[str]]:
    lines = []
    changed = []
    for line in text.splitlines(keepends=True):
        match = ROW.match(line)
        if not match or match.group("profile") not in PROFILES:
            lines.append(line)
            continue
        cells = line.rstrip("\n").split("|")
        if len(cells) <= MCP_CELL:
            lines.append(line)
            continue
        wanted = render(match.group("profile"))
        if cells[MCP_CELL].strip() != wanted:
            changed.append(match.group("profile"))
            cells[MCP_CELL] = f" {wanted} "
            line = "|".join(cells) + ("\n" if line.endswith("\n") else "")
        lines.append(line)
    return "".join(lines), changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify without writing")
    args = parser.parse_args()

    text = MATRIX.read_text()
    updated, changed = rewrite(text)

    if args.check:
        if changed:
            print("MCP column is out of date for: " + ", ".join(changed))
            print("run scripts/gen-mcp-matrix.py")
            return 1
        return 0

    if changed:
        MATRIX.write_text(updated)
        print("updated MCP column: " + ", ".join(changed))
    else:
        print("MCP column already up to date")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
