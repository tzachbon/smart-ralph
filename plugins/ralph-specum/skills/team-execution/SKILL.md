---
name: team-execution
description: Use when implementing specs with [P] parallel task markers and CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled. Spawns 2-3 teammates that claim and execute tasks from shared TaskList.
---

# Team Execution Skill

Auto-invoked skill for parallel task execution with agent teams. Spawns 2-3 spec-executor teammates, coordinates task claiming via shared TaskList, and manages team lifecycle.

## When To Use

Invoke this skill when ALL conditions are met:
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable is set to `1`
- Implementation phase detects `[P]` parallel task markers in `tasks.md`
- 2+ consecutive tasks marked with `[P]` (parallel batch detected)
- No active team exists in `.ralph-state.json` (check `teamName` field)

**Example task patterns:**
```markdown
- [ ] 1. Setup project structure
- [P] 2. Implement user model
- [P] 3. Implement auth service
- [P] 4. Implement database migrations
- [ ] 5. Integration tests
```

Tasks 2-4 form a parallel batch (can execute simultaneously).

## Environment Check

```bash
# Verify teams are enabled
if [ -z "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" ]; then
  echo "WARNING: Agent teams not enabled. Falling back to sequential execution."
  echo "Set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to enable teams."
  # Use existing sequential execution
  return
fi
```

## Team Naming Pattern

```
exec-{specName}-{timestamp}
```

Examples:
- `exec-auth-flow-1738900000`
- `exec-dashboard-1738901234`
- `exec-api-cache-1738902345`

## Workflow

### Step 1: Detect Parallel Batch

Identify consecutive `[P]` tasks in tasks.md:

```bash
# Find parallel task groups
grep -n '^\- \[P\]' "./specs/${SPEC_NAME}/tasks.md" | \
  awk -F: '$1-prev==1 {count++; next} {prev=$1; if(count>1) print "Parallel batch: "count" tasks"; count=1}'

# Validate parallel group detected
PARALLEL_COUNT=$(grep -c '^\- \[P\]' "./specs/${SPEC_NAME}/tasks.md")

if [ "$PARALLEL_COUNT" -lt 2 ]; then
  echo "WARNING: Fewer than 2 parallel tasks. Sequential execution more efficient."
  # Skip team creation, use sequential execution
  return
fi
```

### Step 2: Validate State File

Before creating team, ensure no active team exists:

```bash
STATE_FILE="./specs/${SPEC_NAME}/.ralph-state.json"

# Check for existing team
EXISTING_TEAM=$(jq -r '.teamName // empty' "$STATE_FILE" 2>/dev/null)

if [ -n "$EXISTING_TEAM" ]; then
  echo "ERROR: Active team already exists: $EXISTING_TEAM"
  echo "Cannot create new team. Use /ralph-specum:cancel to clean up existing team."
  exit 1
fi
```

### Step 3: Create Team

Use TeamCreate to initialize execution team:

```
TeamCreate: exec-{specName}-{timestamp}

Teammates: 2-3 spec-executor agents
```

Example:
```
TeamCreate("exec-auth-flow-1738900000", {
  teammates: [
    "executor-1",
    "executor-2",
    "executor-3"
  ]
})
```

**Team size guidance:**
- 2 parallel tasks: Spawn 2 teammates
- 3-5 parallel tasks: Spawn 2-3 teammates (tasks will be dynamically claimed)
- 6+ parallel tasks: Spawn 3 teammates

### Step 4: Spawn Teammates

Delegate task execution to teammates. Each teammate gets context to claim tasks:

```
# Spawn teammates with shared TaskList access
Task("executor-1", {
  type: "spec-executor",
  context: {
    specName: "auth-flow",
    tasks: "./specs/auth-flow/tasks.md",
    instructions: "Use TaskList to claim unclaimed [P] tasks, execute, mark complete"
  }
})

Task("executor-2", {
  type: "spec-executor",
  context: {
    specName: "auth-flow",
    tasks: "./specs/auth-flow/tasks.md",
    instructions: "Use TaskList to claim unclaimed [P] tasks, execute, mark complete"
  }
})

Task("executor-3", {
  type: "spec-executor",
  context: {
    specName: "auth-flow",
    tasks: "./specs/auth-flow/tasks.md",
    instructions: "Use TaskList to claim unclaimed [P] tasks, execute, mark complete"
  }
})
```

**Teammate instructions:**
1. Use `TaskList` to see all tasks
2. Find unclaimed `[P]` tasks (check `owner` field is empty)
3. Claim task via `TaskUpdate(taskId, owner: "executor-N")`
4. Execute task (follow spec-executor agent rules)
5. Mark complete via `TaskUpdate(taskId, status: "completed")`
6. Claim next unclaimed task
7. Go idle when no tasks remain

### Step 5: Monitor Task Execution

Watch for task completion and idle teammates:

```bash
# Poll TaskList for completion (every 5 seconds)
while true; do
  # Check if all parallel tasks completed
  COMPLETED=$(grep -c '^\- \[x\]' "./specs/${SPEC_NAME}/tasks.md" | grep -A 10 'PARALLEL_START')

  if [ "$COMPLETED" -eq "$PARALLEL_COUNT" ]; then
    echo "All parallel tasks completed"
    break
  fi

  # Check for idle teammates (no tasks claimed for 30s)
  IDLE_TIME=$(jq -r '.teammates[] | select(.idle == true) | .idleSince' "$STATE_FILE")

  if [ -n "$IDLE_TIME" ]; then
    NOW=$(date +%s)
    ELAPSED=$((NOW - IDLE_TIME))

    if [ "$ELAPSED" -gt 30 ]; then
      echo "WARNING: Teammate idle for 30s. May be blocked."
      # Continue monitoring, will timeout if all idle
    fi
  fi

  sleep 5
done
```

**Idle detection:**
- Teammate idle < 30s: Normal (waiting for task claim)
- Teammate idle > 30s: Warning (may be blocked, need investigation)
- All teammates idle + tasks incomplete: Error (all stuck, need intervention)

### Step 6: Update State File

Record team creation in state:

```bash
# Update state with team metadata
jq --arg teamName "exec-${SPEC_NAME}-${TIMESTAMP}" \
   --argjson teammateNames ["executor-1","executor-2","executor-3"] \
   --arg teamPhase "execution" \
   '. + {
     teamName: $teamName,
     teammateNames: $teammateNames,
     teamPhase: $teamPhase
   }' "$STATE_FILE" > "$STATE_FILE.tmp" && \
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Step 7: Coordinate Shutdown Protocol

When all parallel tasks complete, initiate graceful shutdown:

```bash
# Verify all parallel tasks done
PARALLEL_DONE=$(grep '^\- \[x\]' "./specs/${SPEC_NAME}/tasks.md" | wc -l)

if [ "$PARALLEL_DONE" -eq "$PARALLEL_COUNT" ]; then
  echo "All parallel tasks complete. Initiating team shutdown..."

  # Send shutdown requests to all teammates
  for teammate in executor-1 executor-2 executor-3; do
    SendMessage({
      type: "shutdown_request",
      recipient: "$teammate",
      content: "All parallel tasks complete. Shutting down execution team."
    })
  done

  # Wait for approvals (up to 10 seconds)
  TIMEOUT=10
  STARTED=$(date +%s)

  while [ $(($(date +%s) - STARTED)) -lt $TIMEOUT ]; do
    # Check if all teammates approved
    APPROVED=$(jq -r '.teammateNames | all(.approved == true)' "$STATE_FILE")

    if [ "$APPROVED" = "true" ]; then
      break
    fi

    sleep 1
  done

  # Force shutdown if timeout
  if [ $(($(date +%s) - STARTED)) -ge $TIMEOUT ]; then
    echo "WARNING: Shutdown timeout. Forcing team deletion."
  fi
fi
```

### Step 8: Advance Task Index

Update state to reflect progress past parallel batch:

```bash
# Find last parallel task index
LAST_PARALLEL=$(grep -n '^\- \[P\]' "./specs/${SPEC_NAME}/tasks.md" | tail -1 | cut -d: -f1)

# Advance taskIndex past parallel group
jq --argjson newIndex "$((LAST_PARALLEL + 1))" '.taskIndex = $newIndex' "$STATE_FILE" > "$STATE_FILE.tmp" && \
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Step 9: Delete Team

Execute TeamDelete after shutdown protocol:

```
TeamDelete("exec-{specName}-{timestamp}")
```

**Post-deletion validation:**
- Verify `~/.claude/teams/exec-{specName}-{timestamp}/` directory removed
- Check for orphaned tmux sessions: `tmux list-sessions | grep "exec-"`
- Log cleanup status

### Step 10: Clear State File

Remove team metadata from state:

```bash
# Clear team fields
jq 'del(.teamName, .teammateNames, .teamPhase)' "$STATE_FILE" > "$STATE_FILE.tmp" && \
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

## Fallback Behavior

If teams unavailable or creation fails:

```bash
# ERROR: TeamCreate failed
echo "WARNING: Failed to create execution team: $ERROR"
echo "Falling back to sequential execution."

# Use existing sequential execution (single spec-executor)
# Execute [P] tasks one-by-one instead of parallel
for task in "${PARALLEL_TASKS[@]}"; do
  Task("spec-executor", {
    task: "$task",
    sequential: true
  })
done
```

**Fallback triggers:**
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` not set
- TeamCreate command fails (API unavailable, permissions error)
- State file has existing `teamName` (team already active)
- Fewer than 2 parallel tasks (sequential is more efficient)

## Error Handling

### TeamCreate Fails

```
ERROR: TeamCreate failed - "API unavailable"
ACTION: Fallback to sequential execution, log warning
LOG: "Executing tasks sequentially (team creation failed)"
```

### TaskList Unavailable

```
ERROR: TaskList tool unavailable
ACTION: Fallback to file-based coordination
LOG: "WARNING: Using file-based task coordination (less efficient)"

# File-based fallback: each teammate edits tasks.md directly
# Use line-based locking to prevent conflicts
```

### Teammate Failure

```
ERROR: executor-2 failed to claim task (crash, timeout)
ACTION: Spawn replacement teammate, reassign task
LOG: "Spawning replacement teammate for executor-2"

# Task becomes unclaimed (owner field cleared)
# New teammate claims task
```

### TaskUpdate Conflict

```
ERROR: TaskUpdate conflict - task already claimed by another executor
ACTION: Claim next unclaimed task (retry once, then move on)
LOG: "Task already claimed, claiming next available task"
```

### TeamDelete Fails

```
ERROR: TeamDelete failed - "Team not responding"
ACTION: Log error with team directory, suggest manual cleanup
LOG: "WARNING: Orphaned team may require manual cleanup: tmux kill-session -t exec-auth-flow-1738900000"
```

## Task Claiming Coordination

Teammates use shared TaskList for distributed task claiming:

```javascript
// Teammate task claiming workflow

// 1. List all tasks
TaskList() → [
  { id: "5", subject: "Implement user model", status: "pending", owner: null },
  { id: "6", subject: "Implement auth service", status: "pending", owner: null },
  { id: "7", subject: "Implement database migrations", status: "pending", owner: "executor-1" }
]

// 2. Claim unclaimed task (race condition safe - first to claim wins)
TaskUpdate({
  taskId: "5",
  owner: "executor-2",
  status: "in_progress"
})

// 3. Execute task
// ... work ...

// 4. Mark complete
TaskUpdate({
  taskId: "5",
  status: "completed",
  owner: "executor-2"
})

// 5. Claim next task
// Repeat from step 1
```

**Claiming rules:**
- Only claim tasks with `owner: null` (unclaimed)
- Only claim `[P]` tasks in the parallel batch
- After completing task, mark `status: "completed"` but keep `owner` field
- If all tasks claimed, go idle (wait for shutdown signal)
- Prefer lower-indexed tasks first (5 before 6 before 7)

## Idle Monitoring

Teammates emit idle notifications when no work available:

```javascript
// Teammate idle behavior
if (noUnclaimedTasks()) {
  // Normal idle - waiting for shutdown
  console.log("All tasks claimed, waiting for completion...");

  // Abnormal idle - stuck or blocked
  if (idleTime > 60s && ownedTask.status === "in_progress") {
    SendMessage({
      type: "message",
      recipient: "team-lead",
      content: "Still working on task ${ownedTask.id}, may be blocked",
      summary: "Task progress check"
    })
  }
}
```

**Coordinator idle detection:**
- All teammates idle + all tasks complete → Success (initiate shutdown)
- All teammates idle + tasks incomplete → Error (all stuck, needs intervention)
- Some teammates idle + tasks remaining → Normal (active teammates working)

## Quality Checks

After team deletion, verify:

```bash
# Check all parallel tasks marked complete
COMPLETED=$(grep '^\- \[x\]' "./specs/${SPEC_NAME}/tasks.md" | wc -l)

if [ "$COMPLETED" -lt "$PARALLEL_COUNT" ]; then
  echo "ERROR: Not all parallel tasks completed ($COMPLETED/$PARALLEL_COUNT)"
  exit 1
fi

# Check team deleted from state
jq -e '.teamName == null' "$STATE_FILE" || {
  echo "ERROR: teamName not cleared from state"
  exit 1
}

# Check no orphaned team directory
test ! -d "~/.claude/teams/exec-${SPEC_NAME}-"*/ || {
  echo "WARNING: Orphaned team directory may exist"
  ls -la ~/.claude/teams/ | grep "exec-${SPEC_NAME}"
}

# Check taskIndex advanced
NEW_INDEX=$(jq -r '.taskIndex' "$STATE_FILE")

if [ "$NEW_INDEX" -le "$LAST_PARALLEL" ]; then
  echo "ERROR: taskIndex not advanced past parallel group"
  exit 1
fi
```

## Integration Points

**Called by:**
- `commands/implement.md` - After parallel batch detection in stop-watcher loop

**Updates:**
- `./specs/{specName}/.ralph-state.json` - Sets teamName, teammateNames, teamPhase, taskIndex
- `./specs/{specName}/tasks.md` - Marks tasks [x] as completed

**Uses tools:**
- TeamCreate - Initialize execution team
- Task - Spawn spec-executor teammates
- TaskList - Shared task claiming coordination
- TaskUpdate - Claim tasks, mark complete
- SendMessage - Coordinate shutdown, report status
- TeamDelete - Cleanup after batch complete

## References

- Design: `specs/ralph-agent-teams/design.md` - Components - New Team-Based Skills
- Requirements: AC-2.1 through AC-2.7, FR-2
- State schema: `plugins/ralph-specum/schemas/spec.schema.json` - teamName, teammateNames, teamPhase
