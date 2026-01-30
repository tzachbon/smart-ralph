---
name: failure-recovery
version: 0.1.0
description: This skill should be used when the user asks about "iterative recovery", "fix task generation", "recovery mode", "parse failure output", "fixTaskMap", "automatic failure recovery", "recovery orchestration", or needs guidance on handling task failures with automatic fix task generation.
---

# Failure Recovery

Orchestrates iterative failure recovery when tasks fail during spec execution. When enabled via `--recovery-mode`, automatically generates fix tasks instead of stopping on failure.

## Overview

Recovery mode is an opt-in enhancement to the standard retry-then-stop behavior. When enabled:
- Failed tasks trigger automatic fix task generation
- Fix tasks are inserted into tasks.md and executed
- Original task is retried after fix task completes
- Process repeats until success or max fix limit reached

**Backwards Compatibility**: `recoveryMode` defaults to false. When false or missing, existing behavior (retry then stop) is preserved exactly.

## Entry Point

When spec-executor does NOT output TASK_COMPLETE:

1. Check if `recoveryMode` is true in .ralph-state.json
2. If recoveryMode is false, undefined, or missing: skip to standard "Max Retries Reached" error (existing behavior preserved)
3. If recoveryMode is explicitly true: proceed with iterative recovery

## Parse Failure Output

Extract error details from spec-executor failure output.

### Failure Output Pattern

Spec-executor outputs failures in this format:

```text
Task X.Y: [task name] FAILED
- Error: [description]
- Attempted fix: [what was tried]
- Status: Blocked, needs manual intervention
```

### Parsing Logic

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

### Example Parsing

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

## Fix Task Generator

Generate a fix task from failure details when recovery mode is enabled.

### Check Fix Task Limits

Before generating a fix task:

1. Read `fixTaskMap` from .ralph-state.json
2. Check if `fixTaskMap[taskId].attempts >= maxFixTasksPerOriginal`
3. If limit reached:
   - Output error: "ERROR: Max fix attempts ($maxFixTasksPerOriginal) reached for task $taskId"
   - Show fix history: "Fix attempts: $fixTaskMap[taskId].fixTaskIds"
   - Do NOT output ALL_TASKS_COMPLETE
   - STOP execution

### Generate Fix Task Markdown

Use the failure object to create a fix task:

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

### Field Derivation

| Field                | Source                              | Fallback                       |
|----------------------|-------------------------------------|--------------------------------|
| errorSummary         | First 50 chars of failure.error     | "task $taskId failure"         |
| failure.error        | Parsed from Error: line             | "Task execution failed"        |
| failure.attemptedFix | Parsed from Attempted fix: line     | "No previous fix attempted"    |
| originalTask.files   | Files field from original task      | Same directory as original     |
| originalTask.verify  | Verify field from original task     | "echo 'Verify manually'"       |
| $scope               | Derived from spec name or task area | "recovery"                     |
| $errorType           | Error category (e.g., "syntax", "missing file") | "error"           |

### Example Fix Task Generation

Original task (failed):
```markdown
- [ ] 1.3 Add failure parser
  - **Do**: Add parsing logic to implement.md
  - **Files**: plugins/ralph-specum/commands/implement.md
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
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Error "File not found: src/parser.ts" no longer occurs
  - **Verify**: grep -q "Parse Failure" implement.md
  - **Commit**: `fix(recovery): address missing file from task 1.3`
```

### Insert Fix Task into tasks.md

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
   - Add the complete fix task markdown block

5. **Insert using Edit tool**:
   - Use Edit tool with `old_string` = content at insertion point
   - `new_string` = fix task markdown + original content at insertion point
   - This places fix task immediately after original task block

6. **Update state totalTasks**:
   - Read .ralph-state.json
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

## Recovery State Management

Track fix task attempts and history using fixTaskMap in .ralph-state.json.

### State Structure

```json
{
  "phase": "execution",
  "taskIndex": 2,
  "totalTasks": 10,
  "recoveryMode": true,
  "maxFixTasksPerOriginal": 3,
  "fixTaskMap": {
    "1.3": {
      "attempts": 2,
      "fixTaskIds": ["1.3.1", "1.3.2"],
      "lastError": "Syntax error in parser.ts line 42"
    }
  }
}
```

### Update State After Generation

After generating a fix task:
1. Increment `fixTaskMap[taskId].attempts`
2. Add fix task ID to `fixTaskMap[taskId].fixTaskIds` array
3. Store error in `fixTaskMap[taskId].lastError`
4. Increment `totalTasks`
5. Write updated .ralph-state.json

**Implementation using jq**:

```bash
# Variables from context
SPEC_PATH="./specs/$spec"
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
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

### Reading fixTaskMap for Limit Checks

```bash
# Check current attempts for a task
CURRENT_ATTEMPTS=$(jq -r --arg taskId "$TASK_ID" \
  '.fixTaskMap[$taskId].attempts // 0' "$SPEC_PATH/.ralph-state.json")

# Check if limit exceeded
MAX_FIX=$(jq -r '.maxFixTasksPerOriginal // 3' "$SPEC_PATH/.ralph-state.json")
if [ "$CURRENT_ATTEMPTS" -ge "$MAX_FIX" ]; then
  echo "ERROR: Max fix attempts ($MAX_FIX) reached for task $TASK_ID"
  # Show fix history
  jq -r --arg taskId "$TASK_ID" \
    '.fixTaskMap[$taskId].fixTaskIds | join(", ")' "$SPEC_PATH/.ralph-state.json"
  exit 1
fi
```

## Iterative Recovery Orchestrator

Complete orchestration flow for the recovery loop.

### Recovery Loop Flow

```text
1. Task fails (no TASK_COMPLETE)
   |
   v
2. Check recoveryMode in state
   |
   |-- false --> Normal retry/stop behavior
   |
   v (true)
3. Parse failure output (Section: Parse Failure Output)
   Extract: taskId, error, attemptedFix
   |
   v
4. Check fix limits (Section: Check Fix Task Limits)
   Read: fixTaskMap[taskId].attempts
   |
   |-- >= maxFixTasksPerOriginal --> STOP with error
   |
   v (under limit)
5. Generate fix task (Section: Fix Task Generator)
   Create: X.Y.N [FIX X.Y] Fix: <error>
   |
   v
6. Insert fix task into tasks.md
   Position: immediately after original task
   |
   v
7. Update state
   - Increment fixTaskMap[taskId].attempts
   - Add fix task ID to fixTaskMap[taskId].fixTaskIds
   - Increment totalTasks
   |
   v
8. Execute fix task
   Delegate to spec-executor (same as normal task delegation)
   |
   |-- TASK_COMPLETE --> Proceed to step 9
   |
   |-- No completion --> Loop back to step 3
       (fix task becomes current, can spawn its own fixes)
   |
   v
9. Retry original task
   Delegate original task to spec-executor again
   |
   |-- TASK_COMPLETE --> Success! Proceed to verification layers
   |
   |-- No completion --> Loop back to step 3
       (generate another fix for original task)
```

### Example Recovery Sequence

```text
Initial: Task 1.3 fails
  |
Recovery Mode enabled
  |
Parse: error = "syntax error in parser.ts"
  |
Check: fixTaskMap["1.3"].attempts = 0 (under limit of 3)
  |
Generate: Task 1.3.1 [FIX 1.3] Fix: syntax error
  |
Insert: Add 1.3.1 after 1.3 in tasks.md
  |
Update: fixTaskMap["1.3"] = {attempts: 1, fixTaskIds: ["1.3.1"]}
  |
Execute: Delegate 1.3.1 to spec-executor
  |
1.3.1 completes with TASK_COMPLETE
  |
Retry: Delegate 1.3 to spec-executor again
  |
1.3 completes with TASK_COMPLETE
  |
Success! --> Verification layers --> State update --> Next task
```

### Nested Fix Example

Fix tasks can fail and spawn their own fix tasks:

```text
Task 1.3 fails --> Generate 1.3.1
  |
1.3.1 fails --> Generate 1.3.1.1 (fix for the fix)
  |
1.3.1.1 completes
  |
Retry 1.3.1 --> completes
  |
Retry 1.3 --> completes
  |
Success!
```

### Important Rules

- Fix tasks can spawn their own fix tasks (recursive recovery)
- Each original task tracks its own fix count independently
- taskIndex does NOT advance during fix task execution
- Only after original task passes does taskIndex advance
- Fix task IDs use dot notation to show lineage: 1.3.1, 1.3.2, 1.3.1.1

## Fix Task Progress Logging

After original task completes following fix task recovery, log the fix task chain to .progress.md.

### Fix Task History Section

Add/update section in .progress.md:

```markdown
## Fix Task History
- Task 1.3: 2 fixes attempted (1.3.1, 1.3.2) - Final: PASS
- Task 2.1: 1 fix attempted (2.1.1) - Final: PASS
- Task 3.4: 3 fixes attempted (3.4.1, 3.4.2, 3.4.3) - Final: FAIL (max limit)
```

### Logging Implementation

After successful original task retry (TASK_COMPLETE):

1. Check if fixTaskMap[$taskId] exists and has attempts > 0
2. If yes, append fix task history entry to .progress.md:
   ```
   - Task $taskId: $attempts fixes attempted ($fixTaskIds) - Final: PASS
   ```
3. Use Edit tool to append to "## Fix Task History" section
4. If section doesn't exist, create it before "## Learnings" section

On max fix limit reached:

1. Log failed recovery attempt:
   ```
   - Task $taskId: $attempts fixes attempted ($fixTaskIds) - Final: FAIL (max limit)
   ```
2. Include in .progress.md before stopping execution

### Example Progress Update

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

## Why This Matters

| Without Recovery Mode | With Recovery Mode |
|----------------------|-------------------|
| Single failure stops execution | Automatic fix attempt generation |
| Manual intervention required | Self-healing loop attempts |
| Context lost on restart | Continuous execution with tracking |
| Binary pass/fail per task | Iterative refinement of fixes |
| No history of fix attempts | Full fix task lineage tracked |
