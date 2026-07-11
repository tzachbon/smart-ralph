#!/usr/bin/env bats

setup() {
    TEST_ROOT="$(mktemp -d)"
    TARGET_WORKSPACE="$TEST_ROOT/target"
    CALLER_WORKSPACE="$TEST_ROOT/caller"
    OUTSIDE_WORKSPACE="$TEST_ROOT/outside"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    INDEX_SCRIPT="$REPO_ROOT/plugins/ralph-specum/hooks/scripts/update-spec-index.sh"

    mkdir -p "$TARGET_WORKSPACE/specs/example" "$CALLER_WORKSPACE" "$OUTSIDE_WORKSPACE"
    printf '%s\n' '- [ ] 1.1 Example task' > "$TARGET_WORKSPACE/specs/example/tasks.md"
}

teardown() {
    rm -rf "$TEST_ROOT"
}

snapshot_index() {
    local index_dir="$1"

    if [ ! -d "$index_dir" ]; then
        printf '%s\n' '<missing>'
        return
    fi

    find "$index_dir" -type f -print0 \
        | sort -z \
        | xargs -0 -r sha256sum
}

@test "index writes stay inside RALPH_CWD regardless of caller directory" {
    local repo_before
    repo_before="$(snapshot_index "$REPO_ROOT/specs/.index")"

    run bash -c 'cd "$1" && RALPH_CWD="$2" bash "$3" --quiet' \
        _ "$CALLER_WORKSPACE" "$TARGET_WORKSPACE" "$INDEX_SCRIPT"

    [ "$status" -eq 0 ]
    [ -f "$TARGET_WORKSPACE/specs/.index/index-state.json" ]
    [ -f "$TARGET_WORKSPACE/specs/.index/index.md" ]
    [ ! -e "$CALLER_WORKSPACE/specs/.index" ]
    run jq -e '.specs[] | select(.name == "example" and .phase == "tasks")' \
        "$TARGET_WORKSPACE/specs/.index/index-state.json"
    [ "$status" -eq 0 ]
    [ "$repo_before" = "$(snapshot_index "$REPO_ROOT/specs/.index")" ]
}

@test "configured specs directories cannot escape RALPH_CWD" {
    mkdir -p "$TARGET_WORKSPACE/.claude" "$OUTSIDE_WORKSPACE/specs/external"
    ln -s "$OUTSIDE_WORKSPACE/specs" "$TARGET_WORKSPACE/linked-specs"
    printf '%s\n' \
        '---' \
        'specs_dirs: ["../outside/specs", "./linked-specs"]' \
        '---' \
        > "$TARGET_WORKSPACE/.claude/ralph-specum.local.md"
    local outside_before
    outside_before="$(snapshot_index "$OUTSIDE_WORKSPACE/specs/.index")"

    run bash -c 'cd "$1" && RALPH_CWD="$2" bash "$3" --quiet' \
        _ "$CALLER_WORKSPACE" "$TARGET_WORKSPACE" "$INDEX_SCRIPT"

    [ "$status" -eq 0 ]
    [ -f "$TARGET_WORKSPACE/specs/.index/index-state.json" ]
    [ "$outside_before" = "$(snapshot_index "$OUTSIDE_WORKSPACE/specs/.index")" ]
}

@test "concurrent index updates publish complete files without lock residue" {
    run bash -c '
        cd "$1" || exit 1
        for _iteration in 1 2 3 4 5 6 7 8; do
            RALPH_CWD="$2" bash "$3" --quiet &
        done
        wait
    ' _ "$CALLER_WORKSPACE" "$TARGET_WORKSPACE" "$INDEX_SCRIPT"

    [ "$status" -eq 0 ]
    run jq -e '.version == "1.0" and (.specs | length) == 1' \
        "$TARGET_WORKSPACE/specs/.index/index-state.json"
    [ "$status" -eq 0 ]
    run grep -F '# Spec Index' "$TARGET_WORKSPACE/specs/.index/index.md"
    [ "$status" -eq 0 ]
    run find "$TARGET_WORKSPACE/specs/.index" -maxdepth 1 \
        \( -name '*.tmp.*' -o -name '.update.lock' \) -print
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
