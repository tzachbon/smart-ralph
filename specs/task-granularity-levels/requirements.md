# Requirements: Task Granularity Levels

## Goal

Add configurable task granularity levels (fine/coarse) to ralph-specum's task planner so users can reduce task count and token consumption for sequential execution, while preserving fine-grained tasks for parallel dispatch.

## User Stories

### US-1: Specify granularity via --tasks-size flag on /ralph-specum:start

**As a** plugin user
**I want to** pass `--tasks-size fine|coarse` when starting a spec
**So that** the granularity preference is stored early and carries through to task generation

**Acceptance Criteria:**
- [ ] AC-1.1: `/ralph-specum:start my-spec My goal --tasks-size coarse` stores `"granularity": "coarse"` in `.ralph-state.json`
- [ ] AC-1.2: `/ralph-specum:start my-spec My goal --tasks-size fine` stores `"granularity": "fine"` in `.ralph-state.json`
- [ ] AC-1.3: Omitting `--tasks-size` on `/start` does NOT set the field (deferred to interview or default)
- [ ] AC-1.4: Invalid value (e.g., `--tasks-size mega`) logs a warning and defaults to fine

### US-2: Specify granularity via --tasks-size flag on /ralph-specum:tasks

**As a** plugin user
**I want to** pass `--tasks-size fine|coarse` when generating tasks
**So that** I can override or set granularity at task-generation time

**Acceptance Criteria:**
- [ ] AC-2.1: `/ralph-specum:tasks --tasks-size coarse` stores `"granularity": "coarse"` in `.ralph-state.json` and passes it to task-planner
- [ ] AC-2.2: `/ralph-specum:tasks --tasks-size fine` stores `"granularity": "fine"` and passes it to task-planner
- [ ] AC-2.3: Flag on `/tasks` overrides any value previously stored by `/start`
- [ ] AC-2.4: Invalid value logs a warning and defaults to fine

### US-3: Task planner generates fine-grained tasks (40-60+) with [VERIFY] checkpoints

**As a** plugin user who chose fine granularity
**I want** the task planner to produce 40-60+ small tasks with intermediate [VERIFY] checkpoints every 2-3 tasks
**So that** I get maximum recoverability and parallel dispatch potential

**Acceptance Criteria:**
- [ ] AC-3.1: Fine mode produces 40-60+ tasks (current behavior preserved)
- [ ] AC-3.2: Max 4 steps in Do section per task
- [ ] AC-3.3: Max 3 files per task
- [ ] AC-3.4: Intermediate [VERIFY] quality checkpoints inserted every 2-3 tasks
- [ ] AC-3.5: Final verification sequence (V4-V6) always included regardless of mode

### US-4: Task planner generates coarse-grained tasks (10-20) without intermediate [VERIFY]

**As a** plugin user who chose coarse granularity
**I want** the task planner to produce 10-20 larger tasks without intermediate [VERIFY] checkpoints
**So that** I reduce token consumption and execution time for sequential runs

**Acceptance Criteria:**
- [ ] AC-4.1: Coarse mode produces 10-20 tasks
- [ ] AC-4.2: Max 8-10 steps in Do section per task
- [ ] AC-4.3: Max 5-6 files per task
- [ ] AC-4.4: No intermediate [VERIFY] quality checkpoints between tasks
- [ ] AC-4.5: Final verification sequence (V4-V6) always included
- [ ] AC-4.6: Each coarse task remains a single logical concern (no unrelated changes bundled)

### US-5: User asked granularity preference during tasks interview

**As a** plugin user in normal (non-quick) mode
**I want to** be asked my granularity preference during the tasks interview when no flag was provided
**So that** I can decide based on my execution context

**Acceptance Criteria:**
- [ ] AC-5.1: Interview asks granularity question when `granularity` field is absent from `.ralph-state.json`
- [ ] AC-5.2: Fine is pre-selected/recommended as the default option
- [ ] AC-5.3: Interview skips the question if `--tasks-size` flag was already provided (via `/start` or `/tasks`)
- [ ] AC-5.4: Response stored in `.ralph-state.json` and `.progress.md` under interview section
- [ ] AC-5.5: In `--quick` mode, default to fine (no interview question asked)

### US-6: Granularity setting persisted in .ralph-state.json

**As a** task-planner agent
**I want** the granularity setting available in `.ralph-state.json`
**So that** I can read it and apply the correct sizing rules

**Acceptance Criteria:**
- [ ] AC-6.1: `.ralph-state.json` contains `"granularity": "fine"|"coarse"` when set
- [ ] AC-6.2: When field is missing (old specs), default behavior is `fine` (backwards compatible)
- [ ] AC-6.3: Task-planner reads granularity from state and applies corresponding sizing rules
- [ ] AC-6.4: Re-running `/ralph-specum:tasks` with different `--tasks-size` updates the stored value

### US-7: [P] parallel markers generated in both modes

**As a** plugin user
**I want** [P] parallel markers on eligible tasks regardless of granularity level
**So that** parallel dispatch works when available, even with coarse tasks

**Acceptance Criteria:**
- [ ] AC-7.1: Fine mode generates [P] markers on eligible tasks (current behavior)
- [ ] AC-7.2: Coarse mode generates [P] markers on eligible tasks (same rules: zero file overlap, no output dependencies)
- [ ] AC-7.3: [VERIFY] tasks still break parallel groups in both modes

### US-8: README documents --tasks-size flag

**As a** plugin user reading the documentation
**I want** the CLAUDE.md or README to explain the `--tasks-size` flag and granularity levels
**So that** I know how to control task granularity

**Acceptance Criteria:**
- [ ] AC-8.1: CLAUDE.md documents the `--tasks-size fine|coarse` flag with usage examples and explains what each level produces

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Parse `--tasks-size fine\|coarse` from `$ARGUMENTS` in start.md | High | AC-1.1, AC-1.2, AC-1.4 |
| FR-2 | Parse `--tasks-size fine\|coarse` from `$ARGUMENTS` in tasks.md | High | AC-2.1, AC-2.2, AC-2.4 |
| FR-3 | Store granularity in `.ralph-state.json` | High | AC-6.1, AC-6.2 |
| FR-4 | Task-planner reads granularity and selects sizing rules | High | AC-6.3 |
| FR-5 | Fine sizing rules: max 4 Do steps, 3 files, 40-60+ tasks, [VERIFY] every 2-3 | High | AC-3.1 through AC-3.5 |
| FR-6 | Coarse sizing rules: max 8-10 Do steps, 5-6 files, 10-20 tasks, no intermediate [VERIFY] | High | AC-4.1 through AC-4.6 |
| FR-7 | Interview question for granularity during tasks phase | Medium | AC-5.1 through AC-5.5 |
| FR-8 | Flag on /tasks overrides value from /start | Medium | AC-2.3 |
| FR-9 | [P] markers applied in both modes using same eligibility rules | Medium | AC-7.1 through AC-7.3 |
| FR-10 | Final verification sequence (V4-V6) always generated regardless of mode | High | AC-3.5, AC-4.5 |
| FR-11 | Invalid granularity value warns and defaults to fine | Low | AC-1.4, AC-2.4 |
| FR-12 | Quick mode defaults to fine when no flag provided | Medium | AC-5.5 |
| FR-13 | Update CLAUDE.md/README with `--tasks-size` flag documentation | Medium | AC-8.1 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Backwards compatibility | Old specs without `granularity` field | Must default to fine behavior, no breakage |
| NFR-2 | Token reduction | Coarse vs fine token consumption | Coarse uses ~3-5x fewer stop-hook iterations than fine for same feature |
| NFR-3 | Task quality | Coarse task autonomy | Each coarse task executable without clarifying questions (same clarity test as fine) |
| NFR-4 | Change locality | Files modified | Only task-planner.md, tasks.md, start.md, and .ralph-state.json schema |

## Glossary

- **Fine granularity**: 40-60+ tasks, max 4 Do steps, max 3 files, [VERIFY] every 2-3 tasks. Current default behavior.
- **Coarse granularity**: 10-20 tasks, max 8-10 Do steps, max 5-6 files, no intermediate [VERIFY]. Optimized for sequential execution.
- **[VERIFY] checkpoint**: A task tagged `[VERIFY]` that runs lint/typecheck/test commands. Delegated to qa-engineer agent.
- **[P] marker**: Parallel-eligible tag on tasks with zero file overlap and no output dependencies.
- **Stop-hook cycle**: One iteration of the stop-watcher loop: context injection, task execution, progress update.
- **Final verification sequence**: V4 (full local CI), V5 (CI pipeline), V6 (AC checklist) -- always generated in both modes.

## Out of Scope

- Auto-detection logic (fine if parallel plugin installed, coarse if not) -- deferred per user decision
- Plugin settings via `.claude/ralph-specum.local.md` for `default_granularity` -- deferred
- Converting [VERIFY] tasks to hooks (user decided to keep as opt-in tasks)
- Hybrid/mixed granularity within a single spec
- Granularity levels beyond fine/coarse (e.g., "balanced", "minimal")
- Changes to stop-watcher or hook infrastructure
- Changes to spec-executor behavior

## Dependencies

- Task-planner agent prompt (`plugins/ralph-specum/agents/task-planner.md`) -- primary modification target
- Commands: `plugins/ralph-specum/commands/tasks.md` and `plugins/ralph-specum/commands/start.md` -- flag parsing
- `.ralph-state.json` schema -- new `granularity` field
- Existing [P] parallel marker logic (must remain functional in both modes)

## Assumptions

- "Fine" is the right default for quick mode since quick mode is designed for maximum automation
- Coarse tasks still follow the same POC-first or TDD workflow structure (just fewer, larger tasks)
- The phase distribution ratios (Phase 1 = 50-60%, etc.) apply proportionally regardless of granularity
- VE tasks (E2E verification) are generated in both modes

## Unresolved Questions

- Should coarse mode adjust the max number of VE tasks (currently max 5)? Likely no change needed since VE count is already small.
- What task count range for coarse mode in TDD workflow? (TDD currently targets 30+; coarse TDD might be 8-15)

## Success Criteria

- Fine mode produces task count within 40-60+ range (same as current)
- Coarse mode produces task count within 10-20 range for equivalent spec
- `--tasks-size coarse` on `/start` or `/tasks` correctly propagates to task-planner
- Old specs without granularity field continue working unchanged (fine default)
- [P] markers appear on eligible tasks in both modes
