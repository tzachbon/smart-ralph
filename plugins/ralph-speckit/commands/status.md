---
description: Show current feature status and progress
argument-hint:
allowed-tools: [Read, Bash, Glob]
---

# Ralph Speckit Status

You are displaying status for the current feature in ralph-speckit.

## Gather Information

1. Check if `.specify/` directory exists
2. Read `.specify/.current-feature` to identify active feature
3. List all subdirectories in `.specify/specs/` (each is a feature)

## For Active Feature

If a current feature is set:

1. Read `.speckit-state.json` if exists to get:
   - Current phase (specify, plan, tasks, execution)
   - Task progress (taskIndex/totalTasks)
   - Iteration count (taskIteration, globalIteration)
   - Awaiting approval status

2. Check which files exist:
   - spec.md (or specification.md)
   - plan.md
   - tasks.md
   - .progress.md

3. If tasks.md exists, count completed tasks:
   - Count lines matching `- [x]` pattern (completed)
   - Count lines matching `- [ ]` pattern (pending)

4. If .progress.md exists, extract:
   - Current Task section
   - Learnings section (last 3 entries)
   - Blockers section

## Output Format

```text
# Ralph Speckit Status

Current feature: <id>-<name> (or "none set")
Feature path: .specify/specs/<id>-<name>/

## State

Phase: <phase> (specify | plan | tasks | execution)
Status: <Active | Awaiting Approval | Idle>

## Progress

Tasks: <completed>/<total> (<percentage>%)

### Completed Tasks
- [x] 1.1 Task name
- [x] 1.2 Task name
...

### Current Task
<task description from state or .progress.md>

### Next Task
<next unchecked task>

## Files

[x] spec.md
[x] plan.md
[x] tasks.md
[ ] .progress.md

## Blockers (if any)

<blockers from .progress.md>

## Recent Learnings

- <learning 1>
- <learning 2>
- <learning 3>

---

Commands:
- /speckit:switch <id-name> - Switch active feature
- /speckit:start <name> <goal> - Create new feature
- /speckit:implement - Start/resume task execution
- /speckit:cancel - Cancel execution and cleanup state
```

## Phase Display

Show phase with indicator:
- specify: "Specify (defining requirements)"
- plan: "Plan (technical design)"
- tasks: "Tasks (generating task list)"
- execution: "Execution (implementing tasks)"

## File Indicators

For each file, show:
- [x] if file exists
- [ ] if file does not exist

Example: `[x] spec.md [x] plan.md [ ] tasks.md`

## No Feature Active

If `.specify/.current-feature` does not exist or is empty:

```text
# Ralph Speckit Status

No active feature.

Available features in .specify/specs/:
- 001-feature-name
- 002-another-feature

Commands:
- /speckit:start <name> <goal> - Create new feature
- /speckit:switch <id-name> - Activate existing feature
```

## Error Handling

If `.specify/` directory does not exist:
```text
Ralph Speckit not initialized.
Run `/speckit:start <name> <goal>` to begin.
```

If state file is corrupted:
```text
Warning: .speckit-state.json is malformed. Run /speckit:cancel to reset.
```
