---
name: ralph-specum-help
description: This skill should be used when the user asks for Ralph help in Codex, wants the Ralph command surface explained, needs quick mode guidance, or mentions "$ralph-specum-help".
metadata:
  surface: helper
  action: help
---

# Ralph Specum Help

Use this to explain the Ralph Specum surface in Codex.

## Cover

- Primary skill: `$ralph-specum`
- Helper skills: `$ralph-specum-start`, `$ralph-specum-research`, `$ralph-specum-requirements`, `$ralph-specum-design`, `$ralph-specum-tasks`, `$ralph-specum-implement`, `$ralph-specum-status`, `$ralph-specum-switch`, `$ralph-specum-cancel`, `$ralph-specum-index`, `$ralph-specum-refactor`, `$ralph-specum-feedback`, `$ralph-specum-help`
- Normal flow: start, research, requirements, design, tasks, implement
- Quick mode: generate missing artifacts and continue into implementation in one run
- Disk contract: `./specs` or configured roots, `.current-spec`, per-spec markdown files, `.ralph-state.json`

## Guidance

- Recommend `$ralph-specum` as the default entrypoint.
- Mention helper skills when the user wants explicit phase control.
- Mention optional bootstrap assets only when the user wants repo-local guidance.
