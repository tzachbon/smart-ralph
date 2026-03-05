---
spec: karpathy-skills-rules
phase: requirements
created: 2026-02-19
generated: auto
---

# Requirements: karpathy-skills-rules

## Summary

Enforce Karpathy's 4 coding rules (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution) across CLAUDE.md, 6 agents, and 2 skills. Each agent gets a tailored subset. Rules must be concise and LLM-readable.

## User Stories

### US-1: Project-level rule enforcement
As a developer using Smart Ralph, I want Karpathy's coding rules in CLAUDE.md so that all agents inherit baseline behavioral expectations.

**Acceptance Criteria**:
- AC-1.1: CLAUDE.md contains all 4 Karpathy rules in a new section after Critical Safety Rules
- AC-1.2: Rules are concise (fragments/bullets, not prose)
- AC-1.3: Section uses LLM-readable format (clear imperatives, not suggestions)

### US-2: Agent-tailored rule integration
As a spec workflow user, I want each agent to have the most relevant Karpathy rules so that behavior is role-appropriate.

**Acceptance Criteria**:
- AC-2.1: spec-executor has Surgical Changes + Simplicity First rules
- AC-2.2: task-planner has Goal-Driven Execution rules
- AC-2.3: architect-reviewer has Simplicity First rules
- AC-2.4: product-manager has Think Before Coding rules
- AC-2.5: research-analyst references existing alignment with Think Before Coding
- AC-2.6: plan-synthesizer has all 4 rules (condensed)

### US-3: Skill reinforcement
As a plugin maintainer, I want existing skills updated to reference Karpathy rules so that skill guidance is consistent.

**Acceptance Criteria**:
- AC-3.1: communication-style skill has complementary Karpathy reference
- AC-3.2: delegation-principle skill reinforces Surgical Changes

### US-4: Version bump
As a plugin consumer, I want the version bumped so I know rules were added.

**Acceptance Criteria**:
- AC-4.1: plugin.json version bumped to 3.6.0
- AC-4.2: marketplace.json version bumped to 3.6.0

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Add Karpathy rules section to CLAUDE.md | Must | US-1 |
| FR-2 | Add tailored rules to spec-executor agent | Must | US-2 |
| FR-3 | Add tailored rules to task-planner agent | Must | US-2 |
| FR-4 | Add tailored rules to architect-reviewer agent | Must | US-2 |
| FR-5 | Add tailored rules to product-manager agent | Must | US-2 |
| FR-6 | Add tailored rules to research-analyst agent | Should | US-2 |
| FR-7 | Add tailored rules to plan-synthesizer agent | Should | US-2 |
| FR-8 | Update communication-style skill | Should | US-3 |
| FR-9 | Update delegation-principle skill | Should | US-3 |
| FR-10 | Bump plugin version to 3.6.0 | Must | US-4 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Each rule section under 20 lines per agent | Conciseness |
| NFR-2 | No duplication of existing agent rules | Maintainability |
| NFR-3 | Use `<mandatory>` tags consistent with existing patterns | Consistency |

## Out of Scope

- Adding new agents or skills
- Modifying command files
- Changing hook scripts
- Adding enforcement/validation logic (runtime checks)
- Modifying non-ralph-specum plugins

## Dependencies

- None -- pure markdown edits to existing files
