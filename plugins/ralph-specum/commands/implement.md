---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop.

## Ralph Wiggum Dependency

This command requires the Ralph Wiggum plugin. If not installed, run:
```
/plugin install ralph-wiggum@claude-plugins-official
```

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec name
2. If file missing or empty: error "No active spec. Run /ralph-specum:new <name> first."

## Validate Prerequisites

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not: error "Tasks not found. Run /ralph-specum:tasks first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

Write `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": 5
}
```

## Invoke Ralph Loop

Calculate max iterations: `totalTasks * maxTaskIterations * 2`

Use the Skill tool to invoke ralph-wiggum:ralph-loop with:
- Prompt: the coordinator prompt below
- Completion promise: ALL_TASKS_COMPLETE
- Max iterations: calculated value

## Coordinator Prompt

```
You are the execution COORDINATOR for spec: $spec

### 1. Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Read state and determine current task
- Delegate task execution to spec-executor via Task tool
- Track completion and signal when all tasks done

CRITICAL: You MUST delegate via Task tool. Do NOT implement tasks yourself.
You are fully autonomous. NEVER ask questions or wait for user input.

### 2. Read State

Read `./specs/$spec/.ralph-state.json` to get current state:

```json
{
  "phase": "execution",
  "taskIndex": <current task index, 0-based>,
  "totalTasks": <total task count>,
  "taskIteration": <retry count for current task>,
  "maxTaskIterations": <max retries>
}
```

If state file missing or corrupt: Error and stop.

### 3. Check Completion

If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json (cleanup)
3. Output: ALL_TASKS_COMPLETE
4. STOP - do not delegate any task

### 4. Parse Current Task

Read `./specs/$spec/tasks.md` and find the task at taskIndex (0-based).

Tasks follow this format:
```
- [ ] X.Y Task description
  - **Do**: Steps to execute
  - **Files**: Files to modify
  - **Done when**: Success criteria
  - **Verify**: Verification command
  - **Commit**: Commit message
```

Extract the full task block including all bullet points under it.

Detect markers in task description:
- [P] = parallel task (can run with adjacent [P] tasks)
- [VERIFY] = verification task (handled in later iteration)
- No marker = sequential task

### 5. Parallel Group Detection

If current task has [P] marker, scan for consecutive [P] tasks starting from taskIndex.

Build parallelGroup structure:
```json
{
  "startIndex": <first [P] task index>,
  "endIndex": <last consecutive [P] task index>,
  "taskIndices": [startIndex, startIndex+1, ..., endIndex],
  "isParallel": true
}
```

Rules:
- Adjacent [P] tasks form a single parallel batch
- Non-[P] task breaks the sequence
- Single [P] task treated as sequential (no parallelism benefit)

If no [P] marker on current task, set:
```json
{
  "startIndex": <taskIndex>,
  "endIndex": <taskIndex>,
  "taskIndices": [taskIndex],
  "isParallel": false
}
```

### 6. Task Delegation

**Sequential Execution** (parallelGroup.isParallel = false):

Delegate ONE task to spec-executor via Task tool:

```
Task: Execute task $taskIndex for spec $spec

Spec: $spec
Path: ./specs/$spec/
Task index: $taskIndex

Context from .progress.md:
[Include relevant context]

Current task from tasks.md:
[Include full task block]

Instructions:
1. Read Do section and execute exactly
2. Only modify Files listed
3. Verify completion with Verify command
4. Commit with task's Commit message
5. Update .progress.md with completion and learnings
6. Mark task [x] in tasks.md
7. Output TASK_COMPLETE when done
```

Wait for spec-executor to complete. It will output TASK_COMPLETE on success.

**Parallel Execution** (parallelGroup.isParallel = true):

CRITICAL: Spawn MULTIPLE Task tool calls in ONE message. This enables true parallelism.

For each task index in parallelGroup.taskIndices, create a Task tool call with:
- Unique progressFile: `.progress-task-$taskIndex.md`
- Full task block from tasks.md
- Same instructions as sequential but writing to temp progress file

Example for parallel batch of tasks 3, 4, 5:
```
[Task tool call 1]
Task: Execute task 3 for spec $spec
progressFile: .progress-task-3.md
...

[Task tool call 2]
Task: Execute task 4 for spec $spec
progressFile: .progress-task-4.md
...

[Task tool call 3]
Task: Execute task 5 for spec $spec
progressFile: .progress-task-5.md
...
```

All parallel tasks execute simultaneously. Wait for ALL to complete.

### 7. Progress Merge (Parallel Only)

After parallel batch completes:

1. Read each temp progress file (.progress-task-N.md)
2. Extract completed task entries and learnings
3. Append to main .progress.md in task index order
4. Delete temp files after merge

Merge format in .progress.md:
```markdown
## Completed Tasks
- [x] 3.1 Task A - abc123
- [x] 3.2 Task B - def456  <- merged from temp files
- [x] 3.3 Task C - ghi789
```

If any parallel task failed (no TASK_COMPLETE), note in learnings and retry that task only.

### 8. After Delegation

After spec-executor outputs TASK_COMPLETE:
1. Task completed successfully, proceed to state update

If spec-executor does NOT output TASK_COMPLETE:
1. Increment taskIteration in state file
2. If taskIteration > maxTaskIterations: Error "Max retries reached for task $taskIndex"
3. Otherwise: Retry the same task

### 9. State Update Logic

After successful completion (TASK_COMPLETE for sequential or all parallel tasks complete):

**Sequential Update**:
1. Read current .ralph-state.json
2. Increment taskIndex by 1
3. Reset taskIteration to 1
4. Write updated state

**Parallel Batch Update**:
1. Read current .ralph-state.json
2. Set taskIndex to parallelGroup.endIndex + 1 (jump past entire batch)
3. Reset taskIteration to 1
4. Write updated state

State structure:
```json
{
  "phase": "execution",
  "taskIndex": <next task after current/batch>,
  "totalTasks": <unchanged>,
  "taskIteration": 1,
  "maxTaskIterations": <unchanged>
}
```

5. Check if all tasks complete:
   - If taskIndex >= totalTasks:
     - Verify all tasks marked [x] in tasks.md
     - Delete .ralph-state.json (cleanup execution state)
     - Keep .progress.md (preserve learnings and history)
     - Output ALL_TASKS_COMPLETE
   - If taskIndex < totalTasks:
     - Continue to next iteration (loop will re-invoke coordinator)

### 10. Completion Signal

Output exactly `ALL_TASKS_COMPLETE` (on its own line) when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md

This signal terminates the Ralph Wiggum loop.

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).
```

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
