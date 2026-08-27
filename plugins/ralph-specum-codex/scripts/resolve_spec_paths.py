#!/usr/bin/env python3
"""Resolve Ralph Specum roots, current spec, and named specs."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

DEFAULT_SPECS_DIR = "./specs"
TRUE_VALUES = {"true", "yes", "1"}
FALSE_VALUES = {"false", "no", "0"}
PROTOTYPE_SETTINGS = {
    "prototype_lock_timeout_seconds": (10, 1, 60),
    "prototype_quick_lock_timeout_seconds": (3, 1, 30),
    "prototype_logic_timeout_minutes": (20, 1, 180),
    "prototype_ui_timeout_minutes": (45, 1, 240),
    "prototype_quick_logic_timeout_minutes": (10, 1, 60),
    "prototype_quick_ui_timeout_minutes": (20, 1, 90),
    "prototype_activity_extension_minutes": (10, 1, 30),
    "prototype_transfer_path_extra_minutes": (2, 0, 10),
    "prototype_transfer_path_extra_cap_minutes": (10, 0, 60),
    "prototype_hard_deadline_multiplier": (2, 1, 4),
    "prototype_conflict_timeout_min_minutes": (10, 1, 120),
    "prototype_conflict_timeout_max_minutes": (30, 1, 240),
    "prototype_conflict_resolution_retries": (0, 0, 3),
    "prototype_normal_builder_executions": (2, 1, 5),
    "prototype_quick_builder_executions": (2, 1, 2),
}


def parse_scalar(value: str):
    stripped = value.strip()
    lowered = stripped.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered == "null":
        return None
    if re.fullmatch(r"-?\d+", stripped):
        return int(stripped)
    if (stripped.startswith('"') and stripped.endswith('"')) or (
        stripped.startswith("'") and stripped.endswith("'")
    ):
        return stripped[1:-1]
    if stripped.startswith("[") and stripped.endswith("]"):
        body = stripped[1:-1].strip()
        if not body:
            return []
        return [part.strip().strip('"').strip("'") for part in body.split(",") if part.strip()]
    return stripped


def parse_frontmatter(path: Path) -> dict[str, object]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.DOTALL)
    if not match:
        return {}
    lines = match.group(1).splitlines()
    data: dict[str, object] = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if ":" not in line:
            i += 1
            continue
        key, raw_value = line.split(":", 1)
        key = key.strip()
        raw_value = raw_value.strip()
        if raw_value:
            data[key] = parse_scalar(raw_value)
            i += 1
            continue
        i += 1
        items: list[str] = []
        while i < len(lines):
            item = lines[i]
            stripped = item.strip()
            if stripped.startswith("- "):
                items.append(stripped[2:].strip().strip('"').strip("'"))
                i += 1
                continue
            if stripped:
                break
            i += 1
        data[key] = items
    return data


def coerce_int(value: object, default: int) -> int:
    if isinstance(value, bool):
        return default
    if isinstance(value, int):
        return value
    if isinstance(value, str) and re.fullmatch(r"-?\d+", value.strip()):
        return int(value.strip())
    return default


def coerce_bool(value: object, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        if value == 1:
            return True
        if value == 0:
            return False
        return default
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in TRUE_VALUES:
            return True
        if lowered in FALSE_VALUES:
            return False
    return default


def default_specs_dir(cwd: Path, specs_dirs: list[str]) -> str:
    for root in specs_dirs:
        root_path = cwd / root
        if root_path.exists() and root_path.is_dir():
            return root
    return DEFAULT_SPECS_DIR


def resolve_prototype_settings(
    settings: dict[str, object],
) -> tuple[dict[str, int], list[str]]:
    resolved: dict[str, int] = {}
    warnings: list[str] = []
    for key, (default, minimum, maximum) in PROTOTYPE_SETTINGS.items():
        raw = settings.get(key, default)
        valid_integer = isinstance(raw, int) and not isinstance(raw, bool)
        if isinstance(raw, str) and re.fullmatch(r"-?\d+", raw.strip()):
            valid_integer = True
        value = coerce_int(raw, default)
        if not valid_integer or value < minimum or value > maximum:
            value = default
            warnings.append(
                f"{key} must be an integer from {minimum} to {maximum}; using {default}"
            )
        resolved[key] = value
    return resolved, warnings


def resolve_config(cwd: Path) -> dict[str, object]:
    settings = parse_frontmatter(cwd / ".claude" / "ralph-specum.local.md")
    raw_dirs = settings.get("specs_dirs")
    if isinstance(raw_dirs, list):
        specs_dirs = [str(item) for item in raw_dirs if str(item).strip()]
    else:
        specs_dirs = [DEFAULT_SPECS_DIR]
    if not specs_dirs:
        specs_dirs = [DEFAULT_SPECS_DIR]
    prototype_settings, config_warnings = resolve_prototype_settings(settings)
    return {
        "specs_dirs": specs_dirs,
        "default_dir": default_specs_dir(cwd, specs_dirs),
        "default_max_iterations": coerce_int(settings.get("default_max_iterations", 5), 5),
        "auto_commit_spec": coerce_bool(settings.get("auto_commit_spec", True), True),
        "prototype_settings": prototype_settings,
        "configWarnings": config_warnings,
    }


def normalize_relative(value: str) -> str:
    if value.startswith("/"):
        return value
    norm = str(Path(value))
    return norm if norm.startswith(".") else f"./{norm.lstrip('./')}"


def resolve_current(cwd: Path, default_dir: str) -> str | None:
    marker = cwd / default_dir / ".current-spec"
    if not marker.exists():
        return None
    content = marker.read_text().strip()
    if not content:
        return None
    if content.startswith("./") or content.startswith("/"):
        return content
    return f"{default_dir.rstrip('/')}/{content}"


def resolve_spec_root(current: str | None, specs_dirs: list[str], default_dir: str) -> str:
    if not current:
        return normalize_relative(default_dir)
    normalized_current = normalize_relative(current)
    roots = sorted((normalize_relative(root) for root in specs_dirs), key=len, reverse=True)
    for root in roots:
        if normalized_current == root or normalized_current.startswith(f"{root.rstrip('/')}/"):
            return root
    if current.startswith("/"):
        return str(Path(current).parent)
    return normalize_relative(str(Path(current).parent))


def list_specs(cwd: Path, specs_dirs: list[str]) -> list[dict[str, str]]:
    specs = []
    for root in specs_dirs:
        root_path = cwd / root
        if not root_path.exists() or not root_path.is_dir():
            continue
        for child in sorted(root_path.iterdir()):
            if not child.is_dir() or child.name.startswith("."):
                continue
            specs.append(
                {
                    "name": child.name,
                    "path": normalize_relative(str(Path(root) / child.name)),
                    "root": normalize_relative(root),
                }
            )
    return specs


def main() -> int:
    parser = argparse.ArgumentParser(description="Resolve Ralph Specum spec paths.")
    parser.add_argument("--cwd", default=".", help="Repository root")
    parser.add_argument("--current", action="store_true", help="Print current spec path")
    parser.add_argument("--list", action="store_true", help="Print all specs as JSON")
    parser.add_argument("--name", help="Find a spec by name")
    args = parser.parse_args()

    cwd = Path(args.cwd).resolve()
    config = resolve_config(cwd)
    specs = list_specs(cwd, config["specs_dirs"])
    current = resolve_current(cwd, config["default_dir"])

    if args.list:
        print(json.dumps(specs, indent=2, sort_keys=True))
        return 0

    if args.current:
        if not current:
            return 1
        print(current)
        return 0

    if args.name:
        matches = [spec["path"] for spec in specs if spec["name"] == args.name]
        if not matches:
            return 1
        if len(matches) > 1:
            print(json.dumps(matches, indent=2), end="")
            return 2
        print(matches[0])
        return 0

    payload = dict(config)
    payload["current_spec"] = current
    payload["specRoot"] = resolve_spec_root(
        current, config["specs_dirs"], config["default_dir"]
    )
    payload["basePath"] = current
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
