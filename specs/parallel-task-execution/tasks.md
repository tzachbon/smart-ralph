# Tasks: Parallel Task Execution

## Phase 1: Make It Work (POC)

Focus: Validate parallel execution works end-to-end. Skip tests, accept minimal error handling.

- [x] 1.1 Add parallel state fields to schema
  - **Do**: Extend spec.schema.json with parallelGroup and taskResults definitions
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema includes parallelGroup object and taskResults map definitions
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | grep -q "parallelGroup"` exits 0
  - **Commit**: `feat(schema): add parallel execution state fields`
  - _Requirements: FR-012, FR-013_
  - _Design: Component 5 - State Schema Extension_

- [x] 1.2 [P] Add progressFile parameter to spec-executor
  - **Do**: Add optional progressFile parameter handling to spec-executor.md. When provided, write learnings and completed task entries to this file instead of .progress.md. Add documentation explaining isolated write behavior for parallel execution.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor accepts progressFile param and writes to it when provided
  - **Verify**: `grep -q "progressFile" plugins/ralph-specum/agents/spec-executor.md` exits 0
  - **Commit**: `feat(executor): add progressFile param for isolated writes`
  - _Requirements: FR-006, FR-007_
  - _Design: Component 3 - Parallel Executor Spawner, Implementation Notes - Executor Prompt Updates_

- [x] 1.3 [P] Add [P] marker parsing to implement.md
  - **Do**: Add logic to implement.md to parse tasks.md and detect [P], [VERIFY], [SEQUENTIAL] markers using regex. Build parsed task list with isParallel, isVerify, isSequential flags.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator can identify which tasks have [P] marker
  - **Verify**: `grep -q "\[P\]" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `feat(coordinator): add parallel marker parsing`
  - _Requirements: FR-001, FR-003, FR-004_
  - _Design: Component 1 - Task Parser Extension_

- [x] 1.4 Add parallel group detection to implement.md
  - **Do**: Add algorithm to detect consecutive [P] tasks and group them. Non-[P], [VERIFY], or [SEQUENTIAL] tasks break the group. Return group boundaries (startIndex, endIndex, taskIndices array).
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator can identify parallel group boundaries from current taskIndex
  - **Verify**: `grep -q "parallelGroup" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `feat(coordinator): add parallel group detection`
  - _Requirements: FR-002, FR-003_
  - _Design: Component 2 - Parallel Group Detector_

- [x] 1.5 [VERIFY] Quality checkpoint: verify schema and executor changes
  - **Do**: Validate schema is valid JSON and executor has progressFile handling
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | python3 -c "import sys,json; json.load(sys.stdin)" && grep -q "progressFile" plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Schema parses as valid JSON, progressFile in executor
  - **Commit**: `chore(parallel): pass quality checkpoint` (only if fixes needed)

- [x] 1.6 Add parallel executor spawning to implement.md
  - **Do**: Add logic to spawn multiple spec-executors via Task tool in single message when parallel group detected. Pass .progress-task-N.md path to each executor. Write parallelGroup to state before spawning.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator spawns N Task tool calls in one message for parallel groups
  - **Verify**: `grep -q "progress-task" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `feat(coordinator): add parallel executor spawning`
  - _Requirements: FR-005, FR-006_
  - _Design: Component 3 - Parallel Executor Spawner_

- [x] 1.7 Add progress file merge logic to implement.md
  - **Do**: Add logic to merge .progress-task-N.md temp files into .progress.md after all parallel tasks complete. Extract Learnings and Completed Tasks sections, append in task index order. Delete temp files after merge.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator can merge temp progress files and clean up
  - **Verify**: `grep -q "merge" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `feat(coordinator): add progress file merger`
  - _Requirements: FR-009, FR-010_
  - _Design: Component 4 - Progress File Merger_

- [x] 1.8 Add BATCH_COMPLETE signal and taskIndex update
  - **Do**: After merge, update taskIndex to endIndex+1, serialize git commits from each executor, output both TASK_COMPLETE and BATCH_COMPLETE. Ensure stop-handler sees TASK_COMPLETE for compatibility.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator outputs BATCH_COMPLETE and advances taskIndex past group
  - **Verify**: `grep -q "BATCH_COMPLETE" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `feat(coordinator): add batch completion signal`
  - _Requirements: FR-011, FR-015, FR-016_
  - _Design: Technical Decisions - Completion signal, Implementation Notes - BATCH_COMPLETE Signal_

- [x] 1.9 [VERIFY] Quality checkpoint: verify implement.md changes
  - **Do**: Verify implement.md has all parallel execution components
  - **Verify**: `grep -q "\[P\]" plugins/ralph-specum/commands/implement.md && grep -q "parallelGroup" plugins/ralph-specum/commands/implement.md && grep -q "BATCH_COMPLETE" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All three patterns found in implement.md
  - **Commit**: `chore(parallel): pass quality checkpoint` (only if fixes needed)

- [x] 1.10 POC end-to-end test with test spec
  - **Do**: Create test spec at ./specs/test-parallel/ with 3 simple [P] tasks (create 3 independent .txt files). Run /ralph-specum:implement and verify all 3 tasks execute in parallel (check transcript for multiple Task tool calls in one message).
  - **Files**: `specs/test-parallel/tasks.md`, `specs/test-parallel/.progress.md`, `specs/test-parallel/.ralph-state.json`
  - **Done when**: 3 [P] tasks are spawned together and all complete successfully
  - **Verify**: `ls specs/test-parallel/file-*.txt 2>/dev/null | wc -l` shows 3 files created
  - **Commit**: `feat(parallel): complete POC with test spec`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3_
  - _Design: Test Strategy - Integration Tests_

## Phase 2: Refactoring

After POC validated, clean up code and add robustness.

- [x] 2.1 Add error handling for parallel failures
  - **Do**: Add taskResults tracking to state. Mark each task success/failed after execution. On partial failure, merge successful tasks only, leave failed unchecked for retry.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Partial failures do not corrupt progress, successful tasks preserved
  - **Verify**: `grep -q "taskResults" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `refactor(coordinator): add parallel error handling`
  - _Requirements: FR-013, FR-014, AC-4.1, AC-4.2, AC-4.3, AC-4.4_
  - _Design: Error Handling_

- [x] 2.2 Handle single [P] task edge case
  - **Do**: Add check for parallel group size. If group size is 1, treat as sequential (no parallel overhead). Skip temp file, write directly to .progress.md.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Single [P] task runs as sequential without overhead
  - **Verify**: Manual test with single [P] task spec
  - **Commit**: `refactor(coordinator): handle single [P] task as sequential`
  - _Requirements: AC-5.1_
  - _Design: Edge Cases - Single [P] task_

- [x] 2.3 [VERIFY] Quality checkpoint: verify error handling
  - **Do**: Verify error handling and edge cases in implement.md
  - **Verify**: `grep -q "taskResults" plugins/ralph-specum/commands/implement.md && grep -q "size" plugins/ralph-specum/commands/implement.md`
  - **Done when**: Both patterns present
  - **Commit**: `chore(parallel): pass quality checkpoint` (only if fixes needed)

- [x] 2.4 Add marker override precedence
  - **Do**: Ensure [VERIFY] and [SEQUENTIAL] on same line as [P] cause override. Check for override markers before isParallel flag. Document precedence in implement.md.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: [VERIFY] [P] task treated as sequential
  - **Verify**: `grep -q "\[SEQUENTIAL\]" plugins/ralph-specum/commands/implement.md` exits 0
  - **Commit**: `refactor(coordinator): add marker override precedence`
  - _Requirements: FR-004, AC-1.4_
  - _Design: Edge Cases - [P] with [VERIFY] on same task_

- [x] 2.5 Improve progress merge robustness
  - **Do**: Handle incomplete temp files gracefully (skip if no Learnings section). Log warnings for missing files. Ensure merge is idempotent.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Merge handles edge cases without crashing
  - **Verify**: Manual review of merge logic in implement.md
  - **Commit**: `refactor(coordinator): improve merge robustness`
  - _Requirements: AC-3.2, AC-3.3_
  - _Design: Error Handling - Merge fails, Partial temp file write_

## Phase 3: Testing

- [x] 3.1 Create test spec with mixed parallel/sequential tasks
  - **Do**: Create comprehensive test spec with: [P] batch, then [VERIFY], then another [P] batch, then sequential task. Validate correct grouping and execution order.
  - **Files**: `specs/test-parallel-mixed/tasks.md`, `specs/test-parallel-mixed/.progress.md`, `specs/test-parallel-mixed/.ralph-state.json`
  - **Done when**: Mixed spec groups tasks correctly and executes in right order
  - **Verify**: Manual execution of /ralph-specum:implement on test-parallel-mixed
  - **Commit**: `test(parallel): add mixed parallel/sequential test spec`
  - _Requirements: AC-1.2, AC-1.3, AC-1.4_
  - _Design: Test Strategy - E2E Tests_

- [x] 3.2 Test backwards compatibility
  - **Do**: Run existing spec without [P] markers through new implement.md. Verify unchanged behavior.
  - **Files**: None (existing specs)
  - **Done when**: Non-[P] spec executes identically to before
  - **Verify**: Manual test with existing spec
  - **Commit**: `test(parallel): verify backwards compatibility`
  - _Requirements: AC-5.1, AC-5.2, AC-5.3_
  - _Design: Test Strategy - E2E Tests - Backwards compatibility_

- [x] 3.3 Test partial failure scenario
  - **Do**: Create test spec with 3 [P] tasks where one intentionally fails. Verify successful tasks marked complete, failed task remains unchecked, progress preserved.
  - **Files**: `specs/test-parallel-failure/tasks.md`, `specs/test-parallel-failure/.progress.md`, `specs/test-parallel-failure/.ralph-state.json`
  - **Done when**: Partial failure handled correctly
  - **Verify**: Check tasks.md shows 2 [x] and 1 [ ] after execution
  - **Commit**: `test(parallel): add partial failure test spec`
  - _Requirements: AC-4.1, AC-4.2, AC-4.3, AC-4.4_
  - _Design: Test Strategy - Integration Tests - Partial failure_

- [x] 3.4 [VERIFY] Quality checkpoint: all test specs complete
  - **Do**: Verify all test specs exist and are properly structured
  - **Verify**: `ls specs/test-parallel*/tasks.md 2>/dev/null | wc -l` shows at least 3
  - **Done when**: At least 3 test spec directories exist with tasks.md
  - **Commit**: `chore(parallel): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [x] 4.1 [VERIFY] Full local verification
  - **Do**: Run all verification commands. Validate JSON schema, check all patterns in files.
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | python3 -c "import sys,json; json.load(sys.stdin)" && grep -q "parallelGroup" plugins/ralph-specum/commands/implement.md && grep -q "progressFile" plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: All verification commands pass
  - **Commit**: `chore(parallel): pass local verification` (if fixes needed)

- [x] 4.2 [VERIFY] Manual integration test
  - **Do**: Execute test-parallel spec with /ralph-specum:implement. Verify parallel execution in transcript.
  - **Verify**: Confirm Task tool calls appear in same message for [P] batch
  - **Done when**: Parallel execution demonstrated working
  - **Commit**: None

- [x] 4.3 Clean up test specs
  - **Do**: Remove test-parallel*, test-parallel-mixed, test-parallel-failure directories. They were for validation only.
  - **Files**: `specs/test-parallel/`, `specs/test-parallel-mixed/`, `specs/test-parallel-failure/`
  - **Done when**: Test directories removed
  - **Verify**: `ls specs/test-parallel* 2>/dev/null | wc -l` shows 0
  - **Commit**: `chore(parallel): remove test specs`

- [x] 4.4 Create PR and verify CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Push: `git push -u origin feat/parallel-task-execution`
    4. Create PR: `gh pr create --title "feat: add parallel task execution with [P] markers" --body "..."`
  - **Verify**: `gh pr checks --watch` shows all green
  - **Done when**: PR created, CI passes
  - **Commit**: None

- [x] 4.5 [VERIFY] AC checklist
  - **Do**: Review requirements.md, verify each AC-* satisfied
  - **Verify**: Manual review against implementation
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

## Notes

**POC shortcuts taken**:
- Max concurrent executors hardcoded to 3 (not configurable)
- Minimal error messages in merge failures
- No retry logic for temp file reads

**Production TODOs**:
- Make max concurrent configurable via state or argument
- Add detailed logging for parallel execution flow
- Consider timeout handling for slow parallel tasks
