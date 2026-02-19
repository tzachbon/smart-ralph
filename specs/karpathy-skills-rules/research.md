---
spec: karpathy-skills-rules
phase: research
created: 2026-02-19
generated: auto
---

# Research: karpathy-skills-rules

## Executive Summary

Integrating Karpathy's 4 coding rules into CLAUDE.md, 6 agents, and 2 skills. All target files are markdown -- no code changes, no build impact. Straightforward documentation enhancement with surgical per-agent tailoring.

## Source

Rules from [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills):

| Rule | Core Idea | Primary Audience |
|------|-----------|-----------------|
| Think Before Coding | Surface assumptions, don't hide confusion | product-manager, research-analyst |
| Simplicity First | Minimum code, nothing speculative | architect-reviewer, spec-executor |
| Surgical Changes | Touch only what you must | spec-executor, plan-synthesizer |
| Goal-Driven Execution | Define success criteria, loop until verified | task-planner, spec-executor |

## Codebase Analysis

### Existing Patterns

- **Communication Style skill** (`plugins/ralph-specum/skills/communication-style/SKILL.md`): Already enforces conciseness. Karpathy rules complement but don't duplicate.
- **Delegation Principle skill** (`plugins/ralph-specum/skills/delegation-principle/SKILL.md`): Aligned with Surgical Changes (coordinator doesn't implement). Brief reinforcement sufficient.
- **research-analyst agent**: Already has "verify-first, assume-never" philosophy. Maps directly to Think Before Coding. Reference, don't restate.
- **spec-executor agent**: Has verification rules. Goal-Driven Execution + Surgical Changes are natural additions.
- **All agents**: Have `<mandatory>` communication style blocks. Karpathy section should use same pattern.

### Constraints

- **No duplication**: Several agents already embody parts of these rules. Must reference existing rules rather than restate.
- **Concise for LLM**: Rules must be scannable fragments, not prose.
- **Per-agent tailoring**: Not all 4 rules apply equally to all agents.
- **Version bump**: Plugin version must bump (minor: 3.5.1 -> 3.6.0).

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Pure markdown edits |
| Effort Estimate | S | ~10 files, section additions only |
| Risk Level | Low | No code changes, no build impact |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | N/A | No linting for markdown plugin files |
| TypeCheck | N/A | No TypeScript in plugin |
| Test | N/A | No test framework for plugin |
| Build | N/A | No build step |

**Local CI**: Not applicable -- this is a documentation-only change to markdown files.

## Recommendations

1. Add concise Karpathy rules section to CLAUDE.md between "Critical Safety Rules" and "Overview"
2. Tailor subset of rules per agent based on role
3. Use `<mandatory>` tags for consistency with existing agent patterns
4. Reference existing alignment where rules overlap (e.g., research-analyst already does "Think Before Coding")
5. Bump version to 3.6.0 (minor: new behavioral feature)
