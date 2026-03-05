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
4. Update files in order:
   - `requirements.md`
   - `design.md`
   - `tasks.md`
5. If requirements changed, revisit design and tasks.
6. If design changed, revisit tasks.
7. Record the rationale in `.progress.md`.
