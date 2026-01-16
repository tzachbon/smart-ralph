#!/bin/bash
# Stop Watcher Hook for Ralph Speckit
# This is a WATCHER only - does NOT control the loop
# Ralph Wiggum plugin handles loop continuation via exit code 2
# This hook always exits 0 to let Ralph Wiggum do its job

# Read hook input from stdin
INPUT=$(cat)

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory (guard against parse failures)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Check for active feature
CURRENT_FEATURE_FILE="$CWD/.specify/.current-feature"
if [ ! -f "$CURRENT_FEATURE_FILE" ]; then
    exit 0
fi

FEATURE_NAME=$(cat "$CURRENT_FEATURE_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$FEATURE_NAME" ]; then
    exit 0
fi

STATE_FILE="$CWD/.specify/specs/$FEATURE_NAME/.speckit-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Validate state file is readable JSON
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    echo "WARNING: Corrupt .speckit-state.json detected for feature: $FEATURE_NAME" >&2
    exit 0
fi

# Read state for logging (guard all jq calls)
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")

# Only log if in execution phase
if [ "$PHASE" = "execution" ]; then
    echo "[ralph-speckit] Feature: $FEATURE_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
find "$CWD/.specify/specs/$FEATURE_NAME" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Always exit 0 - Ralph Wiggum handles loop continuation
exit 0
