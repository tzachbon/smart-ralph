#!/usr/bin/env bats
# Integration Tests
# Tests end-to-end loop behavior with multiple stop-hook invocations

load 'helpers/setup.bash'

# =============================================================================
# Test: Full loop simulation (2-task spec completing)
# =============================================================================

@test "integration: full loop completes 2-task spec" {
    # Setup: Create a 2-task spec in execution phase
    create_state_file "execution" 0 2 1
    create_tasks_file 2

    # Iteration 1: taskIndex=0, should output continuation
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Simulate coordinator completing task 0, advancing to task 1
    create_state_file "execution" 1 2 1

    # Iteration 2: taskIndex=1, still has tasks, should continue
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Simulate coordinator completing task 1, advancing to task 2 (done)
    create_state_file "execution" 2 2 1

    # Iteration 3: taskIndex=2, totalTasks=2, should be silent (complete)
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_not_contains "Continue executing spec"
}

@test "integration: loop handles task retry scenario" {
    # Setup: Task 1 failed, now on retry attempt 2
    create_state_file "execution" 1 3 2
    create_tasks_file 3

    # Should still continue (retry in progress)
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Simulate retry succeeding, advance to task 2
    create_state_file "execution" 2 3 1

    # Should continue to next task
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"
}

@test "integration: loop terminates on state file deletion (cancel)" {
    # Setup: Mid-execution
    create_state_file "execution" 1 5 1
    create_tasks_file 5

    # Verify loop would continue
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Simulate cancel: delete state file
    rm "$TEST_WORKSPACE/specs/test-spec/.ralph-state.json"

    # Loop should terminate silently (no state file)
    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "integration: loop terminates on phase change" {
    # Setup: Mid-execution
    create_state_file "execution" 2 5 1

    # Verify loop would continue
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Simulate phase change (e.g., user interrupted)
    create_state_file "paused" 2 5 1

    # Loop should terminate silently (wrong phase)
    run run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: Multiple specs scenario
# =============================================================================

@test "integration: handles switching between specs" {
    # Setup: First spec mid-execution
    create_state_file "execution" 1 3 1

    # First spec continues
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Create second spec
    mkdir -p "$TEST_WORKSPACE/specs/other-spec"
    create_state_file "execution" 0 2 1 "$TEST_WORKSPACE/specs/other-spec"

    # Switch current spec
    echo "other-spec" > "$TEST_WORKSPACE/specs/.current-spec"

    # Should now continue other-spec
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: other-spec"
}

# =============================================================================
# Test: Edge case - single task spec
# =============================================================================

@test "integration: single task spec completes correctly" {
    # Setup: Single task spec
    create_state_file "execution" 0 1 1
    create_tasks_file 1

    # Should continue for task 0
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "Continue executing spec: test-spec"

    # Complete the single task
    create_state_file "execution" 1 1 1

    # Should be silent (complete)
    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_not_contains "Continue executing spec"
}

# =============================================================================
# Test: Continuation prompt contains required info
# =============================================================================

@test "integration: continuation prompt includes state file path" {
    create_state_file "execution" 0 3 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains ".ralph-state.json"
}

@test "integration: continuation prompt includes tasks.md reference" {
    create_state_file "execution" 0 3 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "tasks.md"
}

@test "integration: continuation prompt mentions spec-executor delegation" {
    create_state_file "execution" 0 3 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "spec-executor"
}

@test "integration: continuation prompt mentions completion signal" {
    create_state_file "execution" 0 3 1

    run run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_contains "ALL_TASKS_COMPLETE"
}
