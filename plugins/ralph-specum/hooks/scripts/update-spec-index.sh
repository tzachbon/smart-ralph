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
# shellcheck disable=SC1091
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

# Print tab-separated overlay counts and dependency data for one resolved spec path.
prototype_metrics() {
    local base_path="$1"
    local state_file="$2"
    local prototype_dir="$base_path/prototypes"
    local active_count=0 candidate_count=0 final_file_count=0 quarantine_file_count=0
    local selection='{}' malformed_count=0 final_count=0 quarantine_count=0
    local blockers='[]' blocker_count=0 stale_artifacts='[]' stale_tasks='[]'

    if [ -f "$state_file" ]; then
        active_count=$(jq -r '(.activePrototypes // {}) | length' "$state_file" 2>/dev/null || echo 0)
    fi
    if [ "$active_count" -gt 0 ] || [ -d "$prototype_dir" ]; then
        candidate_count=$(find "$prototype_dir" -maxdepth 1 -type f -name '.*.candidate.md' 2>/dev/null | wc -l | tr -d ' ')
        final_file_count=$(find "$prototype_dir" -maxdepth 1 -type f -name '*.md' ! -name '.*' ! -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
        quarantine_file_count=$(find "$prototype_dir" -maxdepth 1 -type f -name '*.quarantine.md' 2>/dev/null | wc -l | tr -d ' ')
        if [ -f "$state_file" ]; then
            selection=$(python3 "$SCRIPT_DIR/prototype-records.py" select-downstream --base-path "$base_path" --state "$state_file" 2>/dev/null || printf '{}')
        else
            selection=$(python3 "$SCRIPT_DIR/prototype-records.py" select-downstream --base-path "$base_path" 2>/dev/null || printf '{}')
        fi
        malformed_count=$(printf '%s' "$selection" | jq -r '(.quarantined // []) | length' 2>/dev/null || echo 0)
        blockers=$(printf '%s' "$selection" | jq -c '.activeBlockers // []' 2>/dev/null || printf '[]')
        blocker_count=$(printf '%s' "$blockers" | jq -r 'length' 2>/dev/null || echo 0)
        stale_artifacts=$(printf '%s' "$selection" | jq -c '.staleArtifacts // []' 2>/dev/null || printf '[]')
        stale_tasks=$(printf '%s' "$selection" | jq -c '.staleTaskIndexes // []' 2>/dev/null || printf '[]')
    fi
    final_count=$((final_file_count - malformed_count))
    [ "$final_count" -lt 0 ] && final_count=0
    quarantine_count=$((quarantine_file_count + malformed_count))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$active_count" "$candidate_count" "$final_count" "$quarantine_count" \
        "$blocker_count" "$blockers" "$stale_artifacts" "$stale_tasks"
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

# Resolve STATE_FILE/PHASE/TASK_INDEX/TOTAL_TASKS/AWAITING_APPROVAL for one
# spec. STATE_FILE is set here, once, because prototype_metrics reads it too.
# A .ralph-state.json is trusted only when it does not contradict tasks.md:
# if tasks.md shows every task checked off, that always wins over a stale
# or absent state file (the only prior refresh path -- stop-watcher.sh's
# ALL_TASKS_COMPLETE transcript scan -- can silently never fire).
resolve_spec_state() {
    local spec_path="$1"
    local tm_completed=0 tm_total=0

    STATE_FILE="$spec_path/.ralph-state.json"

    PHASE="unknown"; TASK_INDEX=0; TOTAL_TASKS=0; AWAITING_APPROVAL=false

    # Count tasks.md once; the no-state-file branch and the
    # reconciliation below both read these.
    if [ -f "$spec_path/tasks.md" ]; then
        tm_completed=$(grep -c '\- \[x\]' "$spec_path/tasks.md" 2>/dev/null) || tm_completed=0
        tm_total=$(grep -c '\- \[.\]' "$spec_path/tasks.md" 2>/dev/null) || tm_total=0
    fi

    if [ -f "$STATE_FILE" ]; then
        PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        AWAITING_APPROVAL=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo false)
    elif [ -f "$spec_path/tasks.md" ]; then
        TASK_INDEX=$tm_completed
        TOTAL_TASKS=$tm_total
        if [ "$TASK_INDEX" -eq "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
            PHASE="completed"
        else
            PHASE="tasks"
        fi
    elif [ -f "$spec_path/design.md" ]; then
        PHASE="design"
    elif [ -f "$spec_path/requirements.md" ]; then
        PHASE="requirements"
    elif [ -f "$spec_path/research.md" ]; then
        PHASE="research"
    else
        PHASE="new"
    fi

    # Reconciliation: a stale/absent state file must never outrank a
    # tasks.md that shows the spec fully checked off. (tm_total stays 0
    # when tasks.md is absent, so this is a no-op then.) awaitingApproval
    # is deliberately left alone: it is a live gate (written by tasks.md
    # Step 6, honoured by stop-watcher.sh) and cannot be derived from
    # tasks.md. Assignments are idempotent when PHASE is already
    # "completed", which also repairs a completed state file frozen at
    # totalTasks:0.
    if [ "$tm_completed" -eq "$tm_total" ] && [ "$tm_total" -gt 0 ]; then
        PHASE="completed"
        TASK_INDEX=$tm_completed
        TOTAL_TASKS=$tm_total
    fi
}

# Build specs array for JSON
SPECS_JSON="["
FIRST_SPEC=true

# Get all specs using path resolver
ALL_SPECS=$(ralph_list_specs)

while IFS='|' read -r name path; do
    [ -z "$name" ] && continue

    resolve_spec_state "$path"

    IFS=$'\t' read -r PROTOTYPE_ACTIVE PROTOTYPE_CANDIDATES PROTOTYPE_FINALS PROTOTYPE_QUARANTINED \
        PROTOTYPE_BLOCKER_COUNT PROTOTYPE_BLOCKERS PROTOTYPE_STALE_ARTIFACTS PROTOTYPE_STALE_TASKS \
        <<< "$(prototype_metrics "$path" "$STATE_FILE")"

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

    if [ "$PROTOTYPE_ACTIVE" -gt 0 ] || [ "$PROTOTYPE_CANDIDATES" -gt 0 ] || \
       [ "$PROTOTYPE_FINALS" -gt 0 ] || [ "$PROTOTYPE_QUARANTINED" -gt 0 ] || \
       [ "$PROTOTYPE_STALE_ARTIFACTS" != "[]" ] || [ "$PROTOTYPE_STALE_TASKS" != "[]" ]; then
        SPEC_OBJ="$SPEC_OBJ,
      \"prototype\": {
        \"active\": $PROTOTYPE_ACTIVE,
        \"candidates\": $PROTOTYPE_CANDIDATES,
        \"finals\": $PROTOTYPE_FINALS,
        \"quarantined\": $PROTOTYPE_QUARANTINED,
        \"activeBlockers\": $PROTOTYPE_BLOCKERS,
        \"staleArtifacts\": $PROTOTYPE_STALE_ARTIFACTS,
        \"staleTaskIndexes\": $PROTOTYPE_STALE_TASKS
      }"
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

    resolve_spec_state "$path"

    STATUS=""
    if [ "$PHASE" = "execution" ]; then
        STATUS="$TASK_INDEX/$TOTAL_TASKS tasks"
    elif [ "$AWAITING_APPROVAL" = "true" ]; then
        STATUS="awaiting approval"
    elif [ "$PHASE" = "completed" ]; then
        STATUS="done"
    elif [ "$PHASE" = "tasks" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
        STATUS="$TASK_INDEX/$TOTAL_TASKS tasks"
    fi

    IFS=$'\t' read -r PROTOTYPE_ACTIVE PROTOTYPE_CANDIDATES PROTOTYPE_FINALS PROTOTYPE_QUARANTINED \
        PROTOTYPE_BLOCKER_COUNT PROTOTYPE_BLOCKERS PROTOTYPE_STALE_ARTIFACTS PROTOTYPE_STALE_TASKS \
        <<< "$(prototype_metrics "$path" "$STATE_FILE")"
    if [ "$PROTOTYPE_ACTIVE" -gt 0 ] || [ "$PROTOTYPE_CANDIDATES" -gt 0 ] || \
       [ "$PROTOTYPE_FINALS" -gt 0 ] || [ "$PROTOTYPE_QUARANTINED" -gt 0 ] || \
       [ "$PROTOTYPE_STALE_ARTIFACTS" != "[]" ] || [ "$PROTOTYPE_STALE_TASKS" != "[]" ]; then
        STALE_COUNT=$(printf '%s\n%s' "$PROTOTYPE_STALE_ARTIFACTS" "$PROTOTYPE_STALE_TASKS" | jq -s 'map(length) | add' 2>/dev/null || echo 0)
        PROTOTYPE_STATUS="prototypes a=$PROTOTYPE_ACTIVE c=$PROTOTYPE_CANDIDATES f=$PROTOTYPE_FINALS q=$PROTOTYPE_QUARANTINED blockers=$PROTOTYPE_BLOCKER_COUNT stale=$STALE_COUNT"
        if [ -n "$STATUS" ]; then
            STATUS="$STATUS; $PROTOTYPE_STATUS"
        else
            STATUS="$PROTOTYPE_STATUS"
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
