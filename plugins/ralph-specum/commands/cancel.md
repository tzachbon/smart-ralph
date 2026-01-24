---
description: Cancel active execution loop, cleanup state, and remove spec
argument-hint: [spec-name]
allowed-tools: [Read, Bash, Task]
---

# Cancel Execution

You are canceling the active execution loop, cleaning up state files, and removing the spec directory.

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

3. Remove spec directory:
   ```bash
   rm -rf ./specs/$spec
   ```

4. Clear current spec marker:
   ```bash
   rm -f ./specs/.current-spec
   ```

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
- [x] Removed spec directory (./specs/$spec)
- [x] Cleared current spec marker

The spec and all its files have been permanently removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```

## If No Active Loop

If there's no `.ralph-state.json`, still proceed with removing the spec directory and clearing `.current-spec`:

```
No active execution loop found for spec: $spec

Cleanup:
- [x] Removed spec directory (./specs/$spec)
- [x] Cleared current spec marker

The spec has been removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```
