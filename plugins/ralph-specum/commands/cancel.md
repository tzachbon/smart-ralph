---
description: Cancel active execution loop and cleanup state
argument-hint: [spec-name]
allowed-tools: [Read, Bash, Task]
---

# Cancel Execution

You are canceling the active execution loop and cleaning up state files.

## Determine Target Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, inform user there's nothing to cancel

## Check State

1. Check if `./specs/$spec/.ralph-state.json` exists
2. If not, inform user no active loop for this spec

## Read Current State

If state file exists, read and display:
- Current phase
- Task progress (taskIndex/totalTasks)
- Iteration count

## Cleanup

1. Stop Ralph loop (if running):
   ```text
   Use the Skill tool to invoke ralph-loop:cancel-ralph
   This stops any active Ralph loop iteration
   ```

2. Delete state file:
   ```bash
   rm ./specs/$spec/.ralph-state.json
   ```

3. Keep `.progress.md` as it contains valuable context

## Output

```
Canceled execution for spec: $spec

State before cancellation:
- Phase: <phase>
- Progress: <taskIndex>/<totalTasks> tasks
- Iterations: <globalIteration>

Cleanup:
- [x] Stopped Ralph loop (/ralph-loop:cancel-ralph)
- [x] Removed .ralph-state.json
- [ ] Kept .progress.md (contains history)

To resume later:
- Run /ralph-specum:implement to restart execution
- Progress file retains completed tasks and learnings
```

## If No Active Loop

```
No active execution loop found.

To start a new spec: /ralph-specum:new <name>
To check status: /ralph-specum:status
```
