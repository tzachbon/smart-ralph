#!/usr/bin/env bash
# PreToolUse hook: require a current phase approval before artifact-agent Task calls.

set -euo pipefail

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || {
    printf '%s\n' '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"Ralph phase gate unavailable: jq is required for artifact delegation."}'
    exit 0
}

SUBAGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)

# Explore is read-only by contract and never produces Ralph artifacts.
if [[ "$SUBAGENT_TYPE" =~ (^|:)Explore$ ]] || [ "$SUBAGENT_TYPE" = "Explore" ]; then
    exit 0
fi

if [[ ! "$SUBAGENT_TYPE" =~ (^|:)(research-analyst|product-manager|architect-reviewer|task-planner|triage-analyst)$ ]]; then
    exit 0
fi

PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null || true)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)

deny() {
    local reason=$1
    jq -n --arg reason "$reason" '{
      hookSpecificOutput: {permissionDecision: "deny"},
      systemMessage: ("Ralph artifact delegation blocked: " + $reason)
    }'
    exit 0
}

[ -n "$CWD" ] || deny "hook input cwd is required for artifact delegation."
[ -d "$CWD" ] || deny "hook input cwd does not exist."
CWD=$(cd "$CWD" && pwd -P)

if ! printf '%s\n' "$PROMPT" | grep -Fxq '[RALPH_PHASE_GATE]'; then
    deny "Task prompt is missing the [RALPH_PHASE_GATE] marker."
fi

marker_value() {
    local key=$1
    printf '%s\n' "$PROMPT" | sed -n "s/^${key}=//p" | head -1
}

STATE=$(marker_value state)
PHASE=$(marker_value phase)
INTERVIEW_ID=$(marker_value interviewId)
REVISION=$(marker_value discoveryRevision)
DIGEST=$(marker_value contextDigest)

[ -n "$STATE" ] || deny "gate state path is missing."
[ -n "$PHASE" ] || deny "gate phase is missing."
[ -n "$INTERVIEW_ID" ] || deny "gate interview ID is missing."
[ -n "$REVISION" ] || deny "gate discovery revision is missing."
[[ "$DIGEST" =~ ^[0-9a-f]{64}$ ]] || deny "gate context digest is invalid."

case "$PHASE" in
    start|research)
        [[ "$SUBAGENT_TYPE" =~ (^|:)research-analyst$ ]] || deny "subagent type is not authorized for phase $PHASE."
        ;;
    requirements)
        [[ "$SUBAGENT_TYPE" =~ (^|:)product-manager$ ]] || deny "subagent type is not authorized for phase $PHASE."
        ;;
    design)
        [[ "$SUBAGENT_TYPE" =~ (^|:)architect-reviewer$ ]] || deny "subagent type is not authorized for phase $PHASE."
        ;;
    tasks)
        [[ "$SUBAGENT_TYPE" =~ (^|:)task-planner$ ]] || deny "subagent type is not authorized for phase $PHASE."
        ;;
    triage)
        [[ "$SUBAGENT_TYPE" =~ (^|:)(triage-analyst|research-analyst)$ ]] || deny "subagent type is not authorized for phase $PHASE."
        ;;
    *) deny "gate phase is not an artifact phase." ;;
esac

[[ "$STATE" = /* ]] || deny "gate state path must be absolute."
case "$STATE" in
    */.ralph-state.json|*/.epic-state.json) ;;
    *) deny "gate state must be a Ralph spec or epic state file." ;;
esac
[ -f "$STATE" ] || deny "gate state file does not exist."

canonical_file() {
    local path=$1
    local directory
    directory=$(cd "$(dirname "$path")" 2>/dev/null && pwd -P) || return 1
    printf '%s/%s\n' "$directory" "$(basename "$path")"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_CWD="$CWD"
export RALPH_CWD
source "$SCRIPT_DIR/path-resolver.sh"

EXPECTED_STATES=()
SPEC_PATH=$(ralph_resolve_current 2>/dev/null) || true
if [ -n "$SPEC_PATH" ]; then
    case "$SPEC_PATH" in
        /*) SPEC_STATE="$SPEC_PATH/.ralph-state.json" ;;
        *) SPEC_STATE="$CWD/$SPEC_PATH/.ralph-state.json" ;;
    esac
    if [ -f "$SPEC_STATE" ]; then
        EXPECTED_STATES+=("$(canonical_file "$SPEC_STATE")")
    fi
fi

CURRENT_EPIC_FILE="$CWD/specs/.current-epic"
if [ -f "$CURRENT_EPIC_FILE" ]; then
    EPIC_NAME=$(tr -d '[:space:]' < "$CURRENT_EPIC_FILE")
    if [[ "$EPIC_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        EPIC_STATE="$CWD/specs/_epics/$EPIC_NAME/.epic-state.json"
        if [ -f "$EPIC_STATE" ]; then
            EXPECTED_STATES+=("$(canonical_file "$EPIC_STATE")")
        fi
    fi
fi

CANONICAL_STATE=$(canonical_file "$STATE") || deny "gate state path cannot be resolved."
STATE_IS_ACTIVE=false
for EXPECTED_STATE in "${EXPECTED_STATES[@]}"; do
    if [ "$CANONICAL_STATE" = "$EXPECTED_STATE" ]; then
        STATE_IS_ACTIVE=true
        break
    fi
done
[ "$STATE_IS_ACTIVE" = true ] || deny "gate state does not match the active spec or epic state for hook cwd."

PHASE_GATE="$SCRIPT_DIR/../../scripts/phase_gate.py"
[ -f "$PHASE_GATE" ] || deny "phase_gate.py is unavailable."

set +e
GATE_OUTPUT=$(python3 "$PHASE_GATE" check-delegation "$STATE" \
    --phase "$PHASE" \
    --interview-id "$INTERVIEW_ID" \
    --discovery-revision "$REVISION" \
    --context-digest "$DIGEST" 2>&1)
GATE_STATUS=$?
set -e

if [ "$GATE_STATUS" -ne 0 ]; then
    deny "$GATE_OUTPUT"
fi

exit 0
