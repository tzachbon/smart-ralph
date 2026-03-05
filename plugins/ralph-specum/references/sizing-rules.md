# Sizing Rules

> Used by: task-planner agent

Determine the active granularity level from delegation context. Default: fine.

## Fine (default)

| Constraint | Value |
|-----------|-------|
| Target task count (POC) | 40-60+ |
| Target task count (TDD) | 30-50+ |
| Max Do steps | 4 |
| Max files per task | 3 |
| Intermediate [VERIFY] | Every 2-3 tasks |
| [P] markers | Yes |
| Final V4-V6 | Always |
| VE tasks | Per project type |

### Fine Split/Combine Rules

**Split if:**
- Do section > 4 steps
- Files section > 3 files
- Task mixes creation + testing
- Task mixes > 1 logical concern
- Verification requires > 1 unrelated command

**Combine if:**
- Task 1 creates a file, Task 2 adds a single import to that file
- Both tasks touch the same file with trivially related changes
- Neither task is meaningful alone

## Coarse

| Constraint | Value |
|-----------|-------|
| Target task count (POC) | 10-20 |
| Target task count (TDD) | 8-15 |
| Max Do steps | 8-10 |
| Max files per task | 5-6 |
| Intermediate [VERIFY] | Every 2-3 tasks |
| [P] markers | Yes |
| Final V4-V6 | Always |
| VE tasks | Per project type |

### Coarse Split/Combine Rules

**Split if:**
- Do section > 10 steps
- Files section > 6 files
- Task mixes unrelated logical concerns
- Task crosses phase boundaries

**Combine if:**
- Multiple fine tasks touch the same component for the same concern
- Error handling + happy path are in the same component
- Setup + first usage are tightly coupled

### Coarse Guidance

- Each task remains a single logical concern (no bundling unrelated changes)
- Each task should be completable in a single focused session
- Combine what fine mode splits when they share a component and concern

## Shared Rules (both levels)

- 1 logical concern per task (always)
- Phase distribution ratios preserved proportionally
- [P] eligibility: zero file overlap, no output deps, not [VERIFY], no shared config
- Final verification sequence (V4-V6) always generated
- VE tasks generated per project type detection (independent of granularity)
- POC-first or TDD workflow selection unchanged by granularity
- Clarity test: each task executable without clarifying questions
- Simplicity principle: minimum code to achieve goal
- Surgical principle: touch only what the task requires
