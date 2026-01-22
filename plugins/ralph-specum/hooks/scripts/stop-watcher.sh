#!/bin/bash
# Stop Hook for Ralph Specum - Loop Control + Cleanup
#
# This hook controls the execution loop (replacing ralph-wiggum dependency):
# 1. During execution: blocks exit and injects continuation prompt
# 2. On completion: allows exit and cleans up state
# 3. Always: cleans up orphaned temp files
#
# Note: .progress.md is preserved for history/learnings

# Read hook input from stdin
INPUT=$(cat)

# CRITICAL: Prevent infinite loops (FR-3)
# Must be the FIRST check - if we're already in a hook, exit immediately
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory and transcript path (guard against parse failures)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
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

SPEC_NAME=$(tr -d '[:space:]' < "$CURRENT_SPEC_FILE" 2>/dev/null)
if [ -z "$SPEC_NAME" ]; then
    exit 0
fi

STATE_FILE="$CWD/specs/$SPEC_NAME/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Validate state file is readable JSON
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    echo "[ralph-specum] WARNING: Corrupt state file, allowing exit" >&2
    exit 0
fi

# Read state
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
GLOBAL_ITER=$(jq -r '.globalIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
MAX_ITER=$(jq -r '.maxGlobalIterations // 100' "$STATE_FILE" 2>/dev/null || echo "100")

# Only block during execution phase (FR-4)
if [ "$PHASE" != "execution" ]; then
    exit 0
fi

# Check for completion signal in transcript (FR-2)
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    if grep -q "ALL_TASKS_COMPLETE" "$TRANSCRIPT_PATH" 2>/dev/null; then
        # Cleanup and allow stop
        rm -f "$STATE_FILE" 2>/dev/null || true
        echo "[ralph-specum] Execution complete, cleaned up state for: $SPEC_NAME" >&2
        # Cleanup orphaned temp progress files
        find "$CWD/specs/$SPEC_NAME" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true
        exit 0
    fi
fi

# Safety limit check (FR-7, FR-8)
if [ "$GLOBAL_ITER" -ge "$MAX_ITER" ]; then
    echo "[ralph-specum] Max iterations ($MAX_ITER) reached for: $SPEC_NAME" >&2
    rm -f "$STATE_FILE" 2>/dev/null || true
    exit 0
fi

# Update iteration counter atomically (temp file + mv pattern)
NEW_ITER=$((GLOBAL_ITER + 1))
if jq ".globalIteration = $NEW_ITER" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null; then
    mv "$STATE_FILE.tmp" "$STATE_FILE"
else
    rm -f "$STATE_FILE.tmp"
fi

# Block and inject continuation prompt (FR-1)
# Exit code 0 + JSON = block exit and inject the reason as prompt
cat << EOF
{"decision": "block", "reason": "Continue executing tasks for spec '$SPEC_NAME'. Read ./specs/$SPEC_NAME/.ralph-state.json for current state (task $((TASK_INDEX + 1))/$TOTAL_TASKS, iteration $NEW_ITER/$MAX_ITER). Follow coordinator instructions from ./specs/$SPEC_NAME/.coordinator-prompt.md."}
EOF
exit 0
