#!/usr/bin/env python3
"""Compatibility wrapper for top-level Ralph state merges."""

from __future__ import annotations

import sys

from locked_state import StateError, main as locked_main


def _translate_legacy_assignments(arguments: list[str]) -> list[str]:
    translated: list[str] = []
    expects_value = False
    for argument in arguments:
        if expects_value:
            translated.append(argument)
            expects_value = False
        elif argument in {"--state", "--timeout", "--set", "--json"}:
            translated.append(argument)
            expects_value = True
        elif "=" in argument and not argument.startswith("-"):
            translated.extend(("--set", argument))
        else:
            translated.append(argument)
    return translated


def main(argv: list[str] | None = None) -> int:
    """Translate legacy assignments and delegate to the locked state merge."""

    raw = list(sys.argv[1:] if argv is None else argv)
    if not raw or raw[0] in {"-h", "--help"}:
        return locked_main(["merge", "--help"])
    if raw and raw[0] == "merge":
        return locked_main(["merge", *_translate_legacy_assignments(raw[1:])])
    state_file = raw[0]
    return locked_main(
        ["merge", "--state", state_file, *_translate_legacy_assignments(raw[1:])]
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except StateError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(2) from exc
