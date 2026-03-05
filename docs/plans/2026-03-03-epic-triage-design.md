# Epic Triage: Multi-Spec Feature Decomposition

**Date**: 2026-03-03
**Status**: Design approved

## Problem

Large features often can't fit into a single spec. Users need a way to brainstorm a big feature end-to-end at a high level, then decompose it into multiple specs with dependencies, interface contracts, and execution order.

## Solution: Epic Layer

Introduce "Epics" - a coordination layer above specs. An epic is a plan (not a runtime). It captures the decomposition of a large feature into ordered, dependency-aware specs. Individual spec execution remains manual and independent.

## Concepts

### Epic

A high-level feature decomposition containing:
- Vision/goal statement
- Multiple spec definitions (goal, acceptance criteria, architecture guidance, interface contracts)
- Dependency graph between specs
- Output format preference (spec files, GitHub issues, or both)

### Relationship to Specs

Epics coordinate specs but don't own them. A spec created through triage is still a normal spec - it can be run, cancelled, or modified independently. The epic is a planning document, not an execution engine.

## Entry Points

### `/ralph-specum:triage <goal>` (New command)

Dedicated command for epic creation and status.

**No active epic**: Creates a new triage session. Researches, brainstorms, decomposes, produces the epic.

**Active epic exists**: Shows current epic status (which specs are done, which are ready, which are blocked). Offers to continue with the next unblocked spec.

### `/ralph-specum:start` (Enhanced)

Gains epic awareness in its routing logic:

```
/start is called
  -> Check: is there an active epic? (.current-epic exists)
    -> YES: Read .epic-state.json
      -> Show epic status
      -> Suggest next unblocked spec: "Epic 'auth-system' has spec-c ready. Start it?"
      -> User accepts: creates/resumes that spec (normal /start flow)
      -> User declines: asks what they want to do instead
    -> NO: Check if the goal looks complex
      -> If complex: "This looks like it might need multiple specs. Run as triage?"
      -> User accepts: routes to /triage flow
      -> User declines: continues as normal single spec
```

## Triage Flow

### Step 1: Exploration Research

Spawns research team (parallel-research pattern) with a triage-focused prompt:
- Codebase analysis: existing components, patterns, boundaries, tech stack
- Domain research: how similar features are built
- Constraint discovery: what exists that must be worked with/around
- Seam identification: natural module boundaries in the codebase

Output: `specs/_epics/<epic-name>/research.md`

### Step 2: Brainstorming & Decomposition

New `triage-analyst` agent runs deep brainstorming using interview-framework:

1. **Understand** - Q&A to grasp the full feature scope, users, success criteria, constraints
2. **Map user journeys** - identify all distinct flows/capabilities, grounded in research findings (e.g., "the codebase already has X, so we don't need a spec for that")
3. **Propose decomposition** - present candidate specs as vertical slices with dependency graph, interface contracts, and architecture-informed ordering
4. **Refine with user** - iterate on decomposition (merge, split, reorder, adjust contracts)

### Step 3: Validation Research

Second research pass to validate the proposed decomposition against reality:
- Can each spec be built independently?
- Do interface contracts make sense given actual code structure?
- Are dependency assumptions correct?
- Are there hidden shared modules or setup needs?

If validation surfaces issues, the decomposition is adjusted before finalizing.

### Step 4: Output Selection

System asks: "Where should I store this plan?"
- **Spec files** - creates `_epics/` structure + individual spec directories with pre-populated `plan.md` (goal + acceptance criteria + interface contracts)
- **GitHub issues** - parent issue + sub-issues with dependency links
- **Both** - cross-referenced (issue links in spec files, spec paths in issues)

### Step 5: State Initialization

Creates `.epic-state.json` and sets `.current-epic`. Triage is complete.

## Per-Spec Detail Level

Each spec in the epic gets (informed by PM best practices research):

- **Name** (kebab-case)
- **Goal** in user story format ("As a [user] I want [X] so that [Y]")
- **Acceptance criteria** (specific, testable conditions)
- **MVP scope boundary** (explicitly what's IN and OUT)
- **Dependencies** (which specs block this one)
- **Interface contracts** (API endpoints, data shapes, message schemas - the key artifact for parallel work)
- **Rough architecture** (advisory - key components, data flow. Used to inform decomposition, not to constrain individual spec design phases)
- **Size estimate** (S/M/L/XL)

Note: Architecture is advisory. When a spec runs its own design phase, it can deviate if it discovers better approaches. The triage architecture serves as a starting direction that also informs how the decomposition itself was decided.

## File Structure

```
specs/
  .current-epic          # Points to active epic name (like .current-spec)
  _epics/
    <epic-name>/
      epic.md            # The triage output document
      research.md        # Research from exploration + validation phases
      .epic-state.json   # Tracks progress across specs
  <spec-a>/              # Individual specs, unchanged from today
  <spec-b>/
```

## State Management

### `.epic-state.json`

```json
{
  "name": "epic-name",
  "goal": "...",
  "specs": [
    { "name": "spec-a", "status": "pending", "dependencies": [] },
    { "name": "spec-b", "status": "pending", "dependencies": ["spec-a"] },
    { "name": "spec-c", "status": "pending", "dependencies": ["spec-a"] }
  ],
  "output": "spec-files",
  "issueNumber": null
}
```

Status values: `pending`, `in_progress`, `completed`, `cancelled`

### `.current-epic`

Same pattern as `.current-spec` - bare name pointing to the active epic under `_epics/`.

### Session Resumption

When Claude starts a new session:
1. Check `specs/.current-epic` - is there an active epic?
2. If yes, read `.epic-state.json` to know the state
3. `/start` and `/triage` both check this on invocation

## Spec-to-Epic Integration

### When a spec starts within an epic

When `/start` routes to a spec from the epic:
1. Pre-populates the spec's goal and acceptance criteria from `epic.md`
2. Passes interface contracts as context to research and design phases
3. Passes `.progress.md` from completed dependency specs as context
4. Sets `epicName` field in `.ralph-state.json` so completion updates epic state

### When a spec completes within an epic

When ALL_TASKS_COMPLETE fires and spec has `epicName`:
1. Updates `.epic-state.json`: marks spec status as "completed"
2. Checks for newly unblocked specs
3. Outputs: "Spec 'spec-a' complete. Epic progress: 2/5. Next unblocked: spec-c, spec-d."

No auto-execution. User decides when to start the next spec.

### Spec independence

A spec created through triage remains a normal spec:
- Can be run with `/start spec-c` directly
- Can be cancelled without affecting the epic (stays "pending")
- Can be added to an epic manually
- Can be run outside the suggested order (system warns but allows)

### Epic completion

When all specs have status "completed":
- `.current-epic` cleared
- If GitHub issues were created, parent issue closed
- `epic.md` gets a completion timestamp

## New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `triage.md` | Command | Entry point for epic creation/status |
| `triage-analyst.md` | Agent | Deep brainstorming + decomposition |
| `epic.md` template | Template | Structure for the epic artifact |
| `.epic-state.json` schema | Schema | State tracking for epic progress |

### Modified Components

| Component | Change |
|-----------|--------|
| `start.md` | Add epic detection in routing logic |
| `stop-watcher.sh` | Update epic state on spec completion when `epicName` exists |
| `implement.md` | Pass `epicName` context to coordinator |

## Anti-Patterns to Avoid

Based on PM best practices research:

1. **Don't decompose by technical layer** ("backend spec" + "frontend spec"). Decompose by user journey (vertical slices).
2. **Don't over-detail at triage time**. Architecture is advisory. The real design happens in each spec's design phase.
3. **Don't auto-execute spec chains**. The epic is a plan, not a runtime. Users control execution pace.
4. **Don't skip interface contracts**. They're the single most important artifact for enabling parallel/independent spec work.
5. **Don't create specs that aren't independently deliverable**. Each spec should provide user value on its own.
