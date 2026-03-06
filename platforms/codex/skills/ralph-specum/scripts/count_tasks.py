#!/usr/bin/env python3
"""Count Ralph markdown tasks and find the next incomplete task."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

TASK_RE = re.compile(r"^- \[(?P<mark>[ xX])\] ")


def main() -> int:
    parser = argparse.ArgumentParser(description="Count Ralph task checkboxes.")
    parser.add_argument("tasks_file", help="Path to tasks.md")
    args = parser.parse_args()

    task_path = Path(args.tasks_file)
    if not task_path.exists():
        raise SystemExit(f"Tasks file not found: {task_path}")

    total = 0
    completed = 0
    next_index = None

    for line in task_path.read_text().splitlines():
        match = TASK_RE.match(line)
        if not match:
            continue
        if next_index is None and match.group("mark") == " ":
            next_index = total
        if match.group("mark").lower() == "x":
            completed += 1
        total += 1

    payload = {
        "total": total,
        "completed": completed,
        "incomplete": total - completed,
        "next_index": total if next_index is None else next_index,
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
