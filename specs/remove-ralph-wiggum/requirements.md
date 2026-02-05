---
spec: remove-ralph-wiggum
phase: requirements
created: 2026-02-05
generated: auto
---

# Requirements: remove-ralph-wiggum

## Summary

Remove ralph-wiggum/ralph-loop plugin dependency by inlining loop control into the stop-hook. Version bump to 3.0.0.

## User Stories

### US-1: Self-contained execution loop

As a plugin user, I want the execution loop to work without installing ralph-loop plugin so that I have fewer dependencies to manage.

**Acceptance Criteria**:
- AC-1.1: `/ralph-specum:implement` works without ralph-loop installed
- AC-1.2: Stop-hook continues execution loop when tasks remain
- AC-1.3: Loop terminates when `ALL_TASKS_COMPLETE` detected
- AC-1.4: No references to `ralph-loop` or `ralph-wiggum` in codebase

### US-2: Simplified cancel command

As a plugin user, I want `/ralph-specum:cancel` to cleanly stop execution so that I can abort specs without external dependencies.

**Acceptance Criteria**:
- AC-2.1: Cancel deletes `.ralph-state.json` and `.progress.md`
- AC-2.2: Cancel clears `.current-spec` marker
- AC-2.3: No skill invocation required
- AC-2.4: Works even if state file missing

### US-3: Tested stop-hook behavior

As a developer, I want bats-core tests for the stop-hook so that loop control logic is verified.

**Acceptance Criteria**:
- AC-3.1: Tests for state reading/parsing
- AC-3.2: Tests for loop continuation output
- AC-3.3: Tests for completion detection
- AC-3.4: Tests for error handling (missing state, corrupt JSON)

### US-4: CI pipeline

As a developer, I want GitHub Actions CI running bats tests so that PRs are validated automatically.

**Acceptance Criteria**:
- AC-4.1: CI workflow triggers on push and PR
- AC-4.2: Workflow installs bats-core
- AC-4.3: Workflow runs all `.bats` test files
- AC-4.4: Workflow reports pass/fail status

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Stop-hook reads `.ralph-state.json` and determines if more tasks exist | Must | US-1 |
| FR-2 | Stop-hook outputs coordinator prompt when `taskIndex < totalTasks` | Must | US-1 |
| FR-3 | Stop-hook outputs nothing when `ALL_TASKS_COMPLETE` detected or phase != execution | Must | US-1 |
| FR-4 | implement.md writes state file directly without invoking external skill | Must | US-1 |
| FR-5 | implement.md outputs coordinator prompt inline (not via file+skill) | Must | US-1 |
| FR-6 | cancel.md deletes state files without skill invocation | Must | US-2 |
| FR-7 | cancel.md removes spec directory and clears .current-spec | Should | US-2 |
| FR-8 | bats-core tests cover stop-hook state machine | Must | US-3 |
| FR-9 | GitHub Actions workflow runs bats tests | Must | US-4 |
| FR-10 | Plugin version bumped to 3.0.0 in both plugin.json and marketplace.json | Must | Breaking |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Stop-hook execution < 100ms (no network calls) | Performance |
| NFR-2 | All shell scripts pass shellcheck | Quality |
| NFR-3 | bats tests complete in < 30 seconds | Performance |

## Out of Scope

- Modifying spec-executor or other agents
- Changing task file format
- Adding new features to loop control
- Recovery mode changes

## Dependencies

- bats-core (test framework)
- shellcheck (linting, already likely used)
- GitHub Actions (existing infrastructure)
