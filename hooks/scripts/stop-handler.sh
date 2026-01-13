#!/bin/bash
# Ralph Specum Stop Hook Handler
# Handles task-by-task execution loop with fresh context per task

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

# Validate required fields parsed correctly
if [[ -z "$PHASE" || "$PHASE" == "null" ]]; then
    exit 0  # Invalid state, allow stop
fi

# Check global iteration limit (safety cap)
if [[ $GLOBAL_ITER -ge $MAX_GLOBAL_ITER ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Max global iterations ($MAX_GLOBAL_ITER) reached. Run /ralph-specum:cancel to cleanup and review progress.\"}"
    exit 0
fi

# Only handle execution phase for task loop
if [[ "$PHASE" != "execution" ]]; then
    exit 0  # Allow stop for non-execution phases (research, requirements, design, tasks)
fi

# Check if task failed too many times
if [[ $TASK_ITER -ge $MAX_TASK_ITER ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Task $TASK_INDEX failed after $MAX_TASK_ITER attempts. Fix the issue manually, then run /ralph-specum:implement to resume from task $TASK_INDEX.\"}"
    exit 0
fi

# Check if all tasks are done
if [[ $TASK_INDEX -ge $TOTAL_TASKS ]]; then
    # All tasks complete! Cleanup state file, keep progress
    rm "$STATE_FILE"
    exit 0  # Allow stop - execution complete
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

# Return block decision with continue prompt
# The reason becomes the next user input, giving fresh context
REASON="Continue execution for spec '$CURRENT_SPEC'. Read $SPEC_PATH/.progress.md for context and $SPEC_PATH/tasks.md for task $NEW_TASK_INDEX."

echo "{\"decision\": \"block\", \"reason\": \"$REASON\", \"systemMessage\": \"Task $TASK_INDEX complete. Continuing to task $NEW_TASK_INDEX of $TOTAL_TASKS.\"}"
