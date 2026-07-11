---
name: ralph-specum-implement
description: Implement approved Ralph Specum tasks using native Codex subagents or `/goal`. Use when the user invokes `$ralph-specum-implement` or asks Ralph Specum to implement, resume, finish, run quickly, or work autonomously.
---

# Ralph Specum Implement

Read `../../references/workflow.md` and `../../references/state-contract.md` relative to this skill.

## Preconditions

1. Resolve the active spec and require approved `tasks.md`.
2. Count checkboxes with `../../scripts/count_tasks.py`. Task checkboxes are authoritative.
3. Read `progress.md`. If only `.progress.md` exists, create a reviewed canonical summary before implementation and leave the legacy file unchanged and unstaged.
4. Stop when tasks are unapproved or no actionable unchecked task exists.

## Explicit autonomous execution

Treat only explicit autonomous, quick, finish, or long-running wording as permission to start native `/goal`.

Build the goal objective with the resolved spec path, selected unchecked tasks, constraints, verification commands, and this terminal condition: selected tasks are checked, verification passes, `progress.md` is current, and no selected work remains. Do not include a token budget unless the user supplied one. Let native goal state own persistence and resume behavior.

## Normal execution

Without explicit autonomous intent, execute one verified logical batch and return:

1. Select the smallest coherent set of unchecked tasks with one verification boundary.
2. Give one write subagent a bounded packet with the `bounded executor` role and `medium` reasoning tier. Raise the tier to `strongest` only for a genuinely high-risk batch. Permit only the implementation files for that batch. Prohibit edits to `tasks.md`, `progress.md`, `.current-spec`, and Git state.
3. Require `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`.
4. Allow at most three attempts. Stop after the third failure with evidence.
5. Validate the diff and run the narrowest useful verification as the root coordinator.
6. Only after verification passes, mark the completed checkboxes and atomically update `progress.md`.
7. Commit the verified logical batch when commits are enabled. Do not commit per small task.
8. Report the batch, verification, remaining task count, and any risk.

Use one write subagent at a time. Parallel writes require disjoint files and isolated worktrees. Do not create adapter-local continuation state or hooks.
