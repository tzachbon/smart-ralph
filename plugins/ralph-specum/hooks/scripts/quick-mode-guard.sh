#!/usr/bin/env bash
# PreToolUse hook: Block AskUserQuestion in quick mode
# Reads .ralph-state.json and denies the call if quickMode is true.

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

# Resolve current spec
SPEC_PATH=$(ralph_resolve_current 2>/dev/null)
if [ -z "$SPEC_PATH" ]; then
    exit 0
fi

STATE_FILE="$CWD/$SPEC_PATH/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Check quickMode flag
QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
if [ "$QUICK_MODE" != "true" ]; then
    exit 0
fi

# Quick mode is active — block AskUserQuestion
jq -n '{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": "Quick mode active: do NOT ask the user any questions. Make opinionated decisions autonomously. Choose the simplest, most conventional approach."
}'
