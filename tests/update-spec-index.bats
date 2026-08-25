#!/usr/bin/env bats
# Regression tests for update-spec-index.sh's stale-state reconciliation.
#
# Bug: when .ralph-state.json exists, its phase/taskIndex/totalTasks were
# trusted unconditionally, even when tasks.md shows every task checked off.
# A spec finished outside a watched implement loop (no stop-watcher.sh run
# to delete/refresh the state file) then displays as stuck forever.

load 'helpers/setup.bash'

# Create tasks.md with every task checked off (create_tasks_file only emits
# unchecked boxes, which can never trip the reconciliation).
create_completed_tasks_file() {
    local total_tasks="${1:-3}"
    local spec_dir="${2:-$TEST_WORKSPACE/specs/test-spec}"

    cat > "$spec_dir/tasks.md" <<EOF
---
spec: test-spec
phase: tasks
total_tasks: $total_tasks
---

# Tasks: test-spec

## Phase 1: POC

EOF

    for i in $(seq 1 "$total_tasks"); do
        echo "- [x] 1.$i Task number $i" >> "$spec_dir/tasks.md"
    done
}

# update-spec-index.sh resolves paths via $PWD (RALPH_CWD), not JSON stdin
# like stop-watcher.sh -- run it with TEST_WORKSPACE as cwd.
run_update_spec_index() {
    (cd "$TEST_WORKSPACE" && bash "$INDEX_SCRIPT" --quiet)
}

@test "reconciles a stale .ralph-state.json against a fully completed tasks.md" {
    create_completed_tasks_file 3
    create_state_file "tasks" 0 0 1

    run run_update_spec_index
    [ "$status" -eq 0 ]

    local state_json="$TEST_WORKSPACE/specs/.index/index-state.json"
    [ -f "$state_json" ]

    run jq -r '.specs[0].phase' "$state_json"
    [ "$output" = "completed" ]

    run jq -r '.specs[0].taskIndex' "$state_json"
    [ "$output" = "3" ]

    run jq -r '.specs[0].totalTasks' "$state_json"
    [ "$output" = "3" ]
}

@test "leaves an in-progress spec's phase untouched" {
    create_tasks_file 5
    create_state_file "execution" 2 5 1

    run run_update_spec_index
    [ "$status" -eq 0 ]

    local state_json="$TEST_WORKSPACE/specs/.index/index-state.json"
    run jq -r '.specs[0].phase' "$state_json"
    [ "$output" = "execution" ]

    run jq -r '.specs[0].taskIndex' "$state_json"
    [ "$output" = "2" ]
}

@test "human-readable index.md shows done status for the reconciled spec" {
    create_completed_tasks_file 3
    create_state_file "tasks" 0 0 1

    run run_update_spec_index
    [ "$status" -eq 0 ]

    local index_md="$TEST_WORKSPACE/specs/.index/index.md"
    run grep -F '| test-spec |' "$index_md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"| completed |"* ]]
    [[ "$output" == *"| done |"* ]]
}

# prototype_metrics reads activePrototypes from the same state file that
# resolve_spec_state reads; both index outputs must keep reporting it.
@test "prototype overlay still reads activePrototypes from the state file" {
    create_tasks_file 5
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"
    jq '.activePrototypes = {"probe": {"id": "probe", "status": "pending"}}' \
        "$state_file" > "$state_file.tmp"
    mv "$state_file.tmp" "$state_file"

    run run_update_spec_index
    [ "$status" -eq 0 ]

    run jq -r '.specs[0].prototype.active' "$TEST_WORKSPACE/specs/.index/index-state.json"
    [ "$output" = "1" ]

    run grep -F '| test-spec |' "$TEST_WORKSPACE/specs/.index/index.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"prototypes a=1 "* ]]
}
