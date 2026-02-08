---
name: team-management
description: Use for team status queries, orphaned team detection, and team cleanup operations. Provides utilities for monitoring active agent teams and removing orphaned team directories.
---

# Team Management Skill

Provides team status and cleanup utilities for agent teams. Queries state files for active teams, scans for orphaned team directories, and coordinates cleanup operations.

## When To Use

Invoke this skill when:
- User runs `/ralph-specum:team-status [spec-name]` - Display active teams
- User runs `/ralph-specum:cleanup-teams` - Remove orphaned teams
- Orphaned team detected by `hooks/scripts/stop-watcher.sh`
- Manual cleanup needed after crash or forced shutdown

## Active Team Detection

### Query Active Teams from State Files

Scan all spec directories for `.ralph-state.json` files with `teamName` field:

```bash
# Find all active teams
find ./specs -name ".ralph-state.json" -exec jq -r 'select(.teamName != null) | "\(.teamName)|\(.teamPhase)|\(.teammateNames | length)"' {} \; 2>/dev/null | \
  while IFS='|' read -r teamName phase teammateCount; do
    echo "Team: $teamName"
    echo "  Phase: $phase"
    echo "  Teammates: $teammateCount"
    echo "  Spec: $(basename $(dirname $file))"
    echo ""
  done
```

**Output format:**
```
Active Teams:
  research-auth-flow-1738900000 (Research Phase)
    Teammates: 5 (oauth2-researcher, security-analyst, codebase-explorer, session-specialist, token-expert)
    Spec: auth-flow

  exec-dashboard-1738901234 (Execution Phase)
    Teammates: 3 (executor-1, executor-2, executor-3)
    Spec: dashboard
```

### Filter by Spec Name

If user provides spec-name argument, filter results:

```bash
if [ -n "$SPEC_NAME" ]; then
  # Check specific spec
  STATE_FILE="./specs/${SPEC_NAME}/.ralph-state.json"

  if [ -f "$STATE_FILE" ]; then
    TEAM_NAME=$(jq -r '.teamName // empty' "$STATE_FILE")

    if [ -n "$TEAM_NAME" ]; then
      echo "Active team: $TEAM_NAME"
      jq '.' "$STATE_FILE"
    else
      echo "No active team for spec: $SPEC_NAME"
    fi
  else
    echo "Spec not found: $SPEC_NAME"
  fi
fi
```

## Orphaned Team Detection

### Cross-Reference Team Directories with State Files

Orphaned teams exist when:
- Team directory in `~/.claude/teams/` exists
- No matching `teamName` in any `.ralph-state.json` file
- Team directory > 1 hour old (avoid false positives during creation)

```bash
# Detect orphaned teams
TEAM_DIR="$HOME/.claude/teams"

for team_dir in "$TEAM_DIR"/research-* "$TEAM_DIR"/exec-*; do
  if [ -d "$team_dir" ]; then
    TEAM_NAME=$(basename "$team_dir")

    # Check if team exists in any state file
    ACTIVE=$(find ./specs -name ".ralph-state.json" -exec jq -r "select(.teamName == \"$TEAM_NAME\")" {} \; 2>/dev/null)

    if [ -z "$ACTIVE" ]; then
      # Check team directory age
      CREATION_TIME=$(stat -c %Y "$team_dir" 2>/dev/null || stat -f %m "$team_dir")
      NOW=$(date +%s)
      AGE_HOURS=$(( (NOW - CREATION_TIME) / 3600 ))

      if [ "$AGE_HOURS" -ge 1 ]; then
        echo "WARNING: Orphaned team detected: $TEAM_NAME"
        echo "  Age: ${AGE_HOURS}h"
        echo "  Directory: $team_dir"
        echo "  Consider running: /ralph-specum:cleanup-teams"
      fi
    fi
  fi
done
```

**Orphaned team scenarios:**
- Crash during research/execution (state file not updated)
- Forced shutdown (SIGKILL) preventing graceful cleanup
- Network/ filesystem error during TeamDelete
- Manual tmux session creation outside of Ralph workflow

### Orphaned Team Warning Integration

The `hooks/scripts/stop-watcher.sh` scans for orphaned teams on every session stop:

```bash
# In stop-watcher.sh, after state file checks
echo "Checking for orphaned agent teams..."

bash -c '
  TEAM_DIR="$HOME/.claude/teams"
  for team_dir in "$TEAM_DIR"/research-* "$TEAM_DIR"/exec-*; do
    if [ -d "$team_dir" ]; then
      TEAM_NAME=$(basename "$team_dir")
      ACTIVE=$(find ./specs -name ".ralph-state.json" -exec jq -r "select(.teamName == \"$TEAM_NAME\")" {} \; 2>/dev/null)

      if [ -z "$ACTIVE" ]; then
        CREATION_TIME=$(stat -c %Y "$team_dir" 2>/dev/null || stat -f %m "$team_dir")
        NOW=$(date +%s)
        AGE=$(( (NOW - CREATION_TIME) / 3600 ))

        if [ "$AGE" -ge 1 ]; then
          echo "⚠️  Orphaned team: $TEAM_NAME (${AGE}h old)"
          echo "   Directory: $team_dir"
          echo "   Cleanup: /ralph-specum:cleanup-teams"
        fi
      fi
    fi
  done
'
```

## Cleanup Workflow

### Interactive Cleanup Prompt

For each orphaned team, prompt user for confirmation:

```bash
# Orphaned team cleanup
TEAM_DIR="$HOME/.claude/teams"

for team_dir in "$TEAM_DIR"/research-* "$TEAM_DIR"/exec-*; do
  if [ -d "$team_dir" ]; then
    TEAM_NAME=$(basename "$team_dir")

    # Verify orphaned (no state file reference)
    ACTIVE=$(find ./specs -name ".ralph-state.json" -exec jq -r "select(.teamName == \"$TEAM_NAME\")" {} \; 2>/dev/null)

    if [ -z "$ACTIVE" ]; then
      # Prompt user
      echo "Found orphaned team: $TEAM_NAME"
      echo "  Directory: $team_dir"
      echo "  Created: $(stat -c %y "$team_dir" 2>/dev/null | cut -d'.' -f1)"

      read -p "Delete this team? [y/N] " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Force TeamDelete (bypass shutdown protocol)
        echo "Deleting orphaned team: $TEAM_NAME"

        # Kill tmux sessions
        tmux kill-session -t "$TEAM_NAME" 2>/dev/null

        # Remove team directory
        rm -rf "$team_dir"

        echo "✓ Deleted: $TEAM_NAME"
      else
        echo "Skipped: $TEAM_NAME"
      fi
    fi
  fi
done

echo "Cleanup complete."
```

### Force Cleanup (Non-Interactive)

For automated cleanup (CI/CD, scripts):

```bash
# Force delete all orphaned teams (no prompts)
cleanup-teams --force

TEAM_DIR="$HOME/.claude/teams"

find "$TEAM_DIR" -maxdepth 1 -type d -name "research-*" -o -name "exec-*" | \
  while read -r team_dir; do
    TEAM_NAME=$(basename "$team_dir")

    # Verify orphaned
    ACTIVE=$(find ./specs -name ".ralph-state.json" -exec jq -r "select(.teamName == \"$TEAM_NAME\")" {} \; 2>/dev/null)

    if [ -z "$ACTIVE" ]; then
      echo "Force deleting orphaned team: $TEAM_NAME"
      tmux kill-session -t "$TEAM_NAME" 2>/dev/null
      rm -rf "$team_dir"
      echo "✓ Deleted: $TEAM_NAME"
    fi
  done
```

## Team Status Display

### Detailed Team Information

Show comprehensive team status including:

```bash
# Team status for active teams
echo "=== Active Agent Teams ==="
echo ""

find ./specs -name ".ralph-state.json" -exec sh -c '
  STATE_FILE="$1"
  SPEC_NAME=$(basename "$(dirname "$STATE_FILE")")

  TEAM_DATA=$(jq -r "select(.teamName != null)" "$STATE_FILE" 2>/dev/null)

  if [ -n "$TEAM_DATA" ]; then
    TEAM_NAME=$(jq -r ".teamName" "$STATE_FILE")
    PHASE=$(jq -r ".teamPhase" "$STATE_FILE")
    TEAMMATES=$(jq -r ".teammateNames[]" "$STATE_FILE")

    echo "Team: $TEAM_NAME"
    echo "  Spec: $SPEC_NAME"
    echo "  Phase: $PHASE"
    echo "  Teammates:"

    # Get teammate status from TaskList if available
    for teammate in $TEAMMATES; do
      # Check if teammate has claimed tasks
      OWNER_TASKS=$(jq -r "map(select(.owner == \"$teammate\")) | length" ./specs/"$SPEC_NAME"/.ralph-state.json 2>/dev/null)

      if [ "$OWNER_TASKS" -gt 0 ]; then
        echo "    - $teammate (working, $OWNER_TASKS tasks claimed)"
      else
        echo "    - $teammate (idle)"
      fi
    done

    echo "  Directory: ~/.claude/teams/$TEAM_NAME"
    echo ""
  fi
' sh {} \;

echo "=== Orphaned Teams ==="
echo ""

# Check for orphaned teams (directories without state references)
TEAM_DIR="$HOME/.claude/teams"

for team_dir in "$TEAM_DIR"/research-* "$TEAM_DIR"/exec-*; do
  if [ -d "$team_dir" ]; then
    TEAM_NAME=$(basename "$team_dir")
    ACTIVE=$(find ./specs -name ".ralph-state.json" -exec jq -r "select(.teamName == \"$TEAM_NAME")" {} \; 2>/dev/null)

    if [ -z "$ACTIVE" ]; then
      CREATION_TIME=$(stat -c %Y "$team_dir" 2>/dev/null || stat -f %m "$team_dir")
      NOW=$(date +%s)
      AGE=$(( (NOW - CREATION_TIME) / 3600 ))

      echo "⚠️  Orphaned: $TEAM_NAME (${AGE}h old)"
      echo "   Directory: $team_dir"
      echo "   Cleanup: /ralph-specum:cleanup-teams"
      echo ""
    fi
  fi
done
```

**Example output:**
```
=== Active Agent Teams ===

Team: research-auth-flow-1738900000
  Spec: auth-flow
  Phase: research
  Teammates:
    - oauth2-researcher (working, 1 task claimed)
    - security-analyst (working, 1 task claimed)
    - codebase-explorer (idle)
    - session-specialist (working, 1 task claimed)
    - token-expert (working, 1 task claimed)
  Directory: ~/.claude/teams/research-auth-flow-1738900000

Team: exec-dashboard-1738901234
  Spec: dashboard
  Phase: execution
  Teammates:
    - executor-1 (working, 2 tasks claimed)
    - executor-2 (working, 2 tasks claimed)
    - executor-3 (idle)
  Directory: ~/.claude/teams/exec-dashboard-1738901234

=== Orphaned Teams ===

⚠️  Orphaned: exec-api-cache-1738902345 (3h old)
   Directory: ~/.claude/teams/exec-api-cache-1738902345
   Cleanup: /ralph-specum:cleanup-teams
```

## Error Handling

### State File Missing

```
ERROR: .ralph-state.json not found for spec: auth-flow
ACTION: Check if spec exists, verify spec name spelling
LOG: "Available specs: $(ls ./specs)"
```

### State File Invalid

```
ERROR: Invalid JSON in .ralph-state.json
ACTION: Run jq validation, fix syntax errors
LOG: "WARNING: State file corrupted, manual inspection required"
```

### Team Directory Access Denied

```
ERROR: Permission denied accessing ~/.claude/teams/research-auth-flow-1738900000
ACTION: Check directory permissions, run with appropriate user
LOG: "ERROR: Cannot access team directory. Check permissions."
```

### TeamDelete Fails During Cleanup

```
ERROR: TeamDelete failed for orphaned team
ACTION: Use force cleanup (tmux kill-session, rm -rf)
LOG: "WARNING: Forced cleanup executed for $TEAM_NAME"
```

## Integration Points

**Called by:**
- `commands/team-status.md` - Display active teams
- `commands/cleanup-teams.md` - Remove orphaned teams
- `hooks/scripts/stop-watcher.sh` - Detect orphaned teams on session stop

**Updates:**
- No direct file updates (read-only skill)

**Uses tools:**
- jq - Query state files
- find - Scan for orphaned teams
- tmux - Kill orphaned sessions
- rm - Remove orphaned directories

## References

- Design: `specs/ralph-agent-teams/design.md` - Components - New Team-Based Skills
- Requirements: AC-3.6, AC-5.1 through AC-5.3, FR-5
- State schema: `plugins/ralph-specum/schemas/spec.schema.json` - teamName, teammateNames, teamPhase
