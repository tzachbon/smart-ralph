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
1. Output error: "ERROR: Ralph Loop plugin not found. Install with: /plugin install ralph-loop@claude-plugins-official"
2. STOP execution immediately. Do NOT continue.

This is a hard dependency. The command cannot function without Ralph Loop.

## Determine Active Feature

1. Read `.specify/.current-feature` to get active feature (format: `<id>-<name>`)
2. If file missing or empty: error "No active feature. Run /speckit:start <name> first."

## Validate Prerequisites

1. Check `.specify/specs/$feature/` directory exists
2. Check `.specify/specs/$feature/tasks.md` exists. If not: error "Tasks not found. Run /speckit:tasks first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)
- **--recovery-mode**: Enable iterative failure recovery (default: false). When enabled, failed tasks trigger automatic fix task generation instead of stopping.

## Commit Uncommitted Spec Files

Before starting execution, check if spec files are uncommitted:

```bash
git status --porcelain .specify/specs/$feature/
```

If uncommitted files exist, commit them:
```bash
git add .specify/specs/$feature/
git commit -m "chore(speckit): commit spec files before implementation"
```

This ensures spec files are tracked before task execution begins.

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task
4. Read featureId and name from feature directory name (format: `<id>-<name>`)

Write `.specify/specs/$feature/.speckit-state.json`:
```json
{
  "featureId": "<3-digit id>",
  "name": "<feature-name>",
  "basePath": ".specify/specs/<id>-<name>",
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": <parsed from --max-task-iterations or default 5>,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "awaitingApproval": false,
  "recoveryMode": <true if --recovery-mode flag present, false otherwise>,
  "maxFixTasksPerOriginal": 3,
  "fixTaskMap": {}
}
```

## Invoke Ralph Loop

Calculate max iterations: `totalTasks * maxTaskIterations * 2`

### Step 1: Write Coordinator Prompt to File

Write the ENTIRE coordinator prompt (from section below) to `.specify/specs/$feature/.coordinator-prompt.md`.

This file contains the full instructions for task execution. Writing it to a file avoids shell argument parsing issues with the multi-line prompt.

### Step 2: Invoke Ralph Loop Skill

Use the Skill tool to invoke `ralph-loop:ralph-loop` with args:

```
Read .specify/specs/$feature/.coordinator-prompt.md and follow those instructions exactly. Output ALL_TASKS_COMPLETE when done. --max-iterations <calculated> --completion-promise ALL_TASKS_COMPLETE
```

Replace `$feature` with the actual feature name and `<calculated>` with the calculated max iterations value.

## Coordinator Prompt

Write this prompt to `.specify/specs/$feature/.coordinator-prompt.md`:

```text
You are the execution COORDINATOR for feature: $feature

### 1. Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Read state and determine current task
- Delegate task execution to spec-executor via Task tool
- Track completion and signal when all tasks done

CRITICAL: You MUST delegate via Task tool. Do NOT implement tasks yourself.
You are fully autonomous. NEVER ask questions or wait for user input.

### 2. Read State

Read `.specify/specs/$feature/.speckit-state.json` to get current state:

```json
{
  "featureId": "<3-digit id>",
  "name": "<feature-name>",
  "basePath": ".specify/specs/<id>-<name>",
  "phase": "execution",
  "taskIndex": <current task index, 0-based>,
  "totalTasks": <total task count>,
  "taskIteration": <retry count for current task>,
  "maxTaskIterations": <max retries>,
  "globalIteration": <total iterations>,
  "maxGlobalIterations": <max total iterations>,
  "awaitingApproval": <boolean>,
  "recoveryMode": <boolean - true if iterative failure recovery enabled>,
  "maxFixTasksPerOriginal": <max fix tasks per original task, default 3>,
  "fixTaskMap": <object tracking fix attempts per task>
}
```

**ERROR: Missing/Corrupt State File**

If state file missing or corrupt (invalid JSON, missing required fields):
1. Output error: "ERROR: State file missing or corrupt at .specify/specs/$feature/.speckit-state.json"
2. Suggest: "Run /speckit:implement to reinitialize execution state"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

### 3. Check Completion

If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md
2. Delete .speckit-state.json (cleanup)
3. Output: ALL_TASKS_COMPLETE
4. STOP - do not delegate any task

### 4. Parse Current Task

Read `.specify/specs/$feature/tasks.md` and find the task at taskIndex (0-based).

**ERROR: Missing tasks.md**

If tasks.md does not exist:
1. Output error: "ERROR: Tasks file missing at .specify/specs/$feature/tasks.md"
2. Suggest: "Run /speckit:tasks to generate task list"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

**ERROR: Missing Feature Directory**

If feature directory does not exist (.specify/specs/$feature/):
1. Output error: "ERROR: Feature directory missing at .specify/specs/$feature/"
2. Suggest: "Run /speckit:start <feature-name> to create a new feature"
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
Task: Execute verification task $taskIndex for feature $feature

Feature: $feature
Path: .specify/specs/$feature/

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
Task: Execute task $taskIndex for feature $feature

Feature: $feature
Path: .specify/specs/$feature/
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
Task: Execute task 3 for feature $feature
progressFile: .progress-task-3.md
...

[Task tool call 2]
Task: Execute task 4 for feature $feature
progressFile: .progress-task-4.md
...

[Task tool call 3]
Task: Execute task 5 for feature $feature
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

**Example Parsing**:

Input (spec-executor output):
```text
Task 1.3: Add failure parser FAILED
- Error: File not found: src/parser.ts
- Attempted fix: Checked alternate paths
- Status: Blocked, needs manual intervention
```

Parsed failure object:
```json
{
  "taskId": "1.3",
  "failed": true,
  "error": "File not found: src/parser.ts",
  "attemptedFix": "Checked alternate paths",
  "status": "Blocked, needs manual intervention",
  "rawOutput": "..."
}
```

This failure object is used by the recovery orchestrator (section 6c) to generate fix tasks when recoveryMode is enabled.

### 6c. Fix Task Generator

When recoveryMode is enabled and a task fails, generate a fix task from the failure details.

**Check Recovery Mode**:

First, verify recovery mode is enabled:
1. Read `recoveryMode` from .speckit-state.json
2. If `recoveryMode` is false or missing, skip to "ERROR: Max Retries Reached"
3. If `recoveryMode` is true, proceed with fix task generation

**Check Fix Task Limits**:

Before generating a fix task:
1. Read `fixTaskMap` from .speckit-state.json
2. Check if `fixTaskMap[taskId].attempts >= maxFixTasksPerOriginal`
3. If limit reached:
   - Output error: "ERROR: Max fix attempts ($maxFixTasksPerOriginal) reached for task $taskId"
   - Show fix history: "Fix attempts: $fixTaskMap[taskId].fixTaskIds"
   - Do NOT output ALL_TASKS_COMPLETE
   - STOP execution

**Generate Fix Task Markdown**:

Use the failure object from section 6b to create a fix task:

```text
Fix Task ID: $taskId.$attemptNumber
  where attemptNumber = fixTaskMap[taskId].attempts + 1 (or 1 if first attempt)

Fix Task Format:
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

**Field Derivation**:

| Field                | Source                              | Fallback                       |
|----------------------|-------------------------------------|--------------------------------|
| errorSummary         | First 50 chars of failure.error     | "task $taskId failure"         |
| failure.error        | Parsed from Error: line             | "Task execution failed"        |
| failure.attemptedFix | Parsed from Attempted fix: line     | "No previous fix attempted"    |
| originalTask.files   | Files field from original task      | Same directory as original     |
| originalTask.verify  | Verify field from original task     | "echo 'Verify manually'"       |
| $scope               | Derived from feature name or task area | "recovery"                  |
| $errorType           | Error category (e.g., "syntax", "missing file") | "error"           |

**Example Fix Task Generation**:

Original task (failed):
```markdown
- [ ] 1.3 Add failure parser
  - **Do**: Add parsing logic to implement.md
  - **Files**: plugins/ralph-speckit/commands/implement.md
  - **Done when**: Parser extracts error details
  - **Verify**: grep -q "Parse Failure" implement.md
  - **Commit**: feat(coordinator): add failure parser
```

Failure object:
```json
{
  "taskId": "1.3",
  "error": "File not found: src/parser.ts",
  "attemptedFix": "Checked alternate paths"
}
```

Generated fix task:
```markdown
- [ ] 1.3.1 [FIX 1.3] Fix: File not found: src/parser.ts
  - **Do**: Address the error: File not found: src/parser.ts
    1. Analyze the failure: Checked alternate paths
    2. Review related code in Files list
    3. Implement fix for: File not found: src/parser.ts
  - **Files**: plugins/ralph-speckit/commands/implement.md
  - **Done when**: Error "File not found: src/parser.ts" no longer occurs
  - **Verify**: grep -q "Parse Failure" implement.md
  - **Commit**: `fix(recovery): address missing file from task 1.3`
```

**Update State After Generation**:

After generating the fix task:
1. Increment `fixTaskMap[taskId].attempts`
2. Add fix task ID to `fixTaskMap[taskId].fixTaskIds` array
3. Store error in `fixTaskMap[taskId].lastError`
4. Write updated .speckit-state.json

**Insert Fix Task into tasks.md**:

Use the Edit tool to cleanly insert the fix task after the current task block.

**Algorithm**:

1. **Read tasks.md content** using Read tool

2. **Locate current task start**:
   - Search for pattern: `- [ ] $taskId` or `- [x] $taskId`
   - Store the line number as `taskStartLine`

3. **Find current task block end**:
   - Scan forward from `taskStartLine + 1`
   - Task block ends at first line matching:
     - `- [ ]` (next task start)
     - `- [x]` (next completed task)
     - `## Phase` (next phase header)
     - End of file
   - Store this line as `insertPosition`

4. **Build insertion content**:
   - Start with newline if needed for spacing
   - Add the complete fix task markdown block:
   ```markdown
   - [ ] X.Y.N [FIX X.Y] Fix: $errorSummary
     - **Do**: Address the error: $errorDetails
       1. Analyze the failure: $attemptedFix
       2. Review related code in Files list
       3. Implement fix for: $errorDetails
     - **Files**: $originalTaskFiles
     - **Done when**: Error "$errorDetails" no longer occurs
     - **Verify**: $originalTaskVerify
     - **Commit**: `fix($scope): address $errorType from task $taskId`
   ```
   - Ensure proper indentation (2 spaces for sub-bullets)

5. **Insert using Edit tool**:
   - Use Edit tool with `old_string` = content at insertion point
   - `new_string` = fix task markdown + original content at insertion point
   - This places fix task immediately after original task block

6. **Update state totalTasks**:
   - Read .speckit-state.json
   - Increment `totalTasks` by 1
   - Write updated state

**Example Insertion**:

Before insertion (task 1.3 failed):

```markdown
- [ ] 1.3 Add failure parser
  - **Do**: Add parsing logic
  - **Files**: implement.md
  - **Verify**: grep pattern
  - **Commit**: feat: add parser

- [ ] 1.4 Next task
```

After insertion:

```markdown
- [ ] 1.3 Add failure parser
  - **Do**: Add parsing logic
  - **Files**: implement.md
  - **Verify**: grep pattern
  - **Commit**: feat: add parser

- [ ] 1.3.1 [FIX 1.3] Fix: File not found error
  - **Do**: Address the error: File not found
    1. Analyze the failure: Checked alternate paths
    2. Review related code in Files list
    3. Implement fix for: File not found
  - **Files**: implement.md
  - **Done when**: Error "File not found" no longer occurs
  - **Verify**: grep pattern
  - **Commit**: `fix(recovery): address missing file from task 1.3`

- [ ] 1.4 Next task
```

**Execute Fix Task**:

After insertion:
1. Delegate fix task to spec-executor (same as section 6)
2. On TASK_COMPLETE: retry original task
3. On failure: loop back to section 6c (new fix task for fix task)

**Retry Original Task**:

After fix task completes:
1. Return to original task (taskIndex unchanged)
2. Delegate original task to spec-executor
3. If TASK_COMPLETE: proceed to section 7 (verification) then section 8 (state update)
4. If failure: loop back to section 6c (generate another fix task)

### 6d. Iterative Failure Recovery Orchestrator

This section orchestrates the complete failure recovery loop when recoveryMode is enabled.

**Backwards Compatibility Note**:

recoveryMode defaults to false. When recoveryMode is false or missing, the existing behavior (retry then stop) is preserved exactly. The recovery orchestrator only activates when recoveryMode is explicitly set to true via --recovery-mode flag.

**Entry Point**:

When spec-executor does NOT output TASK_COMPLETE:
1. First, check if `recoveryMode` is true in .speckit-state.json
2. If recoveryMode is false, undefined, or missing: skip to "ERROR: Max Retries Reached" (existing behavior preserved)
3. If recoveryMode is explicitly true: proceed with iterative recovery

**Recovery Loop Flow**:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    ITERATIVE FAILURE RECOVERY                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Task fails (no TASK_COMPLETE)                               │
│     │                                                           │
│     ▼                                                           │
│  2. Check recoveryMode in state                                 │
│     │                                                           │
│     ├── false ──► Normal retry/stop behavior                    │
│     │                                                           │
│     ▼ (true)                                                    │
│  3. Parse failure output (Section 6b)                           │
│     Extract: taskId, error, attemptedFix                        │
│     │                                                           │
│     ▼                                                           │
│  4. Check fix limits (Section 6c)                               │
│     Read: fixTaskMap[taskId].attempts                           │
│     │                                                           │
│     ├── >= maxFixTasksPerOriginal ──► STOP with error           │
│     │                                                           │
│     ▼ (under limit)                                             │
│  5. Generate fix task (Section 6c)                              │
│     Create: X.Y.N [FIX X.Y] Fix: <error>                        │
│     │                                                           │
│     ▼                                                           │
│  6. Insert fix task into tasks.md (Section 6c)                  │
│     Position: immediately after original task                   │
│     │                                                           │
│     ▼                                                           │
│  7. Update state                                                │
│     - Increment fixTaskMap[taskId].attempts                     │
│     - Add fix task ID to fixTaskMap[taskId].fixTaskIds          │
│     - Increment totalTasks                                      │
│     │                                                           │
│     ▼                                                           │
│  8. Execute fix task                                            │
│     Delegate to spec-executor (same as Section 6)               │
│     │                                                           │
│     ├── TASK_COMPLETE ──► Proceed to step 9                     │
│     │                                                           │
│     └── No completion ──► Loop back to step 3                   │
│         (fix task becomes current, can spawn its own fixes)     │
│     │                                                           │
│     ▼                                                           │
│  9. Retry original task                                         │
│     Delegate original task to spec-executor again               │
│     │                                                           │
│     ├── TASK_COMPLETE ──► Success! Section 7 verification       │
│     │                                                           │
│     └── No completion ──► Loop back to step 3                   │
│         (generate another fix for original task)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Step-by-Step Implementation**:

**Step 1: Check Recovery Mode**

```text
Read .speckit-state.json
# recoveryMode defaults to false for backwards compatibility
If recoveryMode !== true (false, undefined, or missing):
  - Increment taskIteration
  - If taskIteration > maxTaskIterations: ERROR and STOP
  - Otherwise: retry same task (existing behavior preserved)
  - EXIT this section - do NOT proceed with recovery orchestration
```

**Step 2: Parse Failure (calls Section 6b)**

```text
Parse spec-executor output using pattern from Section 6b
Build failure object:
{
  "taskId": "X.Y",
  "error": "<from Error: line>",
  "attemptedFix": "<from Attempted fix: line>",
  "rawOutput": "<full output>"
}
```

**Step 3: Check Fix Limits (from Section 6c)**

```text
Read fixTaskMap from state
currentAttempts = fixTaskMap[taskId].attempts || 0

If currentAttempts >= maxFixTasksPerOriginal:
  - Output ERROR: "Max fix attempts ($max) reached for task $taskId"
  - Show fix history: fixTaskMap[taskId].fixTaskIds
  - Do NOT output ALL_TASKS_COMPLETE
  - STOP execution
```

**Step 4: Generate Fix Task (calls Section 6c)**

```text
Use failure object to create fix task markdown:
- [ ] X.Y.N [FIX X.Y] Fix: <errorSummary>
  - **Do**: Address the error: <error>
  - **Files**: <originalTask.files>
  - **Done when**: Error no longer occurs
  - **Verify**: <originalTask.verify>
  - **Commit**: fix(<scope>): address <errorType>

Where N = currentAttempts + 1
```

**Step 5: Insert Fix Task (calls Section 6c)**

```text
Use Edit tool to insert fix task into tasks.md
Position: immediately after original task block
Update totalTasks in state
```

**Step 6: Update State (fixTaskMap tracking)**

After generating a fix task, update fixTaskMap in state to track:
- attempts: number of fix tasks generated for this original task
- fixTaskIds: array of fix task IDs created
- lastError: most recent error message

**Implementation using jq**:

```bash
# Variables from context
FEATURE_PATH=".specify/specs/$feature"
TASK_ID="X.Y"           # Original task ID (e.g., "1.3")
FIX_TASK_ID="X.Y.N"     # Generated fix task ID (e.g., "1.3.1")
ERROR_MSG="$failure_error"  # Escaped error message from failure object

# Read current state, update fixTaskMap, write back
jq --arg taskId "$TASK_ID" \
   --arg fixId "$FIX_TASK_ID" \
   --arg error "$ERROR_MSG" \
   '
   # Initialize fixTaskMap if it does not exist
   .fixTaskMap //= {} |

   # Initialize entry for this task if it does not exist
   .fixTaskMap[$taskId] //= {attempts: 0, fixTaskIds: [], lastError: ""} |

   # Update the entry
   .fixTaskMap[$taskId].attempts += 1 |
   .fixTaskMap[$taskId].fixTaskIds += [$fixId] |
   .fixTaskMap[$taskId].lastError = $error |

   # Also increment totalTasks to account for inserted fix task
   .totalTasks += 1
   ' "$FEATURE_PATH/.speckit-state.json" > "$FEATURE_PATH/.speckit-state.json.tmp" && \
   mv "$FEATURE_PATH/.speckit-state.json.tmp" "$FEATURE_PATH/.speckit-state.json"
```

**Example state after fix task generation**:

Before (task 1.3 fails first time):
```json
{
  "phase": "execution",
  "taskIndex": 2,
  "totalTasks": 10,
  "fixTaskMap": {}
}
```

After (fix task 1.3.1 generated):
```json
{
  "phase": "execution",
  "taskIndex": 2,
  "totalTasks": 11,
  "fixTaskMap": {
    "1.3": {
      "attempts": 1,
      "fixTaskIds": ["1.3.1"],
      "lastError": "File not found: src/parser.ts"
    }
  }
}
```

After second failure (fix task 1.3.2 generated):
```json
{
  "phase": "execution",
  "taskIndex": 2,
  "totalTasks": 12,
  "fixTaskMap": {
    "1.3": {
      "attempts": 2,
      "fixTaskIds": ["1.3.1", "1.3.2"],
      "lastError": "Syntax error in parser.ts line 42"
    }
  }
}
```

**Reading fixTaskMap for limit checks**:

```bash
# Check current attempts for a task
CURRENT_ATTEMPTS=$(jq -r --arg taskId "$TASK_ID" \
  '.fixTaskMap[$taskId].attempts // 0' "$FEATURE_PATH/.speckit-state.json")

# Check if limit exceeded
MAX_FIX=$(jq -r '.maxFixTasksPerOriginal // 3' "$FEATURE_PATH/.speckit-state.json")
if [ "$CURRENT_ATTEMPTS" -ge "$MAX_FIX" ]; then
  echo "ERROR: Max fix attempts ($MAX_FIX) reached for task $TASK_ID"
  # Show fix history
  jq -r --arg taskId "$TASK_ID" \
    '.fixTaskMap[$taskId].fixTaskIds | join(", ")' "$FEATURE_PATH/.speckit-state.json"
  exit 1
fi
```

**Step 7: Execute Fix Task**

```text
Delegate fix task to spec-executor via Task tool
Same delegation pattern as Section 6

If TASK_COMPLETE:
  - Mark fix task [x] in tasks.md
  - Proceed to Step 8

If no TASK_COMPLETE:
  - Fix task itself failed
  - Loop back to Step 2 with fix task as current task
  - (Fix task can spawn its own fix tasks)
```

**Step 8: Retry Original Task**

```text
Return to original task (taskIndex unchanged)
Delegate original task to spec-executor again

If TASK_COMPLETE:
  - Success! Proceed to Section 7 (verification layers)
  - Then Section 8 (state update, advance taskIndex)

If no TASK_COMPLETE:
  - Original still failing after fix
  - Loop back to Step 2
  - Generate another fix task for original
```

**Example Recovery Sequence**:

```text
Initial: Task 1.3 fails
  ↓
Recovery Mode enabled
  ↓
Parse: error = "syntax error in parser.ts"
  ↓
Check: fixTaskMap["1.3"].attempts = 0 (under limit of 3)
  ↓
Generate: Task 1.3.1 [FIX 1.3] Fix: syntax error
  ↓
Insert: Add 1.3.1 after 1.3 in tasks.md
  ↓
Update: fixTaskMap["1.3"] = {attempts: 1, fixTaskIds: ["1.3.1"]}
  ↓
Execute: Delegate 1.3.1 to spec-executor
  ↓
1.3.1 completes with TASK_COMPLETE
  ↓
Retry: Delegate 1.3 to spec-executor again
  ↓
1.3 completes with TASK_COMPLETE
  ↓
Success! → Section 7 → Section 8 → Next task
```

**Nested Fix Example** (fix task fails):

```text
Task 1.3 fails → Generate 1.3.1
  ↓
1.3.1 fails → Generate 1.3.1.1 (fix for the fix)
  ↓
1.3.1.1 completes
  ↓
Retry 1.3.1 → completes
  ↓
Retry 1.3 → completes
  ↓
Success!
```

**Important Notes**:

- Fix tasks can spawn their own fix tasks (recursive recovery)
- Each original task tracks its own fix count independently
- taskIndex does NOT advance during fix task execution
- Only after original task passes does taskIndex advance
- Fix task IDs use dot notation to show lineage: 1.3.1, 1.3.2, 1.3.1.1

**Fix Task Progress Logging**:

After original task completes (TASK_COMPLETE) following fix task recovery, log the fix task chain to .progress.md.

Add/update section in .progress.md:
```markdown
## Fix Task History
- Task 1.3: 2 fixes attempted (1.3.1, 1.3.2) - Final: PASS
- Task 2.1: 1 fix attempted (2.1.1) - Final: PASS
- Task 3.4: 3 fixes attempted (3.4.1, 3.4.2, 3.4.3) - Final: FAIL (max limit)
```

**Logging Implementation**:

After successful original task retry (Step 8 TASK_COMPLETE):
1. Check if fixTaskMap[$taskId] exists and has attempts > 0
2. If yes, append fix task history entry to .progress.md:
   ```
   - Task $taskId: $attempts fixes attempted ($fixTaskIds) - Final: PASS
   ```
3. Use Edit tool to append to "## Fix Task History" section
4. If section doesn't exist, create it before "## Learnings" section

On max fix limit reached (section 6c limit error):
1. Log failed recovery attempt:
   ```
   - Task $taskId: $attempts fixes attempted ($fixTaskIds) - Final: FAIL (max limit)
   ```
2. Include in .progress.md before stopping execution

**Example Progress Update**:

Before fix task logging:
```markdown
## Completed Tasks
- [x] 1.1 Task A - abc123
- [x] 1.2 Task B - def456

## Learnings
- Some learning
```

After fix task logging:
```markdown
## Completed Tasks
- [x] 1.1 Task A - abc123
- [x] 1.2 Task B - def456

## Fix Task History
- Task 1.2: 2 fixes attempted (1.2.1, 1.2.2) - Final: PASS

## Learnings
- Some learning
```

**ERROR: Max Retries Reached**

If taskIteration exceeds maxTaskIterations:
1. Output error: "ERROR: Max retries reached for task $taskIndex after $maxTaskIterations attempts"
2. Include last error/failure reason from spec-executor output
3. Suggest: "Review .progress.md Learnings section for failure details"
4. Suggest: "Fix the issue manually then run /speckit:implement to resume"
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
git status --porcelain .specify/specs/$feature/tasks.md .specify/specs/$feature/.progress.md
```

If output is non-empty (uncommitted changes):
- REJECT the completion
- Log: "uncommitted spec files detected - task not properly committed"
- Increment taskIteration and retry

All spec file changes must be committed before task is considered complete.

**Layer 3: Checkmark Verification**

Count completed tasks in tasks.md:

```bash
grep -c '- \[x\]' .specify/specs/$feature/tasks.md
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
1. Read current .speckit-state.json
2. Increment taskIndex by 1
3. Reset taskIteration to 1
4. Increment globalIteration by 1
5. Write updated state

**Parallel Batch Update**:
1. Read current .speckit-state.json
2. Set taskIndex to parallelGroup.endIndex + 1 (jump past entire batch)
3. Reset taskIteration to 1
4. Increment globalIteration by batch size
5. Write updated state

State structure:
```json
{
  "featureId": "<unchanged>",
  "name": "<unchanged>",
  "basePath": "<unchanged>",
  "phase": "execution",
  "taskIndex": <next task after current/batch>,
  "totalTasks": <unchanged>,
  "taskIteration": 1,
  "maxTaskIterations": <unchanged>,
  "globalIteration": <incremented>,
  "maxGlobalIterations": <unchanged>,
  "awaitingApproval": false
}
```

Check if all tasks complete:
- If taskIndex >= totalTasks: proceed to section 10 (Completion Signal)
- If taskIndex < totalTasks: continue to next iteration (loop re-invokes coordinator)

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

Output exactly `ALL_TASKS_COMPLETE` (on its own line) when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md

Before outputting:
1. Verify all tasks marked [x] in tasks.md
2. Delete .speckit-state.json (cleanup execution state)
3. Keep .progress.md (preserve learnings and history)

This signal terminates the Ralph Loop loop.

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).
```

## Output on Start

```text
Starting execution for '$feature'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
