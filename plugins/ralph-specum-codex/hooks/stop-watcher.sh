#!/usr/bin/env bash
# Stop hook for Ralph Specum Codex plugin.
# Reads .ralph-state.json and blocks stop only when execution should continue.

set -euo pipefail

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

emit_block() {
  local reason="$1"
  jq -cn --arg reason "$reason" '{decision: "block", reason: $reason}'
}

CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
  exit 0
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
RESOLVER="$PLUGIN_ROOT/scripts/resolve_spec_paths.py"
RECORD_HELPER="$PLUGIN_ROOT/scripts/prototype_records.py"

RESOLVED=$(PYTHONDONTWRITEBYTECODE=1 python3 "$RESOLVER" --cwd "$CWD" 2>/dev/null || true)
SPEC_PATH=$(echo "$RESOLVED" | jq -r '.basePath // empty' 2>/dev/null || true)
if [ -z "$SPEC_PATH" ]; then
  exit 0
fi

if [[ "$SPEC_PATH" == /* ]]; then
  BASE_PATH="$SPEC_PATH"
else
  BASE_PATH="$CWD/${SPEC_PATH#./}"
fi
STATE_FILE="$BASE_PATH/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(jq -r '.phase // empty' "$STATE_FILE" 2>/dev/null || true)
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo "false")

if [ "$PHASE" != "execution" ] || [ "$AWAITING" = "true" ]; then
  exit 0
fi

ACTIVE_PROTOTYPE_COUNT=$(jq '(.activePrototypes // {}) | length' "$STATE_FILE" 2>/dev/null || echo "0")
if [ "$ACTIVE_PROTOTYPE_COUNT" -gt 0 ]; then
  if ! PYTHONDONTWRITEBYTECODE=1 python3 "$RECORD_HELPER" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE" >/dev/null 2>&1; then
    emit_block "Prototype reconciliation failed. Preserve .ralph-state.json and resume the active prototype before task continuation."
    exit 0
  fi

  ACTIVE_PROTOTYPE_COUNT=$(jq '(.activePrototypes // {}) | length' "$STATE_FILE" 2>/dev/null || echo "0")
  if [ "$ACTIVE_PROTOTYPE_COUNT" -gt 0 ]; then
    if ! SELECTOR_OUTPUT=$(PYTHONDONTWRITEBYTECODE=1 python3 "$RECORD_HELPER" select-downstream --base-path "$BASE_PATH" --state "$STATE_FILE" 2>/dev/null); then
      emit_block "Prototype selection failed. Preserve .ralph-state.json and resume the active prototype before task continuation."
      exit 0
    fi

    NEXT_TASK_NUMBER=$((TASK_INDEX + 1))
    STATE_BLOCKERS=$(jq -c '[.activePrototypes | to_entries[]? | {id: .key, status: .value.status, blocked: (.value.blocking.blocks // [])}]' "$STATE_FILE" 2>/dev/null || echo '[]')
    SELECTED_BLOCKERS=$(echo "$SELECTOR_OUTPUT" | jq -c '.activeBlockers // []' 2>/dev/null || echo '[]')
    ALL_BLOCKERS=$(jq -cn --argjson state "$STATE_BLOCKERS" --argjson selected "$SELECTED_BLOCKERS" '$state + $selected | unique_by(.id)')
    DEPENDENT_BLOCKERS=$(echo "$ALL_BLOCKERS" | jq -c --argjson index "$TASK_INDEX" --argjson number "$NEXT_TASK_NUMBER" '
      [.[]? |
        ((.blocked // []) | if type == "array" then map(tostring) else [tostring] end) as $targets |
        select(
          ($targets | index("execution")) != null or
          ($targets | index("implement")) != null or
          ($targets | index("tasks")) != null or
          ($targets | index("tasks.md")) != null or
          ($targets | index("task:" + ($index | tostring))) != null or
          ($targets | index("task:" + ($number | tostring))) != null or
          ($targets | index($index | tostring)) != null
        )
      ]' 2>/dev/null || echo '[]')
    STALE_TASK=$(jq -n --argjson selected "$SELECTOR_OUTPUT" --slurpfile state "$STATE_FILE" --argjson task "$TASK_INDEX" '[($selected.staleTaskIndexes[]?), ($state[0].activePrototypes[]?.decisionCheckpoint.staleTaskIndexes[]?)] | map(select(. == $task)) | length' 2>/dev/null || echo "0")
    STALE_ARTIFACT=$(jq -n --argjson selected "$SELECTOR_OUTPUT" --slurpfile state "$STATE_FILE" '[($selected.staleArtifacts[]?), ($state[0].activePrototypes[]?.decisionCheckpoint.staleArtifacts[]?)] | map(select(. == "research.md" or . == "requirements.md" or . == "design.md" or . == "tasks.md" or . == "execution")) | length' 2>/dev/null || echo "0")
    DEPENDENT_COUNT=$(echo "$DEPENDENT_BLOCKERS" | jq 'length' 2>/dev/null || echo "0")

    if [ "$DEPENDENT_COUNT" -gt 0 ] || [ "$STALE_TASK" -gt 0 ] || [ "$STALE_ARTIFACT" -gt 0 ]; then
      PROTOTYPE_IDS=$(echo "$DEPENDENT_BLOCKERS" | jq -r 'map(.id) | unique | join(", ")' 2>/dev/null || true)
      if [ -z "$PROTOTYPE_IDS" ]; then
        PROTOTYPE_IDS=$(jq -r '(.activePrototypes // {}) | keys | join(", ")' "$STATE_FILE" 2>/dev/null || echo "unknown")
      fi
      RETURN_TASK_INDEX=$(jq -r '[.activePrototypes[]? | .returnTaskIndex // empty] | first // empty' "$STATE_FILE" 2>/dev/null || true)
      emit_block "Prototype ${PROTOTYPE_IDS} blocks task ${NEXT_TASK_NUMBER}/${TOTAL_TASKS}. Resume it with \$ralph-specum-prototype --resume <id>; after verified handoff restore taskIndex from returnTaskIndex${RETURN_TASK_INDEX:+ ($RETURN_TASK_INDEX)}."
      exit 0
    fi
  fi
fi

# Completion must not discard active prototype recovery state, even when it did
# not block the final task itself.
if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ] 2>/dev/null; then
  if [ "$ACTIVE_PROTOTYPE_COUNT" -gt 0 ]; then
    PROTOTYPE_IDS=$(jq -r '(.activePrototypes // {}) | keys | join(", ")' "$STATE_FILE" 2>/dev/null || echo "unknown")
    emit_block "All tasks are complete, but activePrototypes still contains ${PROTOTYPE_IDS}. Keep .ralph-state.json and reconcile or cancel those entries before completion."
  fi
  exit 0
fi

NEXT=$((TASK_INDEX + 1))
emit_block "Continue to task ${NEXT}/${TOTAL_TASKS}. Read .ralph-state.json for the current task index, reconcile prototype blockers, and delegate eligible work to spec-executor."
