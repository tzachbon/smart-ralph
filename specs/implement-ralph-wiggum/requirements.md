# Requirements: Ralph Loop Loop Integration

## Goal

Replace the custom stop-handler loop mechanism in `/implement` with the official Ralph Loop plugin's `/ralph-loop` command, while preserving Task tool delegation to spec-executor subagents for task execution.

## User Stories

### US-1: Thin Wrapper Implementation

**As a** plugin developer
**I want to** have `/implement` call `/ralph-loop` instead of managing its own stop hook
**So that** the loop mechanism is standardized and maintained by the official Ralph Loop plugin

**Acceptance Criteria:**
- [ ] AC-1.1: `/implement` command reads spec from `.current-spec` and validates prerequisites
- [ ] AC-1.2: `/implement` invokes `/ralph-loop` with coordinator prompt and parameters
- [ ] AC-1.3: `--max-iterations` calculated from totalTasks * maxTaskIterations
- [ ] AC-1.4: `--completion-promise` set to "ALL_TASKS_COMPLETE"
- [ ] AC-1.5: implement.md reduced from ~1000 lines to <100 lines (wrapper only)

### US-2: Coordinator Prompt Migration

**As a** plugin developer
**I want to** move the current implement.md coordinator logic into the ralph-loop prompt
**So that** each iteration receives instructions for reading state, parsing tasks, and delegating to spec-executor

**Acceptance Criteria:**
- [ ] AC-2.1: Prompt includes instructions to read `.ralph-state.json` for taskIndex and phase
- [ ] AC-2.2: Prompt includes instructions to parse tasks.md for current task(s)
- [ ] AC-2.3: Prompt delegates sequential tasks to spec-executor via Task tool
- [ ] AC-2.4: Prompt handles [P] parallel tasks via multi-Task tool calls
- [ ] AC-2.5: Prompt delegates [VERIFY] tasks to qa-engineer via Task tool
- [ ] AC-2.6: Prompt outputs "ALL_TASKS_COMPLETE" when taskIndex >= totalTasks
- [ ] AC-2.7: Prompt preserves all verification logic from current implement.md

### US-3: Stop Handler Removal

**As a** plugin maintainer
**I want to** remove the custom stop-handler.sh and convert hooks.json to a read-only watcher
**So that** the plugin relies on Ralph Loop's maintained stop-hook for loop control

**Acceptance Criteria:**
- [ ] AC-3.1: `hooks/scripts/stop-handler.sh` (274 lines) deleted
- [ ] AC-3.2: `hooks/hooks.json` updated to register stop-watcher.sh (logging only, no loop control)
- [ ] AC-3.3: Stop hook is read-only watcher (always exits 0, does not block or restart)
- [ ] AC-3.4: Ralph Loop's stop-hook handles loop continuation

### US-4: Dependency Management

**As a** plugin user
**I want to** receive clear instructions when Ralph Loop plugin is not installed
**So that** I can install the required dependency before using `/implement`

**Acceptance Criteria:**
- [ ] AC-4.1: `/implement` checks if Ralph Loop plugin is available
- [ ] AC-4.2: If missing, error message includes: `/plugin install ralph-wiggum@claude-plugins-official`
- [ ] AC-4.3: README documents Ralph Loop as required dependency
- [ ] AC-4.4: Migration guide documents this breaking change

### US-5: State Management Compatibility

**As a** plugin developer
**I want to** maintain `.ralph-state.json` for task progress tracking
**So that** existing state management patterns continue working alongside Ralph Loop's state

**Acceptance Criteria:**
- [ ] AC-5.1: `.ralph-state.json` continues tracking taskIndex, phase, totalTasks
- [ ] AC-5.2: taskIndex advancement happens in coordinator prompt logic (not stop-hook)
- [ ] AC-5.3: Ralph Loop's `.claude/ralph-loop.local.md` tracks iteration count
- [ ] AC-5.4: Both state files cleaned up on completion

### US-6: Cancel Command Update

**As a** plugin user
**I want to** cancel execution and have both state files cleaned up
**So that** I can safely restart from a clean state

**Acceptance Criteria:**
- [ ] AC-6.1: `/cancel` calls `/cancel-ralph` to stop the Ralph Loop loop
- [ ] AC-6.2: `/cancel` deletes `.ralph-state.json`
- [ ] AC-6.3: Both Ralph Loop state and plugin state cleaned up
- [ ] AC-6.4: `.progress.md` preserved for context

### US-7: Verification Logic Migration

**As a** plugin developer
**I want to** move verification logic from stop-handler into the coordinator prompt
**So that** task completion is validated before outputting ALL_TASKS_COMPLETE

**Acceptance Criteria:**
- [ ] AC-7.1: Coordinator verifies TASK_COMPLETE signal before advancing taskIndex
- [ ] AC-7.2: Coordinator checks tasks.md checkmarks match expected count
- [ ] AC-7.3: Coordinator detects contradiction patterns (manual action claims)
- [ ] AC-7.4: Failed verification retries same task (increment taskIteration)
- [ ] AC-7.5: Max retries blocks with user-facing error message

### US-8: Major Version Bump

**As a** plugin user
**I want to** see the version bumped to 2.0.0
**So that** I know this is a breaking change requiring Ralph Loop dependency

**Acceptance Criteria:**
- [ ] AC-8.1: plugin.json version updated from 1.6.1 to 2.0.0

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | `/implement` becomes thin wrapper calling `/ralph-loop` | High | AC-1.1, AC-1.2, AC-1.5 |
| FR-2 | Coordinator prompt includes full task orchestration logic | High | AC-2.1 through AC-2.7 |
| FR-3 | Delete stop-handler.sh, update hooks.json for watcher | High | AC-3.1, AC-3.2, AC-3.3 |
| FR-4 | Check Ralph Loop dependency on `/implement` invocation | High | AC-4.1, AC-4.2 |
| FR-5 | Maintain .ralph-state.json for task tracking | High | AC-5.1, AC-5.2 |
| FR-6 | Update /cancel to call /cancel-ralph | Medium | AC-6.1, AC-6.2, AC-6.3 |
| FR-7 | Parallel [P] task execution via multi-Task tool calls | High | AC-2.4 |
| FR-8 | [VERIFY] task delegation to qa-engineer | High | AC-2.5 |
| FR-9 | Move verification layers into coordinator prompt | High | AC-7.1 through AC-7.5 |
| FR-10 | Document breaking change in README | Medium | AC-4.3, AC-4.4 |
| FR-11 | Bump plugin version to 2.0.0 | High | AC-8.1 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | implement.md line count | Lines of code | < 100 lines (vs current ~1000) |
| NFR-2 | Watcher-only hook | Hook behavior | stop-watcher.sh exits 0 (no loop control) |
| NFR-3 | Backward compatibility for agents | Agent changes | spec-executor.md, qa-engineer.md unchanged |
| NFR-4 | Documentation completeness | Migration coverage | README + CHANGELOG updated |

## Glossary

- **Ralph Loop**: Official Anthropic plugin providing autonomous loop mechanism via stop-hook
- **Coordinator**: The `/implement` command's role in orchestrating task execution
- **Spec-executor**: Subagent that executes individual tasks autonomously
- **Completion promise**: String that Ralph Loop watches for to end the loop ("ALL_TASKS_COMPLETE")
- **Task tool**: Claude's mechanism for spawning subagents with isolated context
- **Stop hook**: Claude Code hook that intercepts session exits (exit code 2 continues loop)
- **[P] marker**: Parallel execution marker in tasks.md enabling concurrent task execution
- **[VERIFY] marker**: Verification checkpoint delegated to qa-engineer subagent

## Out of Scope

- Modifying spec-executor.md agent logic (stays as-is)
- Modifying qa-engineer.md agent logic (stays as-is)
- Modifying other spec phases (research, requirements, design, tasks)
- Bundling or forking Ralph Loop into this plugin
- Changing the TASK_COMPLETE signal (spec-executor continues using it)
- Removing .ralph-state.json entirely (still needed for task tracking)

## Dependencies

- **Ralph Loop plugin**: Must be installed via `/plugin install ralph-wiggum@claude-plugins-official`
- **Claude Code hooks**: Ralph Loop relies on Stop hook mechanism
- **Task tool**: Subagent delegation requires Task tool support

## Breaking Changes

| Change | Impact | Migration |
|--------|--------|-----------|
| Ralph Loop required | Users must install dependency | Add to README, error message with install command |
| Custom stop-handler removed | No longer self-contained | Ralph Loop provides loop mechanism |
| Completion signal change | ALL_TASKS_COMPLETE vs TASK_COMPLETE | Coordinator handles translation |
| Major version bump | 1.6.1 -> 2.0.0 | Signals breaking change to users |

## Success Criteria

- `/implement` successfully delegates to `/ralph-loop` and completes multi-task specs
- Parallel [P] task execution continues working via multi-Task tool calls
- [VERIFY] delegation to qa-engineer continues working
- Custom stop-handler.sh deleted, hooks.json updated for read-only watcher
- Error message guides users to install Ralph Loop when missing
- All existing specs can complete using the new loop mechanism
