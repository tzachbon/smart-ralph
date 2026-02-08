---
description: Safely remove orphaned team directories
argument-hint: [--force]
allowed-tools: [Read, Bash, AskUserQuestion]
---

# Cleanup Teams

You are scanning for and removing orphaned agent team directories.

## Orphaned Team Detection

An orphaned team is a team directory in `~/.claude/teams/` that does NOT have a corresponding entry in any spec's `.ralph-state.json` file.

**Detection Logic**:
1. List all directories in `~/.claude/teams/`
2. For each team directory, scan all spec directories for matching `teamName` in `.ralph-state.json`
3. If no spec has this `teamName`, the team is orphaned
4. Teams older than 1 hour are considered stale

## Scan Process

1. **List all team directories**:
   ```bash
   ls -1 ~/.claude/teams/
   ```

2. **Cross-reference with state files**:
   For each team directory:
   - Search all spec directories for `.ralph-state.json` files
   - Check if any state file has `teamName` matching this team directory
   - If no match found, team is orphaned

3. **Check team age**:
   ```bash
   # Extract timestamp from team name (e.g., research-spec-1234567890)
   # Calculate age: current_time - team_timestamp
   # If age > 3600 seconds (1 hour), mark as stale
   ```

## User Confirmation

<mandatory>
**Before deleting any team, prompt the user for confirmation**:
- Display each orphaned team found
- Show team name, age, and directory path
- Ask: "Remove this orphaned team? (y/n)"
- Process only teams confirmed by user
</mandatory>

**Skip confirmation with --force flag**:
If `--force` appears in `$ARGUMENTS`, delete all orphaned teams without prompting.

## Removal Process

For each confirmed orphaned team:

1. **Log the action**:
   ```
   Removing orphaned team: $teamName
   Directory: ~/.claude/teams/$teamName/
   Age: $age_minutes minutes
   ```

2. **Execute TeamDelete**:
   Use TeamDelete tool to cleanly remove the team directory
   - Tool: `TeamDelete`
   - Input: team directory path

3. **Verify removal**:
   ```bash
   # Check if directory still exists
   if [ -d "~/.claude/teams/$teamName" ]; then
     echo "WARNING: Team directory still exists after TeamDelete"
   else
     echo "Successfully removed: $teamName"
   fi
   ```

4. **Log failures**:
   If TeamDelete fails:
   - Log error with team directory path
   - Suggest manual cleanup: `rm -rf ~/.claude/teams/$teamName`

## Output Format

```
# Orphaned Team Cleanup

Scanning for orphaned teams...
Found 2 orphaned teams:

### Team 1: research-old-spec-1234567890
Status: ORPHANED
Directory: ~/.claude/teams/research-old-spec-1234567890/
Age: 150 minutes (2 hours 30 minutes)
Reason: No spec found with matching teamName

Remove this team? (y/n): [user enters 'y']
✓ Removed: research-old-spec-1234567890

### Team 2: exec-abandoned-9876543210
Status: ORPHANED
Directory: ~/.claude/teams/exec-abandoned-9876543210/
Age: 45 minutes
Reason: No spec found with matching teamName

Remove this team? (y/n): [user enters 'n']
Skipped: exec-abandoned-9876543210

## Summary
- Orphaned teams found: 2
- Teams removed: 1
- Teams skipped: 1
- Failures: 0

All orphaned teams have been processed.
Run /ralph-specum:team-status to verify no orphaned teams remain.
```

## If No Orphaned Teams

```
# Orphaned Team Cleanup

Scanning for orphaned teams...

No orphaned teams found.

All team directories have corresponding spec state entries.
```

## Error Handling

If TeamDelete fails:
```
Error: Failed to remove team $teamName
Directory: ~/.claude/teams/$teamName/
Error details: <error from TeamDelete>

Manual cleanup required:
  rm -rf ~/.claude/teams/$teamName

Caution: Manual deletion is safe only if team is truly orphaned.
```

If ~/.claude/teams/ directory doesn't exist:
```
No teams directory found at ~/.claude/teams/
This is normal if no agent teams have been created yet.
```

## Safety Checks

Before removing any team:

1. **Verify team is truly orphaned**:
   - Checked all spec directories
   - No matching teamName in any .ralph-state.json

2. **Verify team age**:
   - Team is at least 1 hour old
   - Prevents deletion of recently created teams

3. **User confirmation**:
   - Unless --force flag is set
   - User must explicitly confirm each deletion

4. **Logging**:
   - All actions logged for audit trail
   - Failures clearly marked with manual cleanup instructions
