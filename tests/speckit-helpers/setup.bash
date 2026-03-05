#!/usr/bin/env bash
# Bats-core test helpers for ralph-speckit
# Common setup/teardown functions and fixture helpers

# Path to the stop-watcher script under test
# BATS_TEST_DIRNAME is the directory containing the .bats file (tests/)
STOP_WATCHER_SCRIPT="${BATS_TEST_DIRNAME}/../plugins/ralph-speckit/hooks/scripts/stop-watcher.sh"

# Test workspace directory (created fresh for each test)
TEST_WORKSPACE=""

# Setup: Create isolated test workspace
setup() {
    # Create unique temp directory for this test
    TEST_WORKSPACE="$(mktemp -d)"
    export TEST_WORKSPACE

    # Create standard directory structure (.specify/ for speckit)
    mkdir -p "$TEST_WORKSPACE/.specify/specs/test-feature"
    mkdir -p "$TEST_WORKSPACE/.claude"

    # Set up .current-feature with just the feature name (bare name)
    echo "test-feature" > "$TEST_WORKSPACE/.specify/.current-feature"
}

# Teardown: Clean up test workspace
teardown() {
    if [ -n "$TEST_WORKSPACE" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# Create a .speckit-state.json file with specified values
# Usage: create_state_file [phase] [taskIndex] [totalTasks] [taskIteration] [spec_dir]
# Note: featureId and name are derived from spec_dir (basename of the directory)
create_state_file() {
    local phase="${1:-execution}"
    local task_index="${2:-0}"
    local total_tasks="${3:-5}"
    local task_iteration="${4:-1}"
    local spec_dir="${5:-$TEST_WORKSPACE/.specify/specs/test-feature}"

    # Derive feature name from spec_dir (basename)
    local feature_name
    feature_name=$(basename "$spec_dir")
    local base_path=".specify/specs/$feature_name"

    cat > "$spec_dir/.speckit-state.json" <<EOF
{
  "featureId": "$feature_name",
  "name": "$feature_name",
  "basePath": "$base_path",
  "phase": "$phase",
  "taskIndex": $task_index,
  "totalTasks": $total_tasks,
  "taskIteration": $task_iteration,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "awaitingApproval": false
}
EOF
}

# Create hook input JSON (simulates what Claude sends to stop hooks)
# Usage: create_hook_input [cwd] [stop_hook_active]
create_hook_input() {
    local cwd="${1:-$TEST_WORKSPACE}"
    local stop_hook_active="${2:-false}"
    cat <<EOF
{
  "cwd": "$cwd",
  "stop_hook_active": $stop_hook_active,
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
    local spec_dir="${1:-$TEST_WORKSPACE/.specify/specs/test-feature}"
    echo "{ invalid json here" > "$spec_dir/.speckit-state.json"
}

# Create a minimal tasks.md file
# Usage: create_tasks_file [total_tasks]
create_tasks_file() {
    local total_tasks="${1:-3}"
    local spec_dir="${2:-$TEST_WORKSPACE/.specify/specs/test-feature}"

    cat > "$spec_dir/tasks.md" <<EOF
---
spec: test-feature
phase: tasks
total_tasks: $total_tasks
---

# Tasks: test-feature

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

    cat > "$TEST_WORKSPACE/.claude/ralph-speckit.local.md" <<EOF
---
enabled: $enabled
---

# Ralph Speckit Settings
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

# Extract JSON portion from output (filters out stderr lines mixed in by bats run)
_extract_json_from_output() {
    echo "$output" | grep -v '^\[ralph-speckit\]' | jq -s 'last'
}

# Assert output is valid JSON with decision="block"
assert_json_block() {
    local json
    json=$(_extract_json_from_output 2>/dev/null)
    if [ -z "$json" ] || [ "$json" = "null" ]; then
        echo "Expected valid JSON output"
        echo "Actual output: $output"
        return 1
    fi
    local decision
    decision=$(echo "$json" | jq -r '.decision')
    if [ "$decision" != "block" ]; then
        echo "Expected decision='block', got: $decision"
        echo "Full output: $output"
        return 1
    fi
}

# Assert JSON reason field contains expected text
assert_json_reason_contains() {
    local expected="$1"
    local json
    json=$(_extract_json_from_output 2>/dev/null)
    local reason
    reason=$(echo "$json" | jq -r '.reason // empty')
    if [[ "$reason" != *"$expected"* ]]; then
        echo "Expected JSON reason to contain: $expected"
        echo "Actual reason: $reason"
        return 1
    fi
}

# Assert JSON systemMessage field contains expected text
assert_json_system_message_contains() {
    local expected="$1"
    local json
    json=$(_extract_json_from_output 2>/dev/null)
    local msg
    msg=$(echo "$json" | jq -r '.systemMessage // empty')
    if [[ "$msg" != *"$expected"* ]]; then
        echo "Expected JSON systemMessage to contain: $expected"
        echo "Actual systemMessage: $msg"
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
# Usage: create_hook_input_with_transcript [transcript_path] [cwd] [stop_hook_active]
create_hook_input_with_transcript() {
    local transcript_path="${1:-}"
    local cwd="${2:-$TEST_WORKSPACE}"
    local stop_hook_active="${3:-false}"
    cat <<EOF
{
  "cwd": "$cwd",
  "stop_hook_active": $stop_hook_active,
  "session_id": "test-session",
  "transcript_path": "$transcript_path"
}
EOF
}
