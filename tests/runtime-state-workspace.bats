#!/usr/bin/env bats

setup() {
    TEST_ROOT="$(mktemp -d)"
    TARGET_WORKSPACE="$TEST_ROOT/target"
    OUTSIDE_WORKSPACE="$TEST_ROOT/outside"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    STATE_SCRIPT="$REPO_ROOT/plugins/ralph-specum/hooks/scripts/update-runtime-state.sh"
    mkdir -p "$TARGET_WORKSPACE/specs/example" "$OUTSIDE_WORKSPACE"
}

teardown() {
    rm -rf "$TEST_ROOT"
}

@test "runtime state updates reject workspace escape" {
    run env RALPH_CWD="$TARGET_WORKSPACE" bash "$STATE_SCRIPT" \
        "$OUTSIDE_WORKSPACE/.ralph-state.json" --string phase execution

    [ "$status" -ne 0 ]
    [ ! -e "$OUTSIDE_WORKSPACE/.ralph-state.json" ]
}

@test "concurrent runtime state updates merge atomically without residue" {
    run bash -c '
        for iteration in 1 2 3 4 5 6 7 8 9 10 11 12; do
            RALPH_CWD="$1" bash "$2" specs/example/.ralph-state.json \
                --json "writer_$iteration" "$iteration" &
        done
        wait
    ' _ "$TARGET_WORKSPACE" "$STATE_SCRIPT"

    [ "$status" -eq 0 ]
    run jq -e 'type == "object" and length == 12 and .writer_1 == 1 and .writer_12 == 12' \
        "$TARGET_WORKSPACE/specs/example/.ralph-state.json"
    [ "$status" -eq 0 ]
    run find "$TARGET_WORKSPACE/specs/example" -maxdepth 1 \
        \( -name '*.tmp.*' -o -name '*.lock' \) -print
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
