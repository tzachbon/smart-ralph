---
name: ralph-specum-implement
description: This skill should be used when the user asks to execute Ralph tasks in Codex, resume Ralph implementation, finish a Ralph backlog, recover from an interrupted run, or mentions "$ralph-specum-implement".
metadata:
  surface: helper
  action: implement
---

# Ralph Specum Implement

Use this for the implementation phase.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `tasks.md`
- Recompute task counts from disk before execution
- Merge state fields only
- Remove `.ralph-state.json` only when all tasks are complete and verified

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `tasks.md`. Read `.progress.md`, current state, and current task markers.
3. Recompute `totalTasks`, completed count, and the first incomplete task.
4. Merge state for execution:
   - `phase: "execution"`
   - `awaitingApproval: false`
   - `totalTasks`
   - `taskIndex: first incomplete`
   - preserve `taskIteration`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations`, `commitSpec`, and `relatedSpecs`
5. Execute tasks in order until complete or blocked.
6. `[P]` tasks may batch only when file overlap is low and verification is independent.
7. `[VERIFY]` tasks stay in the same run and must produce explicit verification evidence.
8. After each task or safe batch:
   - mark the checkbox
   - update `.progress.md`
   - merge the state update
   - use the task `Commit` line unless commits were explicitly disabled
9. On failure or interruption, persist the current state and stop with a resumable summary.
10. On full completion, remove `.ralph-state.json` and report completion.

## Resume Rules

- Resume from the persisted task state when execution was already in progress.
- If disk state and task checkboxes disagree, prefer `tasks.md` for completion and repair state to match.
