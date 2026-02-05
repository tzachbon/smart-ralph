#!/bin/bash
# Stop Hook for Ralph Specum
# Loop controller that manages task execution continuation
# 1. Logs current execution state to stderr
# 2. Outputs continuation prompt when more tasks remain (phase=execution, taskIndex < totalTasks)
# 3. Cleans up orphaned temp progress files (>60min old)
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

# Source path resolver for spec directory resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_CWD="$CWD"
export RALPH_CWD
source "$SCRIPT_DIR/path-resolver.sh"

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

# Resolve current spec using path resolver (handles multi-directory support)
SPEC_PATH=$(ralph_resolve_current 2>/dev/null)
if [ -z "$SPEC_PATH" ]; then
    exit 0
fi

# Extract spec name from path (last component)
SPEC_NAME=$(basename "$SPEC_PATH")

STATE_FILE="$CWD/$SPEC_PATH/.ralph-state.json"
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

    # Log current state
    if [ "$PHASE" = "execution" ]; then
        echo "[ralph-specum] Session stopped during spec: $SPEC_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
    fi

    # Loop control: output continuation prompt if more tasks remain
    if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]; then
        cat <<EOF
Continue executing spec: $SPEC_NAME

Read $SPEC_PATH/.ralph-state.json for current state.
Read $SPEC_PATH/tasks.md to find task at taskIndex.
Delegate task to spec-executor via Task tool.
After completion, update state and check if more tasks remain.
Output ALL_TASKS_COMPLETE when taskIndex >= totalTasks.
EOF
    fi
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
# Only remove files older than 60 minutes to avoid race conditions with active executors
find "$CWD/$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Note: .progress.md and .ralph-state.json are preserved for loop continuation
# Use /ralph-specum:cancel to explicitly stop execution and cleanup state

exit 0
