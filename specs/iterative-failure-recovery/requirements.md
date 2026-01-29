---
spec: iterative-failure-recovery
phase: requirements
created: 2026-01-28T22:40:00Z
generated: auto
---

# Requirements: Iterative Failure Recovery

## Summary

Enable execution loop to automatically recover from task failures by creating fix tasks and continuing until all tasks pass, rather than stopping on max retries.

## User Stories

### US-1: Automatic Fix Task Creation
As a developer, I want the execution loop to automatically create fix tasks when a task fails, so that I don't have to manually intervene for common failures.

**Acceptance Criteria**:
- AC-1.1: When task fails and TASK_COMPLETE not received, coordinator parses error from spec-executor output
- AC-1.2: Coordinator creates new fix task based on failure details
- AC-1.3: Fix task inserted into tasks.md immediately after failed task
- AC-1.4: Fix task follows standard task format (Do, Files, Done when, Verify, Commit)

### US-2: Iterative Execution Until Green
As a developer, I want execution to continue automatically after fix tasks complete, so that the loop keeps trying until all tasks pass.

**Acceptance Criteria**:
- AC-2.1: After fix task completes successfully, coordinator retries original failed task
- AC-2.2: If original task now passes, execution continues to next task
- AC-2.3: If original task still fails, coordinator creates another fix task (up to limit)
- AC-2.4: Execution only stops when all tasks pass OR safety limits exceeded

### US-3: Infinite Loop Protection
As a developer, I want safeguards against infinite loops, so that fix tasks don't spawn endlessly.

**Acceptance Criteria**:
- AC-3.1: Max 3 fix tasks per original task (configurable via `--max-fix-tasks`)
- AC-3.2: Global iteration cap honored (maxGlobalIterations in state)
- AC-3.3: Clear error message when limits exceeded
- AC-3.4: State tracks fix task count per original task ID

### US-4: Recovery Mode Toggle
As a developer, I want to enable/disable iterative recovery, so that I can choose behavior based on task type.

**Acceptance Criteria**:
- AC-4.1: `--recovery-mode` flag enables iterative recovery (default: false for backwards compatibility)
- AC-4.2: When recovery disabled, current behavior (stop on max retries) preserved
- AC-4.3: Recovery mode stored in state file for loop continuity

### US-5: Fix Task Traceability
As a developer, I want to track which fix tasks relate to which original tasks, so that I can understand the recovery history.

**Acceptance Criteria**:
- AC-5.1: Fix tasks have `[FIX X.Y]` marker indicating original task ID
- AC-5.2: .progress.md documents fix task chain for each failed task
- AC-5.3: Final summary shows original vs fix task count

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Parse spec-executor failure output to extract error details | Must | AC-1.1 |
| FR-2 | Generate fix task description from error details | Must | AC-1.2, AC-1.4 |
| FR-3 | Insert fix task into tasks.md after current task | Must | AC-1.3 |
| FR-4 | Retry original task after fix task completes | Must | AC-2.1 |
| FR-5 | Track fix task count per original task in state | Must | AC-3.4 |
| FR-6 | Enforce max fix tasks per original task | Must | AC-3.1 |
| FR-7 | Support --recovery-mode argument | Should | AC-4.1 |
| FR-8 | Add recoveryMode flag to state schema | Must | AC-4.3 |
| FR-9 | Add [FIX X.Y] marker to fix task description | Should | AC-5.1 |
| FR-10 | Log fix task chain in .progress.md | Should | AC-5.2 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Backwards compatible - existing specs without recovery mode work unchanged | Compatibility |
| NFR-2 | Fix task generation must not exceed 30 seconds | Performance |
| NFR-3 | Clear error messages when safety limits exceeded | Usability |

## Out of Scope

- Automatic root cause analysis
- Fix task quality scoring
- Learning from past fix patterns
- Cross-spec fix task sharing

## Dependencies

- Existing Phase 5 PR Lifecycle pattern in implement.md
- spec-executor failure output format
- State schema extensibility
