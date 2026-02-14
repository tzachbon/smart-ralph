#!/usr/bin/env bats
# State Management Unit Tests
# Tests for state file operations used by implement/cancel commands

load 'helpers/setup.bash'

# =============================================================================
# Test: State file schema validation - required fields
# =============================================================================

@test "state file has required phase field" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Verify phase field exists and is a string
    run jq -e '.phase' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = '"execution"' ]
}

@test "state file has required taskIndex field" {
    create_state_file "execution" 3 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Verify taskIndex field exists and is a number
    run jq -e '.taskIndex | type' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = '"number"' ]
}

@test "state file has required totalTasks field" {
    create_state_file "execution" 0 10 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Verify totalTasks field exists and is a number
    run jq -e '.totalTasks | type' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = '"number"' ]
}

@test "state file has required taskIteration field" {
    create_state_file "execution" 0 5 2

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Verify taskIteration field exists and is a number
    run jq -e '.taskIteration | type' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = '"number"' ]
}

@test "state file is valid JSON" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # jq exits 0 on valid JSON
    run jq '.' "$state_file"
    [ "$status" -eq 0 ]
}

@test "state file contains all four required fields" {
    create_state_file "execution" 2 8 3

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Check all required fields exist
    run jq -e 'has("phase") and has("taskIndex") and has("totalTasks") and has("taskIteration")' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# =============================================================================
# Test: State file deletion (cancel behavior)
# =============================================================================

@test "state file can be deleted" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # State file exists
    [ -f "$state_file" ]

    # Delete it (simulates cancel)
    rm "$state_file"

    # State file no longer exists
    [ ! -f "$state_file" ]
}

@test "spec directory can be removed after state deletion" {
    create_state_file "execution" 0 5 1
    create_tasks_file 3

    local spec_dir="$TEST_WORKSPACE/specs/test-spec"
    local state_file="$spec_dir/.ralph-state.json"

    # Both files exist
    [ -f "$state_file" ]
    [ -f "$spec_dir/tasks.md" ]

    # Remove state file
    rm "$state_file"
    [ ! -f "$state_file" ]

    # Remove spec directory (simulates full cancel)
    rm -rf "$spec_dir"
    [ ! -d "$spec_dir" ]
}

@test "current-spec marker can be cleared" {
    create_state_file "execution" 0 5 1

    local current_spec="$TEST_WORKSPACE/specs/.current-spec"

    # Marker exists
    [ -f "$current_spec" ]
    [ "$(cat "$current_spec")" = "test-spec" ]

    # Clear it (simulates cancel cleanup)
    rm -f "$current_spec"

    # Marker no longer exists
    [ ! -f "$current_spec" ]
}

@test "state file deletion does not affect other specs" {
    # Create two specs
    create_state_file "execution" 0 5 1
    mkdir -p "$TEST_WORKSPACE/specs/other-spec"
    create_state_file "execution" 2 3 1 "$TEST_WORKSPACE/specs/other-spec"

    local state_file1="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"
    local state_file2="$TEST_WORKSPACE/specs/other-spec/.ralph-state.json"

    # Both exist
    [ -f "$state_file1" ]
    [ -f "$state_file2" ]

    # Delete only first spec's state
    rm "$state_file1"

    # First is gone, second remains
    [ ! -f "$state_file1" ]
    [ -f "$state_file2" ]
}

# =============================================================================
# Test: taskIndex field type and range
# =============================================================================

@test "taskIndex is non-negative integer" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    local task_index
    task_index=$(jq '.taskIndex' "$state_file")

    # Is a number >= 0
    [ "$task_index" -ge 0 ]
}

@test "taskIndex can be zero (start of execution)" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    run jq '.taskIndex' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "taskIndex can equal totalTasks (completion)" {
    create_state_file "execution" 5 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    local task_index total_tasks
    task_index=$(jq '.taskIndex' "$state_file")
    total_tasks=$(jq '.totalTasks' "$state_file")

    [ "$task_index" -eq "$total_tasks" ]
}

@test "taskIndex less than totalTasks means tasks remain" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    local task_index total_tasks
    task_index=$(jq '.taskIndex' "$state_file")
    total_tasks=$(jq '.totalTasks' "$state_file")

    [ "$task_index" -lt "$total_tasks" ]
}

@test "taskIndex updates correctly via jq" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Initial value
    local initial_index
    initial_index=$(jq '.taskIndex' "$state_file")
    [ "$initial_index" -eq 2 ]

    # Update taskIndex (simulates coordinator advancing)
    jq '.taskIndex = 3' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    # New value
    local new_index
    new_index=$(jq '.taskIndex' "$state_file")
    [ "$new_index" -eq 3 ]
}

@test "taskIteration resets to 1 when taskIndex advances" {
    create_state_file "execution" 2 5 3

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Initial: taskIndex=2, taskIteration=3
    local initial_iteration
    initial_iteration=$(jq '.taskIteration' "$state_file")
    [ "$initial_iteration" -eq 3 ]

    # Simulate successful task completion: advance taskIndex, reset taskIteration
    jq '.taskIndex = 3 | .taskIteration = 1' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    # Verify
    local new_index new_iteration
    new_index=$(jq '.taskIndex' "$state_file")
    new_iteration=$(jq '.taskIteration' "$state_file")

    [ "$new_index" -eq 3 ]
    [ "$new_iteration" -eq 1 ]
}

# =============================================================================
# Test: State file integrity under concurrent-like operations
# =============================================================================

@test "state file remains valid JSON after update" {
    create_state_file "execution" 0 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Update multiple fields
    jq '.taskIndex = 4 | .taskIteration = 2' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    # Still valid JSON
    run jq '.' "$state_file"
    [ "$status" -eq 0 ]

    # All required fields still present
    run jq -e 'has("phase") and has("taskIndex") and has("totalTasks") and has("taskIteration")' "$state_file"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "totalTasks can be incremented (fix task insertion)" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Initial totalTasks
    local initial_total
    initial_total=$(jq '.totalTasks' "$state_file")
    [ "$initial_total" -eq 5 ]

    # Increment (simulates fix task insertion)
    jq '.totalTasks += 1' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    # New totalTasks
    local new_total
    new_total=$(jq '.totalTasks' "$state_file")
    [ "$new_total" -eq 6 ]
}

# =============================================================================
# Test: Stop hook relies on state file correctly
# =============================================================================

@test "stop hook uses taskIndex for continuation check" {
    # Tasks remaining (taskIndex < totalTasks)
    create_state_file "execution" 2 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_reason_contains "Continue spec"
}

@test "stop hook silent when taskIndex equals totalTasks" {
    # No tasks remaining (taskIndex == totalTasks)
    create_state_file "execution" 5 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_not_contains "Continue spec"
}

@test "stop hook reads phase from state file" {
    # Non-execution phase should be silent
    create_state_file "planning" 0 5 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Change to execution phase
    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"
    jq '.phase = "execution"' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_json_reason_contains "Continue"
}

# =============================================================================
# Test: maxGlobalIterations field (--max-global-iterations flag)
# =============================================================================

@test "maxGlobalIterations defaults to 100 when missing" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # State file created by helper doesn't include maxGlobalIterations
    # Stop hook should use default of 100
    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should continue (globalIteration 1 < default 100)
    assert_json_reason_contains "Continue"
}

@test "stop hook enforces maxGlobalIterations limit" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Set globalIteration to match maxGlobalIterations (at limit)
    jq '.globalIteration = 100 | .maxGlobalIterations = 100' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should output error about max iterations reached
    assert_json_block
    assert_json_reason_contains "Maximum global iterations"
    assert_output_not_contains "Continue"
}

@test "stop hook allows execution when under maxGlobalIterations" {
    create_state_file "execution" 2 5 1

    local state_file="$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Set globalIteration below maxGlobalIterations
    jq '.globalIteration = 50 | .maxGlobalIterations = 100' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"

    run run_stop_watcher
    [ "$status" -eq 0 ]
    # Should continue (50 < 100)
    assert_json_reason_contains "Continue"
}
