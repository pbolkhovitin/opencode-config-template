import json
import re
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

MODEL_RE = re.compile(r"^[^/#]+/[^#]+(?:#[^#]+)?$")


def load_jsonc(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"^\s*//.*$", "", text, flags=re.M)
    return json.loads(text)


def load_schema() -> dict:
    schema = json.loads(
        (Path(__file__).parent / "schema/opencode-config.json").read_text()
    )

    def strip_remote_refs(node):
        if isinstance(node, dict):
            ref = node.get("$ref")
            if isinstance(ref, str) and ref.startswith("https://models.dev"):
                del node["$ref"]
            for value in node.values():
                strip_remote_refs(value)
        elif isinstance(node, list):
            for item in node:
                strip_remote_refs(item)

    strip_remote_refs(schema)
    schema["properties"].setdefault("theme", {"type": "string"})
    return schema


def validate(path: Path, base: Path) -> list[str]:
    errors: list[str] = []
    cfg = load_jsonc(path)
    schema = load_schema()
    for e in Draft202012Validator(schema).iter_errors(cfg):
        message = e.message if len(e.message) <= 300 else e.message[:300] + "..."
        errors.append(f"schema: {e.json_path}: {message}")
    for key in ("plugins", "instructions"):
        for item in cfg.get(key, []):
            if isinstance(item, str) and item.startswith(("/", "C:\\")):
                errors.append(f"absolute path in config: {key}={item}")
    for key in ("model", "small_model"):
        v = cfg.get(key)
        if isinstance(v, str) and not MODEL_RE.match(v):
            errors.append(f"invalid model id: {key}={v}")
    for rel in cfg.get("instructions", []):
        if not (base / rel).exists():
            errors.append(f"instruction not found: {rel}")
    return errors


if __name__ == "__main__":
    bad = False
    for root in sys.argv[1:]:
        for p in Path(root).rglob("opencode.json*"):
            if "platform" in p.parts:
                continue
            errs = validate(p, p.parent)
            for e in errs:
                print(f"{p}: {e}")
            bad |= bool(errs)
    sys.exit(1 if bad else 0)
