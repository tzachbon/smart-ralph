---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash]
---

# Start Execution

You are starting the task execution loop. Running this command implicitly approves the tasks phase.

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not, error: "Tasks not found. Run /ralph-specum:tasks first."
3. Read `.ralph-state.json`

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

Update `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  ...
}
```

## Read Context

Before executing:

1. Read `./specs/$spec/.progress.md` for:
   - Original goal
   - Completed tasks
   - Learnings
   - Blockers

2. Read `./specs/$spec/tasks.md` for current task

## Execute Current Task

<mandatory>
Use the Task tool with `subagent_type: spec-executor` to execute the current task.
Execute tasks autonomously with NO human interaction.
</mandatory>

Find current task (by taskIndex) and invoke spec-executor with:

```
You are executing task for spec: $spec
Spec path: ./specs/$spec/
Task index: $taskIndex (0-based)

Context from .progress.md:
[include progress file content]

Current task from tasks.md:
[include the specific task block]

Your task:
1. Read the task's Do section and execute exactly
2. Only modify files listed in Files section
3. Verify completion with the Verify command
4. Commit with the task's Commit message
5. Update .progress.md:
   - Add task to Completed Tasks with commit hash
   - Add any learnings discovered
   - Update Current Task to next task
6. Mark task as [x] in tasks.md

After successful completion, output exactly:
TASK_COMPLETE

If verification fails, describe the issue and retry.
```

## After Task Completes

The spec-executor will:
1. Execute the task
2. Run verification
3. Commit changes
4. Update progress
5. Say "TASK_COMPLETE"

The stop hook will then:
1. Increment taskIndex
2. Reset taskIteration
3. Return block with continue prompt (fresh context)
4. OR allow stop if all tasks done

## Completion

When all tasks are done:
1. Stop hook deletes `.ralph-state.json`
2. `.progress.md` remains as record
3. Session ends normally

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Stop after each task for fresh context
- Continue until all tasks complete or max iterations reached

Beginning task $taskIndex...
```
