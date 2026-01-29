---
spec: iterative-failure-recovery
phase: research
created: 2026-01-28T22:40:00Z
generated: auto
---

# Research: Iterative Failure Recovery

## Executive Summary

Current execution loop stops on max retries (default 5 per task). Need iterative recovery: detect failures, dynamically add fix tasks, continue until green. Phase 5 PR Lifecycle already demonstrates dynamic task creation pattern for CI failures - extend this to all phases.

## Codebase Analysis

### Current Failure Handling

**implement.md Coordinator** (lines 290-304):
```text
If no completion signal:
1. Increment taskIteration in state file
2. If taskIteration > maxTaskIterations: proceed to max retries error handling
3. Otherwise: Retry the same task
```

Current behavior: retry same task up to 5 times, then STOP with error.

**Phase 5 Dynamic Task Pattern** (implement.md lines 499-511):
```text
If failures:
- Read failure details: gh run view --log-failed
- Create new Phase 5.X task in tasks.md
- Delegate new task to spec-executor
- Wait for TASK_COMPLETE
- Restart wait cycle
```

This is exactly the pattern needed - adapt it for all task failures.

### State Schema (spec.schema.json)

Existing fields supporting iteration:
- `taskIteration`: Current retry attempt (1-based)
- `maxTaskIterations`: Max retries (default 5)
- `globalIteration`: Total iterations across all tasks
- `maxGlobalIterations`: Safety cap (default 100)
- `taskResults`: Per-task status map (pending/success/failed)

**Gap**: No fields for tracking:
- dynamically added fix tasks
- original task to fix task mapping
- failure reason persistence

### Spec-Executor Output

On failure (spec-executor.md lines 396-402):
```text
Task X.Y: [task name] FAILED
- Error: [description]
- Attempted fix: [what was tried]
- Status: Blocked, needs manual intervention
```

Error details available for creating targeted fix tasks.

### Existing Patterns

| Pattern | Location | Reuse for Recovery |
|---------|----------|-------------------|
| Dynamic task creation | implement.md Phase 5 | Yes - extract and generalize |
| Failure reason parsing | implement.md CI loop | Yes - parse spec-executor output |
| Task insertion in tasks.md | implement.md Phase 5.X | Yes - same sed/edit approach |
| Retry with fresh context | spec-executor.md | Partial - leverage learnings |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Phase 5 pattern proves dynamic task creation works |
| Effort Estimate | M | Extend existing coordinator logic, add state fields |
| Risk Level | Medium | Infinite loop risk if fix tasks keep failing |

## Key Constraints

1. **Infinite Loop Protection**: Need global iteration cap + fix task limit per original task
2. **Fix Task Quality**: Must parse failure details accurately to create useful fix tasks
3. **Task Ordering**: Fix tasks must execute immediately after failed task detection
4. **State Tracking**: Need to differentiate original vs fix tasks for reporting

## Recommendations

1. Add `recoveryMode` flag to state - enables iterative recovery when true
2. Add `fixTasks` array to track dynamically added fix task IDs
3. Set `maxFixTasksPerOriginal` limit (default 3) to prevent fix spirals
4. Extract Phase 5 CI failure -> fix task pattern into reusable coordinator logic
5. Parse spec-executor failure output to generate targeted fix task descriptions
6. Insert fix tasks immediately after current task index
7. Continue execution automatically after fix task completion
