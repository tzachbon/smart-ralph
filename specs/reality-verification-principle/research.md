---
spec: reality-verification-principle
phase: research
created: 2026-01-16
generated: auto
---

# Research: reality-verification-principle

## Executive Summary

Adding diagnosis-before-planning and verification-after-implementation for fix-type goals. Feasible via targeted edits to existing agents. Low risk since additive changes.

## Codebase Analysis

### Existing Patterns

| File | Pattern |
|------|---------|
| `skills/delegation-principle/SKILL.md` | Core principle format: rule, examples, tables |
| `skills/communication-style/SKILL.md` | Short, table-heavy, fragments not prose |
| `agents/plan-synthesizer.md` | "When Invoked" section with numbered steps |
| `agents/task-planner.md` | Mandatory sections, phase-based structure |
| `agents/qa-engineer.md` | Do/Verify/Done when task format |
| `templates/tasks.md` | Phase 4 ends with 4.2 PR task, VF would be 4.3 |

### Dependencies

- plan-synthesizer.md: entry point for quick mode, runs codebase exploration
- task-planner.md: generates tasks.md with phase structure
- qa-engineer.md: handles [VERIFY] task execution
- templates/tasks.md: template for Phase 4 Quality Gates

### Constraints

- Cannot add new tools or bash commands beyond what agents have
- Must use existing tool access (Bash, Grep, WebFetch)
- Goal detection heuristics must be simple regex patterns
- Command mapping relies on project-specific discovery

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Additive changes to existing agents |
| Effort Estimate | S | 5 files, ~150 lines total |
| Risk Level | Low | No breaking changes, new optional behavior |

## Recommendations

1. Create SKILL.md as canonical reference, agents import rules
2. Detection in plan-synthesizer since it runs first in quick mode
3. VF task template follows existing [VERIFY] pattern
4. qa-engineer handles VF tasks like other verification tasks
