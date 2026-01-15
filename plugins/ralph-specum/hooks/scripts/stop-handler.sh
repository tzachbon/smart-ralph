#!/bin/bash
# Ralph Specum Stop Hook Handler
# Handles task-by-task execution loop with fresh context per task

set -euo pipefail

# Read input from stdin (Claude Code hook input)
INPUT=$(cat)

# Extract transcript path (not used currently but available)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Find current spec
CURRENT_SPEC_FILE="./specs/.current-spec"
if [[ ! -f "$CURRENT_SPEC_FILE" ]]; then
    exit 0  # No active spec, allow stop
fi

CURRENT_SPEC=$(cat "$CURRENT_SPEC_FILE" 2>/dev/null)
if [[ -z "$CURRENT_SPEC" ]]; then
    exit 0  # No active spec, allow stop
fi

# Find state file
STATE_FILE="./specs/$CURRENT_SPEC/.ralph-state.json"
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0  # No active loop, allow stop
fi

# Read state with error handling
STATE=$(cat "$STATE_FILE" 2>/dev/null)
if [[ -z "$STATE" ]]; then
    exit 0  # Empty or unreadable state file, allow stop
fi

# Parse state with jq, exit gracefully on parse failure
PHASE=$(echo "$STATE" | jq -r '.phase' 2>/dev/null) || exit 0
TASK_INDEX=$(echo "$STATE" | jq -r '.taskIndex' 2>/dev/null) || exit 0
TOTAL_TASKS=$(echo "$STATE" | jq -r '.totalTasks' 2>/dev/null) || exit 0
TASK_ITER=$(echo "$STATE" | jq -r '.taskIteration' 2>/dev/null) || exit 0
MAX_TASK_ITER=$(echo "$STATE" | jq -r '.maxTaskIterations' 2>/dev/null) || exit 0
GLOBAL_ITER=$(echo "$STATE" | jq -r '.globalIteration' 2>/dev/null) || exit 0
MAX_GLOBAL_ITER=$(echo "$STATE" | jq -r '.maxGlobalIterations' 2>/dev/null) || exit 0
SPEC_PATH=$(echo "$STATE" | jq -r '.basePath' 2>/dev/null) || exit 0

# Extract last assistant message from transcript for completion verification
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
    LAST_OUTPUT=""
else
    # Extract last assistant message text content
    LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | jq -r '
        .message.content |
        map(select(.type == "text")) |
        map(.text) |
        join("\n")
    ' 2>/dev/null || echo "")
fi

# Validate required fields parsed correctly
if [[ -z "$PHASE" || "$PHASE" == "null" ]]; then
    exit 0  # Invalid state, allow stop
fi

# Check global iteration limit (safety cap)
if [[ $GLOBAL_ITER -ge $MAX_GLOBAL_ITER ]]; then
    jq -n \
        --arg reason "Max global iterations ($MAX_GLOBAL_ITER) reached. Run /ralph-specum:cancel to cleanup and review progress." \
        '{"decision": "block", "reason": $reason}'
    exit 0
fi

# Check if awaiting user approval between phases
AWAITING_APPROVAL=$(echo "$STATE" | jq -r '.awaitingApproval // false' 2>/dev/null)

if [[ "$AWAITING_APPROVAL" == "true" ]]; then
    # Allow stop - user needs to review and run next command manually
    # The agent already displayed the "run /ralph-specum:<next>" message
    exit 0
fi

# Only handle execution phase for task loop
if [[ "$PHASE" != "execution" ]]; then
    exit 0  # Allow stop for non-execution phases (research, requirements, design, tasks)
fi

# Check if task failed too many times
if [[ $TASK_ITER -ge $MAX_TASK_ITER ]]; then
    jq -n \
        --arg reason "Task $TASK_INDEX failed after $MAX_TASK_ITER attempts. Fix the issue manually, then run /ralph-specum:implement to resume from task $TASK_INDEX." \
        '{"decision": "block", "reason": $reason}'
    exit 0
fi

# Check if all tasks are done - but verify checkmarks match before allowing completion
if [[ $TASK_INDEX -ge $TOTAL_TASKS ]]; then
    # CRITICAL: Verify actual checkmark count matches totalTasks
    # This prevents agent from manipulating state file to skip tasks
    TASKS_FILE="$SPEC_PATH/tasks.md"
    if [[ -f "$TASKS_FILE" ]]; then
        COMPLETED_COUNT=$(grep -c '^[[:space:]]*-[[:space:]]*\[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")

        if [[ $COMPLETED_COUNT -lt $TOTAL_TASKS ]]; then
            # State file says all done, but checkmarks don't match - likely manipulation
            # Reset taskIndex to actual completed count
            TEMP_STATE=$(mktemp)
            if echo "$STATE" | jq "
                .taskIndex = $COMPLETED_COUNT |
                .taskIteration = 1 |
                .globalIteration = $((GLOBAL_ITER + 1))
            " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
                mv "$TEMP_STATE" "$STATE_FILE"
            else
                rm -f "$TEMP_STATE"
            fi

            REASON="STATE MANIPULATION DETECTED. State file claims $TASK_INDEX tasks done but only $COMPLETED_COUNT checkmarks in tasks.md. Resetting to task $COMPLETED_COUNT. Do NOT modify .ralph-state.json directly."
            jq -n \
                --arg reason "$REASON" \
                --arg msg "INTEGRITY VIOLATION: State file manipulated. Only $COMPLETED_COUNT of $TOTAL_TASKS tasks actually completed." \
                '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
            exit 0
        fi
    fi

    # All tasks verified complete! Cleanup state file and current-spec pointer, keep progress
    rm "$STATE_FILE"
    rm "$CURRENT_SPEC_FILE"
    exit 0  # Allow stop - execution complete
fi

# === VERIFICATION LAYER 1: Contradiction detection ===
# Detect if agent says it can't complete but still outputs TASK_COMPLETE
if echo "$LAST_OUTPUT" | grep -q "TASK_COMPLETE"; then
    # Check for contradictory phrases that indicate the task wasn't actually done
    CONTRADICTION_PATTERNS="manual testing required|requires manual|cannot be automated|manual verification needed|needs user interaction|manual action required|could not complete|unable to complete|skipping verification|skip.*verification"

    if echo "$LAST_OUTPUT" | grep -qiE "$CONTRADICTION_PATTERNS"; then
        # Agent is lying - saying it can't do something but claiming TASK_COMPLETE
        NEW_TASK_ITER=$((TASK_ITER + 1))

        TEMP_STATE=$(mktemp)
        if echo "$STATE" | jq "
            .taskIteration = $NEW_TASK_ITER |
            .globalIteration = $((GLOBAL_ITER + 1))
        " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
            mv "$TEMP_STATE" "$STATE_FILE"
        else
            rm -f "$TEMP_STATE"
            exit 0
        fi

        REASON="Task $TASK_INDEX: CONTRADICTION DETECTED. Agent claimed TASK_COMPLETE but indicated task requires manual action. If task cannot be completed, do NOT output TASK_COMPLETE - describe what's needed and let the loop block for user intervention. Retry attempt $NEW_TASK_ITER."
        jq -n \
            --arg reason "$REASON" \
            --arg msg "INTEGRITY VIOLATION: Task $TASK_INDEX claimed complete but requires manual action. Do NOT output TASK_COMPLETE for incomplete tasks." \
            '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
        exit 0
    fi
fi

# === VERIFICATION LAYER 2: Check for uncommitted spec files ===
# Spec files MUST be committed with every task completion
SPEC_FILES_STATUS=$(git status --porcelain "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" 2>/dev/null || echo "")
if [[ -n "$SPEC_FILES_STATUS" ]] && echo "$LAST_OUTPUT" | grep -q "TASK_COMPLETE"; then
    # Spec files have uncommitted changes - agent didn't commit properly
    NEW_TASK_ITER=$((TASK_ITER + 1))

    TEMP_STATE=$(mktemp)
    if echo "$STATE" | jq "
        .taskIteration = $NEW_TASK_ITER |
        .globalIteration = $((GLOBAL_ITER + 1))
    " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
        mv "$TEMP_STATE" "$STATE_FILE"
    else
        rm -f "$TEMP_STATE"
        exit 0
    fi

    REASON="Task $TASK_INDEX: UNCOMMITTED SPEC FILES. Agent claimed TASK_COMPLETE but $SPEC_PATH/tasks.md or .progress.md have uncommitted changes. Commit ALL changes before signaling completion. Retry attempt $NEW_TASK_ITER."
    jq -n \
        --arg reason "$REASON" \
        --arg msg "COMMIT VIOLATION: Task $TASK_INDEX has uncommitted spec files. Commit before TASK_COMPLETE." \
        '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
    exit 0
fi

# === VERIFICATION LAYER 3: Verify task checkmark was updated ===
# Check that the current task is marked [x] in tasks.md
if echo "$LAST_OUTPUT" | grep -q "TASK_COMPLETE"; then
    TASKS_FILE="$SPEC_PATH/tasks.md"
    if [[ -f "$TASKS_FILE" ]]; then
        # Count completed tasks (lines with [x])
        COMPLETED_COUNT=$(grep -c '^[[:space:]]*-[[:space:]]*\[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")

        # Task index is 0-based, so completed count should be at least taskIndex + 1
        EXPECTED_MIN=$((TASK_INDEX + 1))

        if [[ $COMPLETED_COUNT -lt $EXPECTED_MIN ]]; then
            # Task checkmark wasn't updated
            NEW_TASK_ITER=$((TASK_ITER + 1))

            TEMP_STATE=$(mktemp)
            if echo "$STATE" | jq "
                .taskIteration = $NEW_TASK_ITER |
                .globalIteration = $((GLOBAL_ITER + 1))
            " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
                mv "$TEMP_STATE" "$STATE_FILE"
            else
                rm -f "$TEMP_STATE"
                exit 0
            fi

            REASON="Task $TASK_INDEX: CHECKMARK NOT UPDATED. Agent claimed TASK_COMPLETE but tasks.md shows only $COMPLETED_COUNT completed tasks (expected at least $EXPECTED_MIN). Mark task as [x] in tasks.md before signaling completion. Retry attempt $NEW_TASK_ITER."
            jq -n \
                --arg reason "$REASON" \
                --arg msg "CHECKMARK VIOLATION: Task $TASK_INDEX not marked [x] in tasks.md. Update checkmark before TASK_COMPLETE." \
                '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
            exit 0
        fi
    fi
fi

# === VERIFICATION LAYER 4: Verify TASK_COMPLETE signal ===
if ! echo "$LAST_OUTPUT" | grep -q "TASK_COMPLETE"; then
    # Task did not complete successfully - retry same task
    NEW_TASK_ITER=$((TASK_ITER + 1))

    # Update state for retry (same task, incremented iteration)
    TEMP_STATE=$(mktemp)
    if echo "$STATE" | jq "
        .taskIteration = $NEW_TASK_ITER |
        .globalIteration = $((GLOBAL_ITER + 1))
    " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
        mv "$TEMP_STATE" "$STATE_FILE"
    else
        rm -f "$TEMP_STATE"
        exit 0  # Failed to update state, allow stop
    fi

    REASON="Task $TASK_INDEX did not complete. Retry attempt $NEW_TASK_ITER. Read $SPEC_PATH/.progress.md for context and continue task $TASK_INDEX from $SPEC_PATH/tasks.md."
    jq -n \
        --arg reason "$REASON" \
        --arg msg "Task $TASK_INDEX incomplete. Retrying ($NEW_TASK_ITER/$MAX_TASK_ITER)." \
        '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
    exit 0
fi

# Continue to next task with fresh context
NEW_TASK_INDEX=$((TASK_INDEX + 1))
NEW_GLOBAL_ITER=$((GLOBAL_ITER + 1))

# Update state file atomically: write to temp, then move
TEMP_STATE=$(mktemp)
if echo "$STATE" | jq "
    .taskIndex = $NEW_TASK_INDEX |
    .taskIteration = 1 |
    .globalIteration = $NEW_GLOBAL_ITER
" > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
    mv "$TEMP_STATE" "$STATE_FILE"
else
    rm -f "$TEMP_STATE"
    exit 0  # Failed to update state, allow stop
fi

# Return block decision with continue prompt using safe jq output
REASON="Continue execution for spec '$CURRENT_SPEC'. Read $SPEC_PATH/.progress.md for context and $SPEC_PATH/tasks.md for task $NEW_TASK_INDEX."

jq -n \
    --arg reason "$REASON" \
    --arg msg "Task $TASK_INDEX complete. Continuing to task $NEW_TASK_INDEX of $TOTAL_TASKS." \
    '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
