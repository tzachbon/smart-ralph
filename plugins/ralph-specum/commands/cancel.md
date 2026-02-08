---
description: Cancel active execution loop, cleanup state, and remove spec
argument-hint: [spec-name-or-path]
allowed-tools: [Read, Bash, Task]
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
- **Team name** (if teamName field exists)
- **Teammate count** (if teammateNames field exists)

## Team Shutdown Protocol

<mandatory>
**If active team detected in state** (teamName field exists):
1. Send shutdown_request to all teammates via SendMessage
2. Wait up to 10 seconds for graceful shutdown approvals
3. If all teammates approve: Delete team with TeamDelete
4. If timeout or unresponsive: Force TeamDelete after 10s
5. Clear team fields from state (teamName: null, teammateNames: [], teamPhase: null)
</mandatory>

**Shutdown Request Pattern**:
```text
For each teammate in teammateNames:
  SendMessage:
    type: shutdown_request
    recipient: <teammate-name>
    content: "Canceling spec execution, shutting down team"
```

**Forced Cleanup Fallback**:
If teammates don't respond within 10 seconds:
- Log warning: "Team did not shut down gracefully, forcing cleanup"
- Execute TeamDelete with team directory path
- Proceed with spec cleanup regardless of team deletion success
- Log team directory path for manual cleanup if TeamDelete fails

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
- Team: <teamName or "none">
- Teammates: <teammateNames or "none">

Cleanup:
- [x] Removed .ralph-state.json
- [x] Removed spec directory ($spec_path)
- [x] Cleared current spec marker
- [x] Shutdown team: <teamName or "N/A">
- [x] Deleted team directory: <status>

The spec and all its files have been permanently removed.
<If team was active, add:>
All teammates have been notified and the team has been shut down.

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
- [x] Removed spec directory ($spec_path)
- [x] Cleared current spec marker

The spec has been removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```
