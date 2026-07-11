#!/bin/bash
# Atomically merge top-level fields into Claude's disposable runtime state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-resolver.sh"

usage() {
    cat >&2 <<'EOF'
Usage: update-runtime-state.sh <state-file> [updates...]

Updates:
  --string KEY VALUE   Merge a string field
  --json KEY JSON      Merge a JSON field
  --filter JQ_FILTER   Apply a trusted jq filter before the field merge
  --arg KEY VALUE      Bind a string argument for --filter
  --argjson KEY JSON   Bind a JSON argument for --filter
EOF
    exit 2
}

[ "$#" -ge 2 ] || usage

STATE_INPUT="$1"
shift
if ! STATE_FILE=$(ralph_resolve_workspace_path "$STATE_INPUT"); then
    echo "ERROR: Runtime state path escapes RALPH_CWD: $STATE_INPUT" >&2
    exit 1
fi

STATE_DIR=$(dirname "$STATE_FILE")
[ -d "$STATE_DIR" ] || {
    echo "ERROR: Runtime state directory does not exist: $STATE_DIR" >&2
    exit 1
}

PATCH='{}'
FILTER='.'
JQ_ARGS=()
while [ "$#" -gt 0 ]; do
    MODE="$1"

    case "$MODE" in
        --string)
            [ "$#" -ge 3 ] || usage
            KEY="$2"
            VALUE="$3"
            [[ "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
                echo "ERROR: Invalid runtime state key: $KEY" >&2
                exit 1
            }
            PATCH=$(jq -c --arg key "$KEY" --arg value "$VALUE" \
                '. + {($key): $value}' <<< "$PATCH")
            shift 3
            ;;
        --json)
            [ "$#" -ge 3 ] || usage
            KEY="$2"
            VALUE="$3"
            [[ "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
                echo "ERROR: Invalid runtime state key: $KEY" >&2
                exit 1
            }
            jq -e . >/dev/null <<< "$VALUE" || {
                echo "ERROR: Invalid JSON value for runtime state key: $KEY" >&2
                exit 1
            }
            PATCH=$(jq -c --arg key "$KEY" --argjson value "$VALUE" \
                '. + {($key): $value}' <<< "$PATCH")
            shift 3
            ;;
        --filter)
            [ "$#" -ge 2 ] || usage
            FILTER="$2"
            shift 2
            ;;
        --arg)
            [ "$#" -ge 3 ] || usage
            JQ_ARGS+=(--arg "$2" "$3")
            shift 3
            ;;
        --argjson)
            [ "$#" -ge 3 ] || usage
            jq -e . >/dev/null <<< "$3" || {
                echo "ERROR: Invalid JSON jq argument: $2" >&2
                exit 1
            }
            JQ_ARGS+=(--argjson "$2" "$3")
            shift 3
            ;;
        *)
            usage
            ;;
    esac
done

LOCK_DIR="$STATE_FILE.lock"
LOCK_HELD=false
STATE_TMP=""

cleanup() {
    [ -z "$STATE_TMP" ] || rm -f -- "$STATE_TMP"
    if [ "$LOCK_HELD" = true ]; then
        rm -f -- "$LOCK_DIR/pid"
        rmdir -- "$LOCK_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

LOCK_ATTEMPTS=0
until mkdir -- "$LOCK_DIR" 2>/dev/null; do
    if [ -f "$LOCK_DIR/pid" ]; then
        LOCK_PID=$(cat "$LOCK_DIR/pid" 2>/dev/null || true)
        if [ -n "$LOCK_PID" ] && ! kill -0 "$LOCK_PID" 2>/dev/null; then
            rm -f -- "$LOCK_DIR/pid"
            rmdir -- "$LOCK_DIR" 2>/dev/null || true
            continue
        fi
    fi
    LOCK_ATTEMPTS=$((LOCK_ATTEMPTS + 1))
    if [ "$LOCK_ATTEMPTS" -ge 400 ]; then
        echo "ERROR: Timed out waiting for runtime state lock: $STATE_FILE" >&2
        exit 1
    fi
    sleep 0.05
done
LOCK_HELD=true
printf '%s\n' "$$" > "$LOCK_DIR/pid"

if [ -f "$STATE_FILE" ]; then
    jq -e 'type == "object"' "$STATE_FILE" >/dev/null || {
        echo "ERROR: Runtime state is not a valid JSON object: $STATE_FILE" >&2
        exit 1
    }
    SOURCE_FILE="$STATE_FILE"
else
    SOURCE_FILE=/dev/null
fi

STATE_TMP=$(mktemp "$STATE_DIR/.ralph-state.json.tmp.XXXXXX")
if [ "$SOURCE_FILE" = /dev/null ]; then
    jq "${JQ_ARGS[@]}" "$FILTER" <<< '{}' \
        | jq --argjson patch "$PATCH" '. + $patch' > "$STATE_TMP"
else
    jq "${JQ_ARGS[@]}" "$FILTER" "$SOURCE_FILE" \
        | jq --argjson patch "$PATCH" '. + $patch' > "$STATE_TMP"
fi
jq -e 'type == "object"' "$STATE_TMP" >/dev/null
mv -f -- "$STATE_TMP" "$STATE_FILE"
STATE_TMP=""
