---
type: component-spec
generated: true
source: plugins/ralph-specum/references/triage-flow.md
hash: f13f21ac
category: references
indexed: 2026-03-03T00:00:00Z
---

# triage-flow reference

## Purpose
Reference document defining the explore-brainstorm-validate-finalize sequence for epic triage. Orchestrates two research passes sandwiching a decomposition phase, plus output handlers for spec files and GitHub issues.

## Location
`plugins/ralph-specum/references/triage-flow.md`

## Public Interface

### Exports
- Triage flow reference (used by triage.md command)

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Exploration research | parallel-research pattern, triage directive | Codebase landscape analysis, domain research, constraint/seam discovery |
| Brainstorming & decomposition | triage-analyst agent, basePath, goal, research | Produce epic.md with vertical slice decomposition |
| Validation research | research-analyst agent, epic.md | Validate independence, contracts, scope, dependency graph |
| Finalize | epic.md, .epic-state.json | Adjustment rounds, output format selection, state initialization |
| Spec files output | mkdir, plan.md per spec | Create spec directories with goals and contracts from epic |
| GitHub issues output | gh issue create | Create parent epic issue and per-spec sub-issues |
| Epic status display | .epic-state.json | Show completed/ready/blocked specs with progress |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- triage-analyst agent for decomposition
- research-analyst agent for validation
- parallel-research.md reference for exploration dispatch
- gh CLI for GitHub issues output
- .epic-state.json for state tracking
- specs/.current-epic for active epic

## AI Context
**Keywords**: triage-flow explore brainstorm validate finalize epic-state dependency-graph spec-files github-issues output-handlers epic-status parallel-research
**Related files**: plugins/ralph-specum/commands/triage.md, plugins/ralph-specum/agents/triage-analyst.md, plugins/ralph-specum/references/parallel-research.md
