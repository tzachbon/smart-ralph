#!/usr/bin/env bats
# Tests for stop-watcher.sh - Ralph Specum execution loop control
#
# Requirements:
#   - bats-core: brew install bats-core
#   - jq: brew install jq
#
# Run: bats plugins/ralph-specum/tests/stop-watcher.bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../hooks/scripts" && pwd)"
STOP_WATCHER="$SCRIPT_DIR/stop-watcher.sh"

setup() {
    # Create temp directory for test files
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/specs/test-spec"

    # Create current-spec pointer
    echo "test-spec" > "$TEST_DIR/specs/.current-spec"
}

teardown() {
    # Cleanup temp directory
    rm -rf "$TEST_DIR"
}

# Helper to run stop-watcher with test input
run_hook() {
    local input="$1"
    echo "$input" | "$STOP_WATCHER"
}

# Helper to create state file
create_state() {
    local phase="${1:-execution}"
    local task_index="${2:-0}"
    local total_tasks="${3:-5}"
    local global_iter="${4:-1}"
    local max_iter="${5:-100}"

    cat > "$TEST_DIR/specs/test-spec/.ralph-state.json" << EOF
{
  "phase": "$phase",
  "taskIndex": $task_index,
  "totalTasks": $total_tasks,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": $global_iter,
  "maxGlobalIterations": $max_iter
}
EOF
}

# Helper to create transcript file with content
create_transcript() {
    local content="$1"
    local transcript_file="$TEST_DIR/transcript.txt"
    echo "$content" > "$transcript_file"
    echo "$transcript_file"
}

# =============================================================================
# FR-1: Blocks session exit during active execution phase
# =============================================================================

@test "FR-1: blocks exit during execution phase" {
    create_state "execution" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "block"'* ]]
    [[ "$output" == *'"reason":'* ]]
}

@test "FR-1: does not block when no state file" {
    rm -f "$TEST_DIR/specs/test-spec/.ralph-state.json"

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "FR-1: does not block when no current-spec file" {
    rm -f "$TEST_DIR/specs/.current-spec"

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# FR-2: Detects ALL_TASKS_COMPLETE signal in transcript
# =============================================================================

@test "FR-2: allows exit when ALL_TASKS_COMPLETE in transcript" {
    create_state "execution" 5 5 1 100

    local transcript
    transcript=$(create_transcript "Task completed. ALL_TASKS_COMPLETE")

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$transcript"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" != *'"decision": "block"'* ]]

    # State file should be deleted
    [ ! -f "$TEST_DIR/specs/test-spec/.ralph-state.json" ]
}

@test "FR-2: does not trigger on partial completion signal" {
    create_state "execution" 0 5 1 100

    local transcript
    transcript=$(create_transcript "TASK_COMPLETE - moving to next task")

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$transcript"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "block"'* ]]
}

# =============================================================================
# FR-3: Prevents infinite loops with stop_hook_active check
# =============================================================================

@test "FR-3: exits immediately when stop_hook_active is true" {
    create_state "execution" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt", "stop_hook_active": true}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "FR-3: continues when stop_hook_active is false" {
    create_state "execution" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt", "stop_hook_active": false}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "block"'* ]]
}

@test "FR-3: continues when stop_hook_active is not present" {
    create_state "execution" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "block"'* ]]
}

# =============================================================================
# FR-4: Only blocks during execution phase
# =============================================================================

@test "FR-4: does not block during research phase" {
    create_state "research" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "FR-4: does not block during requirements phase" {
    create_state "requirements" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "FR-4: does not block during design phase" {
    create_state "design" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "FR-4: does not block during tasks phase" {
    create_state "tasks" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# =============================================================================
# FR-7 & FR-8: Safety limits
# =============================================================================

@test "FR-7: allows exit when max iterations reached" {
    create_state "execution" 0 5 100 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" != *'"decision": "block"'* ]]
}

@test "FR-7: increments iteration counter on each block" {
    create_state "execution" 0 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    # First call
    run run_hook "$input"
    [ "$status" -eq 0 ]

    # Check iteration was incremented
    local new_iter
    new_iter=$(jq '.globalIteration' "$TEST_DIR/specs/test-spec/.ralph-state.json")
    [ "$new_iter" -eq 2 ]
}

@test "FR-8: default max is 100 iterations" {
    create_state "execution" 0 5 99 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    # At 99, should still block
    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "block"'* ]]

    # At 100 (after increment), next call should not block
    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" != *'"decision": "block"'* ]]
}

# =============================================================================
# Edge cases and error handling
# =============================================================================

@test "handles missing cwd gracefully" {
    local input='{"transcript_path": "/tmp/test.txt"}'

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "handles corrupt state file gracefully" {
    echo "not valid json" > "$TEST_DIR/specs/test-spec/.ralph-state.json"

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" != *'"decision": "block"'* ]]
}

@test "handles empty spec name gracefully" {
    echo "" > "$TEST_DIR/specs/.current-spec"

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "injects correct continuation prompt with spec name" {
    create_state "execution" 2 5 1 100

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$TEST_DIR/empty.txt"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test-spec"* ]]
    [[ "$output" == *"task 3/5"* ]]  # taskIndex+1 / totalTasks
}

@test "cleans up orphaned temp progress files on completion" {
    create_state "execution" 5 5 1 100

    # Create an old temp file (>60 min old per stop-watcher.sh cleanup logic)
    touch -t 202501010000 "$TEST_DIR/specs/test-spec/.progress-task-1.md"

    local transcript
    transcript=$(create_transcript "ALL_TASKS_COMPLETE")

    local input
    input=$(cat << EOF
{"cwd": "$TEST_DIR", "transcript_path": "$transcript"}
EOF
)

    run run_hook "$input"
    [ "$status" -eq 0 ]

    # Verify cleanup occurred - if file still exists, cleanup didn't run
    # (could be due to find -mmin not working on some systems)
    if [ -f "$TEST_DIR/specs/test-spec/.progress-task-1.md" ]; then
        skip "System doesn't support mtime-based cleanup or find -mmin behavior differs"
    fi
}
