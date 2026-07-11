#!/usr/bin/env python3
"""Validate native Ralph Specum packages and repository metadata."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python 3.10 compatibility
    try:
        import tomli as tomllib
    except ModuleNotFoundError:  # No parser is needed when no TOML is shipped.
        tomllib = None

try:
    import yaml
except ImportError as exc:  # pragma: no cover - dependency gate
    raise SystemExit("PyYAML is required for package validation: python -m pip install pyyaml") from exc


ROOT = Path(__file__).resolve().parent.parent
CLAUDE_PLUGIN = ROOT / "plugins" / "ralph-specum"
CODEX_PLUGIN = ROOT / "plugins" / "ralph-specum-codex"
FIRST_CLASS_CODEX_SKILLS = {
    "ralph-specum",
    "ralph-specum-start",
    "ralph-specum-triage",
    "ralph-specum-research",
    "ralph-specum-requirements",
    "ralph-specum-design",
    "ralph-specum-tasks",
    "ralph-specum-implement",
    "ralph-specum-status",
}
SHIPPED_ROOTS = (
    ROOT / ".claude-plugin",
    ROOT / ".agents" / "plugins",
    ROOT / ".github",
    ROOT / "core",
    CLAUDE_PLUGIN,
    CODEX_PLUGIN,
)


def shipped_files(pattern: str) -> list[Path]:
    return sorted({path for root in SHIPPED_ROOTS for path in root.rglob(pattern)})


def parse_frontmatter(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return
    parts = text.split("---", 2)
    if len(parts) != 3:
        raise ValueError("unterminated frontmatter")
    document = yaml.safe_load(parts[1])
    if document is not None and not isinstance(document, dict):
        raise ValueError("frontmatter must be a mapping")


def validate_serialized_files(errors: list[str]) -> None:
    for path in shipped_files("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"invalid JSON {path.relative_to(ROOT)}: {exc}")

    toml_paths = shipped_files("*.toml") + shipped_files("*.toml.template")
    if toml_paths and tomllib is None:
        errors.append(
            "TOML files are shipped but Python has no TOML parser; use Python 3.11+"
        )
    elif tomllib is not None:
        for path in toml_paths:
            try:
                tomllib.loads(path.read_text(encoding="utf-8"))
            except (OSError, tomllib.TOMLDecodeError) as exc:
                errors.append(f"invalid TOML {path.relative_to(ROOT)}: {exc}")

    yaml_paths = shipped_files("*.yaml") + shipped_files("*.yml")
    for path in yaml_paths:
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except (OSError, yaml.YAMLError) as exc:
            errors.append(f"invalid YAML {path.relative_to(ROOT)}: {exc}")

    for path in shipped_files("*.md"):
        try:
            parse_frontmatter(path)
        except (OSError, ValueError, yaml.YAMLError) as exc:
            errors.append(f"invalid frontmatter {path.relative_to(ROOT)}: {exc}")


def validate_manifest(errors: list[str]) -> None:
    claude_manifest = json.loads(
        (CLAUDE_PLUGIN / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8")
    )
    codex_manifest = json.loads(
        (CODEX_PLUGIN / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8")
    )
    if claude_manifest.get("version") != "5.0.0":
        errors.append("Claude plugin version must be 5.0.0")
    if codex_manifest.get("version") != "5.0.0":
        errors.append("Codex plugin version must be 5.0.0")
    if codex_manifest.get("name") != CODEX_PLUGIN.name:
        errors.append("Codex manifest name must match its plugin folder")
    if "hooks" in codex_manifest:
        errors.append("Codex manifest must not register hooks")
    if codex_manifest.get("skills") != "./skills/":
        errors.append("Codex manifest must expose ./skills/")


def validate_codex_surface(errors: list[str]) -> None:
    skill_root = CODEX_PLUGIN / "skills"
    missing = [name for name in sorted(FIRST_CLASS_CODEX_SKILLS) if not (skill_root / name / "SKILL.md").is_file()]
    if missing:
        errors.append("missing first-class Codex skills: " + ", ".join(missing))
    if any(path.is_file() for path in (CODEX_PLUGIN / "hooks").rglob("*")):
        errors.append("Codex package must not ship a hooks directory")
    if any(path.is_file() for path in (CODEX_PLUGIN / "agent-configs").rglob("*")):
        errors.append("Codex package must not require agent-config templates")

    for skill_path in sorted(skill_root.glob("*/SKILL.md")):
        text = skill_path.read_text(encoding="utf-8")
        if "Claude" in text or "CLAUDE_PLUGIN_ROOT" in text:
            errors.append(f"Claude terminology leaked into {skill_path.relative_to(ROOT)}")
        if ".ralph-state.json" in text:
            errors.append(f"Codex continuation state leaked into {skill_path.relative_to(ROOT)}")
        for match in re.finditer(r"`((?:\.\./\.\./)?(?:references|scripts|templates|assets)/[^`]+)`", text):
            relative = match.group(1)
            resolved = (skill_path.parent / relative).resolve()
            if not resolved.exists():
                errors.append(
                    f"unresolved Codex skill resource {relative} in {skill_path.relative_to(ROOT)}"
                )

    for path in sorted(CODEX_PLUGIN.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        if "Claude" in text or ".claude/" in text or "/ralph-specum:" in text:
            errors.append(f"non-native terminology leaked into {path.relative_to(ROOT)}")


def validate_claude_surface(errors: list[str]) -> None:
    for path in sorted(CLAUDE_PLUGIN.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        if "Codex" in text or "`/goal`" in text:
            errors.append(f"Codex terminology leaked into {path.relative_to(ROOT)}")
    hooks = CLAUDE_PLUGIN / "hooks" / "hooks.json"
    if hooks.is_file() and "${CLAUDE_PLUGIN_ROOT}" not in hooks.read_text(encoding="utf-8"):
        errors.append("Claude hooks must use ${CLAUDE_PLUGIN_ROOT}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    errors: list[str] = []
    validate_serialized_files(errors)
    validate_manifest(errors)
    validate_codex_surface(errors)
    validate_claude_surface(errors)
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    print("native packages are valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
