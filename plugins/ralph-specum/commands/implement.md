---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop.

## Ralph Wiggum Dependency

This command requires the Ralph Wiggum plugin. If not installed, run:
```
/plugin install ralph-wiggum@claude-plugins-official
```

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec name
2. If file missing or empty: error "No active spec. Run /ralph-specum:new <name> first."

## Validate Prerequisites

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not: error "Tasks not found. Run /ralph-specum:tasks first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

Write `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": 5
}
```

## Invoke Ralph Loop

Calculate max iterations: `totalTasks * maxTaskIterations * 2`

Use the Skill tool to invoke ralph-wiggum:ralph-loop with:
- Prompt: the coordinator prompt below
- Completion promise: ALL_TASKS_COMPLETE
- Max iterations: calculated value

## Coordinator Prompt

```
You are the execution COORDINATOR for spec: $spec

This is a placeholder prompt. Output the completion signal immediately:

ALL_TASKS_COMPLETE
```

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
