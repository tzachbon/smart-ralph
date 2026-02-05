---
type: component-spec
generated: true
source: plugins/ralph-specum/commands/implement.md
hash: 19181307
category: commands
indexed: 2026-02-05T15:28:01+02:00
---

# implement command

## Purpose
Start task execution loop for a spec. Initializes execution state, writes coordinator prompt, and invokes Ralph Loop for autonomous task completion.

## Location
`plugins/ralph-specum/commands/implement.md`

## Public Interface

### Exports
- `/ralph-specum:implement` slash command

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Parse arguments | --max-task-iterations, --recovery-mode | Extract execution configuration |
| Initialize state | .ralph-state.json | Set phase to execution, count tasks |
| Write coordinator prompt | .coordinator-prompt.md | Full instructions for task execution |
| Invoke Ralph Loop | Skill tool | Start autonomous execution loop |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Ralph Loop plugin (`ralph-wiggum@claude-plugins-official`)
- spec-executor agent for task execution
- qa-engineer agent for [VERIFY] tasks
- .progress.md for context
- tasks.md for task list

## AI Context
**Keywords**: implement execution loop coordinator Ralph-Loop taskIndex totalTasks TASK_COMPLETE ALL_TASKS_COMPLETE parallel recovery-mode
**Related files**: plugins/ralph-specum/agents/spec-executor.md, plugins/ralph-specum/commands/start.md
