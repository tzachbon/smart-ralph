#!/usr/bin/env bash
# PreToolUse hook: Block AskUserQuestion in quick mode
# Denies only when quickMode has exact --quick authorization.

set -euo pipefail

INPUT=$(cat)

# Bail out if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Source path resolver
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_CWD="$CWD"
export RALPH_CWD
source "$SCRIPT_DIR/path-resolver.sh"

# Resolve exact quick authorization from the active spec or epic.
is_exact_quick_state() {
    local state_file=$1
    [ -f "$state_file" ] || return 1

    local quick_mode quick_source
    quick_mode=$(jq -r '.quickMode // false' "$state_file" 2>/dev/null || echo "false")
    quick_source=$(jq -r '.quickAuthorization.source // empty' "$state_file" 2>/dev/null || true)
    [ "$quick_mode" = "true" ] && [ "$quick_source" = "--quick" ]
}

# Resolve the current spec without losing configured-root support.
BASE_PATH=""
STATE_FILE=""
RESOLVED_CONTEXT=$(ralph_resolve_context 2>/dev/null || true)
RESOLVED_BASE_PATH=$(printf '%s' "$RESOLVED_CONTEXT" | jq -r '.basePath // empty' 2>/dev/null || true)
if [ -n "$RESOLVED_BASE_PATH" ]; then
    if [[ "$RESOLVED_BASE_PATH" = /* ]]; then
        BASE_PATH="$RESOLVED_BASE_PATH"
    else
        BASE_PATH="$CWD/${RESOLVED_BASE_PATH#./}"
    fi
    STATE_FILE="$BASE_PATH/.ralph-state.json"
    if is_exact_quick_state "$STATE_FILE"; then
        QUICK_MODE_ACTIVE=true
    fi
fi

CURRENT_EPIC_FILE="$CWD/specs/.current-epic"
if [ -f "$CURRENT_EPIC_FILE" ]; then
    EPIC_NAME=$(tr -d '[:space:]' < "$CURRENT_EPIC_FILE")
    if [[ "$EPIC_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        EPIC_STATE="$CWD/specs/_epics/$EPIC_NAME/.epic-state.json"
        if is_exact_quick_state "$EPIC_STATE"; then
            QUICK_MODE_ACTIVE=true
        fi
    fi
fi

[ "${QUICK_MODE_ACTIVE:-false}" = true ] || exit 0

# Quick mode is active - expose overlay state and block AskUserQuestion
ACTIVE_COUNT=0
PROTOTYPE_DIR=""
CANDIDATE_COUNT=0
FINAL_COUNT=0
QUARANTINE_COUNT=0
SELECTION='{}'
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    ACTIVE_COUNT=$(jq -r '(.activePrototypes // {}) | length' "$STATE_FILE" 2>/dev/null || echo 0)
fi
if [ -n "$BASE_PATH" ]; then
    PROTOTYPE_DIR="$BASE_PATH/prototypes"
fi
if [ -d "$PROTOTYPE_DIR" ]; then
    CANDIDATE_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '.*.candidate.md' 2>/dev/null | wc -l | tr -d ' ')
    FINAL_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' ! -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
    QUARANTINE_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$ACTIVE_COUNT" -gt 0 ] || [ -d "$PROTOTYPE_DIR" ]; then
    SELECTION=$(python3 "$SCRIPT_DIR/prototype-records.py" select-downstream --base-path "$BASE_PATH" --state "$STATE_FILE" 2>/dev/null || printf '{}')
fi
BLOCKERS=$(printf '%s' "$SELECTION" | jq -c '.activeBlockers // []' 2>/dev/null || printf '[]')
STALE_ARTIFACTS=$(printf '%s' "$SELECTION" | jq -c '.staleArtifacts // []' 2>/dev/null || printf '[]')
STALE_TASKS=$(printf '%s' "$SELECTION" | jq -c '.staleTaskIndexes // []' 2>/dev/null || printf '[]')
MESSAGE="Quick mode active: do NOT ask the user any questions. Make opinionated decisions autonomously. Choose the simplest, most conventional approach."
if [ "$ACTIVE_COUNT" -gt 0 ] || [ "$CANDIDATE_COUNT" -gt 0 ] || [ "$FINAL_COUNT" -gt 0 ] || \
   [ "$QUARANTINE_COUNT" -gt 0 ] || [ "$STALE_ARTIFACTS" != "[]" ] || [ "$STALE_TASKS" != "[]" ]; then
    MESSAGE="$MESSAGE Prototype overlay: active=$ACTIVE_COUNT candidates=$CANDIDATE_COUNT finals=$FINAL_COUNT quarantined=$QUARANTINE_COUNT blockers=$BLOCKERS staleArtifacts=$STALE_ARTIFACTS staleTaskIndexes=$STALE_TASKS. Preserve unrelated entries and continue to design after every quick prototype result."
fi

jq -n --arg message "$MESSAGE" '{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": $message
}'
