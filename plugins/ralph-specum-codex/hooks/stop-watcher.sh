#!/usr/bin/env bash
# Stop hook for Ralph Specum Codex plugin.
# Reads .ralph-state.json and outputs {"decision":"block","reason":"..."} to continue execution,
# or exits 0 silently to let Codex stop.

set -euo pipefail

# Read stdin JSON (Codex hook input)
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

if [ -z "$CWD" ]; then
  exit 0
fi

# Locate .current-spec
CURRENT_SPEC_FILE="$CWD/specs/.current-spec"
if [ ! -f "$CURRENT_SPEC_FILE" ]; then
  exit 0
fi

SPEC_NAME=$(cat "$CURRENT_SPEC_FILE" | tr -d '[:space:]')
if [ -z "$SPEC_NAME" ]; then
  exit 0
fi

# Build state file path
if [[ "$SPEC_NAME" == ./* ]] || [[ "$SPEC_NAME" == /* ]]; then
  STATE_FILE="$CWD/$SPEC_NAME/.ralph-state.json"
else
  STATE_FILE="$CWD/specs/$SPEC_NAME/.ralph-state.json"
fi

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read state fields
PHASE=$(jq -r '.phase // empty' "$STATE_FILE" 2>/dev/null)
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null)
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null)
AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null)

# Only act during execution phase
if [ "$PHASE" != "execution" ]; then
  exit 0
fi

# If awaiting approval, do not continue
if [ "$AWAITING" = "true" ]; then
  exit 0
fi

# If all tasks complete, let Codex stop
if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ] 2>/dev/null; then
  exit 0
fi

# Continue to next task
NEXT=$((TASK_INDEX + 1))
echo "{\"decision\":\"block\",\"reason\":\"Continue to task ${NEXT}/${TOTAL_TASKS}. Read .ralph-state.json for current task index and delegate to spec-executor.\"}"
