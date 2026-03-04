# Requirements: native-task-sync

## Overview

Enhance the Ralph Specum implement command to sync tasks.md entries as native Claude Code tasks (TaskCreate/TaskUpdate), providing real-time visual progress tracking in the Claude Code task UI. The sync is fully autonomous, bidirectional, and gracefully degrades on failure.

## User Stories

### US-1: Automatic Task Creation on Implement Start
**As a** developer running `/ralph-specum:implement`,
**I want** all tasks from tasks.md to appear as native Claude Code tasks automatically,
**So that** I can see my spec's progress in the native task UI without manual setup.

**Acceptance Criteria:**
- [ ] Running `/implement` creates a native task for each entry in tasks.md
- [ ] Each native task has a subject matching the task title (e.g., "1.1 Create auth module")
- [ ] Each native task includes the first 1-2 sub-items from the task block as description
- [ ] Already-completed tasks (marked `[x]` in tasks.md) are created with status `completed`
- [ ] Incomplete tasks are created with status `pending`
- [ ] No user interaction required during creation

### US-2: Real-Time Status Updates During Execution
**As a** developer watching execution progress,
**I want** native tasks to update their status as the coordinator progresses,
**So that** I can see which task is active, which passed, and how far along execution is.

**Acceptance Criteria:**
- [ ] Current task shows status `in_progress` with activeForm spinner text (e.g., "Executing 2.1 Add validation")
- [ ] After TASK_COMPLETE + verification, task status changes to `completed`
- [ ] The next task's status changes to `in_progress` when delegation starts
- [ ] Status updates happen without user interaction

### US-3: Graceful Degradation
**As a** developer,
**I want** execution to continue normally even if task sync fails,
**So that** sync issues never block my spec from completing.

**Acceptance Criteria:**
- [ ] If TaskCreate/TaskUpdate fails, a warning is logged to .progress.md
- [ ] Execution loop continues uninterrupted
- [ ] A `nativeSyncEnabled` flag in state is set to `false` on persistent failure
- [ ] Subsequent sync attempts are skipped when disabled
- [ ] tasks.md remains the authoritative source of truth regardless of sync state

### US-4: Parallel Task Batch Display
**As a** developer with parallel [P] tasks,
**I want** parallel tasks to be visually grouped in the native UI,
**So that** I can see which tasks run concurrently.

**Acceptance Criteria:**
- [ ] [P] tasks have a subject prefix indicating parallel (e.g., "[P] 2.1 Task name")
- [ ] All tasks in a parallel group show `in_progress` simultaneously during batch execution
- [ ] Each parallel task completes independently as its executor finishes
- [ ] The group advances only when all parallel tasks complete

### US-5: Verify Task Differentiation
**As a** developer,
**I want** [VERIFY] quality checkpoint tasks to look different from regular tasks,
**So that** I can distinguish implementation work from verification steps.

**Acceptance Criteria:**
- [ ] [VERIFY] tasks have a distinct subject prefix (e.g., "[VERIFY] 1.4 Quality checkpoint")
- [ ] [VERIFY] tasks use a different activeForm pattern (e.g., "Verifying 1.4 Quality checkpoint")

### US-6: Task Modification Sync
**As a** developer whose spec tasks get modified during execution (split, prerequisite, followup),
**I want** the native task list to reflect those modifications,
**So that** the UI stays accurate after task structure changes.

**Acceptance Criteria:**
- [ ] SPLIT_TASK: Original task marked `completed`, new sub-tasks created as `pending`
- [ ] ADD_PREREQUISITE: New prerequisite task created, original task updated with `addBlockedBy`
- [ ] ADD_FOLLOWUP: New followup task created after the original
- [ ] totalTasks in native UI matches updated tasks.md count

### US-7: Failure and Retry Tracking
**As a** developer whose task fails and retries,
**I want** to see the retry status in the native UI,
**So that** I know a task is being retried rather than stuck.

**Acceptance Criteria:**
- [ ] Failed task shows updated subject with retry count (e.g., "1.3 Add auth [retry 2/5]")
- [ ] activeForm reflects retry (e.g., "Retrying 1.3 Add auth (attempt 2)")
- [ ] If max retries exceeded, task description updated with failure info

### US-8: Resume After Session Restart
**As a** developer resuming execution in a new session,
**I want** the native task state to be reconstructed from tasks.md and .ralph-state.json,
**So that** progress is visible even after session interruption.

**Acceptance Criteria:**
- [ ] On resume, coordinator reads tasks.md and creates native tasks for all entries
- [ ] Already-completed tasks (from tasks.md `[x]` marks) are created as `completed`
- [ ] Current task (from taskIndex in state) is marked `in_progress`
- [ ] nativeTaskMap in state is rebuilt with new task IDs

### US-9: Completion Cleanup
**As a** developer whose spec finishes execution,
**I want** all native tasks to show as completed when ALL_TASKS_COMPLETE fires,
**So that** the final state is clean and accurate.

**Acceptance Criteria:**
- [ ] All native tasks show `completed` status
- [ ] No orphaned `pending` or `in_progress` tasks remain
- [ ] Final sync state logged in .progress.md

## Functional Requirements

### FR-1: Initial Task Sync (Integration Point A)
When the coordinator starts execution (implement.md Step 4):
1. Parse all tasks from tasks.md
2. For each task, call TaskCreate with subject (title), description (first 1-2 sub-items), and activeForm
3. Store mapping of tasksmd index -> native task ID in .ralph-state.json as `nativeTaskMap`
4. Mark already-completed tasks as `completed`
5. Mark first incomplete task as `in_progress`

### FR-2: Pre-Delegation Sync (Integration Point D)
Before delegating a task to spec-executor:
1. Look up native task ID from `nativeTaskMap` using current taskIndex
2. Call TaskUpdate to set status `in_progress` and activeForm to "Executing [task title]"

### FR-3: Post-Verification Sync (Integration Point B)
After TASK_COMPLETE + all 3 verification layers pass:
1. Look up native task ID from `nativeTaskMap`
2. Call TaskUpdate to set status `completed`

### FR-4: Failure/Retry Sync (Integration Point E)
When a task fails and taskIteration increments:
1. Look up native task ID from `nativeTaskMap`
2. Call TaskUpdate to update subject with retry count
3. Call TaskUpdate to update activeForm with retry messaging

### FR-5: Modification Request Sync (Integration Point F)
When TASK_MODIFICATION_REQUEST is processed:
1. For SPLIT_TASK: Mark original as `completed`, create new tasks for splits, update `nativeTaskMap`
2. For ADD_PREREQUISITE: Create prerequisite task, set `addBlockedBy` on original
3. For ADD_FOLLOWUP: Create followup task after original in the list
4. Update `totalTasks` in state and `nativeTaskMap` with new entries

### FR-6: Completion Sync (Integration Point G)
When taskIndex >= totalTasks and all tasks verified:
1. Iterate all entries in `nativeTaskMap`
2. Ensure every native task has status `completed`
3. Log final sync state to .progress.md

### FR-7: Parallel Batch Sync (Integration Point H)
When parallel [P] group detected:
1. All tasks in group already created at init (FR-1)
2. Mark all group tasks `in_progress` simultaneously when batch starts
3. Mark each task `completed` individually as its executor finishes
4. Advance to next task only when all parallel tasks complete

### FR-8: Stop-Hook Resume Context (Integration Point C)
The stop-hook continuation prompt must include:
1. Instruction for coordinator to rebuild native task state from tasks.md if needed (do NOT embed full nativeTaskMap in prompt to avoid bloat)
2. Instruction for coordinator to sync native tasks on resume via FR-13
3. Current taskIndex for mapping to native task ID

### FR-9: State File Extension
Extend .ralph-state.json with:
```json
{
  "nativeTaskMap": { "0": "task-1", "1": "task-2", ... },
  "nativeSyncEnabled": true
}
```
- `nativeTaskMap`: maps 0-based task index to native task ID string
- `nativeSyncEnabled`: boolean, set to false on persistent sync failure

### FR-10: Bidirectional Sync Check
Before each task delegation:
1. Read current tasks.md state (checkbox status)
2. Compare with native task status via nativeTaskMap
3. If tasks.md shows a task completed that native doesn't, update native to `completed`
4. This handles cases where tasks.md is updated externally

### FR-11: Task Subject Formatting
Native task subjects follow this format:
- Regular task: `"1.1 Task title"`
- Parallel task: `"[P] 2.1 Task title"`
- Verify task: `"[VERIFY] 1.4 Quality checkpoint"`
- Retry: `"1.3 Task title [retry 2/5]"`

### FR-12: Task activeForm Formatting
Native task activeForm (spinner text) follows:
- Regular: `"Executing 1.1 Task title"`
- Parallel: `"Executing [P] 2.1 Task title"`
- Verify: `"Verifying 1.4 Quality checkpoint"`
- Retry: `"Retrying 1.3 Task title (attempt 2)"`

### FR-13: Resume Reconstruction
When execution resumes in a new session (session restart or stop-hook resume):
1. Coordinator reads tasks.md and .ralph-state.json
2. If `nativeTaskMap` exists but task IDs are stale (from prior session), rebuild:
   - Create fresh native tasks for all entries in tasks.md
   - Set status based on tasks.md checkboxes (`[x]` = completed, `[ ]` = pending)
   - Mark current taskIndex task as `in_progress`
   - Replace `nativeTaskMap` with new ID mappings
3. If `nativeTaskMap` is missing, perform full initial sync (same as FR-1)
4. This ensures native task UI is always accurate after any interruption

## Non-Functional Requirements

### NFR-1: Performance
- Initial task creation (FR-1) must complete within the coordinator's first turn
- Individual TaskCreate/TaskUpdate calls add negligible latency (<100ms each)
- No additional API calls beyond TaskCreate/TaskUpdate (avoid TaskList/TaskGet in hot path)

### NFR-2: Reliability
- Sync failure must never block execution (graceful degradation per US-3)
- If a single TaskUpdate fails, log warning and continue to next task
- If 3+ consecutive sync failures occur, set `nativeSyncEnabled: false`

### NFR-3: Backward Compatibility
- Specs created before this feature must work without native task sync
- Missing `nativeTaskMap` in state treated as sync-not-initialized (skip sync)
- Missing `nativeSyncEnabled` defaults to `true`
- No changes to tasks.md format or .ralph-state.json schema (additive only)

### NFR-4: Autonomy
- Zero user interaction during sync operations
- No approval gates, prompts, or confirmations
- All sync decisions made autonomously by coordinator

### NFR-5: Context Token Efficiency
- Avoid calling TaskList in the execution hot path (it returns all tasks, consuming tokens)
- Use nativeTaskMap for direct ID lookups instead of searching via TaskList
- Only call TaskList for validation during initial sync and final completion check

## Glossary

| Term | Definition |
|------|-----------|
| Native task | A Claude Code task created via TaskCreate, visible in the task UI |
| nativeTaskMap | JSON object mapping 0-based task index to native task ID |
| Task UI | Claude Code's built-in task list panel (toggled with Ctrl+T) |
| Sync | The process of keeping native tasks in sync with tasks.md state |
| Coordinator | The LLM-driven execution loop that delegates tasks to spec-executor |
| Stop-hook | The bash script (stop-watcher.sh) that blocks stops and continues the loop |
| Integration point | A specific location in the execution flow where sync logic is inserted |

## Out of Scope

- Custom task UI rendering (we use Claude Code's built-in task list as-is)
- Task grouping/nesting in native UI (flat list only, use subject prefixes for visual grouping)
- Real-time progress bar or percentage display beyond what native task UI provides
- Sync with external systems beyond Claude Code's task API
- Configuration UI for enabling/disabling sync (controlled via state file only)
- Task priority or ordering in native UI (created in tasks.md order)

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| Claude Code Task API (TaskCreate, TaskUpdate) | Runtime | Available |
| .ralph-state.json state file | Internal | Exists, needs extension |
| tasks.md parser | Internal | Exists in coordinator-pattern.md |
| stop-watcher.sh | Internal | Exists, needs prompt update |
| implement.md | Internal | Exists, needs coordinator prompt update |
| coordinator-pattern.md | Internal | Exists, needs sync logic additions |
