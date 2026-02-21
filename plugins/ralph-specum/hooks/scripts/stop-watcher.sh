#!/usr/bin/env bash
# Stop Hook for Ralph Specum — Loop controller for task execution continuation
# Exits silently (code 0) when no active spec, outputs block JSON when tasks remain.

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
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    REASON=$(cat <<EOF
ERROR: Corrupt state file at $SPEC_PATH/.ralph-state.json

Recovery options:
1. Reset state: /ralph-specum:implement (reinitializes from tasks.md)
2. Cancel spec: /ralph-specum:cancel
EOF
)

    jq -n \
      --arg reason "$REASON" \
      --arg msg "Ralph-specum: corrupt state file" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
    exit 0
fi

# Read state
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")

# Check global iteration limit
GLOBAL_ITERATION=$(jq -r '.globalIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
MAX_GLOBAL=$(jq -r '.maxGlobalIterations // 100' "$STATE_FILE" 2>/dev/null || echo "100")

if [ "$GLOBAL_ITERATION" -ge "$MAX_GLOBAL" ]; then
    echo "[ralph-specum] ERROR: Maximum global iterations ($MAX_GLOBAL) reached. Review .progress.md for failure patterns." >&2
    echo "[ralph-specum] Recovery: fix issues manually, then run /ralph-specum:implement or /ralph-specum:cancel" >&2
    exit 0
fi

# Quick mode guard: block stop during ANY phase when quickMode is active
if [ "$QUICK_MODE" = "true" ] && [ "$PHASE" != "execution" ]; then
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        echo "[ralph-specum] stop_hook_active=true in quick mode, allowing stop to prevent loop" >&2
        exit 0
    fi

    REASON=$(cat <<EOF
Quick mode active — do NOT stop. Continue spec phase: $PHASE for $SPEC_NAME.

You are running in quick mode. Do NOT stop, do NOT ask the user questions.
Continue generating artifacts for the current phase ($PHASE) and proceed to the next phase.
Make strong, opinionated decisions autonomously.
EOF
)
    jq -n \
      --arg reason "$REASON" \
      --arg msg "Ralph-specum quick mode: continue $PHASE phase" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
    exit 0
fi

# Log current state
if [ "$PHASE" = "execution" ]; then
    echo "[ralph-specum] Session stopped during spec: $SPEC_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
fi

# Execution completion verification: cross-check state AND tasks.md
if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
    TASKS_FILE="$CWD/$SPEC_PATH/tasks.md"
    if [ -f "$TASKS_FILE" ]; then
        UNCHECKED=$(grep -c '^\s*- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "0")
        if [ "$UNCHECKED" -gt 0 ]; then
            echo "[ralph-specum] State says complete but tasks.md has $UNCHECKED unchecked items" >&2
            REASON=$(cat <<EOF
Tasks incomplete: state index ($TASK_INDEX) reached total ($TOTAL_TASKS), but tasks.md has $UNCHECKED unchecked items.

## Action Required
1. Read $SPEC_PATH/tasks.md and find unchecked tasks (- [ ])
2. Execute remaining unchecked tasks via spec-executor
3. Update .ralph-state.json totalTasks to match actual count
4. Only output ALL_TASKS_COMPLETE when every task in tasks.md is checked off
5. Do NOT add new tasks — complete existing ones only
EOF
)
            jq -n \
              --arg reason "$REASON" \
              --arg msg "Ralph-specum: $UNCHECKED unchecked tasks remain in tasks.md" \
              '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
              }'
            exit 0
        fi
    fi
    # All tasks verified complete — allow stop
    echo "[ralph-specum] All tasks verified complete for $SPEC_NAME" >&2
    exit 0
fi

# Loop control: output continuation prompt if more tasks remain
if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]; then
    # Read recovery mode for prompt customization
    RECOVERY_MODE=$(jq -r '.recoveryMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
    MAX_TASK_ITER=$(jq -r '.maxTaskIterations // 5' "$STATE_FILE" 2>/dev/null || echo "5")

    # Safety guard: prevent infinite re-invocation loop
    # If a stop event fires while already processing a stop-hook continuation,
    # re-blocking would cause infinite loops. Allow Claude to stop; the next
    # session start will detect remaining tasks via .ralph-state.json.
    # Claude Code sets stop_hook_active: true in Stop hook input when a stop
    # fires during an existing stop-hook continuation.
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        echo "[ralph-specum] stop_hook_active=true, skipping continuation to prevent re-invocation loop" >&2
        exit 0
    fi

    # Extract current task block from tasks.md for inline continuation
    TASKS_FILE="$CWD/$SPEC_PATH/tasks.md"
    TASK_BLOCK=""
    if [ -f "$TASKS_FILE" ]; then
        # Extract task at TASK_INDEX (0-based) by counting unchecked+checked task lines
        # If TASK_INDEX exceeds number of tasks, awk outputs nothing (TASK_BLOCK stays empty)
        # and the coordinator falls back to reading tasks.md directly
        # Note: awk count variable starts at 0 (default) to match 0-based TASK_INDEX
        TASK_BLOCK=$(awk -v idx="$TASK_INDEX" '
            /^- \[[ x]\]/ {
                if (count == idx) { found=1; print; next }
                if (found) { exit }
                count++
            }
            found && /^  / { print; next }
            found && /^$/ { print; next }
            found && !/^  / && !/^$/ { exit }
        ' "$TASKS_FILE" | sed -e :a -e '/^[[:space:]]*$/{' -e '$d' -e N -e ba -e '}')
    fi

    # DESIGN NOTE: Prompt Duplication
    # This continuation prompt is intentionally abbreviated compared to implement.md.
    # - implement.md = full specification (source of truth for coordinator behavior)
    # - stop-watcher.sh = abbreviated resume prompt (minimal context for loop continuation)
    # This is an intentional design choice, not accidental duplication. The full
    # specification lives in implement.md; this prompt provides just enough context
    # for the coordinator to resume execution efficiently.

    REASON=$(cat <<EOF
Continue spec: $SPEC_NAME (Task $((TASK_INDEX + 1))/$TOTAL_TASKS, Iter $GLOBAL_ITERATION)

## State
Path: $SPEC_PATH | Index: $TASK_INDEX | Iteration: $TASK_ITERATION/$MAX_TASK_ITER | Recovery: $RECOVERY_MODE

## Current Task
$TASK_BLOCK

## Resume
1. Read $SPEC_PATH/.ralph-state.json for current state
2. Delegate the task above to spec-executor (or qa-engineer for [VERIFY])
3. On TASK_COMPLETE: verify, update state, advance
4. If taskIndex >= totalTasks: read $SPEC_PATH/tasks.md to verify all [x], delete state file, output ALL_TASKS_COMPLETE

## Critical
- Delegate via Task tool - do NOT implement yourself
- Verify all 3 layers before advancing (see implement.md Section 7)
- On failure: increment taskIteration, retry or generate fix task if recoveryMode
- On TASK_MODIFICATION_REQUEST: validate, insert tasks, update state (see implement.md Section 6e)
EOF
)

    SYSTEM_MSG="Ralph-specum iteration $GLOBAL_ITERATION | Task $((TASK_INDEX + 1))/$TOTAL_TASKS"

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

# Note: .progress.md and .ralph-state.json are preserved for loop continuation
# Use /ralph-specum:cancel to explicitly stop execution and cleanup state

exit 0
