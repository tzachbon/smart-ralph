---
description: Restore working tree to pre-execution git checkpoint via rollback
argument-hint: [spec-name-or-path]
allowed-tools: [Read, Bash]
---

# Checkpoint Rollback

You are rolling back the working tree to the pre-execution git checkpoint stored in the spec's state file.

## Determine Target Spec

1. If `$ARGUMENTS` contains input:
   - If starts with `./` or `/`: treat as full path, validate it exists
   - Otherwise: treat as spec name, use `ralph_find_spec()` pattern to search
2. If no argument provided:
   - Use `ralph_resolve_current()` pattern to get active spec path from `.current-spec`
3. If no active spec and no argument, inform user there is no active spec to rollback

## Locate State File

1. Construct state file path: `$STATE_FILE=$spec_path/.ralph-state.json`
2. If state file does not exist: output error "No execution state found for spec: $spec_path" and exit
3. If state file exists but has no checkpoint field: output error "No checkpoint available for spec: $spec_path" and exit

## Validate Checkpoint

1. Read the checkpoint SHA from the state file:
   ```bash
   SHA=$(jq -r '.checkpoint.sha // empty' "$STATE_FILE" 2>/dev/null)
   ```
2. If `$SHA` is empty: output error "No checkpoint SHA found — execution may have started without a git checkpoint" and exit
3. If `$SHA` is the literal string "null": output error "Checkpoint SHA is null — likely due to detached HEAD or no git repo. Cannot rollback." and exit

## Perform Rollback

1. Source the checkpoint infrastructure:
   ```bash
   source "$CLAUDE_PLUGIN_ROOT/hooks/scripts/checkpoint.sh"
   ```
2. Call the rollback function:
   ```bash
   if ! checkpoint-rollback "$STATE_FILE"; then
     echo "ERROR: Rollback failed. Check git logs for details."
     exit 1
   fi
   ```

## Output

```
Rolled back spec '$spec_name' to checkpoint.

Location: $spec_path
Checkpoint SHA: $SHA

Working tree restored to the state captured before execution.
All uncommitted changes since the checkpoint have been discarded.

To start fresh execution:
- Run /ralph-specum:start $spec_name
- Or /ralph-specum:new $spec_name <goal>
```
