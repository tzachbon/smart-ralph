# Research: adopt-grill-me-interview

## Executive Summary

Matt Pocock's grill-me skill introduces 5 core mechanics (relentless questioning, decision-tree traversal, recommendation-first answers, one-at-a-time, codebase-first) that can be merged into the existing interview-framework by modifying a single file: `plugins/ralph-specum/skills/interview-framework/SKILL.md`. The changes are additive (recommendation labels) and permissive (removing question caps), with low regression risk since the 3-phase structure, completion signals, and context accumulation remain intact.

## External Research

### Best Practices

**Recommendation-first questioning** inverts the standard interview pattern. Instead of open questions, the interviewer proposes a specific answer and asks the user to evaluate it. This reduces blank-page paralysis, surfaces AI assumptions for correction, and speeds up alignment when the recommendation is correct.

Implementation pattern:
```
Question: "[Context-aware question]"
Options:
  - "[Recommended] [Option A] -- [brief rationale]"  <- lead with recommendation
  - "[Option B]"
  - "[Option C]"
  - "Other"
```

When not to recommend: purely preference questions (naming, color) or when the AI genuinely has no basis (novel domain, no codebase context).

**Decision tree traversal** models the interview as a directed acyclic graph where nodes are decisions and edges are dependencies. Dependency ordering rules:
1. Scope before design
2. Architecture before structure
3. Data model before API
4. Interface before implementation
5. Happy path before edge cases

Some answers open new branches. The interview ends when all branches are resolved (semantic condition, not numeric).

### Prior Art

- **Amazon's Working Backwards**: Start with the press release (a recommendation) and work backward
- **Basecamp's Shape Up**: Propose a "shaped" solution with appetite before questions
- **Lean Canvas**: Fill in assumptions first, then validate each cell
- All share: lead with a concrete proposal, then interrogate it

### Pitfalls to Avoid

- **Question fatigue loops**: asking variations of the same question
- **Premature termination**: stopping when caps say so, while architectural decisions are still open
- **Over-branching**: following every possible branch even when irrelevant to the goal
- **Fabricated recommendations**: recommending when genuinely uncertain

## Codebase Analysis

### Existing Patterns

The interview-framework SKILL.md defines a reusable 3-phase algorithm:
1. **UNDERSTAND** -- adaptive dialogue with exploration territories
2. **PROPOSE APPROACHES** -- synthesize into 2-3 approaches (already recommendation-first at approach level)
3. **CONFIRM & STORE** -- recap, correct, store in .progress.md

Current question format has NO recommendation label on individual options. Recommendations only appear in Phase 2 approach proposals.

### Dependencies

All 5 phase commands reference SKILL.md via standard pattern:
| Phase | Command | Territory Focus |
|-------|---------|-----------------|
| Goal | start.md via goal-interview.md | Problem, constraints, success criteria, scope, prior knowledge |
| Research | research.md | Technical approach, constraints, integration surface, technologies |
| Requirements | requirements.md | Users, priority tradeoffs, success criteria, scope, compliance |
| Design | design.md | Architecture fit, tech constraints, integration, failure modes, deployment |
| Tasks | tasks.md | Testing, deployment, execution priority, dependencies, team workflow, E2E |

### Constraints

- **Option Limit Rule**: 2-4 options per question (preserve)
- **Completion signals**: ["done", "proceed", "skip", "enough", "that's all", "continue", "next"] (preserve)
- **Context accumulation**: stores in .progress.md under "## Interview Responses" (preserve)
- **Codebase-first rule**: exists in goal-interview.md as mandatory block, NOT in SKILL.md (move to SKILL.md)

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| goal-interview | Low | Prior work on goal interview process | No (codebase-first rule already present) |
| adaptive-interview | Low | Prior work on adaptive interview | No (superseded by this change) |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Test | `bats tests/*.bats` | All bats test suites |
| Test | `bats tests/stop-hook.bats` | Stop-watcher tests |
| Test | `bats tests/state-management.bats` | State file tests |
| Test | `bats tests/integration.bats` | End-to-end flow tests |
| CI | `plugin-version-check.yml` | Verifies version bumps |
| CI | `bats-tests.yml` | Runs bats on push/PR |
| CI | `spec-file-check.yml` | Prevents .current-spec commits |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Complexity | Low | Single file change (SKILL.md) |
| Risk | Low | Additive changes, 3-phase structure preserved |
| Effort | S | ~100 lines changed in one file + version bump |
| Breaking changes | None | All phase commands inherit changes automatically |
| Test coverage | Partial | Bats tests cover stop-hook/state, not interview content |

## Recommendations for Requirements

1. **Primary change**: Modify interview-framework SKILL.md to add recommendation-first questioning, remove question caps, add codebase-first rule, add decision-tree traversal guidance
2. **Version bump**: Bump plugin.json and marketplace.json for ralph-specum
3. **No other file changes needed**: All phase commands reference SKILL.md and inherit changes
4. **Preserve**: 3-phase structure, option limit (2-4), completion signals, context accumulation, "Other" adaptive depth

## Open Questions

- Should the codebase-first mandatory block be removed from goal-interview.md after it's added to SKILL.md? (Redundant but harmless)
- Should intent classification still be stored in .progress.md even though caps are removed? (Useful for research depth scaling even without interview caps)

## Sources

- https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md
- plugins/ralph-specum/skills/interview-framework/SKILL.md
- plugins/ralph-specum/references/goal-interview.md
- plugins/ralph-specum/commands/{start,research,requirements,design,tasks}.md
- .github/workflows/{bats-tests,plugin-version-check}.yml
