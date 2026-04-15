# VE-Cleanup Skip-Forward Logic

Pseudocode for VE (Verification Error) cleanup when verification fails.

Reference: plugins/ralph-specum/references/quality-checkpoints.md

---

## VE Task Cleanup Skip-Forward

When a VE task fails and the failure is due to an error that can be fixed by the next iteration, use skip-forward logic:

```
IF taskIteration >= 2 AND failure is fixable:
    1. Log: "VE task iteration {taskIteration} failed, skipping to fix task"
    2. Do NOT mark task as complete
    3. Increment fixTaskMap counter
    4. Generate fix task with increased depth
    5. Insert fix task into tasks.md
    6. Set taskIndex to fix task
    7. Continue to fix task
ELSE IF taskIteration >= maxFixTasksPerOriginal:
    1. Log: "Max fix tasks ({maxFixTasksPerOriginal}) reached for task {taskIndex}"
    2. Mark task as FAIL in task_review.md
    3. Stop execution, await human input
ELSE:
    1. Log: "Attempting fix iteration {taskIteration}"
    2. Retry same task with taskIteration + 1
```

---

## VE Recovery Loop

The verify-fix-reverify loop for VE tasks:

```
Loop for each VE task:
    1. Execute task to completion
    2. Verify with verify command
    3. IF verify passes:
        - Mark task [x]
        - Reset nativeSyncFailureCount to 0
        - Continue to next task
    4. IF verify fails:
        - Increment taskIteration
        - IF taskIteration > maxTaskIterations:
            - Log: "Max iterations reached for task {taskIndex}"
            - Mark task FAIL in task_review.md
            - Stop execution
        - ELSE:
            - Attempt fix
            - IF fix task generated:
                - Insert fix task into tasks.md
                - Set taskIndex to fix task
                - Continue to fix task
            - ELSE:
                - Retry same task
```

---

## Verification Failure Patterns

Common VE failure patterns and how to handle them:

### Pattern 1: Test assertion failure
```
Error: Expected 5 tasks but found 3
Fix: Check task list completeness, verify all required tasks exist
```

### Pattern 2: Browser navigation error
```
Error: Page not found /404
Fix: Verify navigation path, check app routing configuration
```

### Pattern 3: Selector not found
```
Error: Element not found with selector [data-testid="submit"]
Fix: Verify selector in ui-map.local.md, check if element exists
```

### Pattern 4: Timeout error
```
Error: Waiting for element timed out after 30s
Fix: Increase timeout, verify element will eventually appear, check network latency
```

---

## Skip-Forward Decision Matrix

| Condition | Action |
|-----------|--------|
| taskIteration < 2 | Retry same task |
| taskIteration >= 2 AND fixable error | Generate fix task, skip forward |
| taskIteration >= maxFixTasksPerOriginal | Mark FAIL, stop execution |
| Unfixable error (e.g., spec contradiction) | Mark FAIL, await human input |

---

## Example Fix Task Generation

When a VE task iteration 2 fails due to a selector issue:

```json
{
  "originalTaskId": "3.1",
  "type": "FIX_TASK",
  "reasoning": "Selector not found: expected [data-testid=\"submit\"] but element not in DOM",
  "proposedTask": "- [ ] 3.1-fix [VERIFY] Fix selector for submit button\n  - **Do**: \n    1. Run `browser_generate_locator` on submit button\n    2. Update ui-map.local.md with correct selector\n    3. Update test to use new selector\n  - **Files**: tests/spec-e2e.spec.ts, specs/ui-map.local.md\n  - **Done when**: `grep -q \"data-testid=\\\"submit\\\"\" ui-map.local.md && echo PASS`\n  - **Verify**: `pnpm test:e2e --grep \"submit button\"`\n  - **Commit**: `fix(e2e): correct submit button selector`\n  - _Requirements: AC-3.1_"
}
```
