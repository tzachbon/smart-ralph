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

# Source path resolver for multi-directory support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/path-resolver.sh" ]; then
    export RALPH_CWD="$CWD"
    # shellcheck source=path-resolver.sh
    source "$SCRIPT_DIR/path-resolver.sh"
else
    # Fallback if path-resolver.sh not found
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

# Resolve current spec using the shared context contract
RESOLVED_CONTEXT=$(ralph_resolve_context 2>/dev/null || true)
SPEC_RELATIVE_PATH=$(printf '%s' "$RESOLVED_CONTEXT" | jq -r '.basePath // empty' 2>/dev/null || true)
if [ -z "$SPEC_RELATIVE_PATH" ]; then
    exit 0
fi

if [[ "$SPEC_RELATIVE_PATH" = /* ]]; then
    SPEC_PATH="$SPEC_RELATIVE_PATH"
else
    SPEC_PATH="$CWD/${SPEC_RELATIVE_PATH#./}"
fi
if [ ! -d "$SPEC_PATH" ]; then
    exit 0
fi

# Extract spec name from path (last component)
SPEC_NAME=$(basename "$SPEC_RELATIVE_PATH")

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
    ACTIVE_COUNT=$(jq -r '(.activePrototypes // {}) | length' "$STATE_FILE" 2>/dev/null || echo 0)

    echo "[ralph-specum] Phase: $PHASE | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Awaiting approval: $AWAITING" >&2

    PROTOTYPE_DIR="$SPEC_PATH/prototypes"
    if [ "$ACTIVE_COUNT" -gt 0 ] || [ -d "$PROTOTYPE_DIR" ]; then
        CANDIDATE_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '.*.candidate.md' 2>/dev/null | wc -l | tr -d ' ')
        FINAL_FILE_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' ! -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
        QUARANTINE_FILE_COUNT=$(find "$PROTOTYPE_DIR" -maxdepth 1 -type f -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
        SELECTION=$(python3 "$SCRIPT_DIR/prototype-records.py" select-downstream --base-path "$SPEC_PATH" --state "$STATE_FILE" 2>/dev/null || printf '{}')
        MALFORMED_COUNT=$(printf '%s' "$SELECTION" | jq -r '(.quarantined // []) | length' 2>/dev/null || echo 0)
        FINAL_COUNT=$((FINAL_FILE_COUNT - MALFORMED_COUNT))
        [ "$FINAL_COUNT" -lt 0 ] && FINAL_COUNT=0
        QUARANTINE_COUNT=$((QUARANTINE_FILE_COUNT + MALFORMED_COUNT))
        BLOCKER_COUNT=$(printf '%s' "$SELECTION" | jq -r '(.activeBlockers // []) | length' 2>/dev/null || echo 0)
        STALE_ARTIFACTS=$(printf '%s' "$SELECTION" | jq -r '(.staleArtifacts // []) | join(",")' 2>/dev/null || true)
        STALE_TASKS=$(printf '%s' "$SELECTION" | jq -r '(.staleTaskIndexes // []) | map(tostring) | join(",")' 2>/dev/null || true)
        echo "[ralph-specum] Prototypes: active=$ACTIVE_COUNT candidates=$CANDIDATE_COUNT finals=$FINAL_COUNT quarantined=$QUARANTINE_COUNT blockers=$BLOCKER_COUNT" >&2
        if [ -n "$STALE_ARTIFACTS$STALE_TASKS" ]; then
            echo "[ralph-specum] Prototype stale dependencies: artifacts=${STALE_ARTIFACTS:-none} tasks=${STALE_TASKS:-none}" >&2
        fi
        if [ "$ACTIVE_COUNT" -gt 0 ] || [ "$CANDIDATE_COUNT" -gt 0 ]; then
            echo "[ralph-specum] Prototype recovery available. Run /ralph-specum:start or /ralph-specum:prototype --resume <id>." >&2
        fi
    fi

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
