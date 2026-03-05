---
name: ralph-specum-refactor
description: This skill should be used when the user asks to refactor Ralph spec files in Codex, update requirements design or tasks after implementation learnings, or mentions "$ralph-specum-refactor".
metadata:
  surface: helper
  action: refactor
---

# Ralph Specum Refactor

Use this to revise spec artifacts after implementation learnings.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Review files in order: `requirements.md`, `design.md`, `tasks.md`
- Cascade downstream updates when upstream content changes

## Action

1. Resolve the target spec.
2. Read `.progress.md` and existing spec files.
3. Identify what implementation changed, what stayed accurate, and what is now obsolete.
4. Preserve newer Ralph concepts already expressed in the spec, including approval checkpoints, granularity choices, `[P]` tasks, `[VERIFY]` tasks, VE tasks, and epic constraints when relevant.
5. Update files in order:
   - `requirements.md`
   - `design.md`
   - `tasks.md`
6. If requirements changed, revisit design and tasks.
7. If design changed, revisit tasks.
8. Record the rationale and cascade decisions in `.progress.md`.
