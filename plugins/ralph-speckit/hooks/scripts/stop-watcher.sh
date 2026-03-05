#!/bin/bash
# Stop Hook for Ralph Speckit
# Loop controller that manages task execution continuation
# 1. Logs current execution state to stderr
# 2. Outputs continuation prompt when more tasks remain (phase=execution, taskIndex < totalTasks)
# 3. Cleans up orphaned temp progress files (>60min old)
# Note: .progress.md and .speckit-state.json are preserved

# Read hook input from stdin
INPUT=$(cat)

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory (guard against parse failures)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Check for settings file to see if plugin is enabled
SETTINGS_FILE="$CWD/.claude/ralph-speckit.local.md"
if [ -f "$SETTINGS_FILE" ]; then
    # Extract enabled setting from YAML frontmatter (normalize case and strip quotes)
    ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" 2>/dev/null \
        | awk -F: '/^enabled:/{val=$2; gsub(/[[:space:]"'"'"']/, "", val); print tolower(val); exit}')
    if [ "$ENABLED" = "false" ]; then
        exit 0
    fi
fi

# Resolve current feature (fixed .specify/ path, no path resolver needed unlike specum)
CURRENT_FEATURE_FILE="$CWD/.specify/.current-feature"
if [ ! -f "$CURRENT_FEATURE_FILE" ]; then
    exit 0
fi

# Extract feature name and derive spec path
FEATURE_NAME=$(cat "$CURRENT_FEATURE_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$FEATURE_NAME" ]; then
    exit 0
fi

SPEC_PATH=".specify/specs/$FEATURE_NAME"
STATE_FILE="$CWD/$SPEC_PATH/.speckit-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Race condition safeguard: if state file was modified in last 2 seconds, wait briefly
# This allows the coordinator to finish writing before we read
if command -v stat >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS stat
        MTIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo "0")
    else
        # Linux stat
        MTIME=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo "0")
    fi
    NOW=$(date +%s)
    AGE=$((NOW - MTIME))
    if [ "$AGE" -lt 2 ]; then
        sleep 1
    fi
fi

# Check for ALL_TASKS_COMPLETE in transcript (backup termination detection)
# Use specific pattern to avoid false positives from code/comments containing the phrase
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Primary: 500 lines covers most sessions for reliable detection
    if tail -500 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '^ALL_TASKS_COMPLETE$|^ALL_TASKS_COMPLETE[[:space:]]'; then
        echo "[ralph-speckit] ALL_TASKS_COMPLETE detected in transcript" >&2
        # Note: State file cleanup is handled by the coordinator (implement.md Section 10)
        # Do not delete here to avoid race condition
        exit 0
    fi
    # Fallback: check last 20 lines for edge cases (very recent signal)
    if tail -20 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '^ALL_TASKS_COMPLETE$'; then
        echo "[ralph-speckit] ALL_TASKS_COMPLETE detected in transcript (tail-end)" >&2
        exit 0
    fi
fi

# Validate state file is readable JSON
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    REASON=$(cat <<EOF
ERROR: Corrupt state file at $SPEC_PATH/.speckit-state.json

Recovery options:
1. Reset state: /speckit:implement (reinitializes from tasks.md)
2. Cancel spec: /speckit:cancel
EOF
)

    jq -n \
      --arg reason "$REASON" \
      --arg msg "Ralph-speckit: corrupt state file" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
    exit 0
fi

# Read state for logging
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")

# Check global iteration limit
GLOBAL_ITERATION=$(jq -r '.globalIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
MAX_GLOBAL=$(jq -r '.maxGlobalIterations // 100' "$STATE_FILE" 2>/dev/null || echo "100")

if [ "$GLOBAL_ITERATION" -ge "$MAX_GLOBAL" ]; then
    echo "[ralph-speckit] ERROR: Maximum global iterations ($MAX_GLOBAL) reached. Review .progress.md for failure patterns." >&2
    echo "[ralph-speckit] Recovery: fix issues manually, then run /speckit:implement or /speckit:cancel" >&2
    exit 0
fi

# Log current state
if [ "$PHASE" = "execution" ]; then
    echo "[ralph-speckit] Session stopped during feature: $FEATURE_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
fi

# Loop control: output continuation prompt if more tasks remain
if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]; then
    # Read recovery mode for prompt customization
    RECOVERY_MODE=$(jq -r '.recoveryMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
    MAX_TASK_ITER=$(jq -r '.maxTaskIterations // 5' "$STATE_FILE" 2>/dev/null || echo "5")

    # Safety guard: prevent infinite re-invocation loop
    # If a stop event fires while already processing a stop-hook continuation,
    # re-blocking would cause infinite loops. Allow Claude to stop; the next
    # session start will detect remaining tasks via .speckit-state.json.
    # Note: Claude Code does not currently set stop_hook_active in hook input,
    # so this guard is defensive-only and never fires in normal operation.
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        echo "[ralph-speckit] stop_hook_active=true, skipping continuation to prevent re-invocation loop" >&2
        exit 0
    fi

    # DESIGN NOTE: Prompt Duplication
    # This continuation prompt is intentionally abbreviated compared to implement.md.
    # - implement.md = full specification (source of truth for coordinator behavior)
    # - stop-watcher.sh = abbreviated resume prompt (minimal context for loop continuation)
    # This is an intentional design choice, not accidental duplication. The full
    # specification lives in implement.md; this prompt provides just enough context
    # for the coordinator to resume execution efficiently.

    REASON=$(cat <<EOF
Continue feature: $FEATURE_NAME (Task $((TASK_INDEX + 1))/$TOTAL_TASKS, Iter $GLOBAL_ITERATION)

## State
Path: $SPEC_PATH | Index: $TASK_INDEX | Iteration: $TASK_ITERATION/$MAX_TASK_ITER | Recovery: $RECOVERY_MODE

## Resume
1. Read $SPEC_PATH/.speckit-state.json and $SPEC_PATH/tasks.md
2. Delegate task $TASK_INDEX to spec-executor (or qa-engineer for [VERIFY])
3. On TASK_COMPLETE: verify, update state, advance
4. If taskIndex >= totalTasks: delete state file, output ALL_TASKS_COMPLETE

## Critical
- Delegate via Task tool - do NOT implement yourself
- Verify all 4 layers before advancing (see implement.md Section 7)
- On failure: increment taskIteration, retry or generate fix task if recoveryMode
EOF
)

    SYSTEM_MSG="Ralph-speckit iteration $GLOBAL_ITERATION | Task $((TASK_INDEX + 1))/$TOTAL_TASKS"

    jq -n \
      --arg reason "$REASON" \
      --arg msg "$SYSTEM_MSG" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
# Only remove files older than 60 minutes to avoid race conditions with active executors
find "$CWD/$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Note: .progress.md and .speckit-state.json are preserved for loop continuation
# Use /speckit:cancel to explicitly stop execution and cleanup state

exit 0
