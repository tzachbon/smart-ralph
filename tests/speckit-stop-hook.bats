#!/usr/bin/env bats
# Speckit Stop Hook Unit Tests
# Tests the loop control logic in ralph-speckit's stop-watcher.sh

load 'speckit-helpers/setup.bash'

# =============================================================================
# Test: No state file -> exits silently
# =============================================================================

@test "exits silently when no state file exists" {
    # Setup: workspace exists but no .speckit-state.json
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
    assert_output_not_contains "Continue feature"
}

@test "exits silently when taskIndex exceeds totalTasks" {
    create_state_file "execution" 10 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should not output continuation prompt (tasks complete)
    assert_output_not_contains "Continue feature"
}

# =============================================================================
# Test: Valid execution state -> outputs continuation prompt
# =============================================================================

@test "outputs continuation prompt when tasks remain (taskIndex=0)" {
    create_state_file "execution" 0 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "Continue feature: test-feature"
    assert_json_reason_contains ".speckit-state.json"
    assert_json_reason_contains "spec-executor"
    assert_json_reason_contains "ALL_TASKS_COMPLETE"
}

@test "outputs continuation prompt when tasks remain (midway)" {
    create_state_file "execution" 2 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "Continue feature: test-feature"
}

@test "outputs continuation prompt when one task remains" {
    create_state_file "execution" 4 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "Continue feature: test-feature"
}

# =============================================================================
# Test: Corrupt JSON -> handles gracefully
# =============================================================================

@test "handles corrupt JSON gracefully" {
    create_corrupt_state_file

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should output JSON error, not continuation prompt
    assert_json_block
    assert_json_reason_contains "ERROR: Corrupt"
}

@test "outputs error message for corrupt JSON" {
    create_corrupt_state_file

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # New behavior: outputs structured JSON error to stdout with recovery options
    assert_json_block
    assert_json_reason_contains "ERROR: Corrupt state file"
    assert_json_reason_contains "Recovery options"
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
    assert_json_block
    assert_json_reason_contains "Continue feature: test-feature"
}

# =============================================================================
# Test: stop_hook_active guard
# =============================================================================

@test "exits silently when stop_hook_active is true" {
    create_state_file "execution" 0 5 1

    local input
    input=$(create_hook_input "$TEST_WORKSPACE" true)

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT' 2>/dev/null"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "outputs JSON when stop_hook_active is false" {
    create_state_file "execution" 0 5 1

    local input
    input=$(create_hook_input "$TEST_WORKSPACE" false)

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "Continue feature"
}

@test "JSON output has all three required fields" {
    create_state_file "execution" 0 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "Continue feature"
    assert_json_system_message_contains "Ralph-speckit"
}

@test "max iterations error exits cleanly with stderr message" {
    create_state_file "execution" 2 5 1
    # Set globalIteration to match maxGlobalIterations to trigger the error
    local spec_dir="$TEST_WORKSPACE/.specify/specs/test-feature"
    local tmp
    tmp=$(jq '.globalIteration = 100 | .maxGlobalIterations = 100' "$spec_dir/.speckit-state.json")
    echo "$tmp" > "$spec_dir/.speckit-state.json"

    # Max iterations now exits cleanly (no JSON block) to allow Claude to stop
    # Capture stderr separately to verify error message
    local stderr_output
    stderr_output=$(run_stop_watcher 2>&1 >/dev/null || true)
    [[ "$stderr_output" == *"Maximum global iterations"* ]]
}

@test "corrupt state error still fires when stop_hook_active is true" {
    create_corrupt_state_file

    local input
    input=$(create_hook_input "$TEST_WORKSPACE" true)

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    assert_json_block
    assert_json_reason_contains "ERROR: Corrupt"
}

# =============================================================================
# Test: Stderr logging for execution phase
# =============================================================================

@test "logs session state to stderr during execution" {
    create_state_file "execution" 2 5 3

    # Capture stderr
    local stderr_output
    stderr_output=$(run_stop_watcher 2>&1 >/dev/null || true)

    [[ "$stderr_output" == *"[ralph-speckit]"* ]]
    [[ "$stderr_output" == *"Task: 3/5"* ]]
    [[ "$stderr_output" == *"Attempt: 3"* ]]
}

# =============================================================================
# Test: Transcript detection for ALL_TASKS_COMPLETE
# =============================================================================

@test "detects ALL_TASKS_COMPLETE in transcript and exits silently" {
    create_state_file "execution" 2 5 1

    # Create transcript with ALL_TASKS_COMPLETE signal
    local transcript_file
    transcript_file=$(create_transcript "Some task output
TASK_COMPLETE
More output
ALL_TASKS_COMPLETE
")

    local input
    input=$(create_hook_input_with_transcript "$transcript_file")

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    # Should NOT output continuation prompt - signal detected
    assert_output_not_contains "Continue feature"
}

@test "continues when ALL_TASKS_COMPLETE signal not in transcript" {
    create_state_file "execution" 2 5 1

    # Create transcript without completion signal
    local transcript_file
    transcript_file=$(create_transcript "Some task output
TASK_COMPLETE
More output")

    local input
    input=$(create_hook_input_with_transcript "$transcript_file")

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    # Should output continuation prompt - tasks remain
    assert_json_reason_contains "Continue feature"
}

@test "handles missing transcript_path gracefully" {
    create_state_file "execution" 2 5 1

    # Hook input without transcript_path field
    local input
    input=$(create_hook_input)

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    # Should continue normally - tasks remain
    assert_json_reason_contains "Continue feature"
}

@test "handles non-existent transcript file gracefully" {
    create_state_file "execution" 2 5 1

    # Hook input with non-existent transcript path
    local input
    input=$(create_hook_input_with_transcript "/nonexistent/transcript.jsonl")

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    # Should continue normally - tasks remain
    assert_json_reason_contains "Continue feature"
}

@test "detects ALL_TASKS_COMPLETE with trailing whitespace" {
    create_state_file "execution" 2 5 1

    # Create transcript with signal followed by whitespace
    local transcript_file
    transcript_file=$(create_transcript "Some output
ALL_TASKS_COMPLETE
More text")

    local input
    input=$(create_hook_input_with_transcript "$transcript_file")

    run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"
    [ "$status" -eq 0 ]
    # Should NOT output continuation prompt - signal detected
    assert_output_not_contains "Continue feature"
}

@test "logs transcript detection to stderr" {
    create_state_file "execution" 2 5 1

    # Create transcript with completion signal
    local transcript_file
    transcript_file=$(create_transcript "ALL_TASKS_COMPLETE")

    local input
    input=$(create_hook_input_with_transcript "$transcript_file")

    # Capture stderr
    local stderr_output
    stderr_output=$(bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'" 2>&1 >/dev/null || true)

    [[ "$stderr_output" == *"ALL_TASKS_COMPLETE detected"* ]]
}
