#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

merge_state_script() {
    echo "$(repo_root)/platforms/codex/skills/ralph-specum/scripts/merge_state.py"
}

resolve_spec_paths_script() {
    echo "$(repo_root)/platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py"
}

json_query() {
    local path
    path="$1"
    python3 -c 'import json, sys
value = json.load(sys.stdin)
for part in sys.argv[1].split("."):
    if not part:
        continue
    if part.isdigit():
        value = value[int(part)]
    else:
        value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)' "$path"
}

json_length() {
    python3 -c 'import json, sys; print(len(json.load(sys.stdin)))'
}

write_crlf_file() {
    local path
    path="$1"
    mkdir -p "$(dirname "$path")"
    python3 -c 'from pathlib import Path; import sys; Path(sys.argv[1]).write_bytes(sys.stdin.buffer.read().replace(b"\n", b"\r\n"))' "$path"
}

setup() {
    TEST_REPO="$(mktemp -d)"
    export TEST_REPO
    mkdir -p "$TEST_REPO/.claude"
}

teardown() {
    if [ -n "$TEST_REPO" ] && [ -d "$TEST_REPO" ]; then
        rm -rf "$TEST_REPO"
    fi
}

@test "codex scripts: merge_state rejects malformed json assignments" {
    local script state_file
    script="$(merge_state_script)"
    state_file="$TEST_REPO/state.json"

    run python3 "$script" "$state_file" --json "relatedSpecs={bad"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid JSON for 'relatedSpecs':"* ]]
}

@test "codex scripts: merge_state rejects malformed existing state files" {
    local script state_file
    script="$(merge_state_script)"
    state_file="$TEST_REPO/state.json"
    printf '{ bad\n' > "$state_file"

    run python3 "$script" "$state_file" --set "phase=execution"
    [ "$status" -ne 0 ]
    [[ "$output" == *"State file is not valid JSON:"* ]]
}

@test "codex scripts: merge_state writes atomically without tmp leftovers" {
    local script state_file phase total_tasks
    script="$(merge_state_script)"
    state_file="$TEST_REPO/state.json"

    run python3 "$script" "$state_file" --set "phase=execution" --set "totalTasks=3"
    [ "$status" -eq 0 ]

    phase="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["phase"])' "$state_file")"
    total_tasks="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["totalTasks"])' "$state_file")"

    [ "$phase" = "execution" ]
    [ "$total_tasks" = "3" ]
    [ ! -e "$state_file.tmp" ]
}

@test "codex scripts: resolve_spec_paths handles crlf frontmatter and bool variants" {
    local script default_dir max_iterations auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/packages/specs"
    write_crlf_file "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./missing-specs"
  - "./packages/specs"
default_max_iterations: 7
auto_commit_spec: no
quick_mode_default: yes
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    default_dir="$(json_query default_dir <<< "$output")"
    max_iterations="$(json_query default_max_iterations <<< "$output")"
    auto_commit="$(json_query auto_commit_spec <<< "$output")"

    [ "$default_dir" = "./packages/specs" ]
    [ "$max_iterations" = "7" ]
    [ "$auto_commit" = "false" ]
    [[ "$output" != *"quick_mode_default"* ]]
}

@test "codex scripts: resolve_spec_paths falls back on malformed scalar settings" {
    local script max_iterations auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/specs"
    cat > "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./specs"
default_max_iterations: maybe
auto_commit_spec: perhaps
quick_mode_default: later
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    max_iterations="$(json_query default_max_iterations <<< "$output")"
    auto_commit="$(json_query auto_commit_spec <<< "$output")"

    [ "$max_iterations" = "5" ]
    [ "$auto_commit" = "true" ]
    [[ "$output" != *"quick_mode_default"* ]]
}

@test "codex scripts: resolve_spec_paths ignores deprecated quick mode setting" {
    local script auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/specs"
    cat > "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./specs"
auto_commit_spec: false
quick_mode_default: true
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    auto_commit="$(json_query auto_commit_spec <<< "$output")"

    [ "$auto_commit" = "false" ]
    [[ "$output" != *"quick_mode_default"* ]]
}

@test "codex scripts: resolve_spec_paths skips missing and file roots" {
    local script count first_name
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/good-specs/demo"
    : > "$TEST_REPO/not-a-dir"
    cat > "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./missing-specs"
  - "./not-a-dir"
  - "./good-specs"
---
EOF

    run python3 "$script" --cwd "$TEST_REPO" --list
    [ "$status" -eq 0 ]

    count="$(json_length <<< "$output")"
    first_name="$(json_query 0.name <<< "$output")"

    [ "$count" = "1" ]
    [ "$first_name" = "demo" ]
}

@test "codex scripts: resolve_spec_paths prefers first valid root for default_dir and current spec" {
    local script default_dir
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/packages/specs/demo"
    cat > "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./missing-specs"
  - "./packages/specs"
---
EOF
    echo "demo" > "$TEST_REPO/packages/specs/.current-spec"

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]
    default_dir="$(json_query default_dir <<< "$output")"
    [ "$default_dir" = "./packages/specs" ]

    run python3 "$script" --cwd "$TEST_REPO" --current
    [ "$status" -eq 0 ]
    [ "$output" = "./packages/specs/demo" ]
}

@test "codex scripts: resolve_spec_paths falls back to ./specs when no configured root is valid" {
    local script default_dir
    script="$(resolve_spec_paths_script)"

    : > "$TEST_REPO/not-a-dir"
    cat > "$TEST_REPO/.claude/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./missing-specs"
  - "./not-a-dir"
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    default_dir="$(json_query default_dir <<< "$output")"
    [ "$default_dir" = "./specs" ]
}
