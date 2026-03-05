---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/triage-analyst.md
hash: 12b69c70
category: agents
indexed: 2026-03-03T00:00:00Z
---

# triage-analyst

## Purpose
Senior engineering manager and product strategist that decomposes large features into independently deliverable specs with clear dependency graphs and interface contracts. Thinks in vertical slices (user-value driven), not horizontal layers.

## Location
`plugins/ralph-specum/agents/triage-analyst.md`

## Public Interface

### Exports
- `triage-analyst` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Understand | goal, researchOutput | Brainstorm problem space, users, constraints |
| Map user journeys | research findings | Identify distinct user flows as spec boundaries |
| Propose decomposition | candidate specs | Present vertical slices with dependency graph and interface contracts |
| Refine with user | feedback | Iterate on decomposition, merge/split/reorder specs |
| Write epic.md | basePath | Create epic document with vision, specs, dependencies, contracts |
| Append learnings | .progress.md | Record decomposition decisions, risks, dependencies |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Task delegation for invocation (receives basePath, epicName, goal, researchOutput)
- basePath directory for file operations
- .progress.md for appending learnings

## AI Context
**Keywords**: triage-analyst epic decomposition vertical-slice dependency-graph interface-contracts user-journey spec-boundary
**Related files**: plugins/ralph-specum/commands/triage.md, plugins/ralph-specum/references/triage-flow.md
