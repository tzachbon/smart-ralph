# Requirements: Parallel Task Execution

## Goal

Enable ralph-specum to execute multiple independent tasks simultaneously by adding [P] markers to tasks.md. This reduces total spec execution time when tasks operate on unrelated files or perform non-conflicting operations.

## User Stories

### US-1: Mark Tasks as Parallelizable

**As a** spec author (task-planner agent)
**I want to** mark independent tasks with [P] in tasks.md
**So that** the executor knows these tasks can run concurrently

**Acceptance Criteria:**
- AC-1.1: Tasks with `[P]` tag in the task line are recognized as parallelizable
- AC-1.2: Consecutive [P] tasks form a single parallel group
- AC-1.3: Non-[P] tasks break parallel groups and execute sequentially
- AC-1.4: [VERIFY] tasks are never parallelized regardless of [P] marker

### US-2: Execute Parallel Groups

**As a** spec executor (implement.md coordinator)
**I want to** spawn multiple spec-executor subagents simultaneously
**So that** parallel groups complete faster than sequential execution

**Acceptance Criteria:**
- AC-2.1: Coordinator detects parallel groups from tasks.md
- AC-2.2: All tasks in a group are invoked via Task tool in a single message
- AC-2.3: Coordinator waits for all parallel tasks to complete before proceeding
- AC-2.4: Sequential tasks continue to execute one at a time

### US-3: Isolated Progress Tracking

**As a** parallel spec-executor
**I want to** write progress to an isolated temp file
**So that** concurrent writes do not corrupt shared .progress.md

**Acceptance Criteria:**
- AC-3.1: Each parallel executor writes to `.progress-task-N.md` where N is task index
- AC-3.2: Coordinator merges temp files into .progress.md after group completes
- AC-3.3: Temp files are deleted after successful merge
- AC-3.4: Sequential tasks continue writing directly to .progress.md

### US-4: Handle Partial Failures

**As a** coordinator
**I want to** continue execution when some parallel tasks fail
**So that** successful tasks are not wasted and failed tasks can retry

**Acceptance Criteria:**
- AC-4.1: Failed tasks are marked in state but do not block successful ones
- AC-4.2: Successful tasks are marked complete in tasks.md
- AC-4.3: Failed tasks remain unchecked and retry in next iteration
- AC-4.4: Progress from successful tasks is preserved in .progress.md

### US-5: Backwards Compatibility

**As a** user with existing specs
**I want to** run specs without [P] markers unchanged
**So that** existing workflows continue to work

**Acceptance Criteria:**
- AC-5.1: Specs without [P] markers execute sequentially as before
- AC-5.2: No changes required to existing tasks.md format
- AC-5.3: Stop-handler behavior unchanged for sequential execution

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | Recognize [P] marker in task descriptions | High | Regex matches `\[P\]` in task line |
| FR-002 | Group consecutive [P] tasks into parallel batches | High | Parser returns array of task groups |
| FR-003 | Non-[P] task or [VERIFY] task breaks parallel group | High | Group ends at first non-[P] or [VERIFY] task |
| FR-004 | [VERIFY] and [SEQUENTIAL] tags force sequential execution | High | These tags override [P] marker if both present |
| FR-005 | Coordinator spawns N spec-executors via Task tool | High | Multiple Task tool calls in single message |
| FR-006 | Each executor receives task index and isolated progress file path | High | Pass `.progress-task-N.md` path in prompt |
| FR-007 | Executor writes learnings to isolated temp file | High | No writes to .progress.md for parallel tasks |
| FR-008 | Coordinator waits for all parallel Task calls to complete | High | Task tool blocking behavior |
| FR-009 | Coordinator merges temp progress files after batch | High | Append learnings, completed tasks to .progress.md |
| FR-010 | Coordinator deletes temp files after merge | Medium | Cleanup step after successful merge |
| FR-011 | Track parallel batch completion with BATCH_COMPLETE | High | Different signal than TASK_COMPLETE |
| FR-012 | State tracks parallel group boundaries | High | parallelGroup field in .ralph-state.json |
| FR-013 | State tracks per-task completion status in batch | High | taskResults array in state |
| FR-014 | Failed tasks marked for retry in next iteration | High | Mark failed index, continue to next group |
| FR-015 | Successful parallel tasks marked [x] in tasks.md | High | Coordinator updates tasks.md after batch |
| FR-016 | Sequential commits after parallel batch | High | Serialize git operations post-execution |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-001 | Parallel execution reduces total time | Wall clock time | N parallel tasks complete faster than N sequential |
| NFR-002 | No race conditions on shared files | Concurrent write conflicts | Zero conflicts via isolated temp files |
| NFR-003 | Backwards compatible | Existing spec execution | 100% of non-[P] specs unchanged |
| NFR-004 | Progress durability | Data loss on partial failure | Zero loss, successful task progress preserved |

## Glossary

- **[P] marker**: Tag `[P]` in task description indicating task is safe to parallelize
- **Parallel group**: Set of consecutive [P] tasks executed simultaneously
- **Coordinator**: implement.md, orchestrates task execution and delegates to spec-executor
- **Executor**: spec-executor subagent, implements a single task
- **Temp progress file**: `.progress-task-N.md`, isolated file for parallel executor writes
- **BATCH_COMPLETE**: Signal from coordinator that a parallel group finished
- **TASK_COMPLETE**: Signal from executor that a single task finished

## Out of Scope

- Stop-handler modifications (coordinator handles all parallel logic)
- Automatic detection of parallelizable tasks (manual [P] marking only)
- Complex dependency graphs between tasks (consecutive grouping only)
- Nested parallel groups (flat structure only)
- Dynamic parallelism adjustment at runtime
- Cross-spec parallel execution
- GUI or visual representation of parallel execution

## Dependencies

- **qa-verification spec**: [VERIFY] tasks must remain sequential (V4 -> V5 -> V6 order)
- **goal-interview spec**: .progress.md shared state, affected by merge strategy
- **Task tool**: Claude Code Task tool supports multiple parallel invocations
- **spec-executor agent**: Must accept isolated progress file path parameter

## Success Criteria

- Two or more [P] tasks execute simultaneously and complete correctly
- Existing specs without [P] markers execute unchanged
- Partial failures do not corrupt progress or lose completed work
- Wall clock time for parallel group is less than sum of individual task times

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Git commit conflicts from parallel tasks | Medium | Serialize commits after batch completes |
| Progress file corruption from concurrent writes | High | Isolated temp files, coordinator merge |
| Subagent nesting limitation (no parallel-in-parallel) | Low | Design enforces flat parallel groups |
| Task tool parallel limit unknown | Medium | Start with 3 concurrent, make configurable |
| Partial state on crash mid-batch | Medium | State stores per-task results, resume from last |
