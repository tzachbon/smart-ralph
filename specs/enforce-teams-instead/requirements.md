---
spec: enforce-teams-instead
phase: requirements
created: 2026-02-19
generated: auto
---

# Requirements: enforce-teams-instead

## Summary
Update Ralph Specum plugin phases to use Claude Code Teams (TeamCreate, TaskCreate, SendMessage, etc.) instead of individual Task-tool subagent calls, applying the team-based pattern already demonstrated in start.md's research phase.

## User Stories

### US-1: Consistent team-based research across commands
As a plugin user, I want the standalone `/ralph-specum:research` command to use the same team-based pattern as `start.md` so that research execution is consistent regardless of entry point.

**Acceptance Criteria**:
- AC-1.1: `research.md` uses TeamCreate/TaskCreate/SendMessage/TeamDelete lifecycle
- AC-1.2: Research teammates are spawned via Task tool with `team_name` parameter
- AC-1.3: Results are merged from partial files into unified research.md
- AC-1.4: Team is cleaned up after research completes (TeamDelete)
- AC-1.5: Orphaned teams are detected and cleaned up on re-entry

### US-2: Team-based requirements phase
As a plugin user, I want the requirements phase to use a team so that the coordination pattern is consistent across all phases.

**Acceptance Criteria**:
- AC-2.1: `requirements.md` command creates a team for the requirements phase
- AC-2.2: Product-manager agent is spawned as a teammate
- AC-2.3: Team is cleaned up after requirements complete
- AC-2.4: Normal mode interview flow still works correctly
- AC-2.5: Quick mode bypasses interview but still uses team pattern

### US-3: Team-based design phase
As a plugin user, I want the design phase to use a team so that the coordination pattern is consistent.

**Acceptance Criteria**:
- AC-3.1: `design.md` command creates a team for the design phase
- AC-3.2: Architect-reviewer agent is spawned as a teammate
- AC-3.3: Team is cleaned up after design complete
- AC-3.4: Review/feedback loop still works correctly with team pattern

### US-4: Team-based tasks phase
As a plugin user, I want the tasks phase to use a team so that the coordination pattern is consistent.

**Acceptance Criteria**:
- AC-4.1: `tasks.md` command creates a team for the tasks phase
- AC-4.2: Task-planner agent is spawned as a teammate
- AC-4.3: Team is cleaned up after tasks complete

### US-5: Team-based parallel execution
As a plugin user, I want [P] parallel task batches in the execution phase to use teams for better coordination.

**Acceptance Criteria**:
- AC-5.1: Parallel [P] task batches spawn a team with multiple spec-executor teammates
- AC-5.2: Sequential tasks continue using direct Task delegation (no team overhead)
- AC-5.3: Stop-hook loop mechanism remains unchanged
- AC-5.4: [VERIFY] tasks still delegate to qa-engineer correctly
- AC-5.5: Team is cleaned up after parallel batch completes

### US-6: Backwards compatibility
As a plugin user, I want all existing workflows to continue working after team conversion.

**Acceptance Criteria**:
- AC-6.1: `--quick` mode completes without errors
- AC-6.2: Normal mode (with interviews) completes without errors
- AC-6.3: Execution loop with stop-hook functions correctly
- AC-6.4: State file management (.ralph-state.json) unchanged
- AC-6.5: Progress tracking (.progress.md) unchanged
- AC-6.6: Commit/push behavior unchanged

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Convert `research.md` from multi-Task parallel to team-based pattern matching start.md | Must | US-1 |
| FR-2 | Add team lifecycle (create/cleanup) to `requirements.md` command | Must | US-2 |
| FR-3 | Add team lifecycle to `design.md` command | Must | US-3 |
| FR-4 | Add team lifecycle to `tasks.md` command | Must | US-4 |
| FR-5 | Convert [P] parallel task execution in `implement.md` to use teams | Should | US-5 |
| FR-6 | Add orphaned team detection and cleanup to all phase commands | Should | US-1, US-2, US-3, US-4 |
| FR-7 | Keep stop-hook loop mechanism unchanged for execution phase | Must | US-5, US-6 |
| FR-8 | Preserve all existing interview, review, and approval flows | Must | US-6 |
| FR-9 | Team naming convention: `$phase-$specName` (e.g., `requirements-my-feature`) | Should | All |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | All changes are markdown file edits only -- no compiled code | Maintainability |
| NFR-2 | Team lifecycle adds less than 5 seconds overhead per phase | Performance |
| NFR-3 | Plugin version bump required for any plugin file change | Process |

## Out of Scope
- Replacing the stop-hook execution loop with teams
- Converting sequential execution tasks to use teams (only [P] parallel batches)
- Modifying agent definitions (agents/*.md remain unchanged)
- Changing the plan-synthesizer quick-mode flow (it already handles all phases internally)
- Converting the `start.md` research section (already uses teams)

## Dependencies
- Claude Code Teams API (TeamCreate, TaskCreate, TaskList, TaskUpdate, SendMessage, TeamDelete)
- Existing agent definitions in `plugins/ralph-specum/agents/`
- Stop-hook mechanism in `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
