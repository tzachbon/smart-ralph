---
name: ralph-specum-status
description: Report Ralph Specum artifact, task, and native goal status in Codex. Use when the user invokes `$ralph-specum-status` or asks Ralph Specum for status or progress.
---

# Ralph Specum Status

1. Resolve configured roots and `.current-spec` with `../../scripts/resolve_spec_paths.py` relative to this skill.
2. Read `progress.md` and the canonical phase artifacts for the active spec.
3. If `progress.md` is absent and `.progress.md` exists, label it legacy history. Do not migrate during a read-only status request.
4. Count task checkboxes with `../../scripts/count_tasks.py`. Treat those counts as authoritative.
5. Query native goal status through the available Codex goal surface.
6. Report the active spec, present artifacts, phase, approved-through phase, completed and remaining tasks, blockers, and next action.
7. When a native goal exists, include its status and objective. When none exists, say `Native goal: none` without treating it as an error.
8. Group non-active specs by configured root and include paths when names collide.

Do not write files, repair state, start a goal, or change Git during status.
