---
spec: remove-ralph-wiggum
phase: design
created: 2026-02-05
generated: auto
---

# Design: remove-ralph-wiggum

## Overview

Inline loop control into stop-hook. The stop-hook becomes the execution loop controller by reading state and outputting continuation prompts.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        BEFORE (Current)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  implement.md ──► ralph-loop:ralph-loop skill ──► Loop Control  │
│                          │                                      │
│                          ▼                                      │
│  stop-watcher.sh ──► Logging only (no control)                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        AFTER (New)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  implement.md ──► Write state ──► Output coordinator prompt     │
│                                                                 │
│  stop-watcher.sh ──► Read state ──► Output continuation prompt  │
│                          │         (if more tasks)              │
│                          ▼                                      │
│                    Loop terminates when ALL_TASKS_COMPLETE      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Stop-Hook (Loop Controller)

**Purpose**: Control execution loop by reading state and outputting prompts

**Responsibilities**:
- Read `.ralph-state.json` from active spec
- Check if `phase == "execution"` and `taskIndex < totalTasks`
- If more tasks: output coordinator prompt for next iteration
- If complete or no state: output nothing (loop ends)
- Detect `ALL_TASKS_COMPLETE` in session transcript to terminate

**State Machine**:

```
┌─────────────┐
│ Read State  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐     no state
│ State Exists?   │──────────────► [Exit Silently]
└──────┬──────────┘
       │ yes
       ▼
┌─────────────────┐     not execution
│ Phase Check     │──────────────► [Exit Silently]
└──────┬──────────┘
       │ execution
       ▼
┌─────────────────┐     taskIndex >= totalTasks
│ Tasks Remain?   │──────────────► [Exit Silently]
└──────┬──────────┘
       │ yes
       ▼
┌─────────────────┐
│ Output Prompt   │──────────────► Continue loop
└─────────────────┘
```

### implement.md (Simplified)

**Purpose**: Initialize state and start execution

**Responsibilities**:
- Validate spec and tasks.md exist
- Parse arguments (--max-task-iterations, --recovery-mode)
- Write `.ralph-state.json` with initial state
- Output coordinator prompt directly (no external skill)
- Remove ralph-loop dependency check

### cancel.md (Simplified)

**Purpose**: Stop execution and cleanup

**Responsibilities**:
- Delete `.ralph-state.json`
- Delete `.progress.md` (optional, preserve for history?)
- Clear `.current-spec`
- Remove spec directory
- No skill invocation

## Data Flow

### Execution Start

```
User: /ralph-specum:implement
         │
         ▼
implement.md:
  1. Validate spec exists
  2. Count tasks in tasks.md
  3. Write .ralph-state.json:
     {
       "phase": "execution",
       "taskIndex": 0,
       "totalTasks": N,
       "taskIteration": 1,
       "maxTaskIterations": 5
     }
  4. Output coordinator prompt inline
         │
         ▼
Claude processes coordinator prompt
  - Delegates task 0 to spec-executor
  - spec-executor completes, outputs TASK_COMPLETE
         │
         ▼
Stop Hook triggers (after each response)
  - Reads .ralph-state.json
  - If taskIndex < totalTasks: output continuation prompt
         │
         ▼
Claude processes continuation prompt
  - Reads updated state
  - Delegates next task
  ... (loop continues)
         │
         ▼
Final task completes
  - spec-executor outputs TASK_COMPLETE
  - Coordinator updates state, outputs ALL_TASKS_COMPLETE
         │
         ▼
Stop Hook triggers
  - Detects ALL_TASKS_COMPLETE OR taskIndex >= totalTasks
  - Outputs nothing
  - Loop ends
```

### Cancellation

```
User: /ralph-specum:cancel
         │
         ▼
cancel.md:
  1. Read spec path from .current-spec
  2. rm .ralph-state.json
  3. rm .progress.md (or preserve?)
  4. rm -rf spec directory
  5. rm .current-spec
  - No skill invocation needed
```

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Loop control location | stop-hook, implement.md, new script | stop-hook | Already triggers after each response, natural fit |
| Continuation prompt | Inline in stop-hook, file reference | Inline | Simpler, no file management |
| State file changes | New schema, extend existing | Keep existing | No breaking changes to state format |
| Completion detection | Parse transcript, check state | Check state (taskIndex >= totalTasks) | More reliable than text parsing |

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/commands/implement.md` | Modify | Remove ralph-loop invocation, output prompt directly |
| `plugins/ralph-specum/commands/cancel.md` | Modify | Remove skill invocation, simplify to file deletion |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Modify | Add loop control logic |
| `plugins/ralph-specum/hooks/scripts/coordinator-prompt.sh` | Create | Extract coordinator prompt generation |
| `plugins/ralph-specum/.claude-plugin/plugin.json` | Modify | Bump to 3.0.0 |
| `.claude-plugin/marketplace.json` | Modify | Bump to 3.0.0 |
| `tests/stop-hook.bats` | Create | bats-core tests for stop-hook |
| `tests/helpers/setup.bash` | Create | Test fixtures and helpers |
| `.github/workflows/bats-tests.yml` | Create | CI workflow for bats tests |

## Error Handling

| Error | Handling | User Impact |
|-------|----------|-------------|
| Missing state file | Exit silently | Loop ends, normal behavior |
| Corrupt JSON | Log warning, exit silently | Loop ends, user sees warning |
| Missing spec directory | Exit silently | Loop ends |
| jq not installed | Exit silently | Loop ends (degrades gracefully) |

## Stop-Hook Output Format

When continuation is needed, output:

```text
Continue executing spec: $SPEC_NAME

Read $SPEC_PATH/.ralph-state.json for current state.
Read $SPEC_PATH/tasks.md to find task at taskIndex.
Delegate task to spec-executor via Task tool.
After completion, update state and check if more tasks remain.
Output ALL_TASKS_COMPLETE when taskIndex >= totalTasks.
```

## Existing Patterns to Follow

1. **State reading** (from current stop-watcher.sh):
```bash
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
```

2. **Path resolution** (from path-resolver.sh):
```bash
SPEC_PATH=$(ralph_resolve_current 2>/dev/null)
```

3. **Settings check** (from stop-watcher.sh):
```bash
ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" 2>/dev/null \
    | awk -F: '/^enabled:/{val=$2; gsub(/[[:space:]"'"'"']/, "", val); print tolower(val); exit}')
```

## Migration Notes

1. **Breaking change**: v3.0.0 removes ralph-loop dependency
2. **No user action**: Works automatically after update
3. **Backwards incompatible**: Cannot use with old ralph-loop plugin
