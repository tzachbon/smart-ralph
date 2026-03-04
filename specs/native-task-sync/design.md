# Design: native-task-sync

## Overview

Add native Claude Code task UI integration to the Ralph Specum execution loop. The coordinator creates all native tasks upfront from tasks.md when execution starts, then updates their status as tasks complete. Sync logic is inline in coordinator-pattern.md, with abbreviated sync instructions also in the stop-hook continuation prompt so they persist across iterations.

## Architecture

```
implement.md
  |
  v
coordinator-pattern.md (first iteration)
  |-- FR-1: Create all native tasks from tasks.md
  |-- FR-2: Mark current task in_progress
  |-- Delegate to spec-executor
  |-- FR-3: Mark task completed after verification
  |-- Update .ralph-state.json (nativeTaskMap)
  |
  v
stop-watcher.sh (each subsequent iteration)
  |-- Read state (includes nativeTaskMap)
  |-- Output continuation prompt WITH sync instructions
  |
  v
coordinator (resumed, abbreviated prompt)
  |-- FR-13: Rebuild nativeTaskMap if stale/missing
  |-- FR-2: Mark current task in_progress
  |-- Delegate to spec-executor
  |-- FR-3: Mark task completed
  |-- Loop until ALL_TASKS_COMPLETE
```

## Components

### Component 1: coordinator-pattern.md (Modified)

**Purpose**: Add sync logic inline at each integration point.

**Changes**:

#### New section: "Native Task Sync - Initial Setup" (after "Read State", before "Check Completion")

```markdown
## Native Task Sync - Initial Setup

If `nativeSyncEnabled` is not `false` in state AND `nativeTaskMap` is missing or empty:

1. Parse all tasks from tasks.md (same parsing as existing task count logic)
2. For each task at index `i`:
   - Extract title (first line after `- [ ]` or `- [x]`)
   - Extract first 1-2 sub-items as description
   - Detect markers: [P], [VERIFY], or none
   - Format subject per FR-11:
     - Regular: "1.1 Task title"
     - Parallel: "[P] 2.1 Task title"
     - Verify: "[VERIFY] 1.4 Quality checkpoint"
   - Format activeForm per FR-12
   - Call TaskCreate(subject, description, activeForm)
   - If task already completed ([x]): immediately TaskUpdate(status: "completed")
   - Store mapping: nativeTaskMap[i] = returned task ID
3. Write updated nativeTaskMap to .ralph-state.json
4. If any TaskCreate fails: log warning to .progress.md, set nativeSyncEnabled: false, continue without sync

If `nativeSyncEnabled` is `false`: skip all sync operations silently.
```

#### New section: "Native Task Sync - Bidirectional Check" (before "Task Delegation")

```markdown
## Native Task Sync - Bidirectional Check

Before each task delegation, reconcile tasks.md with native task state:

1. If nativeSyncEnabled is false or nativeTaskMap is missing: skip
2. Scan tasks.md for any tasks marked [x] whose native counterpart is NOT completed
3. For each such mismatch: TaskUpdate(taskId, status: "completed")
4. This handles: manual task completion, external edits to tasks.md, recovery from sync gaps
5. If any TaskUpdate fails: log warning, continue (best-effort sync)
```

#### New section: "Native Task Sync - Pre-Delegation" (before "Task Delegation")

```markdown
## Native Task Sync - Pre-Delegation

Before delegating the current task:

1. If nativeSyncEnabled is false or nativeTaskMap is missing: skip
2. Look up native task ID: nativeTaskMap[taskIndex]
3. If ID exists:
   - TaskUpdate(taskId, status: "in_progress", activeForm: "Executing [task title]")
4. If TaskUpdate fails: log warning, continue (do not block execution)
```

#### New section: "Native Task Sync - Post-Verification" (after verification layers, before state update)

```markdown
## Native Task Sync - Post-Verification

After all 3 verification layers pass:

1. If nativeSyncEnabled is false or nativeTaskMap is missing: skip
2. Look up native task ID: nativeTaskMap[taskIndex]
3. If ID exists:
   - TaskUpdate(taskId, status: "completed")
4. If TaskUpdate fails: log warning, continue
```

#### New section: "Native Task Sync - Failure" (in failure handling path)

```markdown
## Native Task Sync - Failure

When task fails and taskIteration increments:

1. If nativeSyncEnabled is false or nativeTaskMap is missing: skip
2. Look up native task ID: nativeTaskMap[taskIndex]
3. TaskUpdate(taskId, subject: "[original title] [retry N/M]", activeForm: "Retrying [title] (attempt N)")
4. If TaskUpdate fails: log warning, continue
```

#### New section: "Native Task Sync - Modification" (in modification request handler)

```markdown
## Native Task Sync - Modification

When TASK_MODIFICATION_REQUEST processed and new tasks inserted into tasks.md:

1. If nativeSyncEnabled is false: skip
2. For SPLIT_TASK:
   - TaskUpdate original task status: "completed"
   - For each new split task: TaskCreate, add to nativeTaskMap
3. For ADD_PREREQUISITE:
   - TaskCreate for prerequisite, add to nativeTaskMap
   - TaskUpdate original with addBlockedBy: [prerequisite task ID]
4. For ADD_FOLLOWUP:
   - TaskCreate for followup, add to nativeTaskMap
5. Update nativeTaskMap in .ralph-state.json with new entries
6. Re-indexing strategy: new tasks get keys beyond current max index (e.g., if max is "39", new tasks get "40", "41", etc.). The coordinator updates totalTasks to match. No shifting of existing keys needed since task indices in nativeTaskMap are logical positions, not physical line numbers.
```

#### New section: "Native Task Sync - Completion" (before ALL_TASKS_COMPLETE output)

```markdown
## Native Task Sync - Completion

Before outputting ALL_TASKS_COMPLETE:

1. If nativeSyncEnabled is false or nativeTaskMap is missing: skip
2. Iterate all entries in nativeTaskMap
3. For any task not already "completed": TaskUpdate(status: "completed")
4. Log "Native task sync finalized: N tasks synced" to .progress.md
```

#### New section: "Native Task Sync - Parallel" (in parallel execution section)

```markdown
## Native Task Sync - Parallel

When parallel [P] group starts:

1. If nativeSyncEnabled is false: skip
2. For each taskIndex in parallelGroup.taskIndices:
   - Look up native task ID from nativeTaskMap
   - TaskUpdate(status: "in_progress", activeForm: "Executing [P] [title]")
3. ALL TaskUpdate calls in ONE message (parallel tool calls)
4. As each executor completes: TaskUpdate individual task to "completed"
```

### Component 2: stop-watcher.sh (Modified)

**Purpose**: Include sync instructions in continuation prompt so coordinator syncs on every iteration.

**Changes**: Add sync steps to the REASON continuation prompt (lines ~313-334).

Current resume section:
```
## Resume
1. Read $SPEC_PATH/.ralph-state.json for current state
2. Delegate the task above to spec-executor
3. On TASK_COMPLETE: verify, update state, advance
4. If taskIndex >= totalTasks: verify all [x], delete state, ALL_TASKS_COMPLETE
```

New resume section:
```
## Resume
1. Read $SPEC_PATH/.ralph-state.json for current state
2. **Native Task Sync**: If nativeSyncEnabled != false:
   a. If nativeTaskMap missing/empty: rebuild from tasks.md (create all tasks, map IDs)
   b. TaskUpdate current task to in_progress with activeForm
3. Delegate the task above to spec-executor (or qa-engineer for [VERIFY])
4. On TASK_COMPLETE: verify, then TaskUpdate task to completed, update state, advance
5. If taskIndex >= totalTasks: finalize all native tasks to completed, verify all [x], delete state, ALL_TASKS_COMPLETE
```

**Also add** to the state extraction section (around line 144):
```bash
NATIVE_SYNC=$(jq -r '.nativeSyncEnabled // true' "$STATE_FILE" 2>/dev/null || echo "true")
```

And include `NATIVE_SYNC` in the continuation prompt context:
```
## State
Path: $SPEC_PATH | Index: $TASK_INDEX | Iteration: $TASK_ITERATION/$MAX_TASK_ITER | Recovery: $RECOVERY_MODE | NativeSync: $NATIVE_SYNC
```

### Component 3: implement.md (Modified)

**Purpose**: Initialize sync state fields during Step 3 and add batch push instruction to coordinator prompt.

**Changes**:

#### Change 1: Add to the jq merge in Step 3:

```json
{
  "nativeTaskMap": {},
  "nativeSyncEnabled": true,
  "nativeSyncFailureCount": 0
}
```

These are merged into existing state, preserving all other fields. Empty nativeTaskMap signals the coordinator to perform initial sync on first iteration.

#### Change 2: Add batch push instruction to coordinator prompt

Add a "Git Push Strategy" section to the coordinator prompt (Step 4) or to coordinator-pattern.md:

```markdown
## Git Push Strategy

Do NOT push after every commit. Instead, batch pushes:
- Push after completing each phase (Phase 1, Phase 2, etc.)
- Push after every 5 commits if within a long phase
- Push before creating a PR (Phase 4)
- Push when awaitingApproval is set to true

This reduces remote operations and avoids spamming CI with per-task pushes.
```

### Component 4: .ralph-state.json (Extended Schema)

New fields added by this feature:

```json
{
  "nativeTaskMap": {
    "0": "1",
    "1": "2",
    "2": "3"
  },
  "nativeSyncEnabled": true
}
```

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| nativeTaskMap | object | {} | Maps 0-based task index (string) to native task ID (string) |
| nativeSyncEnabled | boolean | true | Set to false after 3+ consecutive sync failures |
| nativeSyncFailureCount | number | 0 | Consecutive sync failure counter. Reset to 0 on success. |

**Backward compatibility**: Missing fields default to `nativeTaskMap: {}` (triggers initial sync), `nativeSyncEnabled: true`, and `nativeSyncFailureCount: 0`.

## Technical Decisions

### Decision 1: Sync logic inline in coordinator-pattern.md
**Choice**: Inline, not a separate reference file.
**Rationale**: Each sync point is 3-5 lines. A separate file adds indirection for minimal logic. Inline keeps the flow readable.

### Decision 2: All tasks created upfront
**Choice**: Create all tasks from tasks.md in one turn.
**Rationale**: User confirmed Claude Code handles 67+ tasks. No windowing complexity needed. Simple and complete.

### Decision 3: nativeTaskMap in state file, not in memory
**Choice**: Persist task ID mapping in .ralph-state.json.
**Rationale**: Tasks persist across sessions. On resume, coordinator needs to know which native tasks exist. State file is the persistence layer.

### Decision 4: Stop-hook includes sync instructions
**Choice**: Abbreviated sync steps in stop-hook continuation prompt.
**Rationale**: coordinator-pattern.md is only fully loaded on first iteration. Stop-hook fires on every subsequent iteration. Sync instructions must be in both places.

### Decision 5: Graceful degradation via nativeSyncEnabled flag
**Choice**: Disable sync after 3+ consecutive failures, skip silently.
**Rationale**: Sync is a UI convenience, not execution-critical. Must never block the loop.

### Decision 6: Rebuild on resume
**Choice**: If nativeTaskMap is empty/missing, rebuild from tasks.md.
**Rationale**: Session restarts create new task ID space. Old IDs are stale. Rebuilding is simple (parse tasks.md, create all, map).

## File Changes

### Files to Modify

| File | Change Type | Description |
|------|------------|-------------|
| `plugins/ralph-specum/references/coordinator-pattern.md` | Major | Add 8 sync sections at integration points |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Minor | Add sync state to continuation prompt + NATIVE_SYNC variable |
| `plugins/ralph-specum/commands/implement.md` | Minor | Add nativeTaskMap/nativeSyncEnabled to initial state merge |

### Files to Create

None. All changes are to existing files.

### Files Unchanged

| File | Reason |
|------|--------|
| `agents/spec-executor.md` | No changes needed - executor is unaware of native tasks |
| `agents/task-planner.md` | No changes needed - task format unchanged |
| `hooks/hooks.json` | No new hooks needed |
| `templates/` | No template changes |

## Error Handling

### Sync Failure Strategy

```
TaskCreate/TaskUpdate call
  |
  +-- Success: continue normally
  |
  +-- Failure:
      |-- Increment consecutive failure counter
      |-- Log warning to .progress.md: "Native sync warning: [error]"
      |-- If consecutive failures >= 3:
      |     Set nativeSyncEnabled: false in state
      |     Log: "Native sync disabled after 3 failures"
      |-- Continue execution (NEVER block)
```

### Resume Reconstruction

```
Coordinator resumes (stop-hook or session restart)
  |
  +-- Read .ralph-state.json
  |
  +-- nativeSyncEnabled == false? -> Skip all sync
  |
  +-- nativeTaskMap empty/missing?
  |     |-- Parse tasks.md
  |     |-- Create all native tasks (completed ones as completed)
  |     |-- Build new nativeTaskMap
  |     |-- Write to state
  |
  +-- nativeTaskMap exists?
        |-- Validate by trying TaskUpdate on first entry
        |-- If fails (stale IDs): rebuild (same as empty)
        |-- If works: use existing map
```

## Test Strategy

### Manual Testing

1. **Happy path**: Create a spec with 5-10 tasks, run `/implement`. Verify native tasks appear and update.
2. **Large spec**: Create a spec with 40+ tasks. Verify all created, no errors.
3. **Resume**: Start execution, kill session, restart. Verify native tasks rebuilt.
4. **Failure**: Mock TaskCreate failure (edit coordinator to skip). Verify graceful degradation.
5. **Parallel**: Spec with [P] tasks. Verify all marked in_progress simultaneously.
6. **Modification**: Trigger SPLIT_TASK. Verify new native tasks created.

### Verification Commands

```bash
# Validate state file has new fields
jq '.nativeTaskMap, .nativeSyncEnabled' specs/$spec/.ralph-state.json

# Check no syntax errors in modified files
cat plugins/ralph-specum/references/coordinator-pattern.md | head -5
bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh
```
