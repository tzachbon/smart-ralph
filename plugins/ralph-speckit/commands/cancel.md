---
name: cancel
description: Cancel active execution loop and cleanup state
argument-hint: [feature-name]
allowed-tools: [Read, Bash, Task, Skill]
---

# Cancel Execution

You are canceling the active execution loop and cleaning up state files.

## Determine Target Feature

1. If `$ARGUMENTS` contains a feature name, use that
2. Otherwise, read `.specify/.current-feature` to get active feature
3. If no active feature, inform user there's nothing to cancel

## Check State

1. Check if `.specify/specs/$feature/.speckit-state.json` exists
2. If not, inform user no active loop for this feature

## Read Current State

If state file exists, read and display:
- Current phase
- Task progress (taskIndex/totalTasks)
- Iteration count

## Cleanup

1. Stop Ralph Loop (if running):
   ```
   Use the Skill tool to invoke ralph-wiggum:cancel-ralph
   This stops any active Ralph Loop loop iteration
   ```

2. Delete state file:
   ```bash
   rm .specify/specs/$feature/.speckit-state.json
   ```

3. Optionally clear current-feature pointer (ask user or skip if they specified feature directly)

4. Keep `.progress.md` as it contains valuable context

## Output

```text
Canceled execution for feature: $feature

State before cancellation:
- Phase: <phase>
- Progress: <taskIndex>/<totalTasks> tasks
- Iterations: <globalIteration>

Cleanup:
- [x] Stopped Ralph Loop loop (/cancel-ralph)
- [x] Removed .speckit-state.json
- [ ] Kept .progress.md (contains history)

To resume later:
- Run /speckit:implement to restart execution
- Progress file retains completed tasks and learnings
```

## If No Active Loop

```text
No active execution loop found.

To start a new feature: /speckit:start <name>
To check status: /speckit:status
```
