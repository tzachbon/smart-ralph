# Verification Layers

> Used by: implement.md

Five verification layers run BEFORE advancing taskIndex after a task reports TASK_COMPLETE. All must pass.

## Layer 0: EXECUTOR_START Signal (MANDATORY — blocks all other layers)

After every delegation to spec-executor, verify the response begins with `EXECUTOR_START`
BEFORE running any other verification layer.

If `EXECUTOR_START` is absent:
- The delegation silently failed — coordinator must NOT implement the task itself
- Do NOT run Layers 1-4
- Do NOT advance taskIndex or increment taskIteration
- ESCALATE immediately: log "EXECUTOR_START absent for task $taskIndex — delegation may have failed" to .progress.md, stop iteration

This is a hard gate. Layer 1 contradiction check does NOT catch self-implementation — Layer 0 does.

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

Verify spec-executor explicitly output TASK_COMPLETE (or ALL_TASKS_COMPLETE):
- Must be present in response
- ALL_TASKS_COMPLETE is accepted as equivalent to TASK_COMPLETE
- Not just implied or partial completion
- Silent completion is not valid

If TASK_COMPLETE missing:
- Do NOT advance
- Increment taskIteration and retry

## Layer 3: Anti-fabrication (Verification Claim Integrity)

For EVERY task that reports a verify command result, run the verify command independently:

1. Extract the verify command from the task's Verify section in tasks.md
2. Run it independently — do NOT use executor's pasted output
3. Compare actual result with claimed result:
   - Executor said "PASSED" but command exits non-zero -> FABRICATION -> REJECT
   - Executor said "N passed" but actual count differs -> FABRICATION -> REJECT
   - Outputs match -> proceed

Additionally, run global CI checks (project-wide linting, type-checking) independently when available:
- Task Verify and global CI are reported SEPARATELY
- Both must pass for this layer to pass
- If task Verify passes but global CI fails: log "TASK VERIFY PASS but GLOBAL CI FAIL", do NOT advance
- **CI command discovery is deferred to Spec 4 (loop-safety-infra)**. This spec adds the conceptual rule only. Specific command discovery (ruff/mypy for Python, eslint/tsc for JS) is not implemented here.

## Layer 4: Artifact Review

After Layers 1-3 pass, invoke the `spec-reviewer` agent to validate the implementation against the spec.

### When to Run

Layer 4 runs only when ANY of these conditions are true:
- **Phase boundary**: Current task is the first task of a new phase (phase number in task ID changed from previous completed task)
- **Every 5th task**: taskIndex > 0 && taskIndex % 5 == 0
- **Final task**: taskIndex == totalTasks - 1 (accepts either TASK_COMPLETE or ALL_TASKS_COMPLETE from spec-executor)

When skipped, coordinator appends to .progress.md:
"Skipping artifact review (next at task N)" where N is the next taskIndex satisfying the periodic condition (taskIndex > 0 && taskIndex % 5 == 0). For example, at taskIndex 1, N = 5; at taskIndex 6, N = 10. Phase boundary and final task triggers are computed separately.

**Pre-requisite**: Before delegating each task, the coordinator records `TASK_START_SHA=$(git rev-parse HEAD)` to capture the commit state before task execution.

### Review Loop

```text
Set reviewIteration = 1

WHILE reviewIteration <= 3:
  1. Collect changed files from the task (from the task's Files list and git diff --name-only $TASK_START_SHA HEAD)
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
            on TASK_COMPLETE re-run Layer 3. Increment reviewIteration.
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
[File names from `git diff --name-only $TASK_START_SHA HEAD` or task's Files list]

Upstream artifacts (for cross-referencing):
[Full content of $SPEC_PATH/design.md]
[Full content of $SPEC_PATH/requirements.md]

$priorFindings

$artifactTypeInstruction
```

**Artifact type selection**:
- If the task being reviewed is VE/E2E (description contains "VE0", "VE1", "VE2", "VE3", "E2E", or "playwright"):
  Set `$artifactTypeInstruction` to:
  ```
  Apply the e2e-review rubric. Include as additional context:
  - test-results/**/error-context.md artifacts (if available)
  - ui-map.local.md (if available)
  - Task's Skills: field contents
  - Last 3 VE-related entries from .progress.md
  Output structured findings with REVIEW_PASS or REVIEW_FAIL.
  ```
- Otherwise:
  Set `$artifactTypeInstruction` to:
  ```
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

After fix task completes (TASK_COMPLETE), re-run Layer 3 from the top with incremented reviewIteration.

### Review Iteration Logging

After each review iteration (regardless of outcome), append to `$SPEC_PATH/.progress.md`:

```markdown
### Review: execution (Task $taskIndex, Iteration $reviewIteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings, 2-3 bullet points max]
- Action: [fix task added / warnings appended, proceeded / proceeded]
```

### Parallel Batch Note

When Layer 4 runs after a parallel batch, use `parallelGroup.startIndex` as the representative `$taskIndex`, union all tasks' Files lists when collecting changed files, and concatenate all task blocks for the task description.

### Error Handling

- Reviewer fails to output signal: treat as REVIEW_PASS (permissive), log with status "REVIEW_PASS (no signal)"
- Phase agent fails during revision: retry fix task once; if fails again, use original implementation and proceed
- Iteration counter edge cases: if reviewIteration is missing or invalid, default to 1

## Verification Summary

All 5 layers must pass before advancing:
1. Layer 0 (EXECUTOR_START Signal) — blocks if absent
2. Layer 1 (Contradiction Detection) — no failure phrases with completion
3. Layer 2 (TASK_COMPLETE Signal) — explicit signal present
4. Layer 3 (Anti-fabrication) — verify commands run independently
5. Layer 4 (Artifact Review) — periodic spec-reviewer validation

Only after all verifications pass, proceed to State Update.

Only after all verifications pass, proceed to State Update.

## Spec-Executor Self-Verification (Pre-Signal)

Before outputting TASK_COMPLETE, the spec-executor runs its own verification:

1. Run the task's **Verify** command - must pass
2. Check all **Done when** criteria are met
3. Confirm changes committed successfully (including spec files)
4. Confirm task marked `[x]` in tasks.md

The coordinator trusts spec-executor for commit and checkmark verification.
Coordinator layers focus on higher-order checks: contradictions, signal presence, and periodic artifact review.

**ALL_TASKS_COMPLETE handling**: When spec-executor outputs ALL_TASKS_COMPLETE instead of TASK_COMPLETE, Layer 2 treats it as satisfying the TASK_COMPLETE signal requirement. Layer 3's final-task trigger (taskIndex == totalTasks - 1) accepts either signal when deciding to run final-task verification.

The coordinator enforces 5 verification layers:
1. Layer 0 (EXECUTOR_START) - blocks if delegation response is missing signal
2. Layer 1 (Contradiction detection) - rejects "requires manual... TASK_COMPLETE"
3. Layer 2 (Signal verification) - requires TASK_COMPLETE
4. Layer 3 (Anti-fabrication) - independently runs verify commands
5. Layer 4 (Artifact review) - periodic spec-reviewer validation

False completion WILL be caught and retried with a specific error message.
