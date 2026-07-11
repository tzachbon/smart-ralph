#!/usr/bin/env python3
"""Validate and sync Ralph Specum shared assets into native plugins."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
CORE_ROOT = REPOSITORY_ROOT / "core"
PLUGIN_ROOTS = (
    REPOSITORY_ROOT / "plugins" / "ralph-specum",
    REPOSITORY_ROOT / "plugins" / "ralph-specum-codex",
)
SHARED_ASSETS = (
    "templates/component-spec.md",
    "templates/design.md",
    "templates/epic.md",
    "templates/external-spec.md",
    "templates/index-summary.md",
    "templates/progress.md",
    "templates/requirements.md",
    "templates/research.md",
    "templates/tasks.md",
    "schemas/progress-frontmatter.schema.json",
    "schemas/spec.schema.json",
)
REQUIRED_RULES = (
    "rules/approvals.md",
    "rules/phases.md",
    "rules/state.md",
    "rules/verification.md",
    "rules/workflow.md",
)
REQUIRED_FIXTURES = (
    "fixtures/progress.legacy.md",
    "fixtures/progress.valid.md",
)
PROGRESS_FIELDS = ("spec", "phase", "approved_through", "updated")


def parse_frontmatter(path: Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        raise ValueError(f"{path}: missing opening frontmatter delimiter")
    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise ValueError(f"{path}: missing closing frontmatter delimiter") from exc

    result: dict[str, str] = {}
    for line in lines[1:end]:
        if not line.strip():
            continue
        if ":" not in line:
            raise ValueError(f"{path}: invalid frontmatter line: {line}")
        key, value = line.split(":", 1)
        key = key.strip()
        if not key or key in result:
            raise ValueError(f"{path}: invalid or duplicate key: {key}")
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        result[key] = value
    return result


def validate_core() -> list[str]:
    errors: list[str] = []
    required = (*SHARED_ASSETS, *REQUIRED_RULES, *REQUIRED_FIXTURES)
    for relative in required:
        if not (CORE_ROOT / relative).is_file():
            errors.append(f"missing canonical file: core/{relative}")

    for schema_path in sorted((CORE_ROOT / "schemas").glob("*.json")):
        try:
            document = json.loads(schema_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"invalid JSON schema {schema_path}: {exc}")
            continue
        if not isinstance(document, dict) or "$schema" not in document:
            errors.append(f"invalid JSON schema {schema_path}: missing $schema")

    progress_path = CORE_ROOT / "templates" / "progress.md"
    if progress_path.is_file():
        try:
            frontmatter = parse_frontmatter(progress_path)
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
        else:
            if tuple(frontmatter) != PROGRESS_FIELDS:
                errors.append(
                    "progress.md frontmatter must contain exactly, in order: "
                    + ", ".join(PROGRESS_FIELDS)
                )
            expected = {
                "spec": "{{SPEC_NAME}}",
                "phase": "research",
                "approved_through": "none",
                "updated": "{{TIMESTAMP}}",
            }
            if frontmatter != expected:
                errors.append("progress.md frontmatter defaults do not match the contract")

    fixture_path = CORE_ROOT / "fixtures" / "progress.valid.md"
    if fixture_path.is_file():
        try:
            fixture_frontmatter = parse_frontmatter(fixture_path)
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
        else:
            if tuple(fixture_frontmatter) != PROGRESS_FIELDS:
                errors.append("valid progress fixture does not match the progress contract")

    for template_path in sorted((CORE_ROOT / "templates").glob("*.md")):
        if ".progress.md" in template_path.read_text(encoding="utf-8"):
            errors.append(f"legacy .progress.md reference in {template_path}")
    return errors


def compare_assets() -> list[str]:
    errors: list[str] = []
    for plugin_root in PLUGIN_ROOTS:
        for relative in SHARED_ASSETS:
            source = CORE_ROOT / relative
            destination = plugin_root / relative
            if not destination.is_file():
                errors.append(f"missing generated asset: {destination.relative_to(REPOSITORY_ROOT)}")
            elif source.read_bytes() != destination.read_bytes():
                errors.append(f"generated asset differs: {destination.relative_to(REPOSITORY_ROOT)}")
    return errors


def sync_assets() -> None:
    for plugin_root in PLUGIN_ROOTS:
        for relative in SHARED_ASSETS:
            source = CORE_ROOT / relative
            destination = plugin_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate the core and fail if generated plugin assets differ",
    )
    args = parser.parse_args(argv)

    errors = validate_core()
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    if args.check:
        errors = compare_assets()
        if errors:
            for error in errors:
                print(f"error: {error}", file=sys.stderr)
            return 1
        print("shared core assets are valid and synchronized")
        return 0

    sync_assets()
    print(f"synchronized {len(SHARED_ASSETS)} assets into {len(PLUGIN_ROOTS)} plugins")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
