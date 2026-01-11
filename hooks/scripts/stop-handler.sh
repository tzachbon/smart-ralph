#!/bin/bash
# Ralph Specum Stop Hook Handler
# Reads state, determines if loop should continue or block
# Handles auto-compaction in auto mode

# Read input from stdin (Claude Code hook input)
INPUT=$(cat)

# Extract transcript path to find working directory
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Try to find state file in common locations
find_state_file() {
    local dirs=("./spec" "." "../spec")
    for dir in "${dirs[@]}"; do
        if [[ -f "$dir/.ralph-state.json" ]]; then
            echo "$dir/.ralph-state.json"
            return 0
        fi
    done
    return 1
}

STATE_FILE=$(find_state_file)

# If no state file found, allow normal stop
if [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Get spec directory from state file path
SPEC_DIR=$(dirname "$STATE_FILE")

# Read state
STATE=$(cat "$STATE_FILE")
MODE=$(echo "$STATE" | jq -r '.mode')
PHASE=$(echo "$STATE" | jq -r '.phase')
ITERATION=$(echo "$STATE" | jq -r '.iteration')
MAX_ITERATIONS=$(echo "$STATE" | jq -r '.maxIterations')
TASK_INDEX=$(echo "$STATE" | jq -r '.taskIndex')
TOTAL_TASKS=$(echo "$STATE" | jq -r '.totalTasks')

# Check for max iterations
if [[ "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
    echo '{"decision": "block", "reason": "Max iterations reached. Run /ralph-specum:cancel to cleanup."}'
    exit 0
fi

# Increment iteration
NEW_ITERATION=$((ITERATION + 1))

# Compaction instructions per phase
get_compact_instruction() {
    local phase=$1
    case "$phase" in
        "requirements")
            echo "Run: /compact preserve: user stories, acceptance criteria (AC-*), functional requirements (FR-*), non-functional requirements (NFR-*), glossary. Read $SPEC_DIR/.ralph-progress.md for context. Then continue to design phase."
            ;;
        "design")
            echo "Run: /compact preserve: architecture decisions, component boundaries, file paths, patterns. Read $SPEC_DIR/.ralph-progress.md for context. Then continue to tasks phase."
            ;;
        "tasks")
            echo "Run: /compact preserve: task list with IDs, dependencies, quality gates. Read $SPEC_DIR/.ralph-progress.md for context. Then continue to execution phase."
            ;;
        "execution")
            echo "Run: /compact preserve: current task context, verification results. Read $SPEC_DIR/.ralph-progress.md for completed tasks and learnings. Then continue to next task."
            ;;
    esac
}

# Advance phase helper
get_next_phase() {
    local current=$1
    case "$current" in
        "requirements") echo "design" ;;
        "design") echo "tasks" ;;
        "tasks") echo "execution" ;;
        *) echo "$current" ;;
    esac
}

case "$PHASE" in
    "requirements"|"design"|"tasks")
        PHASE_APPROVED=$(echo "$STATE" | jq -r ".phaseApprovals.$PHASE")

        if [[ "$MODE" == "interactive" && "$PHASE_APPROVED" != "true" ]]; then
            # Block and wait for approval or revision
            echo "{\"decision\": \"block\", \"reason\": \"Phase '$PHASE' complete. Options: (1) Discuss/give feedback to revise current phase (2) /ralph-specum:approve to advance to next phase.\"}"
            exit 0
        fi

        # Auto mode: advance phase and trigger compaction
        if [[ "$MODE" == "auto" ]]; then
            NEXT_PHASE=$(get_next_phase "$PHASE")
            COMPACT_MSG=$(get_compact_instruction "$PHASE")

            # Update state: advance phase, mark approved, increment iteration
            echo "$STATE" | jq "
                .phase = \"$NEXT_PHASE\" |
                .phaseApprovals.$PHASE = true |
                .iteration = $NEW_ITERATION
            " > "$STATE_FILE"

            echo "{\"decision\": \"block\", \"reason\": \"Phase '$PHASE' complete. $COMPACT_MSG\"}"
            exit 0
        fi
        ;;

    "execution")
        # Check if all tasks are done
        if [[ "$TASK_INDEX" -ge "$TOTAL_TASKS" && "$TOTAL_TASKS" -gt 0 ]]; then
            # All done, allow stop
            exit 0
        fi

        # More tasks to do
        if [[ "$MODE" == "auto" ]]; then
            COMPACT_MSG=$(get_compact_instruction "execution")

            # Update iteration
            echo "$STATE" | jq ".iteration = $NEW_ITERATION" > "$STATE_FILE"

            echo "{\"decision\": \"block\", \"reason\": \"Task complete. $COMPACT_MSG\"}"
            exit 0
        fi

        # Interactive mode: allow discussion or continue
        echo "$STATE" | jq ".iteration = $NEW_ITERATION" > "$STATE_FILE"
        echo "{\"decision\": \"block\", \"reason\": \"Task done. Discuss results or say 'continue' for next task.\"}"
        exit 0
        ;;
esac

# Default: allow stop
exit 0
