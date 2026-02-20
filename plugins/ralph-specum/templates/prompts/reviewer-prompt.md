# Reviewer Dispatch Template

> Used by: implement.md coordinator (sequential review pattern)
> Placeholders: {SPEC_NAME}, {TASK_TEXT}, {TASK_INDEX}, {IMPLEMENTER_REPORT}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:spec-reviewer`
- **description:** `Review task {TASK_INDEX} completion for {SPEC_NAME}`

## Prompt

Review whether the implementation of task {TASK_INDEX} for spec `{SPEC_NAME}` matches the specification.

## What Was Requested

{TASK_TEXT}

## What Implementer Reports

{IMPLEMENTER_REPORT}

## CRITICAL: Do Not Trust the Report

Verify independently by examining the actual code and behavior:

1. Read the changed files — verify they match what was requested
2. Check that tests pass (if applicable for this phase)
3. Verify no regressions were introduced
4. Check commit message follows conventions
5. Verify tasks.md checkmark was updated

## Output

- Output `REVIEW_PASS` if the implementation correctly satisfies the task specification
- Output `REVIEW_FAIL` with a detailed explanation of what's wrong if it doesn't

Be strict but fair. The spec is the source of truth.
