---
spec: return-ralph-wrigum
phase: requirements
created: 2026-02-14
generated: auto
---

# Requirements: return-ralph-wrigum

## Summary

Re-introduce the Ralph Wiggum plugin as the execution loop mechanism for `/implement`, reverting the self-contained loop from v3.0.0 while preserving all v3.0.0 improvements (recovery mode, fix-task generation, multi-directory support, bats tests). The final output is a PR.

## User Stories

### US-1: Execute specs using Ralph Wiggum loop
As a developer, I want `/ralph-specum:implement` to use the Ralph Wiggum plugin's `/ralph-loop` for execution loop control so that I benefit from the official Anthropic loop mechanism.

**Acceptance Criteria**:
- AC-1.1: implement.md invokes `/ralph-loop` with coordinator prompt, max-iterations, and completion-promise
- AC-1.2: Coordinator prompt includes all current orchestration logic (state reading, task parsing, delegation, verification, parallel execution, recovery mode)
- AC-1.3: `ALL_TASKS_COMPLETE` is used as the completion-promise
- AC-1.4: Max-iterations calculated from totalTasks * maxTaskIterations * 2

### US-2: Cancel execution with dual cleanup
As a developer, I want `/ralph-specum:cancel` to stop both the Ralph Wiggum loop and clean up spec state files so that cancellation is complete.

**Acceptance Criteria**:
- AC-2.1: cancel.md invokes `/cancel-ralph` to stop the Ralph Wiggum loop
- AC-2.2: cancel.md still deletes `.ralph-state.json`
- AC-2.3: cancel.md still removes spec directory and clears `.current-spec`
- AC-2.4: cancel.md still updates Spec Index

### US-3: Stop-watcher becomes passive observer
As a developer, I want the stop-watcher.sh to only provide logging and cleanup (not loop control) so that it does not conflict with Ralph Wiggum's stop-hook.

**Acceptance Criteria**:
- AC-3.1: stop-watcher.sh does NOT output continuation prompts
- AC-3.2: stop-watcher.sh still logs execution state to stderr
- AC-3.3: stop-watcher.sh still cleans orphaned temp progress files
- AC-3.4: stop-watcher.sh still validates state file integrity
- AC-3.5: stop-watcher.sh still detects ALL_TASKS_COMPLETE in transcript

### US-4: Ralph Wiggum dependency documented
As a developer, I want clear installation instructions so that I can set up the Ralph Wiggum dependency.

**Acceptance Criteria**:
- AC-4.1: README documents the Ralph Wiggum dependency
- AC-4.2: README includes install command: `/plugin install ralph-wiggum@claude-plugins-official`
- AC-4.3: implement.md includes dependency check with clear error message
- AC-4.4: CLAUDE.md updated to mention Ralph Wiggum dependency

### US-5: Existing tests updated
As a developer, I want bats tests to reflect the new passive stop-watcher behavior so that CI remains green.

**Acceptance Criteria**:
- AC-5.1: stop-hook.bats tests updated to verify stop-watcher does NOT output continuation prompts
- AC-5.2: Tests that check loop control behavior are removed or updated
- AC-5.3: All existing bats tests pass after changes
- AC-5.4: CI (GitHub Actions) passes

### US-6: Version bumped appropriately
As a developer, I want the version bumped to signal the breaking change so that users know to install Ralph Wiggum.

**Acceptance Criteria**:
- AC-6.1: plugin.json version bumped to 4.0.0
- AC-6.2: marketplace.json version bumped to 4.0.0
- AC-6.3: Both versions match

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | implement.md invokes `/ralph-loop` with coordinator prompt | Must | US-1 |
| FR-2 | Coordinator prompt preserves all v3.0.0 orchestration logic | Must | US-1 |
| FR-3 | cancel.md calls `/cancel-ralph` before file cleanup | Must | US-2 |
| FR-4 | stop-watcher.sh stripped of loop control output | Must | US-3 |
| FR-5 | stop-watcher.sh retains logging, cleanup, validation | Must | US-3 |
| FR-6 | Dependency check in implement.md with install instructions | Must | US-4 |
| FR-7 | README updated with dependency and breaking change | Must | US-4 |
| FR-8 | bats tests updated for passive stop-watcher | Must | US-5 |
| FR-9 | Version bumped to 4.0.0 in both manifests | Must | US-6 |
| FR-10 | PR created via gh CLI | Must | Goal |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | All existing bats tests must pass or be appropriately updated | Quality |
| NFR-2 | CI pipeline must pass (bats + shellcheck + version check) | Quality |
| NFR-3 | No regression in parallel [P] or [VERIFY] task handling | Compatibility |
| NFR-4 | Recovery mode (--recovery-mode) must still work | Compatibility |

## Out of Scope

- Modifying Ralph Wiggum plugin itself
- Adding new features beyond restoring the dependency
- Changing the spec-executor or qa-engineer agents
- Modifying path-resolver.sh or load-spec-context.sh
- Changing the state file schema (.ralph-state.json)

## Dependencies

- Ralph Wiggum plugin: `/plugin install ralph-wiggum@claude-plugins-official`
- Existing bats-core test infrastructure
- jq (already a dependency)
