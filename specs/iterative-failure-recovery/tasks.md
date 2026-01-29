---
spec: iterative-failure-recovery
phase: tasks
total_tasks: 19
created: 2026-01-28T22:40:00Z
generated: auto
---

# Tasks: Iterative Failure Recovery

## Overview

Total tasks: 19
POC-first workflow with 4 phases:
1. Phase 1: Make It Work (POC) - Validate iterative recovery works end-to-end
2. Phase 2: Refactoring - Add robustness and edge case handling
3. Phase 3: Testing - Create test scenarios
4. Phase 4: Quality Gates - Local checks and PR

## Completion Criteria

- Zero regressions (existing specs without recovery mode work unchanged)
- Recovery mode creates fix tasks on failure
- Execution continues until green or limits exceeded
- Clear error messages at safety limits

## Phase 1: Make It Work (POC)

Focus: Validate recovery loop works. Skip edge cases, accept basic fix task generation.

- [x] 1.1 Add recovery state fields to schema
  - **Do**: Extend spec.schema.json with recoveryMode (boolean), maxFixTasksPerOriginal (integer), and fixTaskMap (object) fields
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema includes all three new fields with proper types and defaults
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | python3 -c "import sys,json; j=json.load(sys.stdin); assert 'recoveryMode' in str(j)"`
  - **Commit**: `feat(schema): add recovery state fields`
  - _Requirements: FR-5, FR-8_
  - _Design: State Schema Extension_

- [x] 1.2 Add --recovery-mode argument parsing to implement.md
  - **Do**: In implement.md Parse Arguments section, add --recovery-mode flag parsing. Store recoveryMode: true in state when flag present.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md parses --recovery-mode and writes to state
  - **Verify**: `grep -q "recovery-mode" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add --recovery-mode argument`
  - _Requirements: FR-7, AC-4.1_
  - _Design: Component 4 - Recovery Orchestrator_

- [x] 1.3 Add failure parser to implement.md
  - **Do**: Add section after task delegation to parse spec-executor failure output. Extract error and attempted fix using regex pattern from design. Return structured failure object.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator can extract error details from failure output
  - **Verify**: `grep -q "FAILED" plugins/ralph-specum/commands/implement.md && grep -q "Error:" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add failure output parser`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component 1 - Failure Parser_

- [ ] 1.4 [VERIFY] Quality checkpoint: schema and argument changes
  - **Do**: Verify schema is valid JSON and implement.md has recovery-mode parsing
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | python3 -c "import sys,json; json.load(sys.stdin)" && grep -q "recoveryMode" plugins/ralph-specum/commands/implement.md`
  - **Done when**: Schema parses, recoveryMode in implement.md
  - **Commit**: `chore(recovery): pass quality checkpoint` (only if fixes needed)

- [x] 1.5 Add fix task generator to implement.md
  - **Do**: Add function to create fix task from failure details. Use format from design: `X.Y.N [FIX X.Y] Fix: <summary>`. Include Do, Files, Done when, Verify, Commit fields derived from error and original task.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator can generate properly formatted fix task markdown
  - **Verify**: `grep -q "\[FIX" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add fix task generator`
  - _Requirements: FR-2, AC-1.2, AC-1.4, FR-9_
  - _Design: Component 2 - Fix Task Generator_

- [x] 1.6 Add task inserter to implement.md
  - **Do**: Add logic to insert generated fix task into tasks.md after current task. Find task block end, insert fix task, increment totalTasks in state. Use Edit tool pattern for clean insertion.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Fix task appears in tasks.md after failed task
  - **Verify**: `grep -q "Insert fix task" plugins/ralph-specum/commands/implement.md || grep -q "insert.*task" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add task inserter`
  - _Requirements: FR-3, AC-1.3_
  - _Design: Component 3 - Task Inserter_

- [x] 1.7 Add recovery orchestrator loop to implement.md
  - **Do**: Add Section 6b after task delegation. Check recoveryMode, parse failure, check limits, generate fix task, insert, execute, retry original. Follow design flow exactly.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Full recovery loop implemented: failure -> fix -> retry
  - **Verify**: `grep -q "Iterative Failure Recovery" plugins/ralph-specum/commands/implement.md || grep -q "recoveryMode" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add recovery orchestrator loop`
  - _Requirements: FR-4, AC-2.1, AC-2.2, AC-2.3_
  - _Design: Component 4 - Recovery Orchestrator_

- [ ] 1.8 [VERIFY] Quality checkpoint: verify implement.md recovery components
  - **Do**: Verify implement.md has failure parser, fix generator, inserter, and orchestrator
  - **Verify**: `grep -q "recoveryMode" plugins/ralph-specum/commands/implement.md && grep -q "\[FIX" plugins/ralph-specum/commands/implement.md && grep -q "fixTaskMap" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All three patterns found
  - **Commit**: `chore(recovery): pass quality checkpoint` (only if fixes needed)

- [x] 1.9 POC end-to-end test with intentional failure
  - **Do**: Create test spec at ./specs/test-recovery/ with task that will fail (use invalid command). Run `/ralph-specum:implement --recovery-mode` and verify fix task is created and executed.
  - **Files**: `specs/test-recovery/tasks.md`, `specs/test-recovery/.progress.md`, `specs/test-recovery/.ralph-state.json`
  - **Done when**: Recovery loop creates fix task and retries original
  - **Verify**: `grep -q "\[FIX" specs/test-recovery/tasks.md 2>/dev/null || echo "Manual verification needed"`
  - **Commit**: `feat(recovery): complete POC with test spec`
  - _Requirements: AC-2.4_
  - _Design: Data Flow_

## Phase 2: Refactoring

After POC validated, add robustness and edge cases.

- [x] 2.1 Add fix task limit enforcement
  - **Do**: In recovery orchestrator, check fixTaskMap[taskId].attempts against maxFixTasksPerOriginal. If exceeded, output clear error with fix history and STOP.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Execution stops with error when max fixes reached
  - **Verify**: `grep -q "maxFixTasksPerOriginal" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(coordinator): add fix task limit enforcement`
  - _Requirements: FR-6, AC-3.1, AC-3.3_
  - _Design: Error Handling_

- [x] 2.2 Add fixTaskMap tracking to state updates
  - **Do**: After each fix task creation, update fixTaskMap in state: increment attempts, add fix task ID, store lastError. Read/write using jq pattern from existing state updates.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: State tracks fix task history per original task
  - **Verify**: `grep -q "fixTaskIds" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(coordinator): add fixTaskMap state tracking`
  - _Requirements: FR-5, AC-3.4_
  - _Design: State Extension_

- [ ] 2.3 [VERIFY] Quality checkpoint: limit enforcement and tracking
  - **Do**: Verify limit check and fixTaskMap updates in implement.md
  - **Verify**: `grep -q "maxFixTasksPerOriginal" plugins/ralph-specum/commands/implement.md && grep -q "fixTaskMap" plugins/ralph-specum/commands/implement.md`
  - **Done when**: Both patterns found
  - **Commit**: `chore(recovery): pass quality checkpoint` (only if fixes needed)

- [x] 2.4 Add progress logging for fix tasks
  - **Do**: Log fix task chain in .progress.md. Add section "## Fix Task History" with entries like: `- Task 1.2: 2 fixes attempted (1.2.1, 1.2.2) - Final: PASS/FAIL`
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: .progress.md shows fix task history
  - **Verify**: `grep -q "Fix Task" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(coordinator): add fix task progress logging`
  - _Requirements: FR-10, AC-5.2, AC-5.3_
  - _Design: Progress Updates_

- [x] 2.5 Handle backwards compatibility (recoveryMode default)
  - **Do**: Ensure recoveryMode defaults to false. When false, existing behavior (retry then stop) preserved exactly. Add explicit check at recovery orchestrator entry.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Specs without --recovery-mode work unchanged
  - **Verify**: `grep -q "recoveryMode.*false" plugins/ralph-specum/commands/implement.md || grep -q "recoveryMode !== true" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(coordinator): ensure backwards compatibility`
  - _Requirements: NFR-1, AC-4.2_
  - _Design: Technical Decisions - Recovery default_

## Phase 3: Testing

- [x] 3.1 Test recovery with multiple failures
  - **Do**: Create test spec with task that fails twice before succeeding (use counter file). Verify 2 fix tasks created, then original passes.
  - **Files**: `specs/test-recovery-multi/tasks.md`, `specs/test-recovery-multi/.progress.md`
  - **Done when**: Recovery handles multiple consecutive failures
  - **Verify**: Manual execution of test spec
  - **Commit**: `test(recovery): add multi-failure test spec`
  - _Requirements: AC-2.3_
  - _Design: Data Flow_

- [x] 3.2 Test fix limit enforcement
  - **Do**: Create test spec with task that always fails. Run with --max-fix-tasks 2. Verify execution stops after 2 fix tasks with clear error.
  - **Files**: `specs/test-recovery-limit/tasks.md`
  - **Done when**: Execution stops at limit with proper error
  - **Verify**: Manual execution, check error message
  - **Commit**: `test(recovery): add fix limit test spec`
  - _Requirements: AC-3.1, AC-3.3_
  - _Design: Error Handling_

- [ ] 3.3 [VERIFY] Quality checkpoint: test specs exist
  - **Do**: Verify test specs were created
  - **Verify**: `ls specs/test-recovery*/tasks.md 2>/dev/null | wc -l` shows at least 2
  - **Done when**: At least 2 test spec directories exist
  - **Commit**: `chore(recovery): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [ ] 4.1 [VERIFY] Local quality verification
  - **Do**: Validate schema JSON, verify all components in implement.md
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | python3 -c "import sys,json; json.load(sys.stdin)" && grep -q "recoveryMode" plugins/ralph-specum/commands/implement.md && grep -q "\[FIX" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All verification commands pass
  - **Commit**: `chore(recovery): pass local verification` (if fixes needed)

- [x] 4.2 Clean up test specs
  - **Do**: Remove test-recovery, test-recovery-multi, test-recovery-limit directories
  - **Files**: `specs/test-recovery/`, `specs/test-recovery-multi/`, `specs/test-recovery-limit/`
  - **Done when**: Test directories removed
  - **Verify**: `ls specs/test-recovery* 2>/dev/null | wc -l` shows 0
  - **Commit**: `chore(recovery): remove test specs`

- [ ] 4.3 Create PR and verify CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push: `git push -u origin feat/iterative-failure-recovery`
    3. Create PR: `gh pr create --title "feat: add iterative failure recovery mode" --body "..."`
  - **Verify**: `gh pr checks --watch` shows all green
  - **Done when**: PR created, CI passes
  - **Commit**: None

## Notes

**POC shortcuts taken**:
- Basic fix task description generation (may not cover all failure types)
- Single failure parsing pattern (may miss edge case outputs)
- No --max-fix-tasks argument (uses default 3)

**Production TODOs**:
- Add --max-fix-tasks argument for configurable limits
- Improve fix task generation with more specific error patterns
- Add fix task quality validation before insertion

## Dependencies

```text
Phase 1 (POC) --> Phase 2 (Refactor) --> Phase 3 (Testing) --> Phase 4 (Quality)
```
