---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/spec-executor.md
hash: 1fdc67dd
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# spec-executor

## Purpose
Autonomous execution agent that implements ONE task from a spec. Executes tasks exactly as specified, verifies completion, commits changes, updates progress, and signals TASK_COMPLETE.

## Location
`plugins/ralph-specum/agents/spec-executor.md`

## Public Interface

### Exports
- `spec-executor` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Execute task | taskIndex, spec, progressFile | Execute a single task from tasks.md |
| Verify completion | Verify command | Run verification command and check pass/fail |
| Update progress | .progress.md | Update completed tasks and learnings |
| Commit changes | Commit message | Stage and commit task files with spec files |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Task tool for delegation
- Bash tool for git operations
- Edit tool for file modifications
- Read tool for reading spec files
- qa-engineer agent (for [VERIFY] tasks)

## AI Context
**Keywords**: spec-executor agent task autonomous implementation verification commit TASK_COMPLETE parallel execution flock
**Related files**: plugins/ralph-specum/agents/qa-engineer.md, plugins/ralph-specum/commands/implement.md
