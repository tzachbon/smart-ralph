---
type: component-spec
generated: true
source: plugins/ralph-specum/commands/start.md
hash: 7fefcdda
category: commands
indexed: 2026-02-05T15:28:01+02:00
---

# start command

## Purpose
Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one. Handles branch management, goal interviews, and quick mode.

## Location
`plugins/ralph-specum/commands/start.md`

## Public Interface

### Exports
- `/ralph-specum:start` slash command

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Branch management | git checkout -b, git worktree | Create feature branch or worktree |
| Parse arguments | name, goal, --fresh, --quick, --commit-spec | Extract command options |
| Detection logic | .current-spec, spec directory | Determine new vs resume flow |
| Goal interview | AskUserQuestion | Gather context before research |
| Quick mode | plan-synthesizer | Auto-generate all artifacts |
| Spec scanner | specs directory, .index | Find related existing specs |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- research-analyst agent for research phase
- plan-synthesizer agent for quick mode
- AskUserQuestion tool for interviews
- Git for branch management
- .ralph-state.json for state tracking

## AI Context
**Keywords**: start new-spec resume branch worktree quick-mode goal-interview spec-scanner intent-classification
**Related files**: plugins/ralph-specum/commands/research.md, plugins/ralph-specum/agents/plan-synthesizer.md
