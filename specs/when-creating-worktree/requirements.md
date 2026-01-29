---
spec: when-creating-worktree
phase: requirements
created: 2026-01-29
generated: auto
---

# Requirements: when-creating-worktree

## Summary

Copy spec state files to git worktree so `/research` and other commands know which spec is active.

## User Stories

### US-1: Continue work in worktree

As a developer using ralph-specum,
I want my spec state copied to a new worktree
so that I can continue my spec workflow without losing context.

**Acceptance Criteria**:
- AC-1.1: After worktree creation, `.current-spec` exists in worktree's `specs/` directory
- AC-1.2: After worktree creation, spec's `.ralph-state.json` exists in worktree if it existed in source
- AC-1.3: After worktree creation, spec's `.progress.md` exists in worktree if it existed in source
- AC-1.4: Running `/ralph-specum:research` in worktree correctly identifies active spec

### US-2: Handle missing state gracefully

As a developer,
I want the worktree creation to work even if no spec is active,
so that I can create worktrees at any point in my workflow.

**Acceptance Criteria**:
- AC-2.1: Worktree creation succeeds even if `.current-spec` doesn't exist
- AC-2.2: No errors when spec directory doesn't exist yet
- AC-2.3: Existing state in worktree is not overwritten

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Copy `.current-spec` to worktree after `git worktree add` | Must | AC-1.1 |
| FR-2 | Copy spec's `.ralph-state.json` to worktree | Must | AC-1.2 |
| FR-3 | Copy spec's `.progress.md` to worktree | Must | AC-1.3 |
| FR-4 | Create `specs/` and spec directory in worktree if needed | Must | AC-1.2, AC-1.3 |
| FR-5 | Skip copy if source file doesn't exist | Should | AC-2.1, AC-2.2 |
| FR-6 | Do not overwrite existing files in worktree | Should | AC-2.3 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | State copy must complete in < 1 second | Performance |
| NFR-2 | Must not break existing worktree creation flow | Compatibility |

## Out of Scope

- Syncing state changes back from worktree to main repo
- Copying other spec files (research.md, requirements.md, etc.) - these are committed
- Two-way state synchronization between worktree and main

## Dependencies

- git worktree functionality
- Bash file system commands
