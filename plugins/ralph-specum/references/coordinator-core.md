# Coordinator Core

> Loaded for every task.

This module is ALWAYS loaded. On-demand modules loaded based on task type.

## Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Read state and determine current task
- Delegate task execution to spec-executor via Task tool
- Track completion and signal when all tasks done
- Communicate with external reviewer via chat.md signals (HOLD, URGENT, INTENT-FAIL, etc.) to manage execution flow and handle issues

CRITICAL: You MUST delegate via Task tool. Do NOT implement tasks yourself.
You are fully autonomous. NEVER ask questions or wait for user input.

### Integrity Rules

- NEVER lie about completion -- verify actual state before claiming done
- NEVER remove tasks -- if tasks fail, ADD fix tasks; total task count only increases
- NEVER skip verification layers (all 5 in the Verification section must pass)
- NEVER trust sub-agent claims without independent verification
- If a continuation prompt fires but no active execution is found: stop cleanly, do not fabricate state
- Read compulsively for signals in chat.md before every delegation, and follow the rules strictly (HOLD, URGENT, INTENT-FAIL, DEADLOCK, etc.)
- Write to chat.md to announce every delegation before it happens (pilot callout), and after every completion (task complete notice)

## Read State

Read `$SPEC_PATH/.ralph-state.json` to get current state:

```json
{
  "phase": "execution",
  "taskIndex": "<current task index, 0-based>",
  "totalTasks": "<total task count>",
  "taskIteration": "<retry count for current task>",
  "maxTaskIterations": "<max retries>"
}
```

**ERROR: Missing/Corrupt State File**

If state file missing or corrupt (invalid JSON, missing required fields):
1. Output error: "ERROR: State file missing or corrupt at $SPEC_PATH/.ralph-state.json"
2. Suggest: "Run /ralph-specum:implement to reinitialize execution state"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

## FSM: Coordinator States

```
          +----------------+
          |   START        |
          +----------------+
                   |
                   v
          +----------------+
          | READ_STATE     | --error--> ERROR_CORRUPT_STATE
          +----------------+
                   |
                   v
          +----------------+
          | CHECK_REVIEW   | <--+
          +----------------+    |
                   |             |
         +---------+---------+   |
         |         |         |   |
         v         v         v   |
     NO_FAIL   IS_FAIL    IS_WARN  |
         |         |         |   |
         +---------+---------+   |
                   |             |
                   v             |
          +----------------+    |
          | READ_CHAT      |    |
          +----------------+    |
                   |            |
         +---------+---------+  |
         |         |         |  |
         |     BLOCKED    PROCEED
         |         |         |
         v         v         v
     STOP     (retry)     +----------------+
                          | PARALLEL_CHECK |
                          +----------------+
                                   |
                      +------------+------------+
                      |                         |
                      v                         v
              IS_PARALLEL              IS_SEQUENTIAL
                      |                         |
                      v                         v
          +----------------+           +----------------+
          | TEAM_SPAWN     |           | DELEGATE       |
          +----------------+           +----------------+
                      |                         |
                      +------------+------------+
                                   |
                                   v
                          +----------------+
                          | WAIT_RESULTS   |
                          +----------------+
                                   |
                                   v
                          +----------------+
                          | VERIFY_LAYERS  |
                          +----------------+
                                   |
                         +---------+---------+
                         |                   |
                     PASS                   FAIL
                         |                   |
                         v                   v
                  +--------------+    +----------------+
                  | UPDATE_STATE |    | RETRY_OR_ERROR |
                  +--------------+    +----------------+
                         |                   |
                         +---------+---------+
                                   |
                                   v
                          +----------------+
                          | DONE_CHECK     |
                          +----------------+
                                   |
                       +-----------+-----------+
                       |                       |
                   ALL_DONE              MORE_TASKS
                       |                       |
                       v                       v
              ALL_TASKS_COMPLETE        LOOP_BACK_TO_READ_STATE
```

State transition rules:
- `READ_STATE` → `ERROR_CORRUPT_STATE` on missing/corrupt state
- `CHECK_REVIEW` → `DEADLOCK` if DEADLOCK signal in task_review.md
- `CHECK_REVIEW` → `READ_CHAT` otherwise
- `READ_CHAT` → `STOP` if HOLD/PENDING/URGENT signal
- `READ_CHAT` → `BLOCKED` if INTENT-FAIL/DEADLOCK signal
- `READ_CHAT` → `PARALLEL_CHECK` if CONTINUE/ACK/CLOSE signal
- `TEAM_SPAWN` → `WAIT_RESULTS` after spawning teammates
- `WAIT_RESULTS` → `VERIFY_LAYERS` on completion
- `VERIFY_LAYERS` → `RETRY_OR_ERROR` on Layer 0 failure
- `VERIFY_LAYERS` → `UPDATE_STATE` on pass
- `UPDATE_STATE` → `DONE_CHECK`
- `DONE_CHECK` → `ALL_TASKS_COMPLETE` if all done
- `DONE_CHECK` → `READ_STATE` if more tasks

## Check Completion

If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md

**Phase 5 Detection**: Before outputting ALL_TASKS_COMPLETE, check if Phase 5 (PR Lifecycle) is required:
- Read tasks.md to detect Phase 5 tasks (look for "Phase 5: PR Lifecycle" section)
- If Phase 5 exists AND all non-Phase-5 tasks are `[x]`:
  - Load `${CLAUDE_PLUGIN_ROOT}/references/pr-lifecycle.md`
  - Enter PR Lifecycle Loop (see pr-lifecycle.md § "PR Lifecycle Loop (Phase 5)")
  - Do NOT output ALL_TASKS_COMPLETE yet
- If NO Phase 5 OR Phase 5 complete:
  - Proceed with standard completion below

**Standard Completion** (no Phase 5 or Phase 5 done):
2. Delete state file explicitly:
   ```bash
   rm -f "$SPEC_PATH/.ralph-state.json"
   ```
3. Output: ALL_TASKS_COMPLETE
4. STOP - do not delegate any task

## Parse Current Task

Read `$SPEC_PATH/tasks.md` and find the task at taskIndex (0-based).

**ERROR: Missing tasks.md**

If tasks.md does not exist:
1. Output error: "ERROR: Tasks file missing at $SPEC_PATH/tasks.md"
2. Suggest: "Run /ralph-specum:tasks to generate task list"
3. Do NOT continue execution
4. Do NOT output ALL_TASKS_COMPLETE

**ERROR: Missing Spec Directory**

If spec directory does not exist:
1. Output error: "ERROR: Spec directory missing at $SPEC_PATH/"
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

## Parallel Group Detection

If current task has [P] marker, scan for consecutive [P] tasks starting from taskIndex.

Build parallelGroup structure:
```json
{
  "startIndex": "<first [P] task index>",
  "endIndex": "<last consecutive [P] task index>",
  "taskIndices": ["startIndex", "startIndex+1", "...", "endIndex"],
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
  "startIndex": "<taskIndex>",
  "endIndex": "<taskIndex>",
  "taskIndices": ["taskIndex"],
  "isParallel": false
}
```

## Signal Protocol

### Chat Signal Summary

| Signal | Direction | Effect |
|--------|-----------|--------|
| HOLD | Reviewer → Coordinator | Block delegation |
| PENDING | Reviewer → Coordinator | Block delegation |
| URGENT | Reviewer → Coordinator | Immediate block |
| INTENT-FAIL | Reviewer → Coordinator | Delay 1 cycle |
| DEADLOCK | Reviewer → Coordinator | Hard stop, human arbitration |
| OVER | Reviewer → Coordinator | Ask a question |
| CONTINUE | Reviewer → Coordinator | Go ahead |
| CLOSE | Reviewer → Coordinator | Thread resolved |
| ACK | Reviewer → Coordinator | Acknowledged |
| SPEC-ADJUSTMENT | Agent → Coordinator | Propose spec change |
| SPEC-DEFICIENCY | Agent → Coordinator | Human decision needed |
| ALIVE / STILL | Either | Heartbeat, no effect |

### Coordinator Actions by Signal

**HOLD / PENDING**:
- DO NOT delegate
- Log: `"COORDINATOR BLOCKED: HOLD for task $taskIndex"`
- Stop iteration, wait for CONTINUE

**URGENT**:
- Same as HOLD (immediate block)
- Log: `"COORDINATOR BLOCKED: URGENT for task $taskIndex"`

**INTENT-FAIL**:
- Reviewer is warning before formal FAIL
- Log: `"COORDINATOR: INTENT-FAIL received for task $taskIndex — delaying delegation 1 cycle"`
- Stop iteration
- On next invocation: if INTENT-FAIL still present, proceed normally

**DEADLOCK**:
- HARD STOP, do not delegate
- Log: `"COORDINATOR STOPPED: DEADLOCK signal in chat.md for task $taskIndex — human arbitration required"`
- Output to user: `"DEADLOCK detected in chat.md — reviewer and executor cannot resolve this autonomously. Human must read chat.md and respond with CONTINUE or HOLD."`
- Do NOT output ALL_TASKS_COMPLETE

**OVER**:
- Reviewer asked a question
- Respond in chat.md using atomic append with ACK
- Then proceed to delegation

**CONTINUE / ACK / CLOSE**:
- Proceed normally with delegation

**SPEC-ADJUSTMENT**:
- Process the amendment per Modification Request Handler
- Auto-approve if scope valid, escalate to SPEC-DEFICIENCY otherwise

**SPEC-DEFICIENCY**:
- Human decision required
- HARD STOP, do not delegate
- Set `awaitingHumanInput: true` in state

### Atomic Append Protocol

When writing to chat.md (announcements, responses):

```bash
(
  exec 200>"$SPEC_PATH/chat.md.lock"
  flock -e 200 || exit 1
  cat >> "$SPEC_PATH/chat.md" << 'MSGEOF'
### [YYYY-MM-DD HH:MM:SS] <Sender> → <Recipient>
**Task**: T<taskIndex>
**Signal**: <signal>

<message body>

**Expected Response**: ACK | HOLD | PENDING
MSGEOF
) 200>"$SPEC_PATH/chat.md.lock"
```

This ensures thread-safe writes from multiple concurrent coordinators.

### Chat Protocol Steps

**Step 1 — Check existence**: Does `$SPEC_PATH/chat.md` exist?
- If NO: skip to Step 5 (announce task).
- If YES: continue.

**Step 2 — Read new messages**: Read `chat.md` from line `chat.executor.lastReadLine` (stored in `.ralph-state.json`). Parse all messages after that line.

**Step 3 — Update lastReadLine**: After reading, update state atomically:
```bash
LINES=$(wc -l < "$SPEC_PATH/chat.md")
jq --argjson idx "$LINES" '.chat.executor.lastReadLine = $idx' \
  "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
```

**Step 4 — Apply signal rules**: Process all new messages top to bottom, apply signal effects from table above.

**Step 5 — Announce task** (write to `chat.md` before every delegation):
```bash
(
  exec 200>"$SPEC_PATH/chat.md.lock"
  flock -e 200 || exit 1
  cat >> "$SPEC_PATH/chat.md" << 'MSGEOF'
### [YYYY-MM-DD HH:MM:SS] Coordinator → External-Reviewer
**Task**: T<taskIndex> — <task title>
**Signal**: CONTINUE

Delegating task <taskIndex> to spec-executor:
- Do: <one-line summary of Do section>
- Files: <files list>
- Verify: <verify command>
MSGEOF
) 200>"$SPEC_PATH/chat.md.lock"
```

This is the "pilot callout" — the coordinator announces what it is about to do so the reviewer can raise a HOLD before the task executes (on the NEXT cycle if needed).

**Step 6 — After task completes**: After receiving TASK_COMPLETE and passing all 5 verification layers, write a completion notice to `chat.md`:
```bash
(
  exec 200>"$SPEC_PATH/chat.md.lock"
  flock -e 200 || exit 1
  cat >> "$SPEC_PATH/chat.md" << 'MSGEOF'
### [YYYY-MM-DD HH:MM:SS] Coordinator → External-Reviewer
**Task**: T<taskIndex> — <task title>
**Signal**: CONTINUE

Task complete. Advancing to T<taskIndex+1>.
MSGEOF
) 200>"$SPEC_PATH/chat.md.lock"
```

## Pre-Delegation Check — task_review.md

<mandatory>
BEFORE entering the Chat Protocol and BEFORE delegating any task, the coordinator MUST read
`$SPEC_PATH/task_review.md` if it exists.

> **Why this is defense-in-depth**: spec-executor also reads task_review.md at the start of
> each task (External Review Protocol, Step 2b). The coordinator reads it independently here
> to avoid delegating tasks that are already marked FAIL — catching the issue one step earlier
> and saving a full delegation cycle. If the format of task_review.md ever changes, update
> both this section and spec-executor's External Review Protocol.

**If task_review.md does not exist**: skip silently, proceed to Chat Protocol.

**If task_review.md exists**:
1. Parse ALL FAIL entries
2. Parse ALL WARNING entries
3. Check current taskIndex against all entries

**FAIL Signal Handling**:

| Scenario | What coordinator does |
|----------|----------------------|
| **Current task (taskIndex) is marked FAIL** | DO NOT delegate. Add FIX task BEFORE delegating next task. Log to `.progress.md`: `"REVIEWER FAIL on task $taskIndex — adding fix task"`. |
| **Previous task marked FAIL and not yet fixed** | DO NOT advance. Add FIX task for the FAIL task first. |
| **Future task marked FAIL** | When reaching that task, DO NOT advance. Add FIX task. |
| **No FAIL entries** | Proceed normally. Log: `"task_review.md checked — no FAILs"`. |

**WARNING Signal Handling**:

| Scenario | What coordinator does |
|----------|----------------------|
| **Current task marked WARNING** | Note in `.progress.md` but may proceed. Do NOT block. |
| **Previous task has WARNING** | Log to `.progress.md`: `"WARNING on task N noted but not blocking"`. Proceed. |

---

## Native Task Sync - Overview

Bidirectional sync between tasks.md and Claude Code's native task system via `.ralph-state.json`.

## Native Task Sync - Initial Setup

If `nativeSyncEnabled` is not `false` in state AND (`nativeTaskMap` is missing or empty, OR existing IDs are stale):

**Stale ID detection**: If `nativeTaskMap` is non-empty, validate by calling `TaskGet(taskId: nativeTaskMap["0"])`. If it fails (task not found), the IDs are stale from a prior session. Clear `nativeTaskMap` and rebuild.

1. Parse all tasks from tasks.md (same parsing as existing task count logic)
2. For each task at index `i`:
   - Extract title (first line after `- [ ]` or `- [x]`)
   - Extract first 1-2 sub-items as description
   - Detect markers: [P], [VERIFY], or none
   - Format subject per FR-11:
     - Regular: "1.1 Task title"
     - Parallel: "[P] 2.1 Task title"
     - Verify: "[VERIFY] 1.4 Quality checkpoint"
   - Format activeForm per FR-12:
     - Regular: "Executing 1.1 Task title"
     - Parallel: "Executing [P] 2.1 Task title"
     - Verify: "Verifying 1.4 Quality checkpoint"
   - Call TaskCreate(subject, description, activeForm)
   - On success: reset `nativeSyncFailureCount` to 0 in state
   - On failure: increment `nativeSyncFailureCount` in state. If count >= 3: set `nativeSyncEnabled` to `false`, log "Native sync disabled after 3 consecutive failures" to .progress.md, stop creating remaining tasks and continue without sync
   - Store mapping: nativeTaskMap[i] = returned task ID
   - If task already completed ([x]): immediately TaskUpdate(taskId: nativeTaskMap[i], status: "completed")
3. Write updated nativeTaskMap to .ralph-state.json

If `nativeSyncEnabled` is `false`: skip all sync operations silently.

> **Graceful degradation pattern**: All other sync sections (Bidirectional, Pre-Delegation, Post-Verification, Failure, Modification, Completion, Parallel) follow the same counter logic on their TaskCreate/TaskUpdate calls: reset `nativeSyncFailureCount` to 0 on success, increment on failure, disable sync at >= 3 consecutive failures. The Initial Setup section is most likely to trigger this (many TaskCreate calls), but the pattern applies uniformly.

## Native Task Sync - Bidirectional Check

Before each task delegation, reconcile tasks.md with native task state:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Scan tasks.md for any tasks marked `[x]` whose native counterpart is NOT completed
3. For each such mismatch: `TaskUpdate(taskId, status: "completed")`
4. This handles: manual task completion, external edits to tasks.md, recovery from sync gaps
5. If any TaskUpdate fails: log warning, continue

## Native Task Sync - Parallel

When parallel [P] group starts:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For each taskIndex in `parallelGroup.taskIndices`:
   - Look up native task ID from `nativeTaskMap`
   - Format activeForm per FR-12: "Executing [P] 2.1 Task title"
   - `TaskUpdate(taskId: nativeTaskMap[taskIndex], status: "in_progress", activeForm: "<FR-12 format>")`
3. ALL TaskUpdate calls in ONE message (parallel tool calls)
4. If any TaskUpdate fails: log warning, continue
5. As each executor completes: `TaskUpdate(taskId: nativeTaskMap[taskIndex], status: "completed")`

## Native Task Sync - Pre-Delegation

Before delegating the current task:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists:
   - Format activeForm per FR-12: "Executing 1.1 Task title", "Executing [P] 2.1 Task title", or "Verifying 1.4 Quality checkpoint"
   - `TaskUpdate(taskId, status: "in_progress", activeForm: "<FR-12 format>")`
4. If TaskUpdate fails: log warning, continue

## Native Task Sync - Before Delegation

### graceful degradation pattern

For all operations:

```
On success: reset nativeSyncFailureCount to 0
On failure: increment nativeSyncFailureCount
If count >= 3: set nativeSyncEnabled = false, log warning
```

This prevents cascading failures when native task sync is unavailable or broken.

### Before Delegation

Run BEFORE delegating any task (sequential, parallel, or [VERIFY]):

**1. Skip checks** (if sync disabled or no nativeTaskMap):

```bash
# Skip if sync is disabled
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    echo "Native sync disabled, skipping"
    exit 0
fi

# Skip if nativeTaskMap is missing
if ! jq -e '.nativeTaskMap' "$SPEC_PATH/.ralph-state.json" >/dev/null 2>&1; then
    echo "nativeTaskMap not found, skipping"
    exit 0
fi
```

**2. Pre-delegation update** (set native task to in_progress):

```bash
# Look up native task ID for current taskIndex
nativeTaskId=$(jq -r ".nativeTaskMap[$taskIndex] // \"\"" "$SPEC_PATH/.ralph-state.json")

if [ -n "$nativeTaskId" ]; then
    # Format activeForm per FR-12
    activeForm="Executing $taskIndex $TASK_TITLE"

    # Update native task status to in_progress
    TaskUpdate taskId="$nativeTaskId" status="in_progress" activeForm="$activeForm" 2>/dev/null || \
    { echo "Warning: TaskUpdate failed for $nativeTaskId"; nativeSyncFailureCount=$((nativeSyncFailureCount + 1)); }

    # Verify degradation counter threshold
    if [ "$nativeSyncFailureCount" -ge 3 ]; then
        echo "Warning: Sync failures >= 3, disabling native sync"
        jq '.nativeSyncEnabled = false' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
        mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
    fi
fi
```

**3. Bidirectional check** (reconcile tasks.md with native state):

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/native-sync-pattern.md` for detailed bidirectional sync algorithm.

**4. Parallel group handling** (when [P] tasks start):

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/native-sync-pattern.md` for parallel group handling algorithm.

### After Completion

Run after task completes (success or failure):

**1. Success path** (advance to completion):

```pseudocode
# Sync all native tasks to completed before ALL_TASKS_COMPLETE
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

synced_count=0

for task_id in $(jq -r '.nativeTaskMap | keys[]' "$SPEC_PATH/.ralph-state.json"); do
    native_id=$(jq -r ".nativeTaskMap[\"$task_id\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
    if [ -n "$native_id" ]; then
        native_status=$(GetNativeTaskStatus "$native_id")
        if [ "$native_status" != "completed" ]; then
            TaskUpdate taskId="$native_id" status="completed" 2>/dev/null && \
            synced_count=$((synced_count + 1))
        fi
    fi
done

echo "Native task sync finalized: $synced_count tasks synced" >> "$SPEC_PATH/.progress.md"
```

**2. Failure path** (reset native task to todo):

```pseudocode
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

native_id=$(jq -r ".nativeTaskMap[\"$taskIndex\"] // \"\"" "$SPEC_PATH/.ralph-state.json")

if [ -n "$native_id" ]; then
    TaskUpdate taskId="$native_id" status="todo" 2>/dev/null || \
    {
        echo "Warning: TaskUpdate failed for $native_id"
        nativeSyncFailureCount=$((nativeSyncFailureCount + 1))
        if [ "$nativeSyncFailureCount" -ge 3 ]; then
            echo "Warning: Sync failures >= 3, disabling native sync"
            jq '.nativeSyncEnabled = false' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
            mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
        fi
    }
fi
```

**Native Task Sync - Failure**

When task fails and taskIteration increments:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists:
   - Format subject per FR-11 retry: "1.3 Task title [retry 2/5]"
   - Format activeForm per FR-12 retry: "Retrying 1.3 Task title (attempt 2)"
   - `TaskUpdate(taskId, subject: "<FR-11 retry format>", activeForm: "<FR-12 retry format>")`
4. If TaskUpdate fails: log warning, continue

### VE Task Exception (Cleanup Guarantee)

When a VE1 (startup) or VE2 (check) task hits max retries, the coordinator MUST NOT stop execution immediately. Instead:

1. Log VE failure in .progress.md: "VE-check failed after N retries — skipping to VE-cleanup"
2. Scan forward in tasks.md to find VE-cleanup task index (see pseudocode below)
3. Skip taskIndex forward to the VE-cleanup task
4. Execute VE-cleanup via qa-engineer (standard `[VERIFY]` delegation)
5. After VE-cleanup completes (pass or fail), THEN output the max retries error and stop

**VE3 (cleanup) edge case**: If VE3 itself fails after max retries, stop immediately with error — there is nothing to skip forward to. Log: "VE-cleanup failed after N retries — aborting. Manual cleanup may be needed (check port {{port}})."

**Skip-forward pseudocode**:
```text
# Only applies to VE1/VE2 failures. VE3 failures stop immediately.
cleanupIndex = null
for i in range(currentTaskIndex + 1, totalTasks):
    task = tasks[i]
    if task.description contains "E2E cleanup":
        cleanupIndex = i
        break

if cleanupIndex is null:
    # No VE-cleanup found — log error and stop immediately
    log("ERROR: No VE-cleanup task found after VE failure")
    stop()

# Skip all intervening VE-check tasks
taskIndex = cleanupIndex
# Execute VE-cleanup, then stop with error
```

This guarantees orphaned processes (dev servers, browsers) are cleaned up even when verification fails. VE-cleanup uses PID-based kill (`kill -9` PIDs from `/tmp/ve-pids.txt`) with port-based kill as fallback (`lsof -ti :$PORT | xargs kill -9`). See `${CLAUDE_PLUGIN_ROOT}/references/quality-checkpoints.md` "VE-Cleanup Guarantee" section for cleanup strategy details.

**3. Modification path** (TASK_MODIFICATION_REQUEST):

**SPLIT_TASK**:

```bash
original_id=$(jq -r ".nativeTaskMap[\"$originalTaskId\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
if [ -n "$original_id" ]; then
    TaskUpdate taskId="$original_id" status="completed"
fi

for new_task_id in "${newTaskIds[@]}"; do
    new_native_id=$(TaskCreate subject="$newTaskTitle" description="$newTaskDescription" activeForm="$newTaskActiveForm")
    jq --arg key "$new_task_id" --arg val "$new_native_id" \
       '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
       mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
done
```

**ADD_PREREQUISITE**:

```bash
prereq_native_id=$(TaskCreate subject="$prereqTitle" description="$prereqDescription" activeForm="$prereqActiveForm")
jq --arg key "$prereqTaskId" --arg val "$prereq_native_id" \
   '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
   mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"

original_id=$(jq -r ".nativeTaskMap[\"$originalTaskId\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
if [ -n "$original_id" ]; then
    TaskUpdate taskId="$original_id" addBlockedBy="$prereq_native_id"
fi
```

**ADD_FOLLOWUP**:

```bash
followup_native_id=$(TaskCreate subject="$followupTitle" description="$followupDescription" activeForm="$followupActiveForm")
jq --arg key "$followupTaskId" --arg val "$followup_native_id" \
   '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
   mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
```

## Verification Layers

Layer definitions and full logic are defined in `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md`.
This document is the canonical source for all 5 verification layers (Layer 0 through Layer 4).
Layer 0 in verification-layers.md is self-contained (no need to reference this document for escalation rules).

Key rules (quick reference — see verification-layers.md for full details):
- Layer 0 (EXECUTOR_START) is a hard gate. If absent, log and ESCALATE immediately.
- Layers 1-2 check output text for contradictions and TASK_COMPLETE signal.
- Layer 3 (Anti-fabrication) independently runs verify commands. NEVER trust executor output.
- Layer 4 (Artifact Review) runs periodically per rules defined in verification-layers.md.

### Layer 0: EXECUTOR_START Verification (MANDATORY — blocks all other layers)

After every delegation to spec-executor (sequential or parallel), verify the response
begins with the `EXECUTOR_START` signal BEFORE running any other verification layer.

```text
Expected first signal:
  EXECUTOR_START
    spec: <specName>
    task: <taskIndex>
    agent: spec-executor v...
```

**If `EXECUTOR_START` is absent from spec-executor output:**
- The delegation silently failed — the coordinator must NOT implement the task itself
- Do NOT run Layers 1–4
- Do NOT advance taskIndex
- Do NOT mark the task complete
- Do NOT increment taskIteration (this is an invocation failure, not a task failure)
- ESCALATE immediately:
  ```text
  ESCALATE
    reason: executor-not-invoked
    task: <taskIndex — task title>
    diagnosis: spec-executor subagent did not emit EXECUTOR_START.
               This means either (A) the subagent was never invoked (wrong
               subagent_type, plugin not loaded), (B) it timed out before
               emitting the signal, or (C) the coordinator fell back to direct
               implementation which is forbidden.
    resolution:
      1. Verify ralph-specum plugin is loaded (check Claude Code plugin config)
      2. Verify subagent_type is "spec-executor" (not "ralph-specum:spec-executor")
      3. Retry: /ralph-specum:implement --recovery-mode
  ```

> ⚠️ **Anti-pattern: coordinator self-implementation**
> The absence of `EXECUTOR_START` in a response that nonetheless contains
> TASK_COMPLETE is a strong signal that the coordinator implemented the task
> itself. This MUST be treated as an invocation failure, not a success.
> Layer 1 contradiction check does NOT catch this — Layer 0 does.

## Sequential Delegation Template

When `parallelGroup.isParallel = false` and task has no `[VERIFY]` marker, delegate ONE task to spec-executor via Task tool.

Before delegating, record the current commit SHA for Layer 4 artifact review:
```bash
TASK_START_SHA=$(git rev-parse HEAD)
```

**Delegation Contract**:

```text
Task: Execute task $taskIndex for spec $spec

Spec: $spec
Path: $SPEC_PATH/
Task index: $taskIndex

Context from .progress.md:
[Include relevant context]

Current task from tasks.md:
[Include full task block]

## Delegation Contract

### Design Decisions (from design.md)
[Extract relevant design decisions for THIS task — architectural constraints,
 technology choices, patterns chosen and patterns rejected]

### Anti-Patterns (DO NOT)
[List specific anti-patterns from design.md or .progress.md that apply to this task.
 Include project-specific anti-patterns from .progress.md Learnings and any
 task-specific constraints that must not be violated.
 Do NOT include VE / [VERIFY]-specific browser-navigation or skill-loading rules
 in this template; those belong in `ve-verification-contract.md`.]

### Success Criteria
[Copy the Done when + Verify sections from the task, plus any additional
 constraints from design.md Test Strategy]

Instructions:
1. Read Do section and execute exactly
2. Only modify Files listed
3. Verify completion with Verify command
4. Commit with task's Commit message
5. Update .progress.md with completion and learnings
6. Mark task [x] in tasks.md
7. Output TASK_COMPLETE when done
```

**Delegation Contract Rules:**
- The Sequential Delegation Template applies ONLY when `parallelGroup.isParallel = false` AND task has NO `[VERIFY]` marker.
- VE tasks and [VERIFY] tasks MUST use `${CLAUDE_PLUGIN_ROOT}/references/ve-verification-contract.md` — NOT this template.
- Never delegate a VE task without listing the required skill paths — the subagent cannot discover skills it was not told about.
- For Phase 1-2 implementation tasks, the contract is optional but recommended when design.md contains relevant constraints.
- Extract anti-patterns from: design.md Test Strategy, .progress.md Learnings (especially failures from prior tasks), and the task's own context.

Wait for spec-executor to complete. It will output TASK_COMPLETE on success.

## Parallel Execution Algorithm (Steps 1-8)

When `parallelGroup.isParallel = true` (adjacent [P] tasks), use team lifecycle protocol:

**Step 1: Clean Up Stale Team (MANDATORY FIRST ACTION)**
Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.

**Step 2: Create Team**
`TeamCreate(team_name: "exec-$spec", description: "Parallel execution batch")`

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: spec-executor)` calls in one message (skip Steps 3, 6, 7).

**Step 3: Create Tasks**
For each taskIndex in parallelGroup.taskIndices:
`TaskCreate(subject: "Execute task $taskIndex", description: "Task $taskIndex for $spec. progressFile: .progress-task-$taskIndex.md", activeForm: "Executing task $taskIndex")`

**Step 4: Spawn Teammates**
ALL Task calls in ONE message for true parallelism:
`Task(subagent_type: spec-executor, team_name: "exec-$spec", name: "executor-$taskIndex", prompt: "Execute task $taskIndex for spec $spec\nprogressFile: .progress-task-$taskIndex.md\n[full task block and context]")`

**Step 5: Wait for Completion**
Wait for automatic teammate idle notifications. Use TaskList ONCE to verify all tasks complete. Do NOT poll TaskList in a loop. After spawning teammates, wait for their messages -- they will notify you when done.

**Step 6: Shutdown Teammates**
`SendMessage(type: "shutdown_request", recipient: "executor-$taskIndex", content: "Execution complete, shutting down")` for each teammate.

**Step 7: Collect Results**
Proceed to Progress Merge and State Update.

**Step 8: Clean Up Team**
`TeamDelete()`. If fails, cleaned up on next invocation via Step 1.

---

## After Delegation

Decision tree when spec-executor returns. Applies to both sequential and parallel (per-task result):

**Case 1 — Fix Task Bypass:**
If the just-completed task description contains `[FIX` (e.g. `[FIX-layer2]`), skip all 5 verification layers and proceed directly to retrying the original task per `failure-recovery.md`. When delegating a fix task, pass `fix_type: <xxx>` explicitly in the prompt.

**Case 2 — TASK_MODIFICATION_REQUEST:**
Processing order:
1. Parse the modification request (SPLIT_TASK / ADD_PREREQUISITE / ADD_FOLLOWUP).
2. If TASK_COMPLETE is also present in the same output → process modification then proceed to verification (Case 3).
3. If ADD_PREREQUISITE only (no TASK_COMPLETE) → delegate the prerequisite task, then retry the original.
4. All modification ops: update tasks.md, run Native Task Sync - Modification per `task-modification.md`.

**Case 3 — TASK_COMPLETE / VERIFICATION_PASS:**
Run all 5 verification layers (see `references/verification-layers.md`) before advancing `taskIndex`. Only advance on VERIFICATION_PASS.

**Case 4 — No completion signal:**
Executor output has neither TASK_COMPLETE nor VERIFICATION_PASS:
1. Parse failure output for error context.
2. Increment `taskIteration` in state.
3. If `taskIteration < maxTaskIterations`: retry delegation with failure context appended.
4. If `taskIteration >= maxTaskIterations`: mark task as blocked in .progress.md, stop with error.

---

## State Update

After successful completion (TASK_COMPLETE for sequential or all parallel tasks complete):

**CRITICAL: Always use jq merge pattern to preserve all existing fields (source, name, basePath, commitSpec, relatedSpecs, etc.). Never write a new object from scratch.**

**Sequential Update**:
1. Read current `.ralph-state.json`
2. Increment `taskIndex` by 1
3. Reset `taskIteration` to 1
4. Increment `globalIteration` by 1
5. Write updated state (merge, preserving all existing fields)
6. Commit all spec file changes (skip if nothing staged):
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): update progress for task $taskIndex"
   ```

**Parallel Batch Update**:
1. Read current `.ralph-state.json`
2. Set `taskIndex` to `parallelGroup.endIndex + 1` (jump past entire batch)
3. Reset `taskIteration` to 1
4. Increment `globalIteration` by 1
5. Write updated state (merge, preserving all existing fields)
6. Commit all spec file changes (skip if nothing staged):
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): update progress for parallel batch"
   ```

Updated fields (all other fields preserved as-is):
```json
{
  "taskIndex": "<next task after current/batch>",
  "taskIteration": 1,
  "globalIteration": "<previous + 1>"
}
```

Check if all tasks complete:
- If `taskIndex >= totalTasks`: proceed to Completion Signal
- If `taskIndex < totalTasks`: continue to next iteration (loop re-invokes coordinator)

---

## Progress Merge (Parallel Only)

After all parallel teammates complete (Step 7 above), merge their progress files:

1. For each taskIndex N in parallelGroup.taskIndices: read `.progress-task-N.md`.
2. Extract completed task entries and Learnings sections.
3. Append to main `.progress.md` in task index order (smallest N first).
4. Delete each `.progress-task-N.md` after merging.
5. Commit merged progress separately from State Update: `git add .progress.md && git commit -m "chore: merge parallel progress for tasks $startIndex-$endIndex"`.

**Partial Parallel Batch Failure:**
- If some teammates completed and some failed: identify the failed `taskIndex` values from `.ralph-state.json` `taskResults`.
- Retry ONLY the failed tasks (re-run Steps 1-8 for the failed subset with a new parallelGroup containing only the failed indices).
- Do NOT re-run tasks that already succeeded.
- Do NOT advance `taskIndex` past the batch end until ALL tasks in the batch are complete.
