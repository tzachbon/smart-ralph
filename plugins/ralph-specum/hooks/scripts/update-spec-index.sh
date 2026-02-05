#!/bin/bash
# Spec Index Updater for Ralph Specum
# Updates ./specs/.index/ with current spec state across all directories
#
# Usage: update-spec-index.sh [--quiet]
#
# Creates/updates:
#   ./specs/.index/index-state.json - Machine-readable state
#   ./specs/.index/index.md - Human-readable summary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-resolver.sh"

QUIET=false
if [ "$1" = "--quiet" ]; then
    QUIET=true
fi

log() {
    if [ "$QUIET" = false ]; then
        echo "$1"
    fi
}

# Get default specs dir for index location
DEFAULT_DIR=$(ralph_get_default_dir)
INDEX_DIR="$DEFAULT_DIR/.index"

# Create index directory
mkdir -p "$INDEX_DIR"

# Get all configured directories
SPECS_DIRS=$(ralph_get_specs_dirs)

# Build directories array for JSON
DIRS_JSON="["
FIRST_DIR=true
TOTAL_SPECS=0

while IFS= read -r dir; do
    [ -z "$dir" ] && continue

    # Count specs in this directory
    SPEC_COUNT=0
    if [ -d "$dir" ]; then
        SPEC_COUNT=$(find "$dir" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    fi
    TOTAL_SPECS=$((TOTAL_SPECS + SPEC_COUNT))

    # Determine if this is the default directory
    IS_DEFAULT=false
    if [ "$dir" = "$DEFAULT_DIR" ]; then
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

    # Read state from .ralph-state.json if exists
    STATE_FILE="$path/.ralph-state.json"
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
        if [ -f "$path/tasks.md" ]; then
            # Count completed tasks
            COMPLETED=$(grep -c '\- \[x\]' "$path/tasks.md" 2>/dev/null || echo 0)
            TOTAL_TASKS=$(grep -c '\- \[.\]' "$path/tasks.md" 2>/dev/null || echo 0)
            if [ "$COMPLETED" -eq "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
                PHASE="completed"
            else
                PHASE="tasks"
            fi
            TASK_INDEX=$COMPLETED
        elif [ -f "$path/design.md" ]; then
            PHASE="design"
        elif [ -f "$path/requirements.md" ]; then
            PHASE="requirements"
        elif [ -f "$path/research.md" ]; then
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

# Write index-state.json
cat > "$INDEX_DIR/index-state.json" << EOF
{
  "version": "1.0",
  "updated": "$TIMESTAMP",
  "directories": $DIRS_JSON,
  "specs": $SPECS_JSON
}
EOF

log "Updated $INDEX_DIR/index-state.json"

# Generate human-readable index.md
# Count directories
DIR_COUNT=$(echo "$SPECS_DIRS" | grep -c . || echo 0)

cat > "$INDEX_DIR/index.md" << EOF
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

    SPEC_COUNT=0
    if [ -d "$dir" ]; then
        SPEC_COUNT=$(find "$dir" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    fi

    DEFAULT_MARKER=""
    if [ "$dir" = "$DEFAULT_DIR" ]; then
        DEFAULT_MARKER="Yes"
    fi

    echo "| $dir | $SPEC_COUNT | $DEFAULT_MARKER |" >> "$INDEX_DIR/index.md"
done <<< "$SPECS_DIRS"

# Add specs table
cat >> "$INDEX_DIR/index.md" << EOF

## All Specs ($TOTAL_SPECS)

| Spec | Directory | Phase | Status |
|------|-----------|-------|--------|
EOF

# Add spec rows
while IFS='|' read -r name path; do
    [ -z "$name" ] && continue

    # Get directory from path
    DIR=$(dirname "$path")

    # Read state
    STATE_FILE="$path/.ralph-state.json"
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
        if [ -f "$path/tasks.md" ]; then
            COMPLETED=$(grep -c '\- \[x\]' "$path/tasks.md" 2>/dev/null || echo 0)
            TOTAL=$(grep -c '\- \[.\]' "$path/tasks.md" 2>/dev/null || echo 0)
            if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
                PHASE="completed"
                STATUS="done"
            else
                PHASE="tasks"
                STATUS="$COMPLETED/$TOTAL tasks"
            fi
        elif [ -f "$path/design.md" ]; then
            PHASE="design"
        elif [ -f "$path/requirements.md" ]; then
            PHASE="requirements"
        elif [ -f "$path/research.md" ]; then
            PHASE="research"
        else
            PHASE="new"
        fi
    fi

    echo "| $name | $DIR | $PHASE | $STATUS |" >> "$INDEX_DIR/index.md"
done <<< "$ALL_SPECS"

# Add footer
cat >> "$INDEX_DIR/index.md" << EOF

---

**Commands:**
- \`/ralph-specum:status\` - Show detailed status
- \`/ralph-specum:switch <name>\` - Switch active spec
- \`/ralph-specum:start <name>\` - Create or resume spec
EOF

log "Updated $INDEX_DIR/index.md"
log "Spec index updated: $TOTAL_SPECS specs in $DIR_COUNT directories"
