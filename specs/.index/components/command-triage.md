---
type: component-spec
generated: true
source: plugins/ralph-specum/commands/triage.md
hash: bf372016
category: commands
indexed: 2026-03-03T00:00:00Z
---

# triage command

## Purpose
Decompose a large feature into multiple dependency-aware specs (epic triage). Coordinator that delegates exploration research, brainstorming/decomposition, and validation to subagents.

## Location
`plugins/ralph-specum/commands/triage.md`

## Public Interface

### Exports
- `/ralph-specum:triage` slash command

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Check active epic | .current-epic, .epic-state.json | Detect resume vs new epic |
| Branch management | branch-management.md reference | Create/switch git branch |
| Parse input | epic-name, goal from $ARGUMENTS | Extract epic name and goal |
| Run triage flow | triage-flow.md reference | Explore, brainstorm, validate, finalize sequence |
| Display result | epic summary | Show specs, dependency graph, and next steps |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- triage-analyst agent for brainstorming/decomposition
- research-analyst agent for validation research
- Parallel research pattern for exploration
- triage-flow.md reference for flow orchestration
- branch-management.md reference for git handling
- .epic-state.json for epic state tracking
- specs/.current-epic for active epic tracking

## AI Context
**Keywords**: triage epic decomposition coordinator dependency-graph interface-contracts parallel-research validation spec-files github-issues
**Related files**: plugins/ralph-specum/agents/triage-analyst.md, plugins/ralph-specum/references/triage-flow.md, plugins/ralph-specum/references/branch-management.md
