# Spec: role-boundaries

Epic: specs/_epics/engine-roadmap-epic/epic.md

## Goal
Define who can read/write which files during execution and enforce those boundaries mechanically in all agent prompts and the state integrity hook.

## Acceptance Criteria
1. `references/role-contracts.md` exists with file access matrix for all agents
2. All 4 agent files (spec-executor, external-reviewer, qa-engineer, spec-reviewer) reference role-contracts.md and have DO NOT edit lists
3. State integrity hook detects unauthorized .ralph-state.json modifications
4. Test: ask reviewer to edit .ralph-state.json — it must refuse

## Interface Contracts
### Reads
- `agents/spec-executor.md` — current content for context
- `agents/external-reviewer.md` — current content for context
- `agents/qa-engineer.md` — current content for context
- `agents/spec-reviewer.md` — current content for context

### Writes
- `references/role-contracts.md` — NEW FILE
- `agents/spec-executor.md` — append role contract section
- `agents/external-reviewer.md` — append role contract section
- `agents/qa-engineer.md` — append role contract section
- `agents/spec-reviewer.md` — append role contract section

## Dependencies
**Note**: This plan.md was superseded by requirements.md. See `## Dependencies` section in `requirements.md` for actual dependencies (channel-map.md, phase-rules.md, and epic-level dependencies).
