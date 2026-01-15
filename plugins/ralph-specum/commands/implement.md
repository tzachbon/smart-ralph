---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash]
---

# Start Execution

You are starting the task execution loop. Running this command implicitly approves the tasks phase.

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL task execution to the `spec-executor` subagent. This is NON-NEGOTIABLE.

**NEVER do any of these yourself:**
- Execute task steps from tasks.md
- Write code or modify source files
- Run verification commands as part of task execution
- Commit task changes directly
- "Help" by doing any part of a task yourself

**Your ONLY responsibilities are:**
1. Read state files to determine current task
2. Invoke `spec-executor` subagent via Task tool with full context
3. Report completion status to user

Even if a task seems simple, you MUST delegate to `spec-executor`. No exceptions.
</mandatory>

<mandatory>
## Fully Autonomous = End-to-End Validation

This is a FULLY AUTONOMOUS process. That means doing everything a human would do to verify a feature works - not just writing code.

**What "complete" really means:**
- Code is written ✓
- Code compiles ✓
- Tests pass ✓
- **AND the feature is verified working in the real environment** ✓

**Example: PostHog analytics integration**
A human would:
1. Write the integration code
2. Build the project
3. Load extension in real browser
4. Perform user actions
5. **Check PostHog dashboard to confirm events arrived**
6. Only THEN call it complete

**The agent MUST do the same:**
- Use MCP browser tools to spawn real browsers
- Use WebFetch/curl to hit real APIs
- Verify external systems actually received the data
- Never mark complete based only on "code compiles"

**If a task cannot be verified end-to-end with available tools, it should have been designed differently in task-planner. Do not mark it complete - let it fail and block.**
</mandatory>

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not, error: "Tasks not found. Run /ralph-specum:tasks first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

Update `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  ...
}
```

## Commit Specs First (Before Any Implementation)

<mandatory>
**COMMIT SPECS BEFORE STARTING IMPLEMENTATION**

Before executing any tasks, commit all spec files. This ensures:
- Specs are version-controlled before any code changes
- Clear separation between spec definition and implementation
- Spec history is preserved even if implementation fails
</mandatory>

### Check If Specs Already Committed

Check if this is a fresh start (taskIndex == 0 after initialization) and specs haven't been committed yet:

```bash
# Check if any spec files are uncommitted or untracked
git status --porcelain ./specs/$spec/*.md ./specs/$spec/.progress.md 2>/dev/null | grep -q '.' && echo "uncommitted" || echo "clean"
```

### Commit Spec Files

If specs are uncommitted (new or modified), commit them:

```bash
# Stage all spec files
git add ./specs/$spec/research.md ./specs/$spec/requirements.md ./specs/$spec/design.md ./specs/$spec/tasks.md ./specs/$spec/.progress.md 2>/dev/null

# Commit with descriptive message
git commit -m "docs(spec): add spec for $spec

Spec artifacts:
- research.md: feasibility analysis and codebase exploration
- requirements.md: user stories and acceptance criteria
- design.md: architecture and technical decisions
- tasks.md: POC-first implementation plan

Ready for implementation."
```

If commit succeeds, output:
```
Committed spec files for '$spec'
```

If nothing to commit (specs already committed), continue silently.

## Parallel Task Parsing

When reading tasks.md, parse each task line to detect execution markers:

### Marker Patterns

```
[P]          - Parallel execution marker. Task can run concurrently with adjacent [P] tasks.
[VERIFY]     - Verification checkpoint. Always sequential, never parallel.
[SEQUENTIAL] - Force sequential execution. Overrides [P] if both present.
```

### Regex Detection

For each task line matching `- \[ \]` or `- \[x\]`:
- `/\[P\]/` - Detect parallel marker
- `/\[VERIFY\]/` - Detect verify marker
- `/\[SEQUENTIAL\]/` - Detect sequential override marker

### Parsed Task Structure

Build a list of parsed tasks with flags:

```
ParsedTask {
  index: number           // 0-based task index
  description: string     // Task title/description line
  isParallel: boolean     // Has [P] marker AND no override markers
  isVerify: boolean       // Has [VERIFY] marker
  isSequential: boolean   // Has [SEQUENTIAL] marker OR no [P] marker
}
```

### Marker Override Precedence

When multiple markers appear on the same task line, precedence determines execution behavior:

```
1. [VERIFY] always wins over [P]
2. [SEQUENTIAL] always wins over [P]
3. [P] only applies when no override markers present
```

**Override Check Order**:
Before setting isParallel=true, check for override markers:
1. If [VERIFY] present: isParallel = false (verification must be sequential)
2. If [SEQUENTIAL] present: isParallel = false (explicit override)
3. If neither override present and [P] present: isParallel = true

**Examples**:
- `- [ ] 1.5 [VERIFY] [P] Quality checkpoint` -> isParallel = false (VERIFY wins)
- `- [ ] 2.1 [SEQUENTIAL] [P] Critical update` -> isParallel = false (SEQUENTIAL wins)
- `- [ ] 3.1 [P] Independent task` -> isParallel = true (no override)

### Parsing Logic

1. Read all task lines from tasks.md
2. For each line matching `- [ ]` or `- [x]`:
   - Extract task description (text after checkbox)
   - Check for [P] marker: `line.includes('[P]')`
   - Check for [VERIFY] marker: `line.includes('[VERIFY]')`
   - Check for [SEQUENTIAL] marker: `line.includes('[SEQUENTIAL]')`
   - **Apply override precedence**: isParallel = has [P] AND NOT has [VERIFY] AND NOT has [SEQUENTIAL]
   - Set isVerify = has [VERIFY]
   - Set isSequential = has [SEQUENTIAL] OR NOT isParallel
3. Store parsed tasks for group detection

## Parallel Group Detection

After parsing all tasks, detect parallel groups starting from the current taskIndex.

### parallelGroup Structure

```
ParallelGroup {
  startIndex: number       // First task in group (inclusive)
  endIndex: number         // Last task in group (inclusive)
  taskIndices: number[]    // All task indices in group
  isParallel: boolean      // True if group has 2+ tasks
}
```

### Detection Algorithm

Starting from current taskIndex, determine group boundaries:

1. **Initialize**: Start with task at taskIndex
2. **Check current task**:
   - If task is NOT parallel (no [P] marker, or has [VERIFY]/[SEQUENTIAL]):
     - Return single-task group: `{ startIndex: taskIndex, endIndex: taskIndex, taskIndices: [taskIndex], isParallel: false }`
3. **Expand group** (current task has [P]):
   - Set startIndex = taskIndex
   - Set taskIndices = [taskIndex]
   - Look at next task (taskIndex + 1)
   - While next task exists AND next task is parallel (has [P], no [VERIFY]/[SEQUENTIAL]):
     - Add next task index to taskIndices
     - Advance to following task
   - Set endIndex = last added index
4. **Return group**:
   - isParallel = true if taskIndices.length >= 2
   - If only 1 task in group, set isParallel = false

### Group Breaking Conditions

These conditions break a parallel group:
- Task without [P] marker
- Task with [VERIFY] marker (always sequential)
- Task with [SEQUENTIAL] marker (explicit override)
- End of task list

### Pseudocode

```
function detectParallelGroup(taskIndex, parsedTasks):
  current = parsedTasks[taskIndex]

  // Non-parallel task = single-task group
  if not current.isParallel:
    return {
      startIndex: taskIndex,
      endIndex: taskIndex,
      taskIndices: [taskIndex],
      isParallel: false
    }

  // Start building parallel group
  indices = [taskIndex]
  nextIdx = taskIndex + 1

  // Expand while consecutive [P] tasks
  while nextIdx < parsedTasks.length:
    nextTask = parsedTasks[nextIdx]
    if not nextTask.isParallel:
      break
    indices.push(nextIdx)
    nextIdx++

  return {
    startIndex: taskIndex,
    endIndex: indices[indices.length - 1],
    taskIndices: indices,
    isParallel: indices.length >= 2
  }
```

### Write parallelGroup to State

Before spawning executors, write detected parallelGroup to `.ralph-state.json`:

```json
{
  "phase": "execution",
  "taskIndex": 5,
  "parallelGroup": {
    "startIndex": 5,
    "endIndex": 7,
    "taskIndices": [5, 6, 7],
    "isParallel": true
  },
  ...
}
```

This enables stop-handler and future iterations to understand the current batch context.

## Parallel Executor Spawning

When a parallel group is detected with 2+ tasks, spawn multiple spec-executors simultaneously.

<mandatory>
**All Task tool calls MUST be in a single message for true parallelism.**

If Task tool calls are spread across multiple messages, they execute sequentially, defeating parallelism.
</mandatory>

### Spawning Process

1. **Detect parallel group** using algorithm from previous section
2. **Check group size**:
   - If `parallelGroup.isParallel == false` (single task): use normal sequential execution
   - If `parallelGroup.isParallel == true` (2+ tasks): proceed with parallel spawning
3. **Write state before spawning**:
   - Update `.ralph-state.json` with parallelGroup before any Task tool calls
   - This ensures state reflects intended batch even if spawning partially fails
4. **Generate progress file paths**:
   - Each executor gets isolated progress file: `.progress-task-{taskIndex}.md`
   - Example: Tasks 5, 6, 7 get `.progress-task-5.md`, `.progress-task-6.md`, `.progress-task-7.md`
5. **Spawn all executors in ONE message**:
   - Make N Task tool calls in the same response
   - Each call invokes spec-executor with unique taskIndex and progressFile

### Progress File Path Generation

For each task in `parallelGroup.taskIndices`, generate:

```
progressFile = `./specs/$spec/.progress-task-${taskIndex}.md`
```

These temp files:
- Isolate writes during parallel execution (no race conditions)
- Are merged into main `.progress.md` after batch completes
- Are deleted after successful merge

### Executor Invocation Structure

For each task in the parallel group, invoke spec-executor with:

```
Task tool invocation for task $taskIndex:

You are executing task for spec: $spec
Spec path: ./specs/$spec/
Task index: $taskIndex (0-based)
Progress file: ./specs/$spec/.progress-task-$taskIndex.md

Context from .progress.md:
[include main progress file content - read-only reference]

Current task from tasks.md:
[include the specific task block for this taskIndex]

IMPORTANT: Write your learnings and completion status to the progress file path above.
Do NOT write to the main .progress.md file. The coordinator will merge your progress file after all parallel tasks complete.

Your task:
1. Read the task's Do section and execute exactly
2. Only modify files listed in Files section
3. Verify completion with the Verify command
4. Commit with the task's Commit message
5. Write to ./specs/$spec/.progress-task-$taskIndex.md:
   - Add task to Completed Tasks with commit hash
   - Add any learnings discovered
6. Mark task as [x] in tasks.md

After successful completion, output exactly:
TASK_COMPLETE
```

### Multi-Task Invocation Pattern

When spawning parallel group [5, 6, 7], make 3 Task tool calls in ONE message:

```
<Task tool call 1>
  subagent_type: spec-executor
  prompt: [invocation for task 5 with progressFile: .progress-task-5.md]
</Task tool call 1>

<Task tool call 2>
  subagent_type: spec-executor
  prompt: [invocation for task 6 with progressFile: .progress-task-6.md]
</Task tool call 2>

<Task tool call 3>
  subagent_type: spec-executor
  prompt: [invocation for task 7 with progressFile: .progress-task-7.md]
</Task tool call 3>
```

All three calls appear in the same response, enabling parallel execution.

### State Before Spawning

Update `.ralph-state.json` BEFORE making Task tool calls:

```json
{
  "phase": "execution",
  "taskIndex": 5,
  "parallelGroup": {
    "startIndex": 5,
    "endIndex": 7,
    "taskIndices": [5, 6, 7],
    "isParallel": true
  },
  "taskResults": {
    "5": { "status": "pending" },
    "6": { "status": "pending" },
    "7": { "status": "pending" }
  },
  ...
}
```

This state update ensures:
- Stop-handler knows a parallel batch is in progress
- Recovery can identify which tasks were attempted
- Progress tracking survives partial failures

### Sequential Fallback

If `parallelGroup.isParallel == false`:
- Skip parallel spawning logic
- Use normal single Task tool invocation
- Write directly to `.progress.md` (no temp file)
- Follow existing "Execute Current Task" flow below

### Single [P] Task Optimization

When a parallel group contains only 1 task (group size == 1), treat as sequential to avoid overhead:

**Check Group Size**:
```
if parallelGroup.taskIndices.length == 1:
  parallelGroup.isParallel = false
```

**Optimization Benefits**:
- No temp progress file creation (.progress-task-N.md)
- No merge step after execution
- Direct write to main .progress.md
- No BATCH_COMPLETE signal (just TASK_COMPLETE)
- Identical behavior to non-[P] sequential tasks

**When This Occurs**:
- Single [P] task followed by [VERIFY] or [SEQUENTIAL] task
- Single [P] task at end of task list
- [P] task surrounded by non-[P] tasks

**Implementation**:
```
function handleTaskGroup(parallelGroup, specPath):
  // Single task groups skip parallel overhead
  if parallelGroup.taskIndices.length == 1:
    // Force sequential execution
    parallelGroup.isParallel = false
    // Use standard sequential task invocation
    // No temp file, no merge, no BATCH_COMPLETE
    return executeSequentialTask(parallelGroup.taskIndices[0])

  // Multi-task parallel group
  return executeParallelBatch(parallelGroup)
```

This ensures [P] markers on isolated tasks do not incur unnecessary file I/O or merge operations.

## Progress File Merger

After all parallel executors complete, merge their isolated progress files into the main `.progress.md`.

### Idempotent Merge Guarantee

The merge operation is **idempotent**: running it multiple times with the same inputs produces the same result.

**Idempotency mechanisms**:
- Temp files are deleted after successful merge (no re-processing)
- If merge runs again with no temp files, nothing changes
- Duplicate learnings/tasks are not prevented (temp files exist only once per batch)
- State reset (parallelGroup = null) prevents re-merge attempts

**Recovery safety**: If coordinator crashes mid-merge:
- Temp files may still exist (partial cleanup)
- Re-running merge collects remaining files
- Already-merged content may duplicate (acceptable, manually dedupe if needed)

### Merge Process Overview

1. **Collect temp files**: Gather all `.progress-task-{N}.md` files for the completed batch
2. **Validate files**: Check each file exists and is non-empty (skip invalid with warning)
3. **Sort by task index**: Process files in ascending task index order
4. **Extract sections**: Pull Learnings and Completed Tasks from each temp file
5. **Skip missing sections**: If Learnings section not found, skip extraction (no crash)
6. **Append to main**: Add extracted content to corresponding sections in `.progress.md`
7. **Cleanup**: Delete temp files after successful merge

### Temp File Paths

For a parallel group with taskIndices [5, 6, 7], temp files are:
```
./specs/$spec/.progress-task-5.md
./specs/$spec/.progress-task-6.md
./specs/$spec/.progress-task-7.md
```

### Extraction Logic

For each temp file in task index order:

1. **Read file content**
2. **Extract Learnings section**:
   - Find lines between `## Learnings` and next `##` header (or EOF)
   - Capture bullet points (lines starting with `-`)
   - Skip empty lines and section header itself
3. **Extract Completed Tasks section**:
   - Find lines between `## Completed Tasks` and next `##` header (or EOF)
   - Capture task entries (lines matching `- [x]`)

### Merge Strategy Pseudocode

```
function mergeProgressFiles(parallelGroup, specPath):
  mainProgress = read(specPath + "/.progress.md")
  allLearnings = []
  allCompletedTasks = []

  // Process in task index order
  for taskIndex in sorted(parallelGroup.taskIndices):
    tempFile = specPath + "/.progress-task-" + taskIndex + ".md"

    // ROBUSTNESS: Skip missing temp files with warning
    if not exists(tempFile):
      log("Warning: temp file missing for task " + taskIndex + ", skipping")
      continue

    content = read(tempFile)

    // ROBUSTNESS: Skip empty temp files with warning
    if content.trim() == "":
      log("Warning: temp file empty for task " + taskIndex + ", skipping")
      continue

    // ROBUSTNESS: Check for Learnings section before extraction
    if not content.contains("## Learnings"):
      log("Warning: no Learnings section in temp file for task " + taskIndex + ", skipping learnings")
    else:
      // Extract Learnings
      learnings = extractSection(content, "## Learnings")
      for line in learnings:
        if line.startsWith("-"):
          allLearnings.push(line)

    // ROBUSTNESS: Check for Completed Tasks section before extraction
    if not content.contains("## Completed Tasks"):
      log("Warning: no Completed Tasks section in temp file for task " + taskIndex + ", skipping completed tasks")
    else:
      // Extract Completed Tasks
      completed = extractSection(content, "## Completed Tasks")
      for line in completed:
        if line.matches(/- \[x\]/):
          allCompletedTasks.push(line)

  // Append to main progress file (skip if nothing to add - idempotent)
  if allLearnings.length > 0:
    mainProgress = appendToSection(mainProgress, "## Learnings", allLearnings)
  if allCompletedTasks.length > 0:
    mainProgress = appendToSection(mainProgress, "## Completed Tasks", allCompletedTasks)

  write(specPath + "/.progress.md", mainProgress)

  // Cleanup temp files (ensures idempotency)
  for taskIndex in parallelGroup.taskIndices:
    tempFile = specPath + "/.progress-task-" + taskIndex + ".md"
    if exists(tempFile):
      delete(tempFile)
```

### Section Extraction Helper

```
function extractSection(content, sectionHeader):
  lines = content.split("\n")
  inSection = false
  result = []

  for line in lines:
    if line.startsWith(sectionHeader):
      inSection = true
      continue
    if inSection and line.startsWith("## "):
      break  // Next section reached
    if inSection:
      result.push(line)

  return result
```

### Append to Section Helper

```
function appendToSection(content, sectionHeader, newLines):
  if newLines.length == 0:
    return content

  lines = content.split("\n")
  result = []
  sectionFound = false
  insertIndex = -1

  for (i, line) in enumerate(lines):
    result.push(line)
    if line.startsWith(sectionHeader):
      sectionFound = true
    // Find end of section (next ## or EOF)
    if sectionFound and (line.startsWith("## ") and not line.startsWith(sectionHeader)):
      insertIndex = result.length - 1
      sectionFound = false

  // If section header found but no next section, append at end
  if insertIndex == -1 and sectionFound:
    insertIndex = result.length

  // Insert new lines
  result.splice(insertIndex, 0, ...newLines)

  return result.join("\n")
```

### Error Handling in Merge

- **Missing temp file**: Log warning "temp file missing for task N, skipping", continue with available files
- **Empty temp file**: Log warning "temp file empty for task N, skipping", continue with available files
- **No Learnings section**: Log warning "no Learnings section in temp file for task N", skip learnings extraction only (continue with Completed Tasks)
- **No Completed Tasks section**: Log warning "no Completed Tasks section in temp file for task N", skip completed tasks extraction only (continue with Learnings)
- **Empty section content**: Skip, do not add blank lines to main progress file
- **Malformed temp file**: Log warning, skip extraction for that file entirely
- **Write failure**: Retry once, then fail batch with error message
- **Nothing to merge**: If all temp files invalid/empty, main progress unchanged (idempotent no-op)

### Cleanup After Merge

After successful merge, delete all temp files:

```bash
rm -f ./specs/$spec/.progress-task-*.md
```

This ensures:
- No leftover files from previous batches
- Clean state for next parallel group
- No accumulation of temp files over time

## Batch Completion

After all parallel executors complete and progress files are merged, signal batch completion.

### Completion Sequence

1. **Update taskIndex**: Set taskIndex = parallelGroup.endIndex + 1
2. **Serialize git commits**: Ensure all executor commits are finalized (no pending commits)
3. **Output dual signals**: Output both TASK_COMPLETE and BATCH_COMPLETE for compatibility

### TaskIndex Advancement

After successful parallel batch:

```
newTaskIndex = parallelGroup.endIndex + 1
```

Update `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <endIndex + 1>,
  "parallelGroup": null,
  "taskResults": {},
  ...
}
```

Clear parallelGroup and taskResults after completion to prepare for next batch or sequential task.

### Dual Signal Output

Output both signals for stop-handler compatibility:

```
Parallel batch complete (tasks X-Y).

TASK_COMPLETE
BATCH_COMPLETE
```

Where:
- X = parallelGroup.startIndex (first task in batch)
- Y = parallelGroup.endIndex (last task in batch)
- TASK_COMPLETE satisfies stop-handler regex for advancement
- BATCH_COMPLETE indicates parallel batch completion (vs single task)

### Stop-Handler Behavior

The stop-handler:
1. Sees TASK_COMPLETE and considers the cycle complete
2. Reads updated taskIndex from state (already advanced past batch)
3. Proceeds to next task normally

BATCH_COMPLETE is informational. It enables future enhancements but is not required by stop-handler.

### Completion Output Pattern

For a parallel batch of tasks [5, 6, 7]:

```
Executed parallel batch: tasks 5-7
- Task 5: PASSED (commit abc1234)
- Task 6: PASSED (commit def5678)
- Task 7: PASSED (commit ghi9012)

Progress merged from temp files.
TaskIndex advanced: 5 -> 8

TASK_COMPLETE
BATCH_COMPLETE
```

### Sequential Completion (Single Task)

For non-parallel groups or single-task groups, skip BATCH_COMPLETE:
- Use standard "TASK_COMPLETE" only
- Stop-handler handles advancement as usual
- No taskIndex manipulation needed (stop-handler increments by 1)

## Error Handling

Handle partial failures in parallel batches gracefully without corrupting progress.

### taskResults Tracking

Track each task's execution status in `.ralph-state.json`:

```typescript
taskResults?: {
  [taskIndex: number]: {
    status: "pending" | "success" | "failed";
    error?: string;
  };
}
```

### Initialize taskResults Before Spawning

Before spawning parallel executors, initialize all tasks as pending:

```json
{
  "taskResults": {
    "5": { "status": "pending" },
    "6": { "status": "pending" },
    "7": { "status": "pending" }
  }
}
```

### Update taskResults After Execution

After each executor returns:
1. **If TASK_COMPLETE in output**: Mark status = "success"
2. **If no TASK_COMPLETE or error**: Mark status = "failed", record error message

```
function updateTaskResult(taskIndex, output):
  if output.contains("TASK_COMPLETE"):
    taskResults[taskIndex] = { status: "success" }
  else:
    taskResults[taskIndex] = {
      status: "failed",
      error: extractErrorMessage(output) or "No TASK_COMPLETE signal"
    }
```

### Partial Failure Handling

On batch completion with mixed results:

1. **Identify successful tasks**: Filter taskResults where status == "success"
2. **Identify failed tasks**: Filter taskResults where status == "failed"
3. **Merge only successful progress files**:
   - Only include .progress-task-N.md files for successful tasks
   - Skip temp files for failed tasks
4. **Update tasks.md selectively**:
   - Successful tasks should already be marked [x] by their executor
   - Failed tasks remain unchecked [ ] for retry
5. **Advance taskIndex past successful tasks only**:
   - If all tasks succeeded: taskIndex = endIndex + 1
   - If partial failure: taskIndex = first failed task index

### Partial Failure Merge Logic

```
function mergePartialResults(parallelGroup, taskResults, specPath):
  successfulIndices = []
  failedIndices = []

  for taskIndex in parallelGroup.taskIndices:
    if taskResults[taskIndex].status == "success":
      successfulIndices.push(taskIndex)
    else:
      failedIndices.push(taskIndex)

  // Only merge progress from successful tasks
  for taskIndex in sorted(successfulIndices):
    tempFile = specPath + "/.progress-task-" + taskIndex + ".md"
    if exists(tempFile):
      mergeIntoMainProgress(tempFile)
      delete(tempFile)

  // Clean up failed task temp files (no merge)
  for taskIndex in failedIndices:
    tempFile = specPath + "/.progress-task-" + taskIndex + ".md"
    if exists(tempFile):
      delete(tempFile)

  // Report results
  return {
    successCount: successfulIndices.length,
    failedCount: failedIndices.length,
    failedTasks: failedIndices
  }
```

### Failed Task Retry

Failed tasks remain unchecked in tasks.md and will be retried:
- taskIndex set to first failed task
- Next iteration picks up where failure occurred
- Stop-handler retry logic applies normally

### Batch Failure Scenarios

| Scenario | Behavior |
|----------|----------|
| All succeed | Merge all, advance past batch, output BATCH_COMPLETE |
| All fail | No merge, taskIndex stays at startIndex, retry all |
| Partial (some succeed) | Merge successful only, taskIndex = first failed, retry failed |

### Clear taskResults After Batch

After batch processing (success or partial), clear taskResults:

```json
{
  "taskResults": {}
}
```

This ensures clean state for next batch or sequential task.

## Read Context

Before executing:

1. Read `./specs/$spec/.progress.md` for:
   - Original goal
   - Completed tasks
   - Learnings
   - Blockers

2. Read `./specs/$spec/tasks.md` for current task

## Execute Current Task

<mandatory>
**DELEGATE TO SUBAGENT - DO NOT IMPLEMENT YOURSELF**

Use the Task tool with `subagent_type: spec-executor` to execute the current task.
Execute tasks autonomously with NO human interaction.

You MUST NOT:
- Read task steps and execute them yourself
- Make code changes directly
- Run the verification command yourself
- Commit changes yourself

You MUST:
- Pass ALL context to spec-executor via Task tool
- Let spec-executor handle the ENTIRE task lifecycle
</mandatory>

Find current task (by taskIndex) and invoke spec-executor with:

```
You are executing task for spec: $spec
Spec path: ./specs/$spec/
Task index: $taskIndex (0-based)

Context from .progress.md:
[include progress file content]

Current task from tasks.md:
[include the specific task block]

Your task:
1. Read the task's Do section and execute exactly
2. Only modify files listed in Files section
3. Verify completion with the Verify command
4. Commit with the task's Commit message
5. Update .progress.md:
   - Add task to Completed Tasks with commit hash
   - Add any learnings discovered
   - Update Current Task to next task
6. Mark task as [x] in tasks.md

After successful completion, output exactly:
TASK_COMPLETE

If verification fails, describe the issue and retry.
If task requires manual action, describe what's needed and DO NOT output TASK_COMPLETE.
```

## Task Completion Verification

**TASK_COMPLETE** - The ONLY valid completion signal
- Use when: Task steps executed, verification passed, changes committed
- Stop hook verifies: checkmarks updated, spec files committed, no contradictions

**NEVER use TASK_COMPLETE if:**
- Task requires manual action (block and describe what user needs to do)
- Verification failed
- Implementation is partial
- Changes not committed

## Stop Hook Verification Layers

The stop hook enforces completion integrity with 4 verification layers:

1. **Contradiction Detection**: Rejects TASK_COMPLETE if output contains phrases like "requires manual", "cannot be automated", "could not complete", etc. Agent cannot claim completion while admitting it didn't complete.
2. **Uncommitted Files Check**: Rejects completion if tasks.md or .progress.md have uncommitted changes. All spec files must be committed.
3. **Checkmark Verification**: Validates that task was marked [x] in tasks.md. Counts completed checkmarks and verifies against task index.
4. **Signal Verification**: Requires TASK_COMPLETE to advance to next task.

If any verification fails, the task retries with a specific error message explaining the violation.

## After Task Completes

The spec-executor will:
1. Execute the task
2. Run verification
3. Commit changes (including spec files)
4. Update progress
5. Output "TASK_COMPLETE"

The stop hook will then:
1. Run verification layers (see above)
2. If all pass: Increment taskIndex, reset taskIteration
3. Return block with continue prompt (fresh context)
4. OR allow stop if all tasks done

If task seems to require manual action:
1. NEVER mark complete, lie, or expect user input
2. Use available tools: Bash, WebFetch, MCP browser tools, CLI commands, Task subagents
3. Exhaust ALL automated options before concluding impossible
4. Document each tool attempted and why it didn't work
5. Only if truly impossible after trying all tools: do NOT output TASK_COMPLETE, let retry loop exhaust

## Completion

When all tasks are done:
1. Stop hook deletes `.ralph-state.json`
2. `.progress.md` remains as record
3. Session ends normally

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Stop after each task for fresh context
- Continue until all tasks complete or max iterations reached

Beginning task $taskIndex...
```

