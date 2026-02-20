# Design: Brainstorming-Style Phase Interviews

**Date**: 2026-02-20
**Scope**: Replace fixed question pool interviews with adaptive brainstorming-style dialogue across all 4 Ralph Specum phases.

## Problem

Current phase interviews use rigid question pools (3 required + 1 optional per phase) with pre-defined options. Questions feel like forms to fill out, not collaborative dialogue. Users have no agency over direction until the artifact is generated.

## Solution

Rewrite the `interview-framework` skill to use brainstorming-style adaptive dialogue. Each phase interview becomes a 3-step process:

1. **Understand** - Context-driven questions, one at a time, building on prior answers
2. **Propose Approaches** - Present 2-3 phase-specific approaches with trade-offs
3. **Confirm & Store** - Brief recap, store in .progress.md, format for subagent

## Architecture

### Core Algorithm (interview-framework skill rewrite)

```
Phase 1: UNDERSTAND (Adaptive Dialogue)
  1. Read all available context (.progress.md, prior artifacts, goal)
  2. Identify what's UNKNOWN vs what's already decided
  3. Ask one question at a time, each building on prior answers
  4. Questions emerge from context + exploration territory, not from a pool
  5. Multiple choice preferred (2-4 options, max 4)
  6. After each answer, decide: ask another or move to approaches
  7. Intent scaling controls depth:
     - TRIVIAL: 1-2 questions
     - REFACTOR: 3-5 questions
     - GREENFIELD: 5-10 questions
     - MID_SIZED: 3-7 questions

Phase 2: PROPOSE APPROACHES (2-3 options with trade-offs)
  1. Synthesize dialogue into 2-3 distinct approaches
  2. Present each with: description, trade-offs, recommendation
  3. Lead with recommended option
  4. User picks one (or suggests hybrid via "Other")
  5. Store chosen approach as primary input for subagent

Phase 3: CONFIRM & STORE
  1. Brief recap: "Here's what I'll pass to the [agent]..."
  2. Store in .progress.md under phase section
  3. Format for subagent delegation prompt
```

### What stays from the old skill

- Option limit rule (2-4 options, max 4)
- Completion signal detection ("done", "proceed", "skip", etc.)
- Context accumulator pattern (append to .progress.md)
- Parameter chain — now semantic (reads .progress.md holistically, not key-matched)
- Question piping ({var} replacement from .progress.md)
- Adaptive depth on "Other" responses (context-specific follow-ups)

### What's removed

- Fixed question pool tables
- Rigid semantic key table (camelCase mappings)
- Key-based parameter chain (replaced with context-based skip logic)

### Exploration Territories (Per Phase)

Each command provides an "Exploration Territory" — hints about what areas to probe. The coordinator reads these, reads .progress.md (to see what's already known), and generates questions about what's STILL UNKNOWN.

**Research:**
- Technical approach preference (follow existing vs introduce new)
- Constraints (performance, compatibility, timeline)
- Integration surface area (systems, APIs)
- What user already knows vs needs discovery
- Technologies to evaluate or avoid

**Requirements:**
- Users (developers, end users, roles)
- Priority (speed vs quality vs completeness)
- Success criteria (metrics, behavior, outcomes)
- Scope boundaries (what's out)
- Regulatory/compliance needs

**Design:**
- Architecture fit (extend vs isolate vs refactor)
- Technology constraints/preferences
- Integration tightness with existing systems
- Failure modes (degradation, retry, alerting)
- Deployment model

**Tasks:**
- Testing thoroughness (minimal POC to comprehensive E2E)
- Deployment considerations (feature flags, migrations)
- Execution priority (ship fast to quality first)
- Dependency ordering
- Team workflow constraints

### Approach Proposals (Per Phase)

| Phase | Example approaches |
|-------|-------------------|
| Research | (A) Deep dive library X vs Y, (B) Focus on existing codebase patterns, (C) Broad survey across alternatives |
| Requirements | (A) Full feature - 12 stories, (B) MVP - 5 core stories, (C) Phased - 3 now, rest in v2 |
| Design | (A) Extend existing service layer, (B) New isolated module, (C) Hybrid with shared data layer |
| Tasks | (A) Aggressive POC - 20 tasks, (B) Thorough - 45 tasks with full coverage, (C) Phased delivery - 2 PRs |

## Files Changed

| File | Change |
|------|--------|
| `skills/interview-framework/SKILL.md` | Full rewrite: fixed-pool algorithm → brainstorming-style 3-phase algorithm |
| `commands/research.md` | Replace Interview section (question pool table → exploration territory + approach template) |
| `commands/requirements.md` | Same replacement pattern |
| `commands/design.md` | Same replacement pattern |
| `commands/tasks.md` | Same replacement pattern |

**No changes to:** Agents, artifact review loops, team lifecycles, walkthroughs, state management, stop behavior.

## Key Design Decisions

1. **Keep one shared skill** (not inline per command) — avoids duplication, single source of truth for the algorithm
2. **Exploration territories in commands, not skill** — phase-specific guidance lives where it's used
3. **Semantic parameter chain** — reads .progress.md holistically instead of matching fixed keys. If the goal/context makes a question redundant, skip it
4. **Intent scaling preserved** — TRIVIAL still gets fewer questions, GREENFIELD gets more
5. **Quick mode unchanged** — `--quick` still skips the entire interview section
