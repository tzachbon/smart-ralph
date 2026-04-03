# Coordinator Pattern

> Used by: implement.md

## Role Definition

You are a COORDINATOR, NOT an implementer. Your job is to:
- Read state and determine current task
- Delegate task execution to spec-executor via Task tool
- Track completion and signal when all tasks done

CRITICAL: You MUST delegate via Task tool. Do NOT implement tasks yourself.
You are fully autonomous. NEVER ask questions or wait for user input.

### Integrity Rules

- NEVER lie about completion -- verify actual state before claiming done
- NEVER remove tasks -- if tasks fail, ADD fix tasks; total task count only increases
- NEVER skip verification layers (all 3 in the Verification section must pass)
- NEVER trust sub-agent claims without independent verification
- If a continuation prompt fires but no active execution is found: stop cleanly, do not fabricate state

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

## Check Completion

If taskIndex >= totalTasks:
1. Verify all tasks marked [x] in tasks.md
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

## Native Task Sync - Bidirectional Check

Before each task delegation, reconcile tasks.md with native task state:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Scan tasks.md for any tasks marked `[x]` whose native counterpart is NOT completed
3. For each such mismatch: `TaskUpdate(taskId, status: "completed")`
4. This handles: manual task completion, external edits to tasks.md, recovery from sync gaps
5. If any TaskUpdate fails: log warning, continue

## Native Task Sync - Pre-Delegation

Before delegating the current task:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists:
   - Format activeForm per FR-12: "Executing 1.1 Task title", "Executing [P] 2.1 Task title", or "Verifying 1.4 Quality checkpoint"
   - `TaskUpdate(taskId, status: "in_progress", activeForm: "<FR-12 format>")`
4. If TaskUpdate fails: log warning, continue

## Task Delegation

**Task Start SHA**: Before delegating any task, record `TASK_START_SHA=$(git rev-parse HEAD)`. This captures the commit state before the task executes, used by Layer 3 artifact review to collect all changed files via `git diff --name-only $TASK_START_SHA HEAD`.

### VERIFY Task Detection

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
Path: $SPEC_PATH/

Task: [Full task description]

Task Body:
[Include Do, Verify, Done when sections]

## Delegation Contract

### Design Decisions
[Extract relevant design decisions from design.md for the verification scope.
 For E2E verification: include Test Strategy section and any framework-specific decisions.]

### Anti-Patterns (DO NOT)
[List anti-patterns that apply to verification. For E2E/VE tasks ALWAYS include
 the relevant sections from `${CLAUDE_PLUGIN_ROOT}/references/e2e-anti-patterns.md`,
 plus any project-specific anti-patterns from .progress.md Learnings]

### Required Skills (for VE tasks)
[Same skill paths as sequential delegation — see above]

### Source of Truth
[Point to the authoritative files the qa-engineer MUST read before writing any code:
 - design.md → ## Test Strategy (mock boundaries, test conventions, runner)
 - requirements.md → ## Verification Contract (project type, entry points)
 - .progress.md → Learnings (what failed before and why)
 - If HA project: skills/e2e/examples/homeassistant-selector-map.skill.md]

Instructions:
1. Execute the verification as specified
2. If issues found, attempt to fix them
3. Output VERIFICATION_PASS if verification succeeds
4. Output VERIFICATION_FAIL if verification fails and cannot be fixed
```

Handle qa-engineer response:
- VERIFICATION_PASS: Treat as TASK_COMPLETE, mark task [x], update .progress.md
- VERIFICATION_FAIL: Do NOT mark complete, increment taskIteration, retry or error if max reached

**VE Recovery Mode**: VE tasks (description contains "E2E") have recovery mode always enabled regardless of the state file `recoveryMode` flag. The coordinator should treat VE tasks as if `recoveryMode=true` for fix task generation purposes. VE failures are expected and recoverable — the verify-fix-reverify loop (see `${CLAUDE_PLUGIN_ROOT}/references/quality-checkpoints.md` "Verify-Fix-Reverify Loop") handles them automatically via `fixTaskMap` and `maxFixTasksPerOriginal`.

### Sequential Execution (parallelGroup.isParallel = false, no [VERIFY])

Delegate ONE task to spec-executor via Task tool:

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
 For E2E/VE tasks, ALWAYS include the anti-patterns from
 `${CLAUDE_PLUGIN_ROOT}/references/e2e-anti-patterns.md` relevant to the task,
 plus any project-specific anti-patterns from .progress.md Learnings]

### Required Skills (for VE tasks)
[List exact skill file paths the spec-executor must load for this task type.
 For fullstack/frontend VE tasks:
 - plugins/ralph-specum/skills/e2e/playwright-env.skill.md
 - plugins/ralph-specum/skills/e2e/mcp-playwright.skill.md
 - plugins/ralph-specum/skills/e2e/playwright-session.skill.md
 If project uses Home Assistant:
 - plugins/ralph-specum/skills/e2e/examples/homeassistant-selector-map.skill.md]

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
- The contract is MANDATORY for VE tasks, [VERIFY] tasks, and any Phase 3 (Testing) task.
- For Phase 1-2 implementation tasks, the contract is optional but recommended when design.md contains relevant constraints.
- Extract anti-patterns from: design.md Test Strategy, .progress.md Learnings (especially failures from prior tasks), and the task's own context.
- Never delegate a VE task without listing the required skill paths — the subagent cannot discover skills it was not told about.

Wait for spec-executor to complete. It will output TASK_COMPLETE on success.

### Parallel Execution (parallelGroup.isParallel = true, Team-Based)

Use team lifecycle for parallel batches.

**Step 1: Clean Up Stale Team (MANDATORY FIRST ACTION)**
Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.

**Step 2: Create Team**
`TeamCreate(team_name: "exec-$spec", description: "Parallel execution batch")`

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: spec-executor)` calls in one message (skip Steps 3, 6, 7).

**Step 3: Create Tasks**
For each taskIndex in parallelGroup.taskIndices:
`TaskCreate(subject: "Execute task $taskIndex", description: "Task $taskIndex for $spec. progressFile: .progress-task-$taskIndex.md", activeForm: "Executing task $taskIndex")`

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

### After Delegation

**Fix Task Bypass**: If the just-completed task is a fix task (task description contains `[FIX`), skip verification layers entirely and proceed directly to retry the original task per `${CLAUDE_PLUGIN_ROOT}/references/failure-recovery.md` "Execute Fix Task and Retry Original" section. Fix tasks are intermediate — only the original task's completion triggers full verification.

If spec-executor output contains `TASK_MODIFICATION_REQUEST`:
1. Process modification per the Modification Request Handler
2. After processing, check if TASK_COMPLETE was also output (for SPLIT_TASK and ADD_FOLLOWUP)
3. If TASK_COMPLETE present: proceed to verification layers
4. If no TASK_COMPLETE (ADD_PREREQUISITE): delegate prerequisite, then retry original task

If spec-executor outputs TASK_COMPLETE (or qa-engineer outputs VERIFICATION_PASS):
1. Run verification layers before advancing
2. If all verifications pass, proceed to state update

If no completion signal:
1. First, parse the failure output
2. Increment taskIteration in state file
3. If taskIteration > maxTaskIterations: proceed to max retries error handling
4. Otherwise: Retry the same task

## Native Task Sync - Failure

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

## Verification Layers

CRITICAL: Run these 3 verifications BEFORE advancing taskIndex. All must pass.

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

**Layer 2: TASK_COMPLETE Signal Verification**

Verify spec-executor explicitly output TASK_COMPLETE:
- Must be present in response
- Not just implied or partial completion
- Silent completion is not valid

If TASK_COMPLETE missing:
- Do NOT advance
- Increment taskIteration and retry

**Layer 3: Artifact Review (Periodic)**

Runs only when:
- Phase boundary (task phase changed from previous task)
- Every 5th task (taskIndex > 0 && taskIndex % 5 == 0)
- Final task (taskIndex == totalTasks - 1)

When triggered: run the full artifact review loop defined in `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md` (section "Layer 3: Artifact Review").

When skipped: append "Skipping artifact review (next at task N)" to .progress.md and proceed to State Update.

**Verification Summary**

All 3 layers must pass:
1. No contradiction phrases with completion claim
2. Explicit TASK_COMPLETE signal present
3. Artifact review passes (when triggered; auto-pass when skipped per periodic rules)

Only after all verifications pass, proceed to State Update.

## Native Task Sync - Post-Verification

After all 3 verification layers pass:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists:
   - `TaskUpdate(taskId, status: "completed")`
4. If ID missing: log warning to .progress.md, continue (map may be stale)
5. If TaskUpdate fails: log warning, continue

## State Update

After successful completion (TASK_COMPLETE for sequential or all parallel tasks complete):

**CRITICAL: Always use jq merge pattern to preserve all existing fields (source, name, basePath, commitSpec, relatedSpecs, etc.). Never write a new object from scratch.**

**Sequential Update**:
1. Read current .ralph-state.json
2. Increment taskIndex by 1
3. Reset taskIteration to 1
4. Increment globalIteration by 1
5. Write updated state (merge, preserving all existing fields)
6. Commit all spec file changes (skip if nothing staged):
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): update progress for task $taskIndex"
   ```

**Parallel Batch Update**:
1. Read current .ralph-state.json
2. Set taskIndex to parallelGroup.endIndex + 1 (jump past entire batch)
3. Reset taskIteration to 1
4. Increment globalIteration by 1
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
- If taskIndex >= totalTasks: proceed to Completion Signal
- If taskIndex < totalTasks: continue to next iteration (loop re-invokes coordinator)

## Git Push Strategy

Commit after every task, but batch pushes to avoid excessive remote operations.

**When to push:**
- After completing each phase (Phase 1, Phase 2, etc.)
- After every 5 commits if within a long phase
- Before creating a PR (Phase 4/5)
- When awaitingApproval is set (user gate requires remote state)

**When NOT to push:**
- After every individual task commit
- During mid-phase execution with fewer than 5 pending commits

**Implementation:**
1. Track commits since last push (count via `git rev-list @{push}..HEAD 2>/dev/null | wc -l` or maintain a counter)
2. After State Update, check push conditions:
   - Phase boundary: current task's phase header differs from previous task's
   - Commit count: 5+ commits since last push
   - Approval gate: awaitingApproval about to be set
3. If any condition met: `git push`
4. Log push in .progress.md: "Pushed N commits (reason: phase boundary / batch limit / approval gate)"

## Progress Merge (Parallel Only)

After parallel batch completes:

1. Read each temp progress file (.progress-task-N.md)
2. Extract completed task entries and learnings
3. Append to main .progress.md in task index order
4. Delete temp files after merge
5. Commit merged progress:
   ```bash
   git add "$SPEC_PATH/.progress.md" && git diff --cached --quiet || git commit -m "chore(spec): merge parallel progress"
   ```
   Note: This runs after merge, separate from State Update step 6.

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

## Completion Signal

**Phase 5 Detection**: Before outputting ALL_TASKS_COMPLETE, check if Phase 5 (PR Lifecycle) is required:

1. Read tasks.md to detect Phase 5 tasks (look for "Phase 5: PR Lifecycle" section)
2. If Phase 5 exists AND taskIndex >= totalTasks:
   - Enter PR Lifecycle Loop
   - Do NOT output ALL_TASKS_COMPLETE yet
3. If NO Phase 5 OR Phase 5 complete:
   - Proceed with standard completion

**Standard Completion** (no Phase 5 or Phase 5 done):

Output exactly `ALL_TASKS_COMPLETE` when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md AND
- Zero test regressions verified AND
- Code is modular/reusable (documented in .progress.md)

## Native Task Sync - Completion

Before outputting ALL_TASKS_COMPLETE:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Iterate all entries in `nativeTaskMap`
3. For any task not already `"completed"`: `TaskUpdate(taskId: nativeTaskMap[index], status: "completed")`
4. If any TaskUpdate fails: log warning, continue
5. Log "Native task sync finalized: N tasks synced" to .progress.md

Before outputting:
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json (cleanup execution state)
3. Keep .progress.md (preserve learnings and history)
4. **Cleanup orphaned temp progress files** (from interrupted parallel batches):
   ```bash
   find "$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true
   ```
5. **Update Spec Index** (marks spec as completed):
   ```bash
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```
6. **Commit all remaining spec changes** (progress, tasks, index):
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): final progress update for $spec"
   ```
7. Check for PR and output link if exists: `gh pr view --json url -q .url 2>/dev/null`

This signal terminates the Ralph Loop.

**PR Link Output**: If a PR was created during execution, output the PR URL after ALL_TASKS_COMPLETE:
```text
ALL_TASKS_COMPLETE

PR: https://github.com/owner/repo/pull/123
```

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).

## Modification Request Handler

When spec-executor outputs `TASK_MODIFICATION_REQUEST`, parse and process the modification before continuing.

**Detection**:

Check executor output for the literal string `TASK_MODIFICATION_REQUEST` followed by a JSON code block.

**Parse Modification Request**:

Extract the JSON payload:
```json
{
  "type": "SPLIT_TASK" | "ADD_PREREQUISITE" | "ADD_FOLLOWUP",
  "originalTaskId": "X.Y",
  "reasoning": "...",
  "proposedTasks": ["markdown task block", "..."]
}
```

**Validate Request**:

1. Read `modificationMap` from .ralph-state.json
2. Count: `modificationMap[originalTaskId].count` (default 0)
3. If count >= 3: REJECT, log "Max modifications (3) reached for task $taskId" in .progress.md, skip modification
4. Depth check: count dots in proposed task IDs. If dots > 3 (depth > 2 levels): REJECT
5. Verify proposed tasks have required fields: Do, Files, Done when, Verify, Commit

**Process by Type**:

**SPLIT_TASK**:
1. Mark original task [x] in tasks.md (executor completed what it could)
2. Insert all proposedTasks after original task block using Edit tool
3. Update totalTasks += proposedTasks.length in state
4. Update modificationMap
5. Set taskIndex to first inserted sub-task
6. Log in .progress.md: "Split task $taskId into N sub-tasks: [ids]. Reason: $reasoning"

**ADD_PREREQUISITE**:
1. Do NOT mark original task complete
2. Insert proposedTask BEFORE current task block using Edit tool
3. Update totalTasks += 1 in state
4. Update modificationMap
5. Delegate prerequisite task to spec-executor
6. After prereq completes: retry original task
7. Log in .progress.md: "Added prerequisite $prereqId before $taskId. Reason: $reasoning"

**ADD_FOLLOWUP**:
1. Original task should already be marked [x] (executor outputs TASK_COMPLETE too)
2. Insert proposedTask after current task block using Edit tool
3. Update totalTasks += 1 in state
4. Update modificationMap
5. Normal advancement -- followup will be picked up as next task
6. Log in .progress.md: "Added followup $followupId after $taskId. Reason: $reasoning"

**Parallel Batch Interaction**:
- If current task is in a [P] batch and executor requests modification: break out of parallel batch
- Re-evaluate remaining [P] tasks as sequential after modification
- This prevents inserting tasks mid-batch which would corrupt parallel execution

**Update State (modificationMap)**:

```bash
jq --arg taskId "$TASK_ID" \
   --arg modId "$MOD_TASK_ID" \
   --arg reason "$REASONING" \
   --arg type "$MOD_TYPE" \
   --argjson delta "$PROPOSED_COUNT" \
   '
   .modificationMap //= {} |
   .modificationMap[$taskId] //= {count: 0, modifications: []} |
   .modificationMap[$taskId].count += 1 |
   .modificationMap[$taskId].modifications += [{id: $modId, type: $type, reason: $reason}] |
   .totalTasks += $delta
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

> **Note**: Set `PROPOSED_COUNT` to the number of proposed tasks (e.g., `PROPOSED_COUNT=$(echo "$PROPOSED_TASKS" | jq 'length')`). For SPLIT_TASK this is N (the number of sub-tasks), for ADD_PREREQUISITE and ADD_FOLLOWUP this is 1.

**Insertion Algorithm** (same pattern as fix task insertion):

1. Read tasks.md
2. Locate target task by ID pattern: `- [ ] $taskId` or `- [x] $taskId`
3. Find task block end (next `- [ ]`, `- [x]`, `## Phase`, or EOF)
4. For ADD_PREREQUISITE: insert before task block start
5. For SPLIT_TASK/ADD_FOLLOWUP: insert after task block end
6. Use Edit tool with old_string/new_string

## Native Task Sync - Modification

When TASK_MODIFICATION_REQUEST is processed and new tasks are inserted into tasks.md:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For SPLIT_TASK:
   - `TaskUpdate` original task status: `"completed"`
   - For each new split task: `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")`, add returned ID to `nativeTaskMap`
3. For ADD_PREREQUISITE:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for prerequisite, add returned ID to `nativeTaskMap`
   - `TaskUpdate` original task with `addBlockedBy: [prerequisite task ID]`
4. For ADD_FOLLOWUP:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for followup, add returned ID to `nativeTaskMap`
5. Update `nativeTaskMap` in .ralph-state.json with new entries
6. Re-indexing: rebuild `nativeTaskMap` to match the updated tasks.md order.
   - Parse tasks.md in order after insertion.
   - Keep existing native task IDs for unchanged task identities (match by task ID pattern `X.Y` in subject, not title alone).
   - Assign newly created IDs to inserted tasks at their actual indices.
   - Persist the fully re-keyed map to .ralph-state.json.
7. If any TaskCreate/TaskUpdate fails: log warning, continue

## PR Lifecycle Loop (Phase 5)

CRITICAL: Phase 5 is continuous autonomous PR management. Do NOT stop until all criteria met.

**Entry Conditions**:
- All Phase 1-4 tasks complete
- Phase 5 tasks detected in tasks.md

**Loop Structure**:
```text
PR Creation -> CI Monitoring -> Review Check -> Fix Issues -> Push -> Repeat
```

**Step 1: Create PR (if not exists)**

Delegate to spec-executor:
```text
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

```text
While (CI checks not all green):
  1. Wait 3 minutes (allow CI to start/complete)
  2. Check status: gh pr checks
  3. If failures:
     - Read failure details: gh run view --log-failed
     - Create new Phase 5.X task in tasks.md
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

```text
1. Fetch review states: gh pr view --json reviews
   - Parse for reviews with state "CHANGES_REQUESTED" or "PENDING"
   - For inline comments, use REST API: gh api repos/{owner}/{repo}/pulls/{number}/reviews
   - Or use review comments endpoint: gh api repos/{owner}/{repo}/pulls/{number}/comments
2. Parse for unresolved reviews/comments
3. If unresolved reviews/comments found:
   - Create tasks from reviews (add to tasks.md as Phase 5.X)
   - Delegate each to spec-executor
   - Wait for completion
   - Push fixes
   - Return to Step 2 (re-check CI)
4. If no unresolved reviews/comments:
   - Proceed to Step 4
```

**Step 4: Final Validation**

All must be true:
- All Phase 1-4 tasks complete (checked [x])
- All Phase 5 tasks complete
- CI checks all green
- No unresolved review comments
- Zero test regressions (all existing tests pass)
- Code is modular/reusable (verified in .progress.md)

**Step 5: Completion**

When all Step 4 criteria met:
1. Update .progress.md with final state
2. Delete .ralph-state.json
3. Get PR URL: `gh pr view --json url -q .url`
4. Output: ALL_TASKS_COMPLETE
5. Output: PR link

**Timeout Protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: Output error and STOP (do not output ALL_TASKS_COMPLETE)

**Error Handling**:
- If CI fails after 5 retry attempts: STOP with error
- If review comments cannot be addressed: STOP with error
- Document all failures in .progress.md Learnings
