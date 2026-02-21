# Verification Layers

> Used by: implement.md

Three verification layers run BEFORE advancing taskIndex after a task reports TASK_COMPLETE. All must pass.

## Layer 1: Contradiction Detection

Check spec-executor output for contradiction patterns alongside TASK_COMPLETE:

- "requires manual"
- "cannot be automated"
- "could not complete"
- "needs human"
- "manual intervention"

If TASK_COMPLETE appears alongside any contradiction phrase:
- REJECT the completion
- Log: "CONTRADICTION: claimed completion while admitting failure"
- Increment taskIteration and retry

## Layer 2: TASK_COMPLETE Signal Verification

Verify spec-executor explicitly output TASK_COMPLETE:
- Must be present in response
- Not just implied or partial completion
- Silent completion is not valid

If TASK_COMPLETE missing:
- Do NOT advance
- Increment taskIteration and retry

## Layer 3: Artifact Review

After Layers 1-2 pass, invoke the `spec-reviewer` agent to validate the implementation against the spec.

### When to Run

Layer 3 runs only when ANY of these conditions are true:
- **Phase boundary**: Current task is the first task of a new phase (phase number in task ID changed from previous completed task)
- **Every 5th task**: taskIndex % 5 == 0
- **Final task**: taskIndex == totalTasks - 1

When skipped, coordinator appends to .progress.md:
"Skipping artifact review (next at task N)" where N is the next task index that would trigger review.

### Review Loop

```
Set reviewIteration = 1

WHILE reviewIteration <= 3:
  1. Collect changed files from the task (from the task's Files list and git diff --name-only HEAD~1)
  2. Read $SPEC_PATH/design.md and $SPEC_PATH/requirements.md
  3. Invoke spec-reviewer via Task tool
  4. Parse the last line of spec-reviewer output for signal:
     - REVIEW_PASS: log review iteration, proceed to State Update
     - REVIEW_FAIL (reviewIteration < 3):
       a. Log review iteration
       b. Extract "Feedback for Revision" from reviewer output
       c. Coordinator decides path:
          - Path A (code-level issues): Generate fix task from feedback,
            insert after current task, delegate to spec-executor,
            on TASK_COMPLETE re-run Layer 5. Increment reviewIteration.
          - Path B (spec-level/manual issues): Append suggestions under
            "## Review Suggestions" in .progress.md. Do NOT increment
            reviewIteration. Break review loop. Proceed to State Update.
     - REVIEW_FAIL (reviewIteration >= 3):
       a. Log review iteration
       b. Log warning:
          "Max iterations (3) reached without REVIEW_PASS.
           Proceeding with best available implementation.
           Outstanding issues: [findings from last REVIEW_FAIL]"
       c. Break loop, proceed to State Update
     - NEITHER signal (reviewer error):
       a. Treat as REVIEW_PASS (permissive)
       b. Log with status "REVIEW_PASS (no signal)"
       c. Break loop, proceed to State Update
```

### Review Delegation Prompt

```yaml
subagent_type: spec-reviewer

You are reviewing the execution artifact for spec: $spec
Spec path: $SPEC_PATH/
Review iteration: $reviewIteration of 3

Task description:
[Full task block from tasks.md]

Changed files:
[File names from `git diff --name-only HEAD~1` or task's Files list]

Upstream artifacts (for cross-referencing):
[Full content of $SPEC_PATH/design.md]
[Full content of $SPEC_PATH/requirements.md]

$priorFindings

Apply the execution rubric. Output structured findings with REVIEW_PASS or REVIEW_FAIL.
If REVIEW_FAIL, provide specific, actionable feedback for revision. Reference file names and line numbers.
```

`$priorFindings` is empty on reviewIteration 1. On subsequent iterations:
```
Prior findings (from iteration $prevIteration):
[Full findings output from previous spec-reviewer invocation]
```

### Fix Task on REVIEW_FAIL (reviewIteration < 3)

Same pattern as the fix task generator in implement.md Section 6c:

```markdown
- [ ] $taskId.$fixN [FIX $taskId] Fix: $reviewerFindingSummary
  - **Do**: Address reviewer finding: $reviewerFinding
    1. Review the finding details
    2. Implement the suggested fix
    3. Verify alignment with design.md
  - **Files**: $originalTask.files
  - **Done when**: Reviewer finding "$reviewerFindingSummary" addressed
  - **Verify**: $originalTask.verify
  - **Commit**: `fix($scope): address review finding from task $taskId`
```

After fix task completes (TASK_COMPLETE), re-run Layer 5 from the top with incremented reviewIteration.

### Review Iteration Logging

After each review iteration (regardless of outcome), append to `$SPEC_PATH/.progress.md`:

```markdown
### Review: execution (Task $taskIndex, Iteration $reviewIteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings, 2-3 bullet points max]
- Action: [fix task added / warnings appended, proceeded / proceeded]
```

### Parallel Batch Note

When Layer 5 runs after a parallel batch, use `parallelGroup.startIndex` as the representative `$taskIndex`, union all tasks' Files lists when collecting changed files, and concatenate all task blocks for the task description.

### Error Handling

- Reviewer fails to output signal: treat as REVIEW_PASS (permissive), log with status "REVIEW_PASS (no signal)"
- Phase agent fails during revision: retry fix task once; if fails again, use original implementation and proceed
- Iteration counter edge cases: if reviewIteration is missing or invalid, default to 1

## Verification Summary

All 5 layers must pass before advancing:
1. No contradiction phrases with completion claim
2. Spec files committed (no uncommitted changes)
3. Checkmark count matches expected taskIndex + 1
4. Explicit TASK_COMPLETE signal present
5. Artifact review passes (spec-reviewer REVIEW_PASS or max iterations with graceful degradation)

Only after all verifications pass, proceed to State Update.

## Spec-Executor Self-Verification (Pre-Signal)

Before outputting TASK_COMPLETE, the spec-executor runs its own verification:

1. Run the task's **Verify** command - must pass
2. Check all **Done when** criteria are met
3. Confirm changes committed successfully (including spec files)
4. Confirm task marked `[x]` in tasks.md

The stop-hook enforces 4 of the 5 coordinator verification layers:
1. Contradiction detection - rejects "requires manual... TASK_COMPLETE"
2. Uncommitted files check - rejects if spec files not committed
3. Checkmark verification - validates task is marked [x]
4. Signal verification - requires TASK_COMPLETE

False completion WILL be caught and retried with a specific error message.
