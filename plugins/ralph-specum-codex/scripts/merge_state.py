#!/usr/bin/env python3
"""Compatibility wrapper for top-level Ralph state merges."""

from __future__ import annotations

import sys

from locked_state import main as locked_main


def main(argv: list[str] | None = None) -> int:
    raw = list(sys.argv[1:] if argv is None else argv)
    if not raw or raw[0] in {"-h", "--help"}:
        return locked_main(["merge", "--help"])
    if raw and raw[0] == "merge":
        return locked_main(raw)
    state_file = raw[0]
    return locked_main(["merge", "--state", state_file, *raw[1:]])


if __name__ == "__main__":
    raise SystemExit(main())
