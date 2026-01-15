# Tasks: Test Parallel Failure Handling

## Phase 1: Partial Failure Test

Test that partial failures in parallel batches are handled correctly. Successful tasks should complete while failed task remains unchecked.

- [ ] 1.1 [P] Create first success file
  - **Do**: Create file-success-1.txt with content "Success 1 from parallel batch"
  - **Files**: `specs/test-parallel-failure/file-success-1.txt`
  - **Done when**: File exists with correct content
  - **Verify**: `cat specs/test-parallel-failure/file-success-1.txt | grep -q "Success 1"`
  - **Commit**: `test: create success file 1 in parallel batch`

- [ ] 1.2 [P] Create intentionally failing task
  - **Do**: Create file-fail.txt with content "This task has invalid verify"
  - **Files**: `specs/test-parallel-failure/file-fail.txt`
  - **Done when**: File exists with correct content
  - **Verify**: `this-command-does-not-exist-and-will-fail-verification`
  - **Commit**: `test: create fail file in parallel batch`

- [ ] 1.3 [P] Create second success file
  - **Do**: Create file-success-2.txt with content "Success 2 from parallel batch"
  - **Files**: `specs/test-parallel-failure/file-success-2.txt`
  - **Done when**: File exists with correct content
  - **Verify**: `cat specs/test-parallel-failure/file-success-2.txt | grep -q "Success 2"`
  - **Commit**: `test: create success file 2 in parallel batch`

## Notes

**Purpose**: Test partial failure scenario for parallel task execution

**Expected behavior**:
1. All 3 tasks (1.1, 1.2, 1.3) spawn in parallel as single batch
2. Tasks 1.1 and 1.3 succeed (valid verify commands)
3. Task 1.2 fails (invalid verify command: `this-command-does-not-exist-and-will-fail-verification`)
4. After batch completes:
   - Tasks 1.1 and 1.3 marked [x] in tasks.md
   - Task 1.2 remains [ ] (unchecked) for retry
   - Progress from 1.1 and 1.3 merged into .progress.md
   - Task 1.2 progress NOT merged (failed task)
   - taskResults shows: { 0: "success", 1: "failed", 2: "success" }

**Validation criteria**:
- After execution, tasks.md should show 2 [x] and 1 [ ]
- .progress.md should contain learnings only from successful tasks
- Failed task can be retried on next execution cycle

**Error handling design reference**:
From implement.md section on partial failure:
- taskResults tracks status per task index
- Merge only includes progress files from successful tasks
- Failed tasks remain unchecked, can be grouped in future batch
- BATCH_COMPLETE still output to advance past successful tasks
