---
name: coordinator-pattern
description: This skill should be used when the user asks about "coordinator role", "delegate to subagent", "use Task tool", "orchestration pattern", "execution loop", "task delegation", or needs guidance on implementing a coordinator that delegates work to subagents while managing state and completion signaling.
version: 0.1.0
---

# COORDINATOR Pattern

The COORDINATOR pattern enables an orchestrating agent to manage task execution by delegating to specialized subagents while tracking state and signaling completion.

## Core Principle

**You are a COORDINATOR, NOT an implementer.**

Your job is to:
- Read state and determine the current task
- Delegate task execution to specialized agents via the Task tool
- Track completion and signal when all work is done

**CRITICAL**: You MUST delegate via the Task tool. Do NOT implement tasks yourself.

## Pattern Components

### 1. Role Definition

Define clear boundaries between coordinator and executor:

```text
You are the execution COORDINATOR for spec: $spec

### Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Read state and determine current task
- Delegate task execution to spec-executor via Task tool
- Track completion and signal when all tasks done

CRITICAL: You MUST delegate via Task tool. Do NOT implement tasks yourself.
You are fully autonomous. NEVER ask questions or wait for user input.
```

**Key constraints:**
- Coordinator reads, decides, delegates
- Executor implements, verifies, commits
- Coordinator NEVER writes code or modifies files directly
- Coordinator only updates state files and coordination metadata

### 2. State Reading

The coordinator maintains execution state in a JSON file:

```json
{
  "phase": "execution",
  "taskIndex": 0,
  "totalTasks": 10,
  "taskIteration": 1,
  "maxTaskIterations": 5
}
```

**State fields:**
| Field | Purpose |
|-------|---------|
| `phase` | Current execution phase (execution, complete) |
| `taskIndex` | 0-based index of current task |
| `totalTasks` | Total number of tasks |
| `taskIteration` | Retry count for current task |
| `maxTaskIterations` | Maximum retries before failure |

**Reading state:**

```text
Read `./specs/$spec/.ralph-state.json` to get current state.

**ERROR: Missing/Corrupt State File**

If state file missing or corrupt (invalid JSON, missing required fields):
1. Output error: "ERROR: State file missing or corrupt"
2. Suggest: "Run initialization command to reinitialize state"
3. Do NOT continue execution
4. Do NOT output completion signal
```

### 3. Task Delegation

Delegate to specialized executor agents via the Task tool:

```text
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

**Delegation rules:**
- Include full task specification in delegation
- Provide all context needed for autonomous execution
- Specify the exact completion signal expected (e.g., `TASK_COMPLETE`)
- Wait for executor response before proceeding

### 4. Completion Checking

Before delegation, check if all work is done:

```text
If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md
2. Delete state file (cleanup)
3. Output: ALL_TASKS_COMPLETE
4. STOP - do not delegate any task
```

### 5. Completion Signaling

The coordinator outputs a specific signal when all tasks are done:

```text
Output exactly `ALL_TASKS_COMPLETE` when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md

Before outputting:
1. Verify all tasks marked [x] in tasks.md
2. Delete state file (cleanup execution state)
3. Keep progress file (preserve learnings and history)

This signal terminates the execution loop.

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for executors only).
```

**Signal hierarchy:**
| Signal | Used By | Meaning |
|--------|---------|---------|
| `TASK_COMPLETE` | Executor | Single task finished |
| `ALL_TASKS_COMPLETE` | Coordinator | All tasks finished |

### 6. State Update After Completion

When executor signals task completion:

```text
After successful completion (TASK_COMPLETE):
1. Read current state file
2. Increment taskIndex by 1
3. Reset taskIteration to 1
4. Write updated state

Check if all tasks complete:
- If taskIndex >= totalTasks: output ALL_TASKS_COMPLETE
- If taskIndex < totalTasks: continue to next iteration
```

### 7. Retry Handling

When executor fails to signal completion:

```text
If no completion signal:
1. Increment taskIteration in state file
2. If taskIteration > maxTaskIterations: output error and STOP
3. Otherwise: Retry the same task

**ERROR: Max Retries Reached**

If taskIteration exceeds maxTaskIterations:
1. Output error: "ERROR: Max retries reached for task $taskIndex"
2. Include last error/failure reason from executor output
3. Suggest: "Fix the issue manually then run again to resume"
4. Do NOT continue execution
5. Do NOT output ALL_TASKS_COMPLETE
```

## Complete Coordinator Flow

```text
1. Read state file
   |
2. Check if taskIndex >= totalTasks
   ├── Yes: Output ALL_TASKS_COMPLETE, STOP
   |
3. Parse current task from tasks.md
   |
4. Delegate to executor via Task tool
   |
5. Wait for executor response
   |
6. Check for completion signal
   ├── TASK_COMPLETE: Update state, go to step 2
   └── No signal: Increment iteration
       ├── Under limit: Retry (step 4)
       └── Over limit: Error and STOP
```

## Parallel Execution Extension

For parallel task execution, detect adjacent parallel tasks and spawn multiple delegations:

```text
If current task has [P] marker, scan for consecutive [P] tasks.

Build parallelGroup:
{
  "startIndex": <first [P] task index>,
  "endIndex": <last consecutive [P] task index>,
  "taskIndices": [startIndex, startIndex+1, ..., endIndex],
  "isParallel": true
}

Spawn MULTIPLE Task tool calls in ONE message for true parallelism.
Wait for ALL to complete before advancing state.
```

## Error Handling Patterns

### Missing State File

```text
If state file missing or corrupt:
1. Output error: "ERROR: State file missing or corrupt"
2. Suggest: "Run initialization to reinitialize state"
3. Do NOT continue
4. Do NOT output completion signal
```

### Missing Task File

```text
If tasks file does not exist:
1. Output error: "ERROR: Tasks file missing"
2. Suggest: "Run task generation command first"
3. Do NOT continue
4. Do NOT output completion signal
```

### Executor Timeout/Failure

```text
If executor does not respond or errors:
1. Log failure in progress file
2. Increment taskIteration
3. Retry if under limit
4. Stop with error if over limit
```

## Usage in Commands

Reference this skill in commands that need coordination:

```markdown
<skill-reference>
**Apply skill**: `skills/coordinator-pattern/SKILL.md`
Use the COORDINATOR pattern to manage task execution loop.
</skill-reference>
```

## Anti-Patterns

**DO NOT:**
- Implement tasks directly in the coordinator
- Skip the Task tool and write code yourself
- Modify files that should be modified by executors
- Output completion signal before verifying all tasks done
- Continue after error without proper state update

**ALWAYS:**
- Delegate via Task tool
- Verify completion signals from executors
- Update state after each task
- Clean up state file on completion
- Preserve progress/learnings files
