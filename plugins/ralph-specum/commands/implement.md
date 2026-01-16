---
description: Start task execution loop with Beads dependency-aware scheduling
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop with Beads dependency-aware task scheduling.

## Prerequisites Check

### 1. Beads (REQUIRED)

```bash
bd --version || { echo "ERROR: Beads required. Install: brew install steveyegge/tap/beads"; exit 1; }
```

If Beads is not installed, STOP and output the error.

### 2. Ralph Wiggum Plugin (REQUIRED)

Verify by attempting to invoke `ralph-wiggum:ralph-loop`. If skill not found, output:
"ERROR: Ralph Wiggum plugin not found. Install: /plugin install ralph-loop@claude-plugins-official"

### 3. Active Spec

```bash
cat ./specs/.current-spec
```

If missing: "ERROR: No active spec. Run /ralph-specum:new <name> first."

### 4. Tasks File

Check `./specs/$spec/tasks.md` exists. If not: "ERROR: Tasks not found. Run /ralph-specum:tasks first."

### 5. Beads Spec Issue

Read the Beads spec ID from research.md:
```bash
grep -oP 'Spec Issue: \Kbd-[a-f0-9]+' ./specs/$spec/research.md
```

If not found, create one:
```bash
SPEC_ID=$(bd create --title "$spec" --type epic --json | jq -r '.id')
```

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Invoke Ralph Loop

### Step 1: Write Coordinator Prompt

Write the coordinator prompt to `./specs/$spec/.coordinator-prompt.md`.

### Step 2: Invoke Skill

```
ralph-wiggum:ralph-loop Read ./specs/$spec/.coordinator-prompt.md and follow instructions. --max-iterations <calculated> --completion-promise ALL_TASKS_COMPLETE
```

## Coordinator Prompt

Write this to `./specs/$spec/.coordinator-prompt.md`:

```
You are the execution COORDINATOR for spec: $spec
Beads Spec ID: $SPEC_ID

### 1. Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Query Beads for ready tasks: `bd list --ready --json`
- Delegate task execution to spec-executor via Task tool
- Pass Beads issue ID to spec-executor for each task
- Run `bd sync` on completion

CRITICAL: Delegate via Task tool. Do NOT implement tasks yourself.
Fully autonomous. NEVER ask questions or wait for user input.

### 2. Find Ready Tasks

Query Beads for unblocked tasks:

```bash
bd list --ready --parent $SPEC_ID --json
```

This returns tasks with no blocking dependencies.

**Parse the result**:
- Extract task IDs from issue titles (e.g., "1.1 Setup config" → task ID "1.1")
- Extract Beads issue IDs (e.g., "bd-abc123")

### 3. Check Completion

```bash
OPEN_COUNT=$(bd list --open --parent $SPEC_ID --json | jq 'length')
```

If OPEN_COUNT = 0:
1. Run Land the Plane protocol (section 8)
2. Output: ALL_TASKS_COMPLETE
3. STOP

### 4. Task Delegation

For each ready task from Beads:

**Extract task block from tasks.md**:
```bash
# Find task block by ID (e.g., "1.1")
grep -A 10 "^\- \[ \] $TASK_ID" ./specs/$spec/tasks.md
```

**Delegate to spec-executor via Task tool**:

```
Task: Execute task $TASK_ID for spec $spec

beadsId: $BEADS_ISSUE_ID
taskId: $TASK_ID
specPath: ./specs/$spec

Task block:
[Include full task specification from tasks.md]

Instructions:
1. Execute Do steps exactly as specified
2. Only modify Files listed
3. Run Verify command (must pass)
4. Commit with Beads ID: git commit -m "type(scope): msg ($BEADS_ISSUE_ID)"
5. Close Beads issue: bd close $BEADS_ISSUE_ID --reason "completed"
6. Update tasks.md checkmark (for human readability)
7. Output TASK_COMPLETE when done
```

**Multiple Ready Tasks (parallel execution)**:

If `bd list --ready` returns multiple tasks, spawn multiple Task tool calls in ONE message for true parallelism:

```
[Task tool call 1]
beadsId: bd-abc123
taskId: 1.3
...

[Task tool call 2]
beadsId: bd-def456
taskId: 1.4
...
```

Each parallel task gets a unique progressFile.

### 5. [VERIFY] Task Handling

If task title contains "[VERIFY]":
1. Delegate to qa-engineer instead of spec-executor
2. Pass same beadsId and taskId
3. On VERIFICATION_PASS: Close Beads issue
4. On VERIFICATION_FAIL: Retry (up to max iterations)

### 6. Handle Completion

On TASK_COMPLETE from spec-executor:
- Beads issue should already be closed by spec-executor
- Verify with: `bd show $BEADS_ISSUE_ID --json | jq '.status'`
- If not closed, close it: `bd close $BEADS_ISSUE_ID`
- Loop back to section 2 (Find Ready Tasks)

On failure (no TASK_COMPLETE):
- Increment retry count (track in memory or temp file)
- If retries exceed --max-task-iterations: output error and stop
- Otherwise: retry the same task

### 7. Retry Tracking

Track retries per task in memory during coordinator execution:
- taskRetries = { "bd-abc123": 1, "bd-def456": 2, ... }
- Increment on failure
- If taskRetries[id] > maxIterations: error and stop

### 8. Land the Plane Protocol

When all Beads issues are closed:

```bash
# Check for orphaned work
bd doctor

# Sync to git
git pull --rebase
bd sync
git push

# Verify clean state
git status
```

Then output: ALL_TASKS_COMPLETE

### 9. Error Handling

**Max Retries Reached**:
```
ERROR: Max retries ($max) reached for task $TASK_ID ($BEADS_ID)
Review Beads issue notes: bd show $BEADS_ID
Fix manually, then run /ralph-specum:implement to resume
```

**Circular Dependencies**:
If `bd list --ready` returns empty but open issues exist:
```
ERROR: No ready tasks but $OPEN_COUNT issues still open
Possible circular dependency. Check: bd list --open --parent $SPEC_ID
```

**Missing Task Block**:
If task ID from Beads not found in tasks.md:
```
ERROR: Task $TASK_ID not found in tasks.md
Beads issue $BEADS_ID exists but no matching task specification
```
```

## Output on Start

```
Starting execution for '$spec'
Beads Spec: $SPEC_ID

Querying ready tasks...

The execution loop will:
- Execute tasks as dependencies are satisfied
- Use Beads for tracking and parallel detection
- Sync to git on completion

Beginning execution...
```
