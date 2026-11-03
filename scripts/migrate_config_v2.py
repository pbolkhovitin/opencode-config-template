#!/usr/bin/env python3
"""Migrate opencode profile configs to the v2 schema where it is safe.

Only fields whose v2 replacement is semantically equivalent are renamed:
  - command  -> commands
  - mcp (flat server map) -> mcp.servers, with enabled -> disabled inverted

`agent`, `provider` and `permission` are intentionally kept in their legacy
form: the v2 schema cannot express `temperature`/`prompt` for agents, nor
`options.baseURL`/`options.apiKey` for providers, and `permissions` uses a
different rule shape. See docs/config-migration.md.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def migrate(cfg: dict) -> dict:
    out = dict(cfg)

    if "command" in out:
        out["commands"] = out.pop("command")

    mcp = out.get("mcp")
    if isinstance(mcp, dict) and "servers" not in mcp:
        servers = {}
        for name, server in mcp.items():
            entry = dict(server)
            if "enabled" in entry:
                entry["disabled"] = not entry.pop("enabled")
            servers[name] = entry
        out["mcp"] = {"servers": servers}

    return out


def load_jsonc(path: Path) -> dict:
    return json.loads(path.read_text())


def dump(cfg: dict) -> str:
    return json.dumps(cfg, indent=2, ensure_ascii=False) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="src", default="profiles")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args(argv)

    base = Path(args.src)
    files = sorted(base.glob("*/opencode.jsonc"))
    if not files:
        print(f"no configs under {base}", file=sys.stderr)
        return 1

    for path in files:
        cfg = migrate(load_jsonc(path))
        text = dump(cfg)
        if args.write:
            path.write_text(text)
            print(f"rewrote {path}")
        else:
            print(f"would rewrite {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
