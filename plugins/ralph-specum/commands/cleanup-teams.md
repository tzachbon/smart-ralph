---
description: Safely remove orphaned team directories
argument-hint: [--force]
allowed-tools: [Read, Bash, Skill, AskUserQuestion]
---

# Cleanup Teams

Remove orphaned agent team directories that are no longer referenced by any active spec.

## Determine Mode

From `$ARGUMENTS`:
- **--force**: Skip confirmation prompts and delete all orphaned teams
- **No flags**: Prompt for each orphaned team before deletion

## Scan for Orphaned Teams

1. List all directories in ~/.claude/teams/
2. For each team directory:
   - Extract team name from directory path
   - Scan all spec directories for .ralph-state.json files
   - Check if any state file has teamName matching this team
3. Mark as orphaned if no state file references it

## Cleanup Workflow

For each orphaned team:

**Normal mode (no --force)**:
1. Prompt user: "Delete orphaned team $team_name? (age: X minutes) [y/N]"
2. If user confirms:
   - Attempt graceful TeamDelete
   - If TeamDelete fails, force rm -rf the directory
   - Log deletion
3. If user declines, skip to next orphan

**Force mode (--force)**:
1. For each orphaned team:
   - Attempt graceful TeamDelete
   - If TeamDelete fails, force rm -rf the directory
   - Log deletion

## Output Format

For each deletion:
```
Deleting orphaned team: research-old-spec-1234567890
Directory: ~/.claude/teams/research-old-spec-1234567890
Method: TeamDelete (or rm -rf if TeamDelete failed)
Status: Success
```

Summary:
```
Cleanup complete: X orphaned teams deleted, Y skipped, Z errors
```

## Error Handling

If TeamDelete fails:
- Log error with team directory path
- Attempt fallback: rm -rf "$team_dir"
- If fallback also fails, log error for manual cleanup

## Safety

- Never delete teams that are referenced in active state files
- Always cross-reference before deletion
- Log all actions for audit trail
