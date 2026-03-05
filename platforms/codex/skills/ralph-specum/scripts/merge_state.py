#!/usr/bin/env python3
"""Merge top-level Ralph state fields into a JSON file."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_scalar(raw: str):
    lowered = raw.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered == "null":
        return None
    try:
        return int(raw)
    except ValueError:
        return raw


def parse_pairs(items: list[str], as_json: bool) -> dict[str, object]:
    merged: dict[str, object] = {}
    for item in items:
        if "=" not in item:
            raise SystemExit(f"Invalid assignment: {item}")
        key, value = item.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            raise SystemExit(f"Invalid assignment: {item}")
        merged[key] = json.loads(value) if as_json else parse_scalar(value)
    return merged


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge Ralph state fields into a JSON file.")
    parser.add_argument("state_file", help="Path to .ralph-state.json")
    parser.add_argument("--set", action="append", default=[], help="key=value assignment")
    parser.add_argument("--json", action="append", default=[], help="key=<json> assignment")
    parser.add_argument("--stdout", action="store_true", help="Print merged JSON to stdout")
    args = parser.parse_args()

    state_path = Path(args.state_file)
    state = {}
    if state_path.exists():
        state = json.loads(state_path.read_text())
        if not isinstance(state, dict):
            raise SystemExit("State file must contain a JSON object.")

    state.update(parse_pairs(args.set, as_json=False))
    state.update(parse_pairs(args.json, as_json=True))

    encoded = json.dumps(state, indent=2, sort_keys=True) + "\n"
    if args.stdout:
        print(encoded, end="")
        return 0

    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
