---
name: ralph-specum-tasks
description: This skill should be used when the user asks to generate Ralph tasks in Codex, write `tasks.md`, approve design and move to task planning, or mentions "$ralph-specum-tasks".
metadata:
  surface: helper
  action: tasks
---

# Ralph Specum Tasks

Use this for the tasks phase.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md` and `design.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md` and `design.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
4. Write or rewrite `tasks.md`.
5. Count tasks and merge state with:
   - `phase: "tasks"`
   - `awaitingApproval: true`
   - `taskIndex: first incomplete or 0`
   - `totalTasks: counted tasks`
6. Update `.progress.md` with the phase breakdown, next milestone, blockers, and next step.
7. If spec commits are enabled, commit only the spec artifacts.
8. In quick mode, continue directly into implementation.

## Output Shape

Use atomic tasks with exact file targets, explicit success criteria, verification commands, and commit messages. Preserve POC-first ordering.
