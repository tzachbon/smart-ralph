#!/usr/bin/env bats
# Stop Hook Unit Tests
# Tests the loop control logic in stop-watcher.sh

load 'helpers/setup.bash'

# =============================================================================
# Test: No state file -> exits silently
# =============================================================================

@test "exits silently when no state file exists" {
    # Setup: workspace exists but no .ralph-state.json
    # (setup.bash creates structure but not state file)

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: phase != "execution" -> exits silently
# =============================================================================

@test "exits silently when phase is planning" {
    create_state_file "planning" 0 0 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "exits silently when phase is research" {
    create_state_file "research" 0 0 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "exits silently when phase is unknown" {
    create_state_file "unknown" 0 0 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: taskIndex >= totalTasks -> exits silently
# =============================================================================

@test "exits silently when taskIndex equals totalTasks" {
    create_state_file "execution" 5 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should not output continuation prompt (tasks complete)
    assert_output_not_contains "Continue executing spec"
}

@test "exits silently when taskIndex exceeds totalTasks" {
    create_state_file "execution" 10 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should not output continuation prompt (tasks complete)
    assert_output_not_contains "Continue executing spec"
}

# =============================================================================
# Test: Valid execution state -> outputs continuation prompt
# =============================================================================

@test "outputs continuation prompt when tasks remain (taskIndex=0)" {
    create_state_file "execution" 0 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"
    assert_output_contains ".ralph-state.json for full state"
    assert_output_contains "Delegate task to spec-executor"
    assert_output_contains "ALL_TASKS_COMPLETE"
}

@test "outputs continuation prompt when tasks remain (midway)" {
    create_state_file "execution" 2 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"
}

@test "outputs continuation prompt when one task remains" {
    create_state_file "execution" 4 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"
}

# =============================================================================
# Test: Corrupt JSON -> handles gracefully
# =============================================================================

@test "handles corrupt JSON gracefully" {
    create_corrupt_state_file

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should not output continuation prompt for corrupt state
    assert_output_not_contains "Continue executing spec"
}

@test "outputs error message for corrupt JSON" {
    create_corrupt_state_file

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # New behavior: outputs structured error to stdout with recovery options
    assert_output_contains "ERROR: Corrupt state file"
    assert_output_contains "Recovery options"
}

# =============================================================================
# Test: Missing jq -> exits gracefully
# =============================================================================

@test "exits gracefully when jq is unavailable" {
    create_state_file "execution" 0 5 1

    # Create a minimal bin directory with symlinks to essential tools but not jq
    local minimal_path="$TEST_WORKSPACE/minimal-bin"
    mkdir -p "$minimal_path"

    # Link only the essentials (bash, cat, sed, awk, grep, basename, dirname, find, mktemp, tr, rm)
    for cmd in bash cat sed awk grep basename dirname find mktemp tr rm cd pwd; do
        local cmd_path
        cmd_path=$(command -v "$cmd" 2>/dev/null || true)
        if [ -n "$cmd_path" ] && [ -x "$cmd_path" ]; then
            ln -sf "$cmd_path" "$minimal_path/$cmd"
        fi
    done

    # Run with minimal PATH that excludes jq
    run bash -c "PATH='$minimal_path' '$minimal_path/bash' '$STOP_WATCHER_SCRIPT' <<< '{\"cwd\": \"$TEST_WORKSPACE\"}'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: Invalid hook input -> exits gracefully
# =============================================================================

@test "exits gracefully with empty input" {
    create_state_file "execution" 0 5 1

    run bash -c "echo '' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "exits gracefully with missing cwd in input" {
    create_state_file "execution" 0 5 1

    run bash -c "echo '{}' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "exits gracefully with invalid JSON input" {
    create_state_file "execution" 0 5 1

    run bash -c "echo 'not json' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: Plugin disabled -> exits silently
# =============================================================================

@test "exits silently when plugin is disabled via settings" {
    create_state_file "execution" 0 5 1
    create_settings_file "false"

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "continues normally when plugin is enabled via settings" {
    create_state_file "execution" 0 5 1
    create_settings_file "true"

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"
}

# =============================================================================
# Test: Stderr logging for execution phase
# =============================================================================

@test "logs session state to stderr during execution" {
    create_state_file "execution" 2 5 3

    # Capture stderr
    local stderr_output
    stderr_output=$(run_stop_watcher 2>&1 >/dev/null || true)

    [[ "$stderr_output" == *"[ralph-specum]"* ]]
    [[ "$stderr_output" == *"Task: 3/5"* ]]
    [[ "$stderr_output" == *"Attempt: 3"* ]]
}
