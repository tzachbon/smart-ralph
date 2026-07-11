#!/usr/bin/env python3
"""Static and behavioral checks for the native Codex adapter."""

from __future__ import annotations

import importlib.util
import re
import tempfile
import unittest
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = PLUGIN_ROOT / "skills"
FIRST_CLASS = {
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
SHIMS = {
    "ralph-specum-switch",
    "ralph-specum-cancel",
    "ralph-specum-index",
    "ralph-specum-refactor",
    "ralph-specum-feedback",
    "ralph-specum-help",
}
PHASES = {
    "ralph-specum-triage",
    "ralph-specum-research",
    "ralph-specum-requirements",
    "ralph-specum-design",
    "ralph-specum-tasks",
    "ralph-specum-implement",
}


def skill_text(name: str) -> str:
    return (SKILLS_ROOT / name / "SKILL.md").read_text(encoding="utf-8")


class NativeContractTests(unittest.TestCase):
    def test_first_class_skills_and_v5_shims_exist(self) -> None:
        for name in FIRST_CLASS | SHIMS:
            self.assertTrue((SKILLS_ROOT / name / "SKILL.md").is_file(), name)

    def test_frontmatter_contains_only_supported_keys(self) -> None:
        for path in SKILLS_ROOT.glob("*/SKILL.md"):
            match = re.match(r"^---\n(.*?)\n---\n", path.read_text(encoding="utf-8"), re.DOTALL)
            self.assertIsNotNone(match, path)
            keys = {
                line.split(":", 1)[0]
                for line in match.group(1).splitlines()
                if line and not line.startswith(" ")
            }
            self.assertEqual({"name", "description"}, keys, path)

    def test_installed_relative_resources_resolve(self) -> None:
        resource_pattern = re.compile(r"`((?:\.\./)+(?:[^`\n]+))`")
        for path in SKILLS_ROOT.glob("*/SKILL.md"):
            for relative in resource_pattern.findall(path.read_text(encoding="utf-8")):
                target = (path.parent / relative).resolve()
                self.assertTrue(target.exists(), f"{path}: missing {relative}")

    def test_phase_skills_define_bounded_native_results(self) -> None:
        for name in PHASES:
            text = skill_text(name)
            self.assertIn("native", text.lower(), name)
            self.assertIn("bounded packet", text, name)
            for heading in (
                "Answer",
                "Evidence",
                "Risks",
                "Verification performed",
                "Changed files",
            ):
                self.assertIn(heading, text, f"{name}: {heading}")

    def test_phase_skills_require_delegation_and_reasoning_tiers(self) -> None:
        expected = {
            "ralph-specum-triage": ("Delegate the primary decomposition", "`strongest`"),
            "ralph-specum-research": ("Delegate substantive research", "`medium`"),
            "ralph-specum-requirements": ("Delegate substantive requirements", "`medium`"),
            "ralph-specum-design": ("Delegate the primary architecture", "`strongest`"),
            "ralph-specum-tasks": ("Delegate task decomposition", "`light`"),
            "ralph-specum-implement": ("Give one write subagent", "`medium`"),
        }
        for name, tokens in expected.items():
            text = skill_text(name)
            for token in tokens:
                self.assertIn(token, text, f"{name}: {token}")

        workflow = (PLUGIN_ROOT / "references" / "workflow.md").read_text(encoding="utf-8")
        self.assertIn("Role:", workflow)
        self.assertIn("Reasoning tier: light | medium | strongest", workflow)
        self.assertIn("Delegate substantive research, requirements, design, tasks, and triage", workflow)
        self.assertIn("Never install or require custom agent TOML", workflow)

    def test_implementation_uses_goal_only_for_explicit_intent(self) -> None:
        text = skill_text("ralph-specum-implement")
        self.assertIn("only explicit autonomous, quick, finish, or long-running", text)
        self.assertIn("Do not include a token budget unless the user supplied one", text)
        self.assertIn("execute one verified logical batch and return", text)

    def test_status_combines_artifacts_tasks_and_native_goal(self) -> None:
        text = skill_text("ralph-specum-status")
        self.assertIn("canonical phase artifacts", text)
        self.assertIn("task checkboxes", text)
        self.assertIn("native goal status", text)

    def test_shims_warn_and_route_to_primary(self) -> None:
        for name in SHIMS:
            text = skill_text(name)
            self.assertIn("deprecated in v5 and removed in v6", text, name)
            self.assertIn("$ralph-specum", text, name)

    def test_no_custom_agents_or_stop_hook_are_shipped(self) -> None:
        self.assertFalse(any((PLUGIN_ROOT / "agent-configs").glob("*")))
        self.assertFalse((PLUGIN_ROOT / "hooks" / "stop-watcher.sh").exists())
        self.assertFalse((PLUGIN_ROOT / "scripts" / "merge_state.py").exists())

    def test_path_resolver_rejects_workspace_escape(self) -> None:
        script = PLUGIN_ROOT / "scripts" / "resolve_spec_paths.py"
        spec = importlib.util.spec_from_file_location("resolve_spec_paths", script)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir).resolve()
            self.assertEqual("./specs", module.workspace_relative(root, "./specs"))
            with self.assertRaises(ValueError):
                module.workspace_relative(root, "../outside")


if __name__ == "__main__":
    unittest.main()
