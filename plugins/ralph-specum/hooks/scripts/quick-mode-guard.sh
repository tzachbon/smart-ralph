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

SPEC_PATH=$(ralph_resolve_current 2>/dev/null) || true
if [ -n "$SPEC_PATH" ]; then
    case "$SPEC_PATH" in
        /*) SPEC_STATE="$SPEC_PATH/.ralph-state.json" ;;
        *) SPEC_STATE="$CWD/$SPEC_PATH/.ralph-state.json" ;;
    esac
    if is_exact_quick_state "$SPEC_STATE"; then
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

# Quick mode is active - block AskUserQuestion
jq -n '{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": "Quick mode active: do NOT ask the user any questions. Make opinionated decisions autonomously. Choose the simplest, most conventional approach."
}'
