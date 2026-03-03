---
generated: auto
---

# Design: Update Index on Spec Completion

## Overview

Add a single `update-spec-index.sh --quiet` call to both ALL_TASKS_COMPLETE detection paths in stop-watcher.sh. This moves index updates from LLM-dependent (implement.md coordinator) to hook-level (guaranteed execution). Two lines added, zero behavior changes.

## Architecture

No new components. Single file modification:

```
stop-watcher.sh detects ALL_TASKS_COMPLETE
  -> calls update-spec-index.sh --quiet (NEW)
  -> exits 0 (existing)
```

## Components

### stop-watcher.sh (Modified)

**Change**: Insert index update call before `exit 0` in both ALL_TASKS_COMPLETE detection branches.

**Primary path** (line 70-74, 500-line transcript grep):
```bash
if tail -500 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '^ALL_TASKS_COMPLETE$|^ALL_TASKS_COMPLETE[[:space:]]'; then
    echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript" >&2
    # Note: State file cleanup is handled by the coordinator (implement.md Section 10)
    # Do not delete here to avoid race condition
    "$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true   # <-- NEW
    exit 0
fi
```

**Fallback path** (line 77-79, 20-line transcript grep):
```bash
if tail -20 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '^ALL_TASKS_COMPLETE$'; then
    echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript (tail-end)" >&2
    "$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true   # <-- NEW
    exit 0
fi
```

### update-spec-index.sh (Unchanged)

Already exists at `$SCRIPT_DIR/update-spec-index.sh`. Supports `--quiet` flag. Idempotent (rebuilds from scratch). No modifications needed.

## Data Flow

```
Stop event fires
  -> stop-watcher.sh reads transcript
  -> grep finds ALL_TASKS_COMPLETE
  -> update-spec-index.sh --quiet rebuilds specs/.index/
  -> exit 0 (allow stop)
```

## Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| Error handling | let it fail / suppress | Suppress (`2>/dev/null \|\| true`) | Index update is best-effort; must never block completion |
| Which paths | primary only / both / all exits | Both ALL_TASKS_COMPLETE paths | FR-1, FR-2. "All tasks verified" path (line 183) excluded per requirements (coordinator already ran) |
| Script resolution | hardcoded path / $SCRIPT_DIR | $SCRIPT_DIR | Matches existing pattern (line 21: `source "$SCRIPT_DIR/path-resolver.sh"`) |

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Modify | Add index update call in 2 locations |

## Error Handling

| Error Scenario | Handling Strategy | User Impact |
|----------------|-------------------|-------------|
| update-spec-index.sh missing | `|| true` suppresses error | None, exit 0 still fires |
| update-spec-index.sh fails | `2>/dev/null || true` | None, index stays stale (same as today) |
| jq unavailable in update script | Caught by update script internally | None |

## Edge Cases

- **Double update**: Coordinator may also call update-spec-index.sh. Safe -- script is idempotent (rebuilds from scratch).
- **State file already deleted**: update-spec-index.sh handles missing .ralph-state.json by inferring phase from file presence.
- **Slow index update**: Script runs <1s. Even if slow, it runs after the "complete" log line and before exit 0, so no user-visible delay.

## Test Strategy

### Manual Verification
1. Run a spec to completion via `/ralph-specum:implement`
2. Confirm `specs/.index/index-state.json` shows spec as "completed"
3. Verify stop-watcher exits cleanly (no errors in stderr)

### Edge Case Check
- Delete `update-spec-index.sh` temporarily, run completion, verify no crash (|| true handles it)

## Existing Patterns to Follow

- Error suppression: `2>/dev/null || true` (used elsewhere in stop-watcher.sh, e.g., line 12, 318)
- Script path resolution: `"$SCRIPT_DIR/..."` (line 21)
- Logging: `echo "[ralph-specum] ..." >&2` (lines 71, 78, 117, etc.)

## Implementation Steps

1. Add `"$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true` before `exit 0` on line 74 (primary detection path)
2. Add `"$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true` before `exit 0` on line 79 (fallback detection path)
3. Bump plugin version in `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
