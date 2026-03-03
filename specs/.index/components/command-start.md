---
type: component-spec
generated: true
source: plugins/ralph-specum/commands/start.md
hash: 62dae51a
category: commands
indexed: 2026-03-03T00:00:00Z
---

# start command

## Purpose
Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one. Handles branch management, input parsing, skill discovery, spec scanning, epic detection, goal interviews, parallel research, and quick mode.

## Location
`plugins/ralph-specum/commands/start.md`

## Public Interface

### Exports
- `/ralph-specum:start` slash command

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Branch management | branch-management.md reference | Create feature branch, worktree, or stay on current |
| Parse input | name, goal, --fresh, --quick, --commit-spec, --no-commit-spec, --specs-dir | Extract command options and classify intent |
| Skill discovery pass 1 | SKILL.md files from plugin/project/claude paths | Match skills against goal text using semantic judgment |
| Scan existing specs | spec-scanner.md reference | Find related specs with keyword matching and relevance scores |
| Epic detection | .current-epic, .epic-state.json | Suggest next unblocked epic spec or recommend /triage |
| Goal interview | goal-interview.md reference | Brainstorming dialogue to refine goal |
| Team research | parallel-research.md reference | Spawn parallel research teammates and merge results |
| Skill discovery pass 2 | SKILL.md files, research context | Re-scan skills with enriched goal + research context |
| Quick mode | --quick flag | Auto-generate all artifacts via delegated subagents |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- research-analyst agent for research phase
- product-manager agent for requirements phase
- architect-reviewer agent for design phase
- task-planner agent for tasks phase
- spec-reviewer agent for artifact review loops
- spec-executor agent for task execution
- branch-management.md, intent-classification.md, spec-scanner.md, goal-interview.md, parallel-research.md, quick-mode.md references
- Git for branch management
- .ralph-state.json for state tracking
- specs/.current-spec for active spec
- update-spec-index.sh for index updates

## AI Context
**Keywords**: start new-spec resume branch worktree quick-mode goal-interview spec-scanner intent-classification skill-discovery epic-detection parallel-research commit-spec specs-dir
**Related files**: plugins/ralph-specum/agents/research-analyst.md, plugins/ralph-specum/agents/product-manager.md, plugins/ralph-specum/agents/architect-reviewer.md, plugins/ralph-specum/agents/task-planner.md, plugins/ralph-specum/references/parallel-research.md, plugins/ralph-specum/references/quick-mode.md
