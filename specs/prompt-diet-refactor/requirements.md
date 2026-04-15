# Requirements: prompt-diet-refactor

## Goal

Reduce coordinator token consumption from ~15,000 tokens (2,363 lines) to <5,000 tokens (<1,200 lines) per iteration by splitting coordinator-pattern.md into 5 focused modules, consolidating duplicated content, and extracting detailed scripts, while maintaining 100% behavioral compatibility.

## User Stories

### US-1: Modular Coordinator Prompts

**As a** coordinator agent
**I want to** load only the reference sections relevant to my current task
**So that** my token consumption stays under 5,000 tokens per iteration

**Acceptance Criteria:**
- AC-1.1: coordinator-pattern.md split into 5 modules: coordinator-core.md (150 lines), ve-verification-contract.md (200 lines), task-modification.md (150 lines), pr-lifecycle.md (150 lines), git-strategy.md (100 lines)
- AC-1.2: implement.md updated to load coordinator-core.md (always) + on-demand module based on task type
- AC-1.3: Total lines loaded per iteration <1,200 (measured by `wc -l` on loaded files)
- AC-1.4: All 5 modules exist in `plugins/ralph-specum/references/` directory

### US-2: Consolidated Native Task Sync

**As a** coordinator agent
**I want to** read Native Task Sync logic in 2 consolidated sections instead of 8 scattered sections
**So that** I don't load redundant graceful degradation patterns 8 times

**Acceptance Criteria:**
- AC-2.1: 8 Native Task Sync sections consolidated into 2: "Before delegation" and "After completion"
- AC-2.2: Graceful degradation pattern defined once in coordinator-core.md, referenced by both sections
- AC-2.3: Line count reduction: ~200 lines → ~100 lines (50% reduction)
- AC-2.4: All sync operations (TaskCreate, TaskUpdate, stale ID detection) preserved in consolidated sections

### US-3: Single Source of Truth for Duplicated Content

**As a** developer maintaining the codebase
**I want to** update documentation in one canonical location
**So that** I don't need to sync changes across multiple files

**Acceptance Criteria:**
- AC-3.1: Quality checkpoints content exists only in quality-checkpoints.md (removed from phase-rules.md, task-planner.md)
- AC-3.2: VE definitions (VE0-VE3) exist only in quality-checkpoints.md (removed from phase-rules.md)
- AC-3.3: E2E anti-patterns exist only in e2e-anti-patterns.md (removed from coordinator-pattern.md inline)
- AC-3.4: Intent classification exists only in intent-classification.md (removed from phase-rules.md, task-planner.md)
- AC-3.5: Test integrity content exists only in test-integrity.md (removed from quality-checkpoints.md)
- AC-3.6: All removed content replaced with references to canonical files (e.g., "See quality-checkpoints.md for details")

### US-4: Extracted Scripts to hooks/scripts/

**As a** coordinator agent
**I want to** reference utility scripts by name instead of embedding detailed logic in my prompt
**So that** my prompt stays focused on coordination logic, not implementation details

**Acceptance Criteria:**
- AC-4.1: Atomic append with flock scripts moved to `hooks/scripts/chat-md-protocol.sh`
- AC-4.2: jq state merge pattern documented in `hooks/scripts/state-update-pattern.md`
- AC-4.3: VE-cleanup pseudocode moved to `hooks/scripts/ve-skip-forward.md`
- AC-4.4: Native Task Sync algorithm moved to `hooks/scripts/native-sync-pattern.md`
- AC-4.5: Coordinator prompts reference script names, not embed script content
- AC-4.6: All extracted scripts are executable with `chmod +x`

### US-5: Mechanical Verification

**As a** developer validating the refactor
**I want to** run automated checks that confirm all files exist and references are updated
**So that** I can catch broken file paths before running the coordinator

**Acceptance Criteria:**
- AC-5.1: Verification script `hooks/scripts/verify-coordinator-diet.sh` exists and is executable
- AC-5.2: Script checks all 5 new modules exist in references/
- AC-5.3: Script greps for old references (coordinator-pattern.md) in implement.md, spec-executor.md, stop-watcher.sh
- AC-5.4: Script reports token count: `wc -l` on all loaded references <1,200 lines
- AC-5.5: Script exits 0 if all checks pass, 1 if any fail

### US-6: Functional Verification

**As a** developer ensuring behavioral compatibility
**I want to** run a full spec execution with the refactored coordinator
**So that** I can confirm no behavior changes were introduced

**Acceptance Criteria:**
- AC-6.1: Test spec (e.g., hello-world or similar simple spec) executes to completion with refactored coordinator
- AC-6.2: All tasks mark complete [x] in tasks.md
- AC-6.3: .progress.md shows normal execution flow (no errors, no stuck states)
- AC-6.4: State file .ralph-state.json deleted on completion (normal cleanup)
- AC-6.5: Git commits created per commit-discipline.md (one per task)
- AC-6.6: No "ERROR: State file missing" or "ERROR: Tasks file missing" during execution

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Split coordinator-pattern.md into 5 modules | High | 5 files exist, total line count matches research estimates |
| FR-2 | Implement on-demand loading in implement.md | High | implement.md Step 4 loads coordinator-core.md + conditional module |
| FR-3 | Consolidate 8 Native Task Sync sections into 2 | Medium | coordinator-core.md contains 2 sync sections, graceful degradation defined once |
| FR-4 | Remove 5 categories of content duplication | Medium | Canonical files contain content, other files reference them |
| FR-5 | Extract 4 detailed scripts to hooks/scripts/ | Medium | 4 new script files, coordinator prompts reference them |
| FR-6 | Create mechanical verification script | High | Script runs all checks, exits 0 on pass, 1 on fail |
| FR-7 | Validate with functional test execution | High | Full spec execution completes successfully |
| FR-8 | Update all file path references | High | grep finds no "coordinator-pattern.md" references in agent files |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Token consumption | Lines of references loaded per iteration | <1,200 lines |
| NFR-2 | Backward compatibility | Behavioral changes | 0 (100% compatible) |
| NFR-3 | Refactoring risk | Code complexity | LOW (pure reorganization) |
| NFR-4 | File organization | Modularity | 5 focused modules vs 1 monolithic file |
| NFR-5 | Verification coverage | Test types | Mechanical + functional |

## Glossary

- **coordinator-pattern.md**: Original 1,023-line monolithic coordinator prompt file
- **coordinator-core.md**: New 150-line module containing role, FSM, critical rules, signal protocol (always loaded)
- **ve-verification-contract.md**: New 200-line module for VE task delegation and skills loading
- **task-modification.md**: New 150-line module for SPLIT/PREREQ/FOLLOWUP/ADJUST operations
- **pr-lifecycle.md**: New 150-line module for PR management and CI monitoring
- **git-strategy.md**: New 100-line module for commit/push strategy
- **Native Task Sync**: Bidirectional synchronization between tasks.md markdown and Claude Code's native task system (TaskCreate/TaskUpdate)
- **Graceful degradation pattern**: Error handling that disables sync after 3 consecutive failures (nativeSyncEnabled = false)
- **Mechanical verification**: File existence and reference checking (no code execution)
- **Functional verification**: Full spec execution to validate behavior (code execution)
- **Token budget**: Conservative 30% reduction target (~1,650 lines, down from 2,363)

## Out of Scope

- Modifying coordinator behavior or logic (refactoring is structural only)
- Changing Native Task Sync functionality (consolidating structure only)
- Altering verification layers or failure recovery logic
- Updates to other agent prompts (spec-executor, task-planner, etc.) beyond file path references
- Performance optimization beyond token reduction
- UI/UX changes to Ralph Specum commands

## Dependencies

- **engine-state-hardening spec** must complete first (modifies coordinator-pattern.md, avoids merge conflicts)
- **hooks/scripts/** directory exists (established pattern for script extraction)
- **implement.md** reference loading pattern exists (established pattern for module loading)
- jq tool available (used for state file manipulation)

## Success Criteria

- Token reduction: <1,200 lines loaded per iteration (48% reduction from 2,363)
- All 5 new modules exist in `plugins/ralph-specum/references/`
- Mechanical verification script passes all checks
- Functional test (full spec execution) completes successfully
- Zero behavior changes (100% backward compatible)
- grep for "coordinator-pattern.md" returns 0 results in agent files
- All Native Task Sync operations preserved in consolidated sections

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Broken file path references after split | High | Mechanical verification script catches all old references |
| Behavior change during consolidation | Medium | Functional verification with full spec execution |
| Merge conflict with engine-state-hardening | Medium | Ensure engine-state-hardening completes first, then split |
| Token reduction target not achievable | Low | Research confirms 48% reduction is achievable |
| Script extraction breaks existing flows | Low | Scripts moved, not modified—logic unchanged |

## Verification Contract

**Project type**: cli

**Entry points**:
- `/ralph-specum:implement` — loads coordinator references, starts execution loop
- `plugins/ralph-specum/references/coordinator-core.md` — new core coordinator module (always loaded)
- `plugins/ralph-specum/references/ve-verification-contract.md` — VE delegation module (on-demand)
- `plugins/ralph-specum/references/task-modification.md` — task modification module (on-demand)
- `plugins/ralph-specum/references/pr-lifecycle.md` — PR lifecycle module (on-demand)
- `plugins/ralph-specum/references/git-strategy.md` — git strategy module (on-demand)

**Observable signals**:
- PASS looks like:
  - `wc -l` on loaded reference files shows <1,200 total lines
  - `hooks/scripts/verify-coordinator-diet.sh` exits with code 0
  - Full spec execution completes with ALL_TASKS_COMPLETE
  - All tasks marked [x] in tasks.md
  - No errors in .progress.md execution log
  - grep for "coordinator-pattern.md" returns 0 results in agent files

- FAIL looks like:
  - `wc -l` shows >=1,200 lines (token budget exceeded)
  - Verification script exits with code 1 and lists missing files
  - Spec execution stops with "ERROR: State file missing" or "ERROR: Tasks file missing"
  - Tasks stuck at same index after multiple iterations (coordinator not advancing)
  - grep finds "coordinator-pattern.md" references (file paths not updated)

**Hard invariants**:
- Coordinator MUST NOT change behavior—only reorganize structure
- All Native Task Sync operations MUST be preserved (TaskCreate, TaskUpdate, stale ID detection)
- State file format MUST remain compatible (.ralph-state.json schema unchanged)
- Commit discipline MUST be preserved (one commit per task)
- Verification layers MUST all pass (no shortcuts in verification logic)
- External reviewer integration MUST work (chat.md protocol unchanged)

**Seed data**:
- Existing coordinator-pattern.md (1,023 lines) — source material for split
- Existing implement.md reference loading pattern (lines 228-240) — update target
- Test spec (e.g., hello-world or similar) — for functional verification
- hooks/scripts/ directory (7 existing files) — pattern for script extraction

**Dependency map**:
- **engine-state-hardening spec** — coordinates to avoid merge conflicts on coordinator-pattern.md
- **implement.md** — updates reference loading to use new modular structure
- **spec-executor.md** — may contain coordinator-pattern.md references that need updating
- **stop-watcher.sh** — continuation prompt may reference coordinator sections by name
- **hooks/scripts/** — gains 4 new utility scripts for extracted logic

**Escalate if**:
- Functional verification fails with coordinator stuck in loop (may indicate behavior change)
- Token count doesn't reduce as expected (may need aggressive consolidation beyond conservative approach)
- Merge conflicts with engine-state-hardening changes (coordinate manual resolution)
- Native Task Sync operations broken after consolidation (may have lost critical logic)
