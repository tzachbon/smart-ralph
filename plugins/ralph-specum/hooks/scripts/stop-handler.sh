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

# Read tasks.md to check for parallel tasks
TASKS_FILE="$SPEC_PATH/tasks.md"
PARALLEL_TASKS=""
PARALLEL_COUNT=0

if [[ -f "$TASKS_FILE" ]]; then
    # Extract all task lines with their markers and indices
    # Task lines match: - [ ], - [x], - [P], or - [X] (completed parallel)
    TASK_LINES=$(grep -n '^\- \[\([ xPX]\)\]' "$TASKS_FILE" 2>/dev/null)

    # Find the task at NEW_TASK_INDEX (0-based, so we need line N+1)
    TASK_LINE_NUM=$((NEW_TASK_INDEX + 1))
    CURRENT_TASK_LINE=$(echo "$TASK_LINES" | sed -n "${TASK_LINE_NUM}p")

    # Check if current task is marked as parallel [P]
    if echo "$CURRENT_TASK_LINE" | grep -q '\- \[P\]'; then
        # Found a parallel task, collect all consecutive parallel tasks
        PARALLEL_INDICES="$NEW_TASK_INDEX"
        PARALLEL_COUNT=1

        # Look ahead for more consecutive [P] tasks
        NEXT_LINE_NUM=$((TASK_LINE_NUM + 1))
        while true; do
            NEXT_TASK_LINE=$(echo "$TASK_LINES" | sed -n "${NEXT_LINE_NUM}p")
            if echo "$NEXT_TASK_LINE" | grep -q '\- \[P\]'; then
                NEXT_TASK_INDEX=$((NEXT_LINE_NUM - 1))
                PARALLEL_INDICES="$PARALLEL_INDICES,$NEXT_TASK_INDEX"
                PARALLEL_COUNT=$((PARALLEL_COUNT + 1))
                NEXT_LINE_NUM=$((NEXT_LINE_NUM + 1))
                # Safety limit: max 4 parallel tasks
                if [[ $PARALLEL_COUNT -ge 4 ]]; then
                    break
                fi
            else
                break
            fi
        done

        PARALLEL_TASKS="$PARALLEL_INDICES"
    fi
fi

# Calculate the end task index (for parallel tasks, skip to after the group)
if [[ $PARALLEL_COUNT -gt 1 ]]; then
    END_TASK_INDEX=$((NEW_TASK_INDEX + PARALLEL_COUNT))
else
    END_TASK_INDEX=$NEW_TASK_INDEX
fi

# Update state file atomically: write to temp, then move
TEMP_STATE=$(mktemp)
if [[ $PARALLEL_COUNT -gt 1 ]]; then
    # Store parallel task info in state
    if echo "$STATE" | jq "
        .taskIndex = $END_TASK_INDEX |
        .taskIteration = 1 |
        .globalIteration = $NEW_GLOBAL_ITER |
        .parallelTasks = \"$PARALLEL_TASKS\" |
        .parallelCount = $PARALLEL_COUNT
    " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
        mv "$TEMP_STATE" "$STATE_FILE"
    else
        rm -f "$TEMP_STATE"
        exit 0  # Failed to update state, allow stop
    fi
else
    if echo "$STATE" | jq "
        .taskIndex = $NEW_TASK_INDEX |
        .taskIteration = 1 |
        .globalIteration = $NEW_GLOBAL_ITER |
        del(.parallelTasks) |
        del(.parallelCount)
    " > "$TEMP_STATE" 2>/dev/null && [[ -s "$TEMP_STATE" ]]; then
        mv "$TEMP_STATE" "$STATE_FILE"
    else
        rm -f "$TEMP_STATE"
        exit 0  # Failed to update state, allow stop
    fi
fi

# Return block decision with continue prompt
# The reason becomes the next user input, giving fresh context
if [[ $PARALLEL_COUNT -gt 1 ]]; then
    REASON="Continue execution for spec '$CURRENT_SPEC'. PARALLEL EXECUTION: Tasks $PARALLEL_TASKS should be executed in parallel. Read $SPEC_PATH/.progress.md for context and $SPEC_PATH/tasks.md for tasks $PARALLEL_TASKS."
    echo "{\"decision\": \"block\", \"reason\": \"$REASON\", \"systemMessage\": \"Task $TASK_INDEX complete. Continuing with $PARALLEL_COUNT parallel tasks ($PARALLEL_TASKS) of $TOTAL_TASKS total.\"}"
else
    REASON="Continue execution for spec '$CURRENT_SPEC'. Read $SPEC_PATH/.progress.md for context and $SPEC_PATH/tasks.md for task $NEW_TASK_INDEX."
    echo "{\"decision\": \"block\", \"reason\": \"$REASON\", \"systemMessage\": \"Task $TASK_INDEX complete. Continuing to task $NEW_TASK_INDEX of $TOTAL_TASKS.\"}"
fi
