#!/bin/bash
# SessionStart Hook for Ralph Specum
# Loads context for active spec on session start:
# 1. Detects active spec from .current-spec
# 2. Loads progress and state for context
# 3. Outputs summary for agent awareness

# Read hook input from stdin
INPUT=$(cat)

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory (guard against parse failures)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Check for settings file to see if plugin is enabled
SETTINGS_FILE="$CWD/.claude/ralph-specum.local.md"
if [ -f "$SETTINGS_FILE" ]; then
    # Extract enabled setting from YAML frontmatter (normalize case and strip quotes)
    ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" 2>/dev/null \
        | awk -F: '/^enabled:/{val=$2; gsub(/[[:space:]"'"'"']/, "", val); print tolower(val); exit}')
    if [ "$ENABLED" = "false" ]; then
        exit 0
    fi
fi

# Check for active spec
CURRENT_SPEC_FILE="$CWD/specs/.current-spec"
if [ ! -f "$CURRENT_SPEC_FILE" ]; then
    exit 0
fi

SPEC_NAME=$(cat "$CURRENT_SPEC_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$SPEC_NAME" ]; then
    exit 0
fi

SPEC_PATH="$CWD/specs/$SPEC_NAME"
if [ ! -d "$SPEC_PATH" ]; then
    exit 0
fi

# Read state file if exists
STATE_FILE="$SPEC_PATH/.ralph-state.json"
PROGRESS_FILE="$SPEC_PATH/.progress.md"

echo "[ralph-specum] Active spec detected: $SPEC_NAME" >&2

# Output state summary if state file exists
if [ -f "$STATE_FILE" ] && jq empty "$STATE_FILE" 2>/dev/null; then
    PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null)
    TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null)
    TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null)
    AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null)

    echo "[ralph-specum] Phase: $PHASE | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Awaiting approval: $AWAITING" >&2

    if [ "$PHASE" = "execution" ] && [ "$AWAITING" = "false" ]; then
        echo "[ralph-specum] Execution in progress. Run /ralph-specum:implement to continue." >&2
    elif [ "$AWAITING" = "true" ]; then
        case "$PHASE" in
            research)
                echo "[ralph-specum] Research complete. Run /ralph-specum:requirements to continue." >&2
                ;;
            requirements)
                echo "[ralph-specum] Requirements complete. Run /ralph-specum:design to continue." >&2
                ;;
            design)
                echo "[ralph-specum] Design complete. Run /ralph-specum:tasks to continue." >&2
                ;;
            tasks)
                echo "[ralph-specum] Tasks complete. Run /ralph-specum:implement to start execution." >&2
                ;;
        esac
    fi
else
    # No state file - check what spec files exist
    if [ -f "$SPEC_PATH/tasks.md" ]; then
        echo "[ralph-specum] Tasks defined but no execution state. Run /ralph-specum:implement to start." >&2
    elif [ -f "$SPEC_PATH/design.md" ]; then
        echo "[ralph-specum] Design exists. Run /ralph-specum:tasks to generate tasks." >&2
    elif [ -f "$SPEC_PATH/requirements.md" ]; then
        echo "[ralph-specum] Requirements exist. Run /ralph-specum:design to continue." >&2
    elif [ -f "$SPEC_PATH/research.md" ]; then
        echo "[ralph-specum] Research exists. Run /ralph-specum:requirements to continue." >&2
    fi
fi

# Output original goal from progress file if exists
if [ -f "$PROGRESS_FILE" ]; then
    GOAL=$(grep -A1 "^## Original Goal" "$PROGRESS_FILE" 2>/dev/null | tail -1)
    if [ -n "$GOAL" ]; then
        echo "[ralph-specum] Goal: $GOAL" >&2
    fi
fi

exit 0
