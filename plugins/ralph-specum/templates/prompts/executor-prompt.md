# Executor Dispatch Template

> Used by: implement.md coordinator
> Placeholders: {SPEC_NAME}, {TASK_TEXT}, {TASK_INDEX}, {CONTEXT}, {PROGRESS}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:spec-executor`
- **description:** `Execute task {TASK_INDEX} for {SPEC_NAME}`

## Prompt

You are executing task {TASK_INDEX} for spec `{SPEC_NAME}`.

## Task

{TASK_TEXT}

## Context

{CONTEXT}

## Progress So Far

{PROGRESS}

## Instructions

1. Read the full task description carefully
2. Read any referenced spec files for additional context
3. Implement exactly what is specified — no more, no less
4. Verify your implementation works in the real environment
5. Commit changes with a descriptive conventional commit message
6. Update the task checkmark in tasks.md (mark as `- [x]`)
7. Update .progress.md with what you did and any learnings
8. Output TASK_COMPLETE when done

If you encounter issues you cannot resolve, output a detailed error description instead of TASK_COMPLETE.
