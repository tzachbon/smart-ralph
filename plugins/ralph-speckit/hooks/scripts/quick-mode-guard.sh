#!/usr/bin/env bash
# PreToolUse hook: Block AskUserQuestion in autonomous modes (quickMode or autoMode)
set -euo pipefail

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -z "$CWD" ] && exit 0

# Find the current feature's state file
CURRENT_FEATURE_FILE="$CWD/.specify/.current-feature"
[ ! -f "$CURRENT_FEATURE_FILE" ] && exit 0

FEATURE_NAME=$(cat "$CURRENT_FEATURE_FILE" 2>/dev/null | tr -d '[:space:]')
[ -z "$FEATURE_NAME" ] && exit 0

# Try .speckit-state.json first, then .ralph-state.json for compatibility
STATE_FILE=""
for candidate in "$CWD/.specify/specs/$FEATURE_NAME/.speckit-state.json" "$CWD/.specify/specs/"*"-$FEATURE_NAME/.speckit-state.json"; do
    if [ -f "$candidate" ]; then
        STATE_FILE="$candidate"
        break
    fi
done
[ -z "$STATE_FILE" ] && exit 0

QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
AUTO_MODE=$(jq -r '.autoMode // false' "$STATE_FILE" 2>/dev/null || echo "false")

if [ "$QUICK_MODE" != "true" ] && [ "$AUTO_MODE" != "true" ]; then
    exit 0
fi

# Autonomous mode is active — block AskUserQuestion
jq -n '{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": "Autonomous mode active: do NOT ask the user any questions. Make opinionated decisions autonomously. Choose the simplest, most conventional approach."
}'
