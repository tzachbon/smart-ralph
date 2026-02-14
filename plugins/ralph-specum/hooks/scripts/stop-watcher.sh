#!/bin/bash
# Stop Hook for Ralph Specum (passive mode)
# Monitors execution state and performs cleanup - does NOT control the loop
# 1. Logs current execution state to stderr
# 2. Cleans up orphaned temp progress files (>60min old)
# Note: Loop control is handled by Ralph Wiggum's stop hook
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
        echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript" >&2
        # Note: State file cleanup is handled by the coordinator (implement.md Section 10)
        # Do not delete here to avoid race condition
        exit 0
    fi
    # Fallback: check last 20 lines for edge cases (very recent signal)
    if tail -20 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '^ALL_TASKS_COMPLETE$'; then
        echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript (tail-end)" >&2
        exit 0
    fi
fi

# Validate state file is readable JSON
CORRUPT_STATE=false
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    cat <<EOF
ERROR: Corrupt state file at $SPEC_PATH/.ralph-state.json

Recovery options:
1. Reset state: /ralph-specum:implement (reinitializes from tasks.md)
2. Cancel spec: /ralph-specum:cancel
EOF
    exit 0
fi

# Read state for logging (guard all jq calls)
if [ "$CORRUPT_STATE" = false ]; then
    PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
    TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
    TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")

    # Check global iteration limit
    GLOBAL_ITERATION=$(jq -r '.globalIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
    MAX_GLOBAL=$(jq -r '.maxGlobalIterations // 100' "$STATE_FILE" 2>/dev/null || echo "100")

    if [ "$GLOBAL_ITERATION" -ge "$MAX_GLOBAL" ]; then
        cat <<EOF
ERROR: Maximum global iterations ($MAX_GLOBAL) reached.

This safety limit prevents infinite execution loops.

Recovery options:
1. Review .progress.md for failure patterns
2. Fix issues manually, then run: /ralph-specum:implement
3. Cancel and restart: /ralph-specum:cancel
EOF
        exit 0
    fi

    # Log current state
    if [ "$PHASE" = "execution" ]; then
        echo "[ralph-specum] Session stopped during spec: $SPEC_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
    fi

    # Note: Loop control is handled by Ralph Wiggum's stop hook
    # This script is passive - no continuation prompts are output to stdout
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
# Only remove files older than 60 minutes to avoid race conditions with active executors
find "$CWD/$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Note: .progress.md and .ralph-state.json are preserved for loop continuation
# Use /ralph-specum:cancel to explicitly stop execution and cleanup state

exit 0
