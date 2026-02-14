#!/usr/bin/env bats
# Integration Tests
# Tests end-to-end stop-hook behavior with passive stop-watcher
# (Ralph Wiggum handles the loop; stop-watcher only logs to stderr)

bats_require_minimum_version 1.5.0

load 'helpers/setup.bash'

# =============================================================================
# Test: Full loop simulation (2-task spec completing)
# =============================================================================

@test "integration: full loop - stop-watcher is passive for 2-task spec" {
    # Setup: Create a 2-task spec in execution phase
    create_state_file "execution" 0 2 1
    create_tasks_file 2

    # Iteration 1: taskIndex=0, stop-watcher should be passive (no stdout)
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Simulate coordinator completing task 0, advancing to task 1
    create_state_file "execution" 1 2 1

    # Iteration 2: taskIndex=1, still has tasks, still passive
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Simulate coordinator completing task 1, advancing to task 2 (done)
    create_state_file "execution" 2 2 1

    # Iteration 3: taskIndex=2, totalTasks=2, should be silent (complete)
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "integration: loop handles task retry scenario passively" {
    # Setup: Task 1 failed, now on retry attempt 2
    create_state_file "execution" 1 3 2
    create_tasks_file 3

    # Should be passive (no stdout), Ralph Wiggum handles retry
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Simulate retry succeeding, advance to task 2
    create_state_file "execution" 2 3 1

    # Should still be passive
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "integration: loop terminates on state file deletion (cancel)" {
    # Setup: Mid-execution
    create_state_file "execution" 1 5 1
    create_tasks_file 5

    # Verify stop-watcher is passive
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

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

    # Verify stop-watcher is passive
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

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

@test "integration: handles switching between specs passively" {
    # Setup: First spec mid-execution
    create_state_file "execution" 1 3 1

    # First spec - passive
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Create second spec
    mkdir -p "$TEST_WORKSPACE/specs/other-spec"
    create_state_file "execution" 0 2 1 "$TEST_WORKSPACE/specs/other-spec"

    # Switch current spec
    echo "other-spec" > "$TEST_WORKSPACE/specs/.current-spec"

    # Should still be passive for other-spec
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: Edge case - single task spec
# =============================================================================

@test "integration: single task spec - passive during execution" {
    # Setup: Single task spec
    create_state_file "execution" 0 1 1
    create_tasks_file 1

    # Should be passive for task 0
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    # Complete the single task
    create_state_file "execution" 1 1 1

    # Should be silent (complete)
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# Test: Passive behavior verification - no continuation prompts
# =============================================================================

@test "integration: stop-watcher never outputs continuation prompts" {
    create_state_file "execution" 0 3 1

    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    assert_output_not_contains "Continue spec"
    assert_output_not_contains ".ralph-state.json"
    assert_output_not_contains "tasks.md"
    assert_output_not_contains "spec-executor"
    assert_output_not_contains "ALL_TASKS_COMPLETE"
}

@test "integration: stop-watcher logs to stderr during execution" {
    create_state_file "execution" 0 3 1

    # Use --separate-stderr to capture stderr independently
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    # stderr should contain the logging line
    [[ "$stderr" == *"ralph-specum"* ]]
}

@test "integration: stop-watcher exits cleanly for all task states" {
    # Test multiple task positions - all should be passive
    for idx in 0 1 2; do
        create_state_file "execution" "$idx" 3 1
        run --separate-stderr run_stop_watcher
        [ "$status" -eq 0 ]
        [ -z "$output" ]
    done

    # Completed state
    create_state_file "execution" 3 3 1
    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "integration: stop-watcher handles high iteration counts passively" {
    create_state_file "execution" 5 10 3
    create_tasks_file 10

    run --separate-stderr run_stop_watcher
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
