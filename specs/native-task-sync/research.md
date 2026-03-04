# Research: native-task-sync

## Executive Summary

This spec adds native Claude Code task UI integration to the Ralph Specum execution loop. The implement command and stop-hook will sync tasks.md entries to native TaskCreate/TaskUpdate calls, displayed in a rolling window of ~10 tasks. The codebase analysis identified 8 integration points in the coordinator/stop-hook flow, with 3 high-priority ones (state init, post-verification, stop-hook resume). A shared sync utility script will handle all CRUD operations, called from both the coordinator and stop-hook. Research shows completed tasks should remain visible (matching ansible-playbook/GitHub Actions patterns) rather than hidden, with sync metadata for debugging. The Task API has no hard limits on task count but practical UX limits suggest 10-20 visible tasks max. Bidirectional sync is achievable via metadata mapping (tasksmdIndex stored in task metadata).

## External Research

### Claude Code Task API

Claude Code provides 4 task management tools for in-session progress tracking:

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| TaskCreate | Create task (status: pending) | subject, description, activeForm, metadata |
| TaskUpdate | Update task properties | taskId, status, subject, activeForm, owner, metadata, addBlocks/addBlockedBy |
| TaskList | List all tasks (summary) | none |
| TaskGet | Get full task details | taskId |

**Status transitions**: pending -> in_progress -> completed (or deleted from any state)

**UI behavior**:
- in_progress tasks show spinner with activeForm text
- completed tasks show checkmark
- pending tasks show as waiting
- Tasks with blockedBy show as blocked

**Practical limits**:
- No hard limit on task count, but TaskList returns ALL tasks and consumes context tokens
- Tasks persist across sessions (stored at `~/.claude/tasks/<ID>/tasks.json`)
- Multi-session coordination via `CLAUDE_CODE_TASK_LIST_ID` env var
- IDs are auto-incrementing strings
- TaskList only returns id, subject, status, owner, blockedBy (no description/metadata). Need TaskGet for full details (1+N overhead)
- Tasks are flat - no built-in grouping/phase concept. Must use naming conventions or metadata
- Last-write-wins concurrent access - no conflict resolution

**UI details**:
- `Ctrl+T` toggles task list visibility in terminal
- `activeForm` shows as animated spinner text during in_progress
- `addBlockedBy`/`addBlocks` enforce task ordering with auto-unblock when blocker completes

**Best practices for our use case**:
- Create all tasks at initialization (single pass), then update statuses incrementally during execution
- Use metadata field for sync mapping: `{"tasksmdIndex": N}`
- Set activeForm always for visible progress
- Mark in_progress before delegation, completed after verification
- Use naming conventions for phase grouping: "P1: 1.1 Task name"

### Progress UI Best Practices

**Industry patterns for completed task visibility**:
- Tools that SHOW completed: make, npm test, GitHub Actions, ansible-playbook (audit trail matters)
- Tools that HIDE completed: pytest -q, docker build, kubectl (focus on active/errors)

**Recommendation**: Hybrid Summary Header + Rolling Window (Option E from research). Layout:
```
=== Progress: 12/47 tasks [Phase 2: Refactoring] ===
  [x] Task 11 - Add validation hooks
  [x] Task 12 - Wire up event handler
  [>] Task 13 - Implement error boundary (in progress)
  [ ] Task 14 - Add retry logic
  [ ] Task 15 - Create test fixtures
  ...37 more tasks remaining
```

Key design decisions:
1. Always show aggregate progress ("12/47") at top for primary progress signal
2. Keep last 2-3 completed tasks visible (recent context + accomplishment feeling)
3. Show current active task prominently with spinner/activeForm
4. Show next 3-4 pending tasks for lookahead
5. Truncate with count ("37 more remaining")
6. Phase label in header for macro context
7. Failed tasks must never scroll off

**Rationale**: GitHub Actions, Docker BuildKit, and ansible all use this pattern. Jira users consistently complain when completed work is hidden entirely. The aggregate counter leverages the Zeigarnik effect (incomplete tasks drive motivation).

### Pitfalls to Avoid
- Don't create all tasks upfront (floods UI, wastes API calls for tasks that may get modified)
- Don't rely on native tasks as sole source of truth (session-scoped, lost on restart)
- Don't block execution if sync fails (graceful degradation)
- Don't over-decorate task subjects (keep them scannable)

## Codebase Analysis

### Execution Flow

1. **implement.md** validates spec, parses args, merges state into .ralph-state.json, outputs coordinator prompt
2. **Coordinator** reads state, extracts task from tasks.md, delegates to spec-executor via Task tool
3. **spec-executor** runs task, outputs TASK_COMPLETE
4. **Coordinator** runs 3 verification layers, updates state (taskIndex++), commits
5. **Stop-hook** fires, reads state, blocks stop with continuation prompt including next task block
6. Loop repeats from step 2

### Integration Points (Ranked by Priority)

| Point | Location | When | Priority |
|-------|----------|------|----------|
| A | implement.md Step 3 | State init, before loop | HIGH - create initial batch |
| B | coordinator-pattern.md | After TASK_COMPLETE + verification | HIGH - mark completed, create next |
| C | stop-watcher.sh | Loop resume | HIGH - refresh window |
| D | coordinator-pattern.md | Before task delegation | MEDIUM - mark in_progress |
| E | coordinator-pattern.md | On failure/retry | LOW - update retry count |
| F | coordinator-pattern.md | On modification request | LOW - handle task splits |
| G | implement.md Step 5 | All tasks complete | MEDIUM - final cleanup |
| H | stop-watcher.sh | Parallel group detection | MEDIUM - batch create |

### Existing Patterns
- State file uses jq merge pattern (never overwrite, always merge)
- tasks.md parsed with awk (0-based index, regex `/^- \[[ x]\]/`)
- Parallel groups: max 5 consecutive [P] tasks
- Task blocks: title line + indented Do/Files/Verify/Commit sections

### Dependencies
- jq (required, already used by stop-hook and coordinator)
- bash (stop-hook is bash script)
- Task tools (TaskCreate, TaskUpdate, TaskList) available in coordinator context

### Constraints
- Stop-hook is a bash script (can't call TaskCreate/TaskUpdate directly from bash)
- Stop-hook can only output JSON block/approve decisions
- Task creation must happen in the coordinator (LLM context), not in bash hooks
- Tasks DO persist across sessions (stored in ~/.claude/tasks/), but tasks.md remains the authoritative source of truth
- TaskList consumes context tokens - keep visible task count low (~10) to avoid bloat

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | N/A (plugin is markdown/bash) | - |
| Test | Manual testing with `claude --plugin-dir ./plugins/ralph-specum` | CLAUDE.md |
| Validate | `jq empty file.json` for JSON validation | stop-watcher.sh |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Technical feasibility | High | Task API is well-suited, integration points are clear |
| Complexity | Medium | Sync logic adds state management, but sync utility centralizes it |
| Risk | Low-Medium | Graceful degradation if sync fails; tasks.md remains source of truth |
| Effort | Medium | ~15-25 tasks across coordinator, stop-hook, and sync utility |
| Breaking changes | None | Additive feature, existing behavior preserved if sync disabled |

## Recommendations for Requirements

1. **Sync utility script** (`task-sync.sh`): Central script that reads tasks.md + .ralph-state.json, computes diff with current native tasks, and outputs TaskCreate/TaskUpdate commands
2. **Coordinator integration**: Call sync utility at Points A (init), B (post-complete), D (pre-delegate)
3. **Stop-hook integration**: Include sync state in continuation prompt so coordinator can refresh window on resume
4. **State extension**: Add `nativeTaskMap` (index -> taskId mapping) and `nativeWindowStart`/`nativeWindowEnd` to .ralph-state.json
5. **Graceful degradation**: If sync fails, log warning and continue execution. Never block the loop.
6. **Autonomy**: Entire sync runs without user interaction. No approval gates, no prompts.

## Open Questions

1. Should the sync utility be a bash script that outputs JSON commands, or inline logic in the coordinator prompt? (Note: bash can't call TaskCreate directly, so sync logic must be in coordinator/LLM context)
2. Since tasks persist across sessions, should we attempt to reuse existing native tasks on resume, or always recreate?
3. Should [VERIFY] tasks appear differently in native UI (e.g., different subject prefix)?
4. Window size: fixed at 10, or configurable via .ralph-state.json?

## Sources

- plugins/ralph-specum/commands/implement.md
- plugins/ralph-specum/hooks/scripts/stop-watcher.sh
- plugins/ralph-specum/references/coordinator-pattern.md
- plugins/ralph-specum/agents/spec-executor.md
- Claude Code TaskCreate/TaskUpdate/TaskList/TaskGet tool schemas
- Industry CLI tool analysis (make, ansible, GitHub Actions, docker, kubectl)
