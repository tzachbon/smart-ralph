#!/usr/bin/env bash
# Bats-core test helpers for ralph-specum
# Common setup/teardown functions and fixture helpers

# Path to the stop-watcher script under test
# BATS_TEST_DIRNAME is the directory containing the .bats file (tests/)
STOP_WATCHER_SCRIPT="${BATS_TEST_DIRNAME}/../plugins/ralph-specum/hooks/scripts/stop-watcher.sh"
export PATH_RESOLVER_SCRIPT="${BATS_TEST_DIRNAME}/../plugins/ralph-specum/hooks/scripts/path-resolver.sh"

# Test workspace directory (created fresh for each test)
TEST_WORKSPACE=""

# Setup: Create isolated test workspace
setup() {
    # Create unique temp directory for this test
    TEST_WORKSPACE="$(mktemp -d)"
    export TEST_WORKSPACE

    # Create standard directory structure
    mkdir -p "$TEST_WORKSPACE/specs/test-spec"
    mkdir -p "$TEST_WORKSPACE/.claude"

    # Set up .current-spec with just the spec name (bare name)
    # ralph_resolve_current() will prepend the default dir (./specs)
    echo "test-spec" > "$TEST_WORKSPACE/specs/.current-spec"
}

# Teardown: Clean up test workspace
teardown() {
    if [ -n "$TEST_WORKSPACE" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# Create a .ralph-state.json file with specified values
# Usage: create_state_file [phase] [taskIndex] [totalTasks] [taskIteration] [spec_dir]
# Note: specName is derived from spec_dir (basename of the directory)
create_state_file() {
    local phase="${1:-execution}"
    local task_index="${2:-0}"
    local total_tasks="${3:-5}"
    local task_iteration="${4:-1}"
    local spec_dir="${5:-$TEST_WORKSPACE/specs/test-spec}"

    # Derive specName from spec_dir (basename)
    local spec_name
    spec_name=$(basename "$spec_dir")
    local spec_path="specs/$spec_name"

    cat > "$spec_dir/.ralph-state.json" <<EOF
{
  "phase": "$phase",
  "taskIndex": $task_index,
  "totalTasks": $total_tasks,
  "taskIteration": $task_iteration,
  "specName": "$spec_name",
  "specPath": "$spec_path"
}
EOF
}

# Create hook input JSON (simulates what Claude sends to stop hooks)
# Usage: create_hook_input [cwd]
create_hook_input() {
    local cwd="${1:-$TEST_WORKSPACE}"

    cat <<EOF
{
  "cwd": "$cwd",
  "stop_hook_active": true,
  "session_id": "test-session"
}
EOF
}

# Run the stop-watcher with provided input
# Usage: run_stop_watcher [input]
run_stop_watcher() {
    local input="${1:-$(create_hook_input)}"
    echo "$input" | bash "$STOP_WATCHER_SCRIPT"
}

# Create a corrupt JSON state file
create_corrupt_state_file() {
    local spec_dir="${1:-$TEST_WORKSPACE/specs/test-spec}"
    echo "{ invalid json here" > "$spec_dir/.ralph-state.json"
}

# Create a minimal tasks.md file
# Usage: create_tasks_file [total_tasks]
create_tasks_file() {
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
        echo "- [ ] 1.$i Task number $i" >> "$spec_dir/tasks.md"
    done
}

# Create a settings file with specified enabled state
# Usage: create_settings_file [enabled]
create_settings_file() {
    local enabled="${1:-true}"

    cat > "$TEST_WORKSPACE/.claude/ralph-specum.local.md" <<EOF
---
enabled: $enabled
---

# Ralph Specum Settings
EOF
}

# Assert that output contains expected text
# Usage: assert_output_contains [expected]
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert that output does not contain text
# Usage: assert_output_not_contains [unexpected]
assert_output_not_contains() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert that stderr contains expected text
# Note: Requires capturing stderr separately in test
assert_stderr_contains() {
    local expected="$1"
    if [[ "$stderr" != *"$expected"* ]]; then
        echo "Expected stderr to contain: $expected"
        echo "Actual stderr: $stderr"
        return 1
    fi
}

# Create a mock transcript file with specified content
# Usage: create_transcript [content]
create_transcript() {
    local content="${1:-}"
    local transcript_file="$TEST_WORKSPACE/transcript.jsonl"

    echo "$content" > "$transcript_file"
    echo "$transcript_file"
}

# Create hook input JSON with transcript_path
# Usage: create_hook_input_with_transcript [transcript_path] [cwd]
create_hook_input_with_transcript() {
    local transcript_path="${1:-}"
    local cwd="${2:-$TEST_WORKSPACE}"

    cat <<EOF
{
  "cwd": "$cwd",
  "stop_hook_active": true,
  "session_id": "test-session",
  "transcript_path": "$transcript_path"
}
EOF
}
