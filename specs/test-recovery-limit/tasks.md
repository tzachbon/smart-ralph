---
spec: test-recovery-limit
phase: tasks
total_tasks: 1
created: 2026-01-28T23:05:00Z
generated: test
---

# Tasks: Test Recovery Fix Limit Enforcement

## Overview

Test spec that validates fix limit enforcement. Task 1.1 ALWAYS fails (uses invalid command), testing that recovery stops after maxFixTasksPerOriginal (2) fix tasks with a clear error message.

## Completion Criteria

- Recovery creates exactly 2 fix tasks (1.1.1 and 1.1.2)
- Execution STOPS with clear error when limit reached
- Error message includes fix task history

## Phase 1: Test Tasks

- [ ] 1.1 Always-failing task
  - **Do**: Run a command that always fails: `exit 1` (simulating unfixable error)
  - **Files**: `specs/test-recovery-limit/.marker`
  - **Done when**: This should NEVER succeed - tests limit enforcement
  - **Verify**: `false` (always fails)
  - **Commit**: `test(recovery): this commit should never happen`

## Test Mechanics

This task is designed to ALWAYS fail:
1. First run: FAIL (triggers fix task 1.1.1)
2. After 1.1.1 fix: re-run 1.1, FAIL (triggers fix task 1.1.2)
3. After 1.1.2 fix: re-run 1.1, FAIL
4. Limit reached (2 fix tasks) - STOP with error

Expected behavior when limit is reached:
```
ERROR: Max fix tasks (2) reached for task 1.1
Fix history: 1.1.1, 1.1.2
Original error: ...
Stopping execution - manual intervention required
```

## Usage

```bash
# Run with recovery mode enabled
/ralph-specum:implement --recovery-mode

# Expected: Stops with clear error after 2 fix tasks
# NOT expected: Infinite loop or silent failure
```

## State Configuration

State file pre-configured with:
- `recoveryMode: true` - enables iterative recovery
- `maxFixTasksPerOriginal: 2` - limit to 2 fix tasks per original
- `fixTaskMap: {}` - empty, will populate during execution
