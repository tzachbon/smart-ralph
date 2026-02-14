---
description: Cancel active execution loop, cleanup state, and remove spec
argument-hint: [spec-name-or-path]
allowed-tools: [Read, Bash, Task, Skill]
---

# Cancel Execution

You are canceling the active execution loop, cleaning up state files, and removing the spec directory.

## Multi-Directory Resolution

This command uses the path resolver for multi-root spec discovery:

```bash
# Source the path resolver (conceptual - commands use these patterns)
# ralph_find_spec(name)   - Find spec by name across all roots
# ralph_resolve_current() - Get current spec's full path
```

## Determine Target Spec

1. If `$ARGUMENTS` contains input:
   - If starts with `./` or `/`: treat as full path, validate it exists
   - Otherwise: treat as spec name, use `ralph_find_spec()` pattern to search
2. If no argument provided:
   - Use `ralph_resolve_current()` pattern to get active spec path from `.current-spec`
3. If no active spec and no argument, inform user there's nothing to cancel

### Handle Disambiguation

If spec name exists in multiple roots (exit code 2 from find):

```
Multiple specs named '$name' found:
1. ./specs/$name
2. ./packages/api/specs/$name

Specify: /ralph-specum:cancel ./packages/api/specs/$name
```

Do NOT automatically select one. User must specify the full path.

## Check State

1. Check if `$spec_path/.ralph-state.json` exists (where `$spec_path` is the resolved full path)
2. If not, inform user no active loop for this spec

## Read Current State

If state file exists, read and display:
- Current phase
- Task progress (taskIndex/totalTasks)
- Iteration count

## Stop Ralph Loop

Before cleaning up files, stop any active Ralph Wiggum loop:

1. Invoke `/cancel-ralph` via the Skill tool
2. This may fail silently if no active Ralph loop is running — this is expected and OK
3. Proceed with file cleanup regardless of whether /cancel-ralph succeeded

## Cleanup

1. Delete state file:
   ```bash
   rm $spec_path/.ralph-state.json
   ```

2. Remove spec directory:
   ```bash
   rm -rf $spec_path
   ```

3. Clear current spec marker:
   ```bash
   rm -f ./specs/.current-spec
   ```

4. Update Spec Index (removes deleted spec from index):
   ```bash
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```

## Output

```
Canceled execution for spec: $spec_name

Location: $spec_path
State before cancellation:
- Phase: <phase>
- Progress: <taskIndex>/<totalTasks> tasks
- Iterations: <globalIteration>

Cleanup:
- [x] Stopped Ralph loop (via /cancel-ralph)
- [x] Removed .ralph-state.json
- [x] Removed spec directory ($spec_path)
- [x] Cleared current spec marker

The spec and all its files have been permanently removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```

## If No Active Loop

If there's no `.ralph-state.json`, still proceed with removing the spec directory and clearing `.current-spec`:

```
No active execution loop found for spec: $spec_name

Location: $spec_path
Cleanup:
- [x] Stopped Ralph loop (via /cancel-ralph, if active)
- [x] Removed spec directory ($spec_path)
- [x] Cleared current spec marker

The spec has been removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```
