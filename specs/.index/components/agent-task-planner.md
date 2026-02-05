---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/task-planner.md
hash: 4e8f2a1b
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# task-planner

## Purpose
Task planning specialist that breaks designs into executable implementation steps. Focus on POC-first workflow, clear task definitions, and quality gates.

## Location
`plugins/ralph-specum/agents/task-planner.md`

## Public Interface

### Exports
- `task-planner` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Read design | requirements.md, design.md | Understand requirements and design |
| Create tasks | POC phases 1-5 | Break into Make It Work, Refactoring, Testing, Quality Gates, PR Lifecycle |
| Add quality checkpoints | [VERIFY] tasks | Insert checkpoints every 2-3 tasks |
| Generate VF tasks | Fix goals | Add verification tasks for fix-type specs |
| Reference specs | _Requirements, _Design | Trace each task to requirements and design |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Explore subagent for context gathering
- Read tool for specs
- Write tool for tasks.md
- research.md for quality commands

## AI Context
**Keywords**: task-planner tasks POC-first phases quality-checkpoints VERIFY autonomous no-manual commit-conventions
**Related files**: plugins/ralph-specum/commands/tasks.md, plugins/ralph-specum/templates/tasks.md
