---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash]
---

# Start Execution

You are starting the task execution loop.

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
  "maxTaskIterations": <parsed from --max-task-iterations or default 5>,
  "globalIteration": 1,
  "maxGlobalIterations": 100
}
```

## Write Coordinator Prompt

Write the ENTIRE coordinator prompt (from section below) to `./specs/$spec/.coordinator-prompt.md`.

This file contains the full instructions for task execution. The stop-hook will inject this prompt when blocking exit.

## Coordinator Prompt

Write this prompt to `./specs/$spec/.coordinator-prompt.md`:

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
```
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

**After Delegation**:

If spec-executor outputs TASK_COMPLETE (or qa-engineer outputs VERIFICATION_PASS):
1. Run verification layers (section 7) before advancing
2. If all verifications pass, proceed to state update

If no completion signal:
1. Increment taskIteration in state file
2. If taskIteration > maxTaskIterations: proceed to max retries error handling
3. Otherwise: Retry the same task

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

All spec file changes must be committed before task is considered complete.

**Layer 3: Checkmark Verification**

Count completed tasks in tasks.md:

```bash
grep -c '\- \[x\]' ./specs/$spec/tasks.md
```

Expected checkmark count = taskIndex + 1 (0-based index, so task 0 complete = 1 checkmark)

If actual count != expected:
- REJECT the completion
- Log: "checkmark mismatch: expected $expected, found $actual"
- This detects state manipulation or incomplete task marking
- Increment taskIteration and retry

**Layer 4: TASK_COMPLETE Signal Verification**

Verify spec-executor explicitly output TASK_COMPLETE:
- Must be present in response
- Not just implied or partial completion
- Silent completion is not valid

If TASK_COMPLETE missing:
- Do NOT advance
- Increment taskIteration and retry

**Verification Summary**

All 4 layers must pass:
1. No contradiction phrases with completion claim
2. Spec files committed (no uncommitted changes)
3. Checkmark count matches expected taskIndex + 1
4. Explicit TASK_COMPLETE signal present

Only after all verifications pass, proceed to State Update (section 8).

### 8. State Update

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

Check if all tasks complete:
- If taskIndex >= totalTasks: proceed to section 10 (Completion Signal)
- If taskIndex < totalTasks: continue to next iteration (stop-hook will re-invoke coordinator)

### 9. Progress Merge

**Parallel Only**: After parallel batch completes:

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

**ERROR: Partial Parallel Batch Failure**

If any parallel task failed (no TASK_COMPLETE in its output):
1. Identify which task(s) failed from the batch
2. Note successful tasks in .progress.md
3. For failed tasks, increment taskIteration
4. If failed task exceeds maxTaskIterations: output "ERROR: Max retries reached for parallel task $failedTaskIndex"
5. Otherwise: retry ONLY the failed task(s), do NOT re-run successful ones
6. Do NOT advance taskIndex past the batch until ALL tasks in batch complete
7. Merge only successful task progress files

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

This signal terminates the execution loop. The stop-hook detects this and allows the session to exit.

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).

### 11. PR Lifecycle Loop (Phase 5)

CRITICAL: Phase 5 is continuous autonomous PR management. Do NOT stop until all criteria met.

**Entry Conditions**:
- All Phase 1-4 tasks complete
- Phase 5 tasks detected in tasks.md

**Loop Structure**:
```
PR Creation → CI Monitoring → Review Check → Fix Issues → Push → Repeat
```

**Step 1: Create PR (if not exists)**

Delegate to spec-executor:
```
Task: Create pull request

Do:
1. Verify not on default branch: git branch --show-current
2. Push branch: git push -u origin <branch>
3. Create PR: gh pr create --title "feat: <spec>" --body "<summary>"

Verify: gh pr view shows PR created
Done when: PR URL returned
Commit: None
```

**Step 2: CI Monitoring Loop**

```
While (CI checks not all green):
  1. Wait 3 minutes (allow CI to start/complete)
  2. Check status: gh pr checks
  3. If failures:
     - Read failure details: gh run view --log-failed
     - Create new Phase 5.X task in tasks.md:
       - [ ] 5.X Fix CI failure: <failure summary>
         - **Do**: <steps to fix based on failure logs>
         - **Files**: <files to modify based on failure>
         - **Done when**: CI check passes
         - **Verify**: gh pr checks shows this check ✓
         - **Commit**: fix: address CI failure - <summary>
     - Delegate new task to spec-executor with task index and Files list
     - Wait for TASK_COMPLETE
     - Push fixes (if not already pushed by spec-executor)
     - Restart wait cycle
  4. If pending:
     - Continue waiting
  5. If all green:
     - Proceed to Step 3
```

**Step 3: Review Comment Check**

```
1. Fetch review states: gh pr view --json reviews
   - Parse for reviews with state "CHANGES_REQUESTED" or "PENDING"
   - Note: --json reviews returns review-level state but NOT inline comment threads
   - For inline comments, use REST API: gh api repos/{owner}/{repo}/pulls/{number}/reviews
   - Or use review comments endpoint: gh api repos/{owner}/{repo}/pulls/{number}/comments
2. Parse for unresolved reviews/comments
3. If unresolved reviews/comments found:
   - Create tasks from reviews (add to tasks.md as Phase 5.X)
   - For each review/comment:
     - [ ] 5.X Address review: <reviewer> - <summary>
       - **Do**: <change requested>
       - **Files**: <files to modify>
       - **Done when**: Review comment addressed
       - **Verify**: Code implements requested change
       - **Commit**: fix: address review - <summary>
   - Delegate each to spec-executor
   - Wait for completion
   - Push fixes
   - Return to Step 2 (re-check CI)
4. If no unresolved reviews/comments:
   - Proceed to Step 4
```

**Step 4: Final Validation**

All must be true:
- ✅ All Phase 1-4 tasks complete (checked [x])
- ✅ All Phase 5 tasks complete
- ✅ CI checks all green
- ✅ No unresolved review comments
- ✅ Zero test regressions (all existing tests pass)
- ✅ Code is modular/reusable (verified in .progress.md)

**Step 5: Completion**

When all Step 4 criteria met:
1. Update .progress.md with final state
2. Delete .ralph-state.json
3. Output: ALL_TASKS_COMPLETE

**Timeout Protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: Output error and STOP (do not output ALL_TASKS_COMPLETE)

**Error Handling**:
- If CI fails after 5 retry attempts: STOP with error
- If review comments cannot be addressed: STOP with error
- Document all failures in .progress.md Learnings
```

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time via Task tool delegation
- Stop-hook blocks exit until ALL_TASKS_COMPLETE detected
- Continue until all tasks complete or max iterations reached

Beginning execution...
```

After outputting this message, immediately read the coordinator prompt from `./specs/$spec/.coordinator-prompt.md` and follow those instructions to begin task execution.
