#!/usr/bin/env bash
# Stop Hook for Ralph Specum Codex -- Loop controller for task execution continuation
# Outputs {"decision":"block","reason":"..."} when tasks remain, exits 0 silently otherwise.

# Read hook input from stdin
INPUT=$(cat)

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Locate current spec name
CURRENT_SPEC_FILE="$CWD/specs/.current-spec"
if [ ! -f "$CURRENT_SPEC_FILE" ]; then
    exit 0
fi

SPEC_NAME=$(cat "$CURRENT_SPEC_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$SPEC_NAME" ]; then
    exit 0
fi

# Build path to state file
STATE_FILE="$CWD/specs/$SPEC_NAME/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Check awaitingApproval -- if true, stop hook yields control to user
AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || true)
if [ "$AWAITING" = "true" ]; then
    exit 0
fi

# Read taskIndex and totalTasks
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || true)
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || true)

# Guard against non-numeric values
if ! [[ "$TASK_INDEX" =~ ^[0-9]+$ ]] || ! [[ "$TOTAL_TASKS" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# All tasks complete
if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ]; then
    echo "ALL_TASKS_COMPLETE"
    exit 0
fi

# Tasks remain -- output Codex block decision
NEXT=$((TASK_INDEX + 1))
printf '{"decision":"block","reason":"Continue to task %s/%s"}\n' "$NEXT" "$TOTAL_TASKS"
