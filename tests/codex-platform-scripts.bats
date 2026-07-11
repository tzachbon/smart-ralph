#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

resolve_spec_paths_script() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/resolve_spec_paths.py"
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
    mkdir -p "$TEST_REPO/.codex"
}

teardown() {
    if [ -n "$TEST_REPO" ] && [ -d "$TEST_REPO" ]; then
        rm -rf "$TEST_REPO"
    fi
}

@test "codex scripts: no adapter continuation state writer is shipped" {
    local root
    root="$(repo_root)/plugins/ralph-specum-codex"
    [ ! -f "$root/scripts/merge_state.py" ]
    [ ! -f "$root/hooks/stop-watcher.sh" ]
}

@test "codex scripts: resolve_spec_paths handles crlf frontmatter and bool variants" {
    local script default_dir auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/packages/specs"
    write_crlf_file "$TEST_REPO/.codex/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./packages/specs"
auto_commit_spec: no
quick_mode_default: yes
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    default_dir="$(json_query default_dir <<< "$output")"
    auto_commit="$(json_query auto_commit_spec <<< "$output")"

    [ "$default_dir" = "./packages/specs" ]
    [ "$auto_commit" = "false" ]
    [[ "$output" != *"quick_mode_default"* ]]
}

@test "codex scripts: resolve_spec_paths falls back on malformed scalar settings" {
    local script auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/specs"
    cat > "$TEST_REPO/.codex/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
  - "./specs"
auto_commit_spec: perhaps
quick_mode_default: later
---
EOF

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    auto_commit="$(json_query auto_commit_spec <<< "$output")"

    [ "$auto_commit" = "true" ]
    [[ "$output" != *"quick_mode_default"* ]]
}

@test "codex scripts: resolve_spec_paths ignores deprecated quick mode setting" {
    local script auto_commit
    script="$(resolve_spec_paths_script)"

    mkdir -p "$TEST_REPO/specs"
    cat > "$TEST_REPO/.codex/ralph-specum.local.md" <<'EOF'
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
    cat > "$TEST_REPO/.codex/ralph-specum.local.md" <<'EOF'
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
    cat > "$TEST_REPO/.codex/ralph-specum.local.md" <<'EOF'
---
specs_dirs:
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

@test "codex scripts: resolve_spec_paths defaults to ./specs without configuration" {
    local script default_dir
    script="$(resolve_spec_paths_script)"

    run python3 "$script" --cwd "$TEST_REPO"
    [ "$status" -eq 0 ]

    default_dir="$(json_query default_dir <<< "$output")"
    [ "$default_dir" = "./specs" ]
}
