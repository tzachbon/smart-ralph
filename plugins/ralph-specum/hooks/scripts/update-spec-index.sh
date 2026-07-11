#!/bin/bash
# Spec Index Updater for Ralph Specum
# Updates ./specs/.index/ with current spec state across all directories
#
# Usage: update-spec-index.sh [--quiet]
#
# Creates/updates:
#   ./specs/.index/index-state.json - Machine-readable state
#   ./specs/.index/index.md - Human-readable summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-resolver.sh"

QUIET=false
if [ "${1:-}" = "--quiet" ]; then
    QUIET=true
fi

log() {
    if [ "$QUIET" = false ]; then
        echo "$1"
    fi
}

# Resolve the index location from the canonical workspace root. Keep the
# configured path for display, but never use it directly for filesystem I/O.
WORKSPACE_ROOT=$(ralph_get_workspace_root)
DEFAULT_DIR_CONFIGURED=$(ralph_get_default_dir)
if ! DEFAULT_DIR=$(ralph_resolve_workspace_path "$DEFAULT_DIR_CONFIGURED"); then
    echo "ERROR: Default specs directory escapes RALPH_CWD: $DEFAULT_DIR_CONFIGURED" >&2
    exit 1
fi
INDEX_DIR="$DEFAULT_DIR/.index"

# Create index directory
mkdir -p "$INDEX_DIR"

# Serialize the complete two-file update per workspace. A directory lock keeps
# the implementation dependency-free and can be removed without leaving a
# lock file in the generated index.
LOCK_DIR="$INDEX_DIR/.update.lock"
LOCK_HELD=false
STATE_TMP=""
INDEX_TMP=""

cleanup() {
    [ -z "$STATE_TMP" ] || rm -f -- "$STATE_TMP"
    [ -z "$INDEX_TMP" ] || rm -f -- "$INDEX_TMP"
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
        echo "ERROR: Timed out waiting for spec index lock in $WORKSPACE_ROOT" >&2
        exit 1
    fi
    sleep 0.05
done
LOCK_HELD=true
printf '%s\n' "$$" > "$LOCK_DIR/pid"

# Get all configured directories
SPECS_DIRS=$(ralph_get_specs_dirs)

# Build directories array for JSON
DIRS_JSON="["
FIRST_DIR=true
TOTAL_SPECS=0

while IFS= read -r dir; do
    [ -z "$dir" ] && continue

    if ! RESOLVED_DIR=$(ralph_resolve_workspace_path "$dir"); then
        continue
    fi

    # Count specs in this directory
    SPEC_COUNT=0
    if [ -d "$RESOLVED_DIR" ]; then
        SPEC_COUNT=$(find "$RESOLVED_DIR" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    fi
    TOTAL_SPECS=$((TOTAL_SPECS + SPEC_COUNT))

    # Determine if this is the default directory
    IS_DEFAULT=false
    if [ "$RESOLVED_DIR" = "$DEFAULT_DIR" ]; then
        IS_DEFAULT=true
    fi

    # Add to JSON array
    if [ "$FIRST_DIR" = true ]; then
        FIRST_DIR=false
    else
        DIRS_JSON="$DIRS_JSON,"
    fi

    DIRS_JSON="$DIRS_JSON
    {
      \"path\": \"$dir\",
      \"specsCount\": $SPEC_COUNT,
      \"isDefault\": $IS_DEFAULT
    }"
done <<< "$SPECS_DIRS"

DIRS_JSON="$DIRS_JSON
  ]"

# Build specs array for JSON
SPECS_JSON="["
FIRST_SPEC=true

# Get all specs using path resolver
ALL_SPECS=$(ralph_list_specs)

while IFS='|' read -r name path; do
    [ -z "$name" ] && continue

    if ! RESOLVED_PATH=$(ralph_resolve_workspace_path "$path"); then
        continue
    fi

    # Read state from .ralph-state.json if exists
    STATE_FILE="$RESOLVED_PATH/.ralph-state.json"
    PHASE="unknown"
    TASK_INDEX=0
    TOTAL_TASKS=0
    AWAITING_APPROVAL=false

    if [ -f "$STATE_FILE" ]; then
        PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        AWAITING_APPROVAL=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo false)
    else
        # No state file - check what files exist to determine phase
        if [ -f "$RESOLVED_PATH/tasks.md" ]; then
            # Count completed tasks
            COMPLETED=$(grep -c '\- \[x\]' "$RESOLVED_PATH/tasks.md" 2>/dev/null || true)
            TOTAL_TASKS=$(grep -c '\- \[.\]' "$RESOLVED_PATH/tasks.md" 2>/dev/null || true)
            COMPLETED=${COMPLETED:-0}
            TOTAL_TASKS=${TOTAL_TASKS:-0}
            if [ "$COMPLETED" -eq "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
                PHASE="completed"
            else
                PHASE="tasks"
            fi
            TASK_INDEX=$COMPLETED
        elif [ -f "$RESOLVED_PATH/design.md" ]; then
            PHASE="design"
        elif [ -f "$RESOLVED_PATH/requirements.md" ]; then
            PHASE="requirements"
        elif [ -f "$RESOLVED_PATH/research.md" ]; then
            PHASE="research"
        else
            PHASE="new"
        fi
    fi

    # Add to JSON array
    if [ "$FIRST_SPEC" = true ]; then
        FIRST_SPEC=false
    else
        SPECS_JSON="$SPECS_JSON,"
    fi

    # Build spec JSON object
    SPEC_OBJ="{
      \"name\": \"$name\",
      \"path\": \"$path\",
      \"phase\": \"$PHASE\""

    if [ "$PHASE" = "execution" ] || [ "$TOTAL_TASKS" -gt 0 ]; then
        SPEC_OBJ="$SPEC_OBJ,
      \"taskIndex\": $TASK_INDEX,
      \"totalTasks\": $TOTAL_TASKS"
    fi

    if [ "$AWAITING_APPROVAL" = "true" ]; then
        SPEC_OBJ="$SPEC_OBJ,
      \"awaitingApproval\": true"
    fi

    SPEC_OBJ="$SPEC_OBJ
    }"

    SPECS_JSON="$SPECS_JSON
    $SPEC_OBJ"
done <<< "$ALL_SPECS"

SPECS_JSON="$SPECS_JSON
  ]"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build both outputs in unique temporary files. Publishing with mv keeps each
# visible file complete even when updates run concurrently.
STATE_TMP=$(mktemp "$INDEX_DIR/.index-state.json.tmp.XXXXXX")
INDEX_TMP=$(mktemp "$INDEX_DIR/.index.md.tmp.XXXXXX")

cat > "$STATE_TMP" << EOF
{
  "version": "1.0",
  "updated": "$TIMESTAMP",
  "directories": $DIRS_JSON,
  "specs": $SPECS_JSON
}
EOF

# Generate human-readable index.md
# Count directories
DIR_COUNT=$(echo "$SPECS_DIRS" | grep -c . || echo 0)

cat > "$INDEX_TMP" << EOF
# Spec Index

Auto-generated summary of all specs across configured directories.
See [index-state.json](./index-state.json) for machine-readable data.

**Last updated:** $TIMESTAMP

## Directories ($DIR_COUNT)

| Directory | Specs | Default |
|-----------|-------|---------|
EOF

# Add directory rows
while IFS= read -r dir; do
    [ -z "$dir" ] && continue

    if ! RESOLVED_DIR=$(ralph_resolve_workspace_path "$dir"); then
        continue
    fi

    SPEC_COUNT=0
    if [ -d "$RESOLVED_DIR" ]; then
        SPEC_COUNT=$(find "$RESOLVED_DIR" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    fi

    DEFAULT_MARKER=""
    if [ "$RESOLVED_DIR" = "$DEFAULT_DIR" ]; then
        DEFAULT_MARKER="Yes"
    fi

    echo "| $dir | $SPEC_COUNT | $DEFAULT_MARKER |" >> "$INDEX_TMP"
done <<< "$SPECS_DIRS"

# Add specs table
cat >> "$INDEX_TMP" << EOF

## All Specs ($TOTAL_SPECS)

| Spec | Directory | Phase | Status |
|------|-----------|-------|--------|
EOF

# Add spec rows
while IFS='|' read -r name path; do
    [ -z "$name" ] && continue

    if ! RESOLVED_PATH=$(ralph_resolve_workspace_path "$path"); then
        continue
    fi

    # Get directory from path
    DIR=$(dirname "$path")

    # Read state
    STATE_FILE="$RESOLVED_PATH/.ralph-state.json"
    PHASE="unknown"
    STATUS=""

    if [ -f "$STATE_FILE" ]; then
        PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo false)

        if [ "$PHASE" = "execution" ]; then
            STATUS="$TASK_INDEX/$TOTAL_TASKS tasks"
        elif [ "$AWAITING" = "true" ]; then
            STATUS="awaiting approval"
        fi
    else
        # Determine from files
        if [ -f "$RESOLVED_PATH/tasks.md" ]; then
            COMPLETED=$(grep -c '\- \[x\]' "$RESOLVED_PATH/tasks.md" 2>/dev/null || true)
            TOTAL=$(grep -c '\- \[.\]' "$RESOLVED_PATH/tasks.md" 2>/dev/null || true)
            COMPLETED=${COMPLETED:-0}
            TOTAL=${TOTAL:-0}
            if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
                PHASE="completed"
                STATUS="done"
            else
                PHASE="tasks"
                STATUS="$COMPLETED/$TOTAL tasks"
            fi
        elif [ -f "$RESOLVED_PATH/design.md" ]; then
            PHASE="design"
        elif [ -f "$RESOLVED_PATH/requirements.md" ]; then
            PHASE="requirements"
        elif [ -f "$RESOLVED_PATH/research.md" ]; then
            PHASE="research"
        else
            PHASE="new"
        fi
    fi

    echo "| $name | $DIR | $PHASE | $STATUS |" >> "$INDEX_TMP"
done <<< "$ALL_SPECS"

# Add footer
cat >> "$INDEX_TMP" << EOF

---

**Commands:**
- \`/ralph-specum:status\` - Show detailed status
- \`/ralph-specum:switch <name>\` - Switch active spec
- \`/ralph-specum:start <name>\` - Create or resume spec
EOF

mv -f -- "$STATE_TMP" "$INDEX_DIR/index-state.json"
STATE_TMP=""
mv -f -- "$INDEX_TMP" "$INDEX_DIR/index.md"
INDEX_TMP=""

log "Updated $INDEX_DIR/index-state.json"
log "Updated $INDEX_DIR/index.md"
log "Spec index updated: $TOTAL_SPECS specs in $DIR_COUNT directories"
