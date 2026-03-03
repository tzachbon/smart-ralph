# Research: update-index-on-complete

## Executive Summary

The spec index (`specs/.index/index-state.json`) is currently updated via `update-spec-index.sh` which is called from the implement.md coordinator's completion section. However, this is LLM-driven and not guaranteed. The stop-watcher.sh hook already detects ALL_TASKS_COMPLETE in the transcript but only exits silently without updating the index. The simplest fix is to add `update-spec-index.sh --quiet` call inside stop-watcher.sh when ALL_TASKS_COMPLETE is detected, ensuring the index is always updated regardless of whether the LLM coordinator remembers to call it.

## Codebase Analysis

### Stop-Watcher Hook (stop-watcher.sh)

The stop-watcher at `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` is a Stop hook that:
- Runs on every Stop event
- Reads `.ralph-state.json` for the current spec
- Detects ALL_TASKS_COMPLETE in transcript (lines 66-81) and exits 0 (allows stop)
- Verifies all tasks are checked in tasks.md when state says complete (lines 154-186)
- Outputs continuation prompts when more tasks remain (lines 188-313)

**Key finding**: When ALL_TASKS_COMPLETE is detected (lines 68-80), the hook just logs to stderr and exits 0. No index update happens here.

### Spec Index System (update-spec-index.sh)

Located at `plugins/ralph-specum/hooks/scripts/update-spec-index.sh`:
- Rebuilds `specs/.index/index-state.json` and `specs/.index/index.md` from scratch
- Scans all specs, reads .ralph-state.json or infers phase from file presence
- When .ralph-state.json is deleted and tasks.md has all [x], phase = "completed"

### Current Index Update Triggers

| Trigger | Location | Reliable? |
|---------|----------|-----------|
| Spec creation | start.md | Yes (always runs) |
| Execution completion | implement.md Section 10 | No (LLM-driven) |
| Cancel | cancel.md | Yes (always runs) |
| Status check | status.md | Yes (user-triggered) |

### Hooks Configuration (hooks.json)

Current hooks: PreToolUse (AskUserQuestion guard), Stop (stop-watcher), SessionStart (load-spec-context). No PostToolUse or completion-specific hooks.

### Gap

The implement.md coordinator *should* call `update-spec-index.sh --quiet` before ALL_TASKS_COMPLETE, but this is an LLM instruction, not a guaranteed execution path. If the coordinator skips it or errors, the index remains stale.

## Recommended Approach

Add `update-spec-index.sh --quiet` to stop-watcher.sh when ALL_TASKS_COMPLETE is detected. This is:
- **Hook-level** (runs automatically, not LLM-dependent)
- **Surgical** (2-3 lines added to existing detection block)
- **Safe** (script already has --quiet mode, runs quickly)
- **Idempotent** (rebuilds index from scratch, safe to call multiple times)

### Integration Point

In stop-watcher.sh lines 68-80, after detecting ALL_TASKS_COMPLETE and before `exit 0`, call:
```bash
"$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true
```

### Risk Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Feasibility | High | 2-3 lines added to existing script |
| Risk | Low | update-spec-index.sh is idempotent, failures are ignored |
| Performance | Low impact | Script runs in <1s, --quiet mode |
| Backward compat | Full | Existing behavior unchanged |

## Open Questions

None - straightforward implementation.

## Sources

- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (lines 66-81)
- `plugins/ralph-specum/hooks/scripts/update-spec-index.sh` (full script)
- `plugins/ralph-specum/hooks/hooks.json`
- `plugins/ralph-specum/commands/implement.md` (Section 10)
- `specs/.index/index-state.json` (current index state)
