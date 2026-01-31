---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop.

## Ralph Loop Dependency Check

**BEFORE proceeding**, verify Ralph Loop plugin is installed by attempting to invoke the skill.

If the Skill tool fails with "skill not found" or similar error for `ralph-loop:ralph-loop`:
1. Output error: "ERROR: Ralph Loop plugin not found. Install with: /plugin install ralph-wiggum@claude-plugins-official"
2. STOP execution immediately. Do NOT continue.

This is a hard dependency. The command cannot function without Ralph Loop.

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec name
2. If file missing or empty: error "No active spec. Run /ralph-specum:new <name> first."

## Validate Prerequisites

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not: error "Tasks not found. Run /ralph-specum:tasks first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)
- **--recovery-mode**: Enable iterative failure recovery (default: false). When enabled, failed tasks trigger automatic fix task generation instead of stopping.

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
  "maxTaskIterations": <parsed from --max-task-iterations or default 5>,
  "recoveryMode": <true if --recovery-mode flag present, false otherwise>,
  "maxFixTasksPerOriginal": 3,
  "fixTaskMap": {}
}
```

## Invoke Ralph Loop

Calculate max iterations: `max(5, min(10, ceil(totalTasks / 5)))`

This formula:
- Minimum 5 iterations (safety floor for small specs)
- Maximum 10 iterations (prevents runaway loops)
- Scales with task count: 5 tasks = 5 iterations, 50 tasks = 10 iterations

### Step 1: Write Coordinator Prompt to File

Write the ENTIRE coordinator prompt (from section below) to `./specs/$spec/.coordinator-prompt.md`.

This file contains the full instructions for task execution. Writing it to a file avoids shell argument parsing issues with the multi-line prompt.

### Step 2: Invoke Ralph Loop Skill

Use the Skill tool to invoke `ralph-loop:ralph-loop` with args:

```
Read ./specs/$spec/.coordinator-prompt.md and follow those instructions exactly. Output ALL_TASKS_COMPLETE when done. --max-iterations <calculated> --completion-promise ALL_TASKS_COMPLETE
```

Replace `$spec` with the actual spec name and `<calculated>` with the calculated max iterations value.

## Coordinator Prompt

Write this prompt to `./specs/$spec/.coordinator-prompt.md`:

```text
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

**ERROR: Missing/Corrupt State File**

If state file missing or corrupt (invalid JSON, missing required fields):
1. Output error: "ERROR: State file missing or corrupt at ./specs/$spec/.ralph-state.json"
2. Suggest: "Run /ralph-specum:implement to reinitialize execution state"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

### 3. Check Completion

If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json (cleanup)
3. Output: ALL_TASKS_COMPLETE
4. STOP - do not delegate any task

### 4. Parse Current Task

Read `./specs/$spec/tasks.md` and find the task at taskIndex (0-based).

**ERROR: Missing tasks.md**

If tasks.md does not exist:
1. Output error: "ERROR: Tasks file missing at ./specs/$spec/tasks.md"
2. Suggest: "Run /ralph-specum:tasks to generate task list"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

**ERROR: Missing Spec Directory**

If spec directory does not exist (./specs/$spec/):
1. Output error: "ERROR: Spec directory missing at ./specs/$spec/"
2. Suggest: "Run /ralph-specum:new <spec-name> to create a new spec"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

Tasks follow this format:
```markdown
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
- [VERIFY] = verification task (delegate to qa-engineer)
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

**[VERIFY] Task Detection**:

Before standard delegation, check if current task has [VERIFY] marker.
Look for `[VERIFY]` in task description line (e.g., `- [ ] 1.4 [VERIFY] Quality checkpoint`).

If [VERIFY] marker present:
1. Do NOT delegate to spec-executor
2. Delegate to qa-engineer via Task tool instead
3. [VERIFY] tasks are ALWAYS sequential (break parallel groups)

Delegate [VERIFY] task to qa-engineer:
```text
Task: Execute verification task $taskIndex for spec $spec

Spec: $spec
Path: ./specs/$spec/

Task: [Full task description]

Task Body:
[Include Do, Verify, Done when sections]

Instructions:
1. Execute the verification as specified
2. If issues found, attempt to fix them
3. Output VERIFICATION_PASS if verification succeeds
4. Output VERIFICATION_FAIL if verification fails and cannot be fixed
```

Handle qa-engineer response:
- VERIFICATION_PASS: Treat as TASK_COMPLETE, mark task [x], update .progress.md
- VERIFICATION_FAIL: Do NOT mark complete, increment taskIteration, retry or error if max reached

**Sequential Execution** (parallelGroup.isParallel = false, no [VERIFY]):

Delegate ONE task to spec-executor via Task tool:

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

Wait for spec-executor to complete. It will output TASK_COMPLETE on success.

**Parallel Execution** (parallelGroup.isParallel = true):

CRITICAL: Spawn MULTIPLE Task tool calls in ONE message. This enables true parallelism.

For each task index in parallelGroup.taskIndices, create a Task tool call with:
- Unique progressFile: `.progress-task-$taskIndex.md`
- Full task block from tasks.md
- Same instructions as sequential but writing to temp progress file

Example for parallel batch of tasks 3, 4, 5:
```text
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

**After Delegation**:

If spec-executor outputs TASK_COMPLETE (or qa-engineer outputs VERIFICATION_PASS):
1. Run verification layers (section 7) before advancing
2. If all verifications pass, proceed to state update

If no completion signal:
1. First, parse the failure output (section 6b)
2. Increment taskIteration in state file
3. If taskIteration > maxTaskIterations: proceed to max retries error handling
4. Otherwise: Retry the same task

### 6b. Parse Failure Output

When spec-executor does not output TASK_COMPLETE, parse the failure output to extract error details.

**Failure Output Pattern**:
Spec-executor outputs failures in this format:
```text
Task X.Y: [task name] FAILED
- Error: [description]
- Attempted fix: [what was tried]
- Status: Blocked, needs manual intervention
```

**Parsing Logic**:

1. **Check for FAILED marker**:
   - Look for pattern: `Task \d+\.\d+:.*FAILED`
   - If found, proceed to extract details
   - If not found, use generic failure: "Task did not complete"

2. **Extract Error Details**:
   - Match `- Error: (.*)` to get error description
   - Match `- Attempted fix: (.*)` to get fix attempt details
   - Match `- Status: (.*)` to get status message

3. **Build Failure Object**:
   ```json
   {
     "taskId": "<X.Y from match>",
     "failed": true,
     "error": "<extracted from Error: line>",
     "attemptedFix": "<extracted from Attempted fix: line>",
     "status": "<extracted from Status: line>",
     "rawOutput": "<full spec-executor output for context>"
   }
   ```

4. **Handle Missing Fields**:
   - If Error: line missing, use "Task execution failed"
   - If Attempted fix: line missing, use "No fix attempted"
   - If Status: line missing, use "Unknown status"

### 6c. Fix Task Generator (Recovery Mode Only)

When recoveryMode is enabled and a task fails, generate a fix task from the failure details.

**Check Recovery Mode**:

First, verify recovery mode is enabled:
1. Read `recoveryMode` from .ralph-state.json
2. If `recoveryMode` is false or missing, skip to "ERROR: Max Retries Reached"
3. If `recoveryMode` is true, proceed with fix task generation

**Check Fix Task Limits**:

Before generating a fix task:
1. Read `fixTaskMap` from .ralph-state.json
2. Check if `fixTaskMap[taskId].attempts >= maxFixTasksPerOriginal`
3. If limit reached: output error and STOP

**Generate Fix Task Markdown**:

```text
- [ ] $taskId.$attemptNumber [FIX $taskId] Fix: $errorSummary
  - **Do**: Address the error: $failure.error
    1. Analyze the failure: $failure.attemptedFix
    2. Review related code in Files list
    3. Implement fix for: $failure.error
  - **Files**: $originalTask.files
  - **Done when**: Error "$failure.error" no longer occurs
  - **Verify**: $originalTask.verify
  - **Commit**: `fix($scope): address $errorType from task $taskId`
```

**Insert Fix Task into tasks.md** using Edit tool, immediately after the original task block.

**Update State** after fix task generation:
- Increment `fixTaskMap[taskId].attempts`
- Add fix task ID to `fixTaskMap[taskId].fixTaskIds`
- Increment `totalTasks`

**Execute Fix Task**, then retry original task.

### 6d. Iterative Failure Recovery Orchestrator

This orchestrates the complete failure recovery loop when recoveryMode is enabled.

**Backwards Compatibility**: recoveryMode defaults to false. When false/missing, existing retry-then-stop behavior is preserved.

**Recovery Loop Flow**:
1. Task fails -> Check recoveryMode
2. Parse failure output (6b)
3. Check fix limits (6c)
4. Generate fix task (6c)
5. Insert fix task into tasks.md
6. Update state (fixTaskMap)
7. Execute fix task
8. If fix completes -> retry original task
9. If fix fails -> loop back to step 2 (fix task can spawn its own fixes)

**ERROR: Max Retries Reached**

If taskIteration exceeds maxTaskIterations:
1. Output error: "ERROR: Max retries reached for task $taskIndex after $maxTaskIterations attempts"
2. Include last error/failure reason from spec-executor output
3. Suggest: "Review .progress.md Learnings section for failure details"
4. Suggest: "Fix the issue manually then run /ralph-specum:implement to resume"
5. Do NOT continue execution
6. Do NOT output ALL_TASKS_COMPLETE

### 7. Verification Layers

CRITICAL: Run these 4 verifications BEFORE advancing taskIndex. All must pass.

**Layer 1: CONTRADICTION Detection**

Check spec-executor output for contradiction patterns:
- "requires manual"
- "cannot be automated"
- "could not complete"
- "needs human"
- "manual intervention"

If TASK_COMPLETE appears alongside any contradiction phrase:
- REJECT the completion
- Log: "CONTRADICTION: claimed completion while admitting failure"
- Increment taskIteration and retry

**Layer 2: Uncommitted Spec Files Check**

Before advancing, verify spec files are committed:

```bash
git status --porcelain ./specs/$spec/tasks.md ./specs/$spec/.progress.md
```

If output is non-empty (uncommitted changes):
- REJECT the completion
- Log: "uncommitted spec files detected - task not properly committed"
- Increment taskIteration and retry

**Layer 3: Checkmark Verification**

Count completed tasks in tasks.md:

```bash
grep -c '\- \[x\]' ./specs/$spec/tasks.md
```

Expected checkmark count = taskIndex + 1

If actual count != expected:
- REJECT the completion
- Log: "checkmark mismatch: expected $expected, found $actual"
- Increment taskIteration and retry

**Layer 4: TASK_COMPLETE Signal Verification**

Verify spec-executor explicitly output TASK_COMPLETE:
- Must be present in response
- Not just implied or partial completion

If TASK_COMPLETE missing:
- Do NOT advance
- Increment taskIteration and retry

**All 4 layers must pass before proceeding to State Update.**

### 8. State Update

After successful completion (TASK_COMPLETE for sequential or all parallel tasks complete):

**Sequential Update**:
1. Increment taskIndex by 1
2. Reset taskIteration to 1
3. Write updated state

**Parallel Batch Update**:
1. Set taskIndex to parallelGroup.endIndex + 1
2. Reset taskIteration to 1
3. Write updated state

Check if all tasks complete:
- If taskIndex >= totalTasks: proceed to section 10 (Completion Signal)
- If taskIndex < totalTasks: continue to next iteration

### 9. Progress Merge (Parallel Only)

After parallel batch completes:
1. Read each temp progress file (.progress-task-N.md)
2. Extract completed task entries and learnings
3. Append to main .progress.md in task index order
4. Delete temp files after merge

### 10. Completion Signal

**Phase 5 Detection**: Before outputting ALL_TASKS_COMPLETE, check if Phase 5 (PR Lifecycle) is required:

1. Read tasks.md to detect Phase 5 tasks (look for "Phase 5: PR Lifecycle" section)
2. If Phase 5 exists AND taskIndex >= totalTasks:
   - Enter PR Lifecycle Loop (section 11)
   - Do NOT output ALL_TASKS_COMPLETE yet
3. If NO Phase 5 OR Phase 5 complete:
   - Proceed with standard completion

**Standard Completion** (no Phase 5 or Phase 5 done):

Output exactly `ALL_TASKS_COMPLETE` when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md AND
- Zero test regressions verified AND
- Code is modular/reusable (documented in .progress.md)

Before outputting:
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json (cleanup execution state)
3. Keep .progress.md (preserve learnings and history)
4. Check for PR and output link if exists: `gh pr view --json url -q .url 2>/dev/null`

This signal terminates the Ralph Loop loop.

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).

### 11. PR Lifecycle Loop (Phase 5)

CRITICAL: Phase 5 is continuous autonomous PR management. Do NOT stop until all criteria met.

**Entry Conditions**:
- All Phase 1-4 tasks complete
- Phase 5 tasks detected in tasks.md

**Loop Structure**:
PR Creation -> CI Monitoring -> Review Check -> Fix Issues -> Push -> Repeat

**Step 1: Create PR (if not exists)**

Delegate to spec-executor to create PR using `gh pr create`.

**Step 2: CI Monitoring Loop**

While CI checks not all green:
1. Wait 3 minutes
2. Check status: `gh pr checks`
3. If failures: create fix task, delegate, push fixes, restart wait
4. If pending: continue waiting
5. If all green: proceed to Step 3

**Step 3: Review Comment Check**

1. Fetch review states: `gh pr view --json reviews`
2. If unresolved reviews/comments: create tasks, delegate, push, return to Step 2
3. If no unresolved: proceed to Step 4

**Step 4: Final Validation**

All must be true:
- All Phase 1-4 tasks complete
- All Phase 5 tasks complete
- CI checks all green
- No unresolved review comments

**Step 5: Completion**

When all criteria met:
1. Delete .ralph-state.json
2. Get PR URL
3. Output: ALL_TASKS_COMPLETE
4. Output: PR link

**Timeout Protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: Output error and STOP
```

## Output on Start

```text
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
