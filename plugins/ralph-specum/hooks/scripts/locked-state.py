#!/usr/bin/env python3
"""Claude entrypoint for locked Ralph state updates."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def load_codex_helper():
    helper = Path(__file__).resolve().parents[3] / "ralph-specum-codex" / "scripts" / "locked_state.py"
    spec = importlib.util.spec_from_file_location("ralph_locked_state", helper)
    if spec is None or spec.loader is None:
        raise SystemExit(f"Cannot load locked state helper: {helper}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main(argv: list[str] | None = None) -> int:
    return load_codex_helper().main(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
