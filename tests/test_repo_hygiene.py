"""Гигиена репозитория: в индексе не должно быть приватных данных и крупных файлов."""

import pathlib
import subprocess

FORBIDDEN = [
    "config/.agents/context/tooling/.gl-profile",
    ".opencode-synced/chunks",
    "data/storage/session_diff",
    "state/prompt-history.jsonl",
    ".agents/skills",
]
MAX_BYTES = 1_048_576


def tracked() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, check=True
    ).stdout
    return [p for p in out.splitlines() if p]


def test_forbidden_paths_not_tracked():
    assert not [p for p in tracked() if any(p.startswith(f) for f in FORBIDDEN)]


def test_no_large_tracked_files():
    big = [
        (p, pathlib.Path(p).stat().st_size)
        for p in tracked()
        if pathlib.Path(p).is_file() and pathlib.Path(p).stat().st_size > MAX_BYTES
    ]
    assert big == []
