#!/bin/bash
# Stop Hook for Ralph Specum
# Logging-only watcher - does NOT control loop execution
# 1. Logs current execution state to stderr
# 2. Cleans up orphaned temp progress files (>60min old)
# Note: Ralph Loop plugin manages loop continuation
# Note: .progress.md and .ralph-state.json are preserved

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
SETTINGS_FILE="$CWD/.claude/ralph-specum.local.md"
if [ -f "$SETTINGS_FILE" ]; then
    # Extract enabled setting from YAML frontmatter (normalize case and strip quotes)
    ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" 2>/dev/null \
        | awk -F: '/^enabled:/{val=$2; gsub(/[[:space:]"'"'"']/, "", val); print tolower(val); exit}')
    if [ "$ENABLED" = "false" ]; then
        exit 0
    fi
fi

# Check for active spec
CURRENT_SPEC_FILE="$CWD/specs/.current-spec"
if [ ! -f "$CURRENT_SPEC_FILE" ]; then
    exit 0
fi

SPEC_NAME=$(cat "$CURRENT_SPEC_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$SPEC_NAME" ]; then
    exit 0
fi

STATE_FILE="$CWD/specs/$SPEC_NAME/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Validate state file is readable JSON
CORRUPT_STATE=false
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    echo "WARNING: Corrupt .ralph-state.json detected for spec: $SPEC_NAME" >&2
    CORRUPT_STATE=true
fi

# Read state for logging (guard all jq calls)
if [ "$CORRUPT_STATE" = false ]; then
    PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
    TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
    TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")

    # Log current state (logging only - Ralph Loop manages continuation)
    if [ "$PHASE" = "execution" ]; then
        echo "[ralph-specum] Session stopped during spec: $SPEC_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
        echo "[ralph-specum] Ralph Loop will resume execution on next iteration" >&2
    fi
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
# Only remove files older than 60 minutes to avoid race conditions with active executors
find "$CWD/specs/$SPEC_NAME" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Note: .progress.md and .ralph-state.json are preserved for loop continuation
# Use /ralph-specum:cancel to explicitly stop execution and cleanup state

exit 0
