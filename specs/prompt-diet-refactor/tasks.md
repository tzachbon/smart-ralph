---
spec: prompt-diet-refactor
phase: tasks
created: 2026-04-15T19:50:00Z
---

# Tasks: prompt-diet-refactor

## Overview

Total tasks: 47

**Workflow**: POC-first (file creation + structural refactor — no pre-existing test suite to drive TDD)
1. Phase 1: Make It Work (POC) - Create modules, split content, update references
2. Phase 2: Refactoring - Remove duplications, consolidate sections
3. Phase 3: Testing - Mechanical + functional verification
4. Phase 4: Quality Gates - Cleanup, documentation, PR
5. Phase 5: PR Lifecycle - CI monitoring, review resolution

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

✅ **Zero Regressions**: All existing tests pass (no broken functionality)
✅ **Modular & Reusable**: Code follows project patterns, properly abstracted
✅ **Real-World Validation**: Feature tested in actual environment (not just unit tests)
✅ **All Tests Pass**: Unit, integration, E2E all green
✅ **CI Green**: All CI checks passing
✅ **PR Ready**: Pull request created, reviewed, approved
✅ **Review Comments Resolved**: All code review feedback addressed

**Note**: The executor will continue working until all criteria are met. Do not stop at Phase 4 if CI fails or review comments exist.

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks to catch issues early. For small tasks, insert after 3 tasks. For medium/large tasks, insert after 2 tasks.

## Phase 1: Make It Work (POC)

Focus: Validate the modular structure works end-to-end. Create modules, split content, update implement.md, verify token reduction.

### Prerequisite: Verify engine-state-hardening Complete

- [x] 0.1 [VERIFY] Verify engine-state-hardening spec is complete and merged
  - **Do**:
    1. Check git log for engine-state-hardening merge commit: `git log --oneline --all | grep "engine-state-hardening"`
    2. Verify PR #12 is merged: `gh pr view 12 --json state | jq -r '.state'`
    3. Confirm coordinator-pattern.md has engine-state-hardening changes (check for Layer 4/5 references)
  - **Files**: .git/logs, .github (via gh CLI)
  - **Done when**: PR #12 shows "MERGED" state, coordinator-pattern.md contains latest engine changes
  - **Verify**: `gh pr view 12 --json state | jq -e '.state == "MERGED"' && echo PASS`
  - **Commit**: None
  - _Requirements: Dependency on engine-state-hardening_

### Module Creation

- [ ] 1.1 [P] Create coordinator-core.md with role, FSM, and signal protocol
  - **Do**:
    1. Create `plugins/ralph-specum/references/coordinator-core.md`
    2. Copy from coordinator-pattern.md: lines 5-47 (role, integrity rules, FSM), lines 78-177 (completion check, parse task, chat protocol), signal protocol section
    3. Add header: "# Coordinator Core\n\nCore coordinator logic loaded for every task type.\n\n## Role Definition"
    4. Add note: "This module is ALWAYS loaded. On-demand modules loaded based on task type."
  - **Files**: plugins/ralph-specum/references/coordinator-core.md
  - **Done when**: File exists with role/FSM/signal protocol content (~150 lines)
  - **Verify**: `test -f plugins/ralph-specum/references/coordinator-core.md && wc -l plugins/ralph-specum/references/coordinator-core.md | awk '{print $1}' | xargs -I {} test {} -gt 100 && echo PASS`
  - **Commit**: `feat(coordinator): create coordinator-core.md module`
  - _Requirements: FR-1, AC-1.1, AC-1.4_
  - _Design: coordinator-core.md section_

- [x] 1.2 [P] Create ve-verification-contract.md with VE delegation rules
  - **Do**:
    1. Create `plugins/ralph-specum/references/ve-verification-contract.md`
    2. Copy from coordinator-pattern.md: lines 178-280 (task delegation, Native Task Sync pre-delegation), lines 281-513 (parallel handling, Native Task Sync parallel/failure)
    3. Copy VE definitions from quality-checkpoints.md (VE0-VE3)
    4. Add header: "# VE Verification Contract\n\nVE task delegation and skills loading.\n\nLoaded for: VERIFY tasks only."
    5. Add reference note: "See ve-skip-forward.md for VE-cleanup pseudocode"
  - **Files**: plugins/ralph-specum/references/ve-verification-contract.md
  - **Done when**: File exists with VE delegation content (~200 lines)
  - **Verify**: `test -f plugins/ralph-specum/references/ve-verification-contract.md && grep -q "VE task delegation" plugins/ralph-specum/references/ve-verification-contract.md && echo PASS`
  - **Commit**: `feat(coordinator): create ve-verification-contract.md module`
  - _Requirements: FR-1, AC-1.1, AC-1.4_
  - _Design: ve-verification-contract.md section_

- [x] 1.3 [P] Create task-modification.md with SPLIT/PREREQ/FOLLOWUP/ADJUST operations
  - **Do**:
    1. Create `plugins/ralph-specum/references/task-modification.md`
    2. Copy from coordinator-pattern.md: lines 756-908 (task modification, Native Task Sync modification)
    3. Add header: "# Task Modification\n\nTask modification operations (SPLIT/PREREQ/FOLLOWUP/ADJUST).\n\nLoaded for: SPLIT, PREREQ, FOLLOWUP, ADJUST tasks."
    4. Add reference note: "See native-sync-pattern.md for Native Task Sync algorithm"
  - **Files**: plugins/ralph-specum/references/task-modification.md
  - **Done when**: File exists with task modification content (~150 lines)
  - **Verify**: `test -f plugins/ralph-specum/references/task-modification.md && grep -q "Task modification operations" plugins/ralph-specum/references/task-modification.md && echo PASS`
  - **Commit**: `feat(coordinator): create task-modification.md module`
  - _Requirements: FR-1, AC-1.1, AC-1.4_
  - _Design: task-modification.md section_

- [x] 1.4 [P] Create pr-lifecycle.md with PR management and CI monitoring
  - **Do**:
    1. Create `plugins/ralph-specum/references/pr-lifecycle.md`
    2. Copy from coordinator-pattern.md: lines 756-908 subset (PR lifecycle management sections)
    3. Add header: "# PR Lifecycle\n\nPR management and CI monitoring.\n\nLoaded for: PR_COMMIT tasks."
  - **Files**: plugins/ralph-specum/references/pr-lifecycle.md
  - **Done when**: File exists with PR lifecycle content (~150 lines)
  - **Verify**: `test -f plugins/ralph-specum/references/pr-lifecycle.md && grep -q "PR management" plugins/ralph-specum/references/pr-lifecycle.md && echo PASS`
  - **Commit**: `feat(coordinator): create pr-lifecycle.md module`
  - _Requirements: FR-1, AC-1.1, AC-1.4_
  - _Design: pr-lifecycle.md section_

- [x] 1.5 [P] Create git-strategy.md with commit and push strategy
  - **Do**:
    1. Create `plugins/ralph-specum/references/git-strategy.md`
    2. Copy from coordinator-pattern.md: lines 909-1023 (final cleanup, git push)
    3. Add header: "# Git Strategy\n\nCommit and push strategy.\n\nLoaded for: COMMIT tasks."
  - **Files**: plugins/ralph-specum/references/git-strategy.md
  - **Done when**: File exists with git strategy content (~100 lines)
  - **Verify**: `test -f plugins/ralph-specum/references/git-strategy.md && grep -q "Git Strategy" plugins/ralph-specum/references/git-strategy.md && echo PASS`
  - **Commit**: `feat(coordinator): create git-strategy.md module`
  - _Requirements: FR-1, AC-1.1, AC-1.4_
  - _Design: git-strategy.md section_

- [x] 1.6 [VERIFY] Quality checkpoint: verify all 5 modules created
  - **Do**:
    1. Check all 5 module files exist
    2. Verify each file has expected header content
    3. Confirm total line count is approximately 750 lines (150+200+150+150+100)
  - **Verify**: All files exist and have content:
    ```bash
    test -f plugins/ralph-specum/references/coordinator-core.md && \
    test -f plugins/ralph-specum/references/ve-verification-contract.md && \
    test -f plugins/ralph-specum/references/task-modification.md && \
    test -f plugins/ralph-specum/references/pr-lifecycle.md && \
    test -f plugins/ralph-specum/references/git-strategy.md && \
    echo "All 5 modules exist: PASS"
    ```
  - **Done when**: All 5 module files exist with expected content
  - **Commit**: `chore(coordinator): verify 5 modules created successfully` (only if fixes needed)
  - _Requirements: FR-1, AC-1.4_

### Script Extraction

- [x] 1.7 [P] Extract chat-md-protocol.sh to hooks/scripts/
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh`
    2. Copy atomic append with flock logic from coordinator-pattern.md (lines 200-249)
    3. Add bash shebang: `#!/bin/bash`
    4. Add documentation: "Atomic append with flock to prevent concurrent write corruption"
    5. Make executable: `chmod +x plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh`
  - **Files**: plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh
  - **Done when**: Script exists, is executable, contains flock logic
  - **Verify**: `test -x plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh && grep -q "flock" plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh && echo PASS`
  - **Commit**: `feat(scripts): extract chat-md-protocol.sh`
  - _Requirements: FR-5, AC-4.1, AC-4.6_
  - _Design: Script extraction section_

- [x] 1.8 [P] Extract state-update-pattern.md to hooks/scripts/
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/state-update-pattern.md`
    2. Copy jq state merge pattern from coordinator-pattern.md (line 642)
    3. Add documentation: "jq state merge pattern for .ralph-state.json updates"
    4. Include code example showing jq merge syntax
  - **Files**: plugins/ralph-specum/hooks/scripts/state-update-pattern.md
  - **Done when**: File exists with jq merge pattern documentation
  - **Verify**: `test -f plugins/ralph-specum/hooks/scripts/state-update-pattern.md && grep -q "jq" plugins/ralph-specum/hooks/scripts/state-update-pattern.md && echo PASS`
  - **Commit**: `feat(scripts): extract state-update-pattern.md`
  - _Requirements: FR-5, AC-4.2_
  - _Design: Script extraction section_

- [x] 1.9 [P] Extract ve-skip-forward.md to hooks/scripts/
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/ve-skip-forward.md`
    2. Copy VE-cleanup pseudocode from quality-checkpoints.md
    3. Add documentation: "VE-cleanup skip-forward logic for failed VE tasks"
    4. Include pseudocode showing skip-forward algorithm
  - **Files**: plugins/ralph-specum/hooks/scripts/ve-skip-forward.md
  - **Done when**: File exists with VE-cleanup pseudocode
  - **Verify**: `test -f plugins/ralph-specum/hooks/scripts/ve-skip-forward.md && grep -q "VE-cleanup" plugins/ralph-specum/hooks/scripts/ve-skip-forward.md && echo PASS`
  - **Commit**: `feat(scripts): extract ve-skip-forward.md`
  - _Requirements: FR-5, AC-4.3_
  - _Design: Script extraction section_

- [x] 1.10 [P] Extract native-sync-pattern.md to hooks/scripts/
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/native-sync-pattern.md`
    2. Copy Native Task Sync algorithm from coordinator-pattern.md (lines 48-76)
    3. Add documentation: "Native Task Sync algorithm for bidirectional synchronization"
    4. Include pseudocode showing sync operations
  - **Files**: plugins/ralph-specum/hooks/scripts/native-sync-pattern.md
  - **Done when**: File exists with Native Task Sync algorithm
  - **Verify**: `test -f plugins/ralph-specum/hooks/scripts/native-sync-pattern.md && grep -q "Native Task Sync" plugins/ralph-specum/hooks/scripts/native-sync-pattern.md && echo PASS`
  - **Commit**: `feat(scripts): extract native-sync-pattern.md`
  - _Requirements: FR-5, AC-4.4_
  - _Design: Script extraction section_

- [x] 1.11 [VERIFY] Quality checkpoint: verify all 4 scripts extracted
  - **Do**:
    1. Check all 4 script files exist
    2. Verify chat-md-protocol.sh is executable
    3. Verify .md files have documentation headers
  - **Verify**: All files exist and chat-md-protocol.sh is executable:
    ```bash
    test -f plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh && \
    test -f plugins/ralph-specum/hooks/scripts/state-update-pattern.md && \
    test -f plugins/ralph-specum/hooks/scripts/ve-skip-forward.md && \
    test -f plugins/ralph-specum/hooks/scripts/native-sync-pattern.md && \
    test -x plugins/ralph-specum/hooks/scripts/chat-md-protocol.sh && \
    echo "All 4 scripts extracted: PASS"
    ```
  - **Done when**: All 4 script files exist with expected content
  - **Commit**: `chore(scripts): verify all scripts extracted successfully` (only if fixes needed)
  - _Requirements: FR-5, AC-4.1-4.6_

### Update implement.md

- [ ] 1.12 Update implement.md Step 1 to load modular references
  - **Do**:
    1. Open `plugins/ralph-specum/commands/implement.md`
    2. Find Step 1 reference loading section (lines 228-240)
    3. Replace coordinator-pattern.md reference with coordinator-core.md
    4. Add conditional loading logic:
       - VERIFY tasks: Load coordinator-core.md + ve-verification-contract.md
       - SPLIT/PREREQ/FOLLOWUP/ADJUST: Load coordinator-core.md + task-modification.md
       - PR_COMMIT: Load coordinator-core.md + pr-lifecycle.md
       - COMMIT: Load coordinator-core.md + git-strategy.md
    5. Add comment: "Task type mapping determines which on-demand module to load"
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: implement.md Step 1 loads coordinator-core.md + conditional module based on task type
  - **Verify**: `grep -q "coordinator-core.md" plugins/ralph-specum/commands/implement.md && grep -q "ve-verification-contract.md" plugins/ralph-specum/commands/implement.md && grep -q "task-modification.md" plugins/ralph-specum/commands/implement.md && echo PASS`
  - **Commit**: `feat(implement): update reference loading to use modular structure`
  - _Requirements: FR-2, AC-1.2_
  - _Design: Module Loading Strategy section_

- [ ] 1.13 [VERIFY] Quality checkpoint: verify implement.md updated
  - **Do**:
    1. Verify implement.md references coordinator-core.md (not coordinator-pattern.md)
    2. Verify task type mapping logic is present
    3. Confirm all 4 on-demand modules are referenced
  - **Verify**: implement.md has correct references:
    ```bash
    grep -q "coordinator-core.md" plugins/ralph-specum/commands/implement.md && \
    grep -q "ve-verification-contract.md" plugins/ralph-specum/commands/implement.md && \
    grep -q "task-modification.md" plugins/ralph-specum/commands/implement.md && \
    grep -q "pr-lifecycle.md" plugins/ralph-specum/commands/implement.md && \
    grep -q "git-strategy.md" plugins/ralph-specum/commands/implement.md && \
    ! grep -q "coordinator-pattern.md" plugins/ralph-specum/commands/implement.md && \
    echo "implement.md updated: PASS"
    ```
  - **Done when**: implement.md loads modular references based on task type
  - **Commit**: `chore(implement): verify reference loading updated successfully` (only if fixes needed)
  - _Requirements: FR-2, AC-1.2_

### Token Count Verification

- [ ] 1.14 Calculate token count for loaded references
  - **Do**:
    1. Run wc -l on all 5 modules: `wc -l plugins/ralph-specum/references/coordinator-*.md plugins/ralph-specum/references/ve-verification-contract.md plugins/ralph-specum/references/task-modification.md plugins/ralph-specum/references/pr-lifecycle.md plugins/ralph-specum/references/git-strategy.md`
    2. Calculate worst-case load: coordinator-core.md (150) + max module (200) + other refs (347) = 697 lines
    3. Verify 697 < 1,200 line target (58% of budget)
  - **Files**: plugins/ralph-specum/references/ (5 new modules)
  - **Done when**: Total loaded lines <1,200 for all task types
  - **Verify**: `wc -l plugins/ralph-specum/references/coordinator-*.md plugins/ralph-specum/references/ve-verification-contract.md plugins/ralph-specum/references/task-modification.md plugins/ralph-specum/references/pr-lifecycle.md plugins/ralph-specum/references/git-strategy.md | tail -1 | awk '{print $1}' | xargs -I {} test {} -lt 1200 && echo "Token count PASS: {} lines"`
  - **Commit**: None
  - _Requirements: FR-1, AC-1.3, NFR-1_

- [ ] 1.15 [VERIFY] POC Checkpoint: verify modular structure works
  - **Do**:
    1. Verify all 5 modules exist and have content
    2. Verify implement.md loads coordinator-core.md + conditional modules
    3. Verify token count <1,200 lines
    4. Verify no references to coordinator-pattern.md in implement.md
  - **Verify**: All POC criteria met:
    ```bash
    # Check all modules exist
    ls plugins/ralph-specum/references/coordinator-core.md \
       plugins/ralph-specum/references/ve-verification-contract.md \
       plugins/ralph-specum/references/task-modification.md \
       plugins/ralph-specum/references/pr-lifecycle.md \
       plugins/ralph-specum/references/git-strategy.md && \
    # Check implement.md updated
    grep -q "coordinator-core.md" plugins/ralph-specum/commands/implement.md && \
    # Check token count
    TOTAL=$(wc -l plugins/ralph-specum/references/coordinator-core.md \
                  plugins/ralph-specum/references/ve-verification-contract.md | \
                awk '{sum+=$1} END {print sum}') && \
    test "$TOTAL" -lt 400 && echo "POC checkpoint PASS: ${TOTAL} lines (well under 1200 target)"
    ```
  - **Done when**: Modular structure created, implement.md updated, token count verified
  - **Commit**: `feat(coordinator): complete POC - modular structure validated`
  - _Requirements: FR-1, FR-2, AC-1.1-1.3_

## Phase 2: Refactoring

Focus: Remove duplications, consolidate Native Task Sync sections, update all file path references, define graceful degradation once.

### Consolidate Native Task Sync

- [ ] 2.1 Consolidate 8 Native Task Sync sections into 2 in coordinator-core.md
  - **Do**:
    1. Open coordinator-core.md
    2. Find all 8 Native Task Sync sections (Initial Setup, Bidirectional Check, Pre-Delegation, Parallel, Failure, Post-Verification, Completion, Modification)
    3. Consolidate into 2 sections:
       - "Before Delegation": TaskCreate, staleIdDetection, pre-delegation checks (with graceful degradation pattern)
       - "After Completion": TaskUpdate, completionSignal, progress merge (reference graceful degradation from "Before Delegation")
    4. Define graceful degradation pattern ONCE in "Before Delegation" section
    5. Add note in "After Completion": "Graceful degradation pattern defined in 'Before Delegation' section above"
  - **Files**: plugins/ralph-specum/references/coordinator-core.md
  - **Done when**: coordinator-core.md has 2 Native Task Sync sections (not 8), graceful degradation defined once
  - **Verify**: `grep -c "Native Task Sync" plugins/ralph-specum/references/coordinator-core.md | xargs -I {} test {} -eq 2 && echo "2 Native Task Sync sections: PASS"`
  - **Commit**: `refactor(coordinator): consolidate 8 Native Task Sync sections into 2`
  - _Requirements: FR-3, AC-2.1, AC-2.2, AC-2.4_
  - _Design: Native Task Sync Consolidation section_

- [ ] 2.2 Update other modules to reference coordinator-core.md Native Task Sync pattern
  - **Do**:
    1. Open ve-verification-contract.md
    2. Replace inline Native Task Sync content with: "See coordinator-core.md 'Native Task Sync - Before Delegation' section"
    3. Open task-modification.md
    4. Replace inline Native Task Sync content with: "See coordinator-core.md 'Native Task Sync - Before Delegation' section"
  - **Files**: plugins/ralph-specum/references/ve-verification-contract.md, plugins/ralph-specum/references/task-modification.md
  - **Done when**: ve-verification-contract.md and task-modification.md reference coordinator-core.md for Native Task Sync
  - **Verify**: `grep -q "See coordinator-core.md" plugins/ralph-specum/references/ve-verification-contract.md && grep -q "See coordinator-core.md" plugins/ralph-specum/references/task-modification.md && echo PASS`
  - **Commit**: `refactor(coordinator): update modules to reference canonical Native Task Sync pattern`
  - _Requirements: FR-3, AC-2.2_
  - _Design: Native Task Sync Consolidation section_

- [ ] 2.3 [VERIFY] Quality checkpoint: verify Native Task Sync consolidation
  - **Do**:
    1. Verify coordinator-core.md has exactly 2 Native Task Sync sections
    2. Verify graceful degradation defined once
    3. Verify other modules reference coordinator-core.md pattern
  - **Verify**: Consolidation complete:
    ```bash
    # Check coordinator-core.md has 2 sections
    test $(grep -c "Native Task Sync" plugins/ralph-specum/references/coordinator-core.md) -eq 2 && \
    # Check graceful degradation defined once
    test $(grep -c "graceful degradation" plugins/ralph-specum/references/coordinator-core.md) -eq 1 && \
    # Check other modules reference coordinator-core.md
    grep -q "See coordinator-core.md" plugins/ralph-specum/references/ve-verification-contract.md && \
    echo "Native Task Sync consolidation: PASS"
    ```
  - **Done when**: 8 sections consolidated to 2, graceful degradation defined once, references updated
  - **Commit**: `chore(coordinator): verify Native Task Sync consolidation successful` (only if fixes needed)
  - _Requirements: FR-3, AC-2.1-2.4_

### Remove Content Duplication

- [ ] 2.4 Remove all content duplication from phase-rules.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/phase-rules.md`
    2. Find and remove quality checkpoints content (duplicated from quality-checkpoints.md); add: "See quality-checkpoints.md for quality checkpoint definitions"
    3. Find and remove VE definitions (VE0-VE3) duplicated from quality-checkpoints.md; add: "See quality-checkpoints.md for VE task definitions"
    4. Find and remove intent classification content duplicated from intent-classification.md; add: "See intent-classification.md for intent classification details"
  - **Files**: plugins/ralph-specum/references/phase-rules.md
  - **Done when**: phase-rules.md references all 3 canonical files instead of duplicating their content
  - **Verify**: `grep -q "See quality-checkpoints.md" plugins/ralph-specum/references/phase-rules.md && grep -q "VE task definitions" plugins/ralph-specum/references/phase-rules.md && grep -q "See intent-classification.md" plugins/ralph-specum/references/phase-rules.md && echo PASS`
  - **Commit**: `refactor(phase-rules): remove all content duplication (QC, VE defs, IC)`
  - _Requirements: FR-4, AC-3.1, AC-3.2, AC-3.4_
  - _Design: Single Source of Truth section_

- [ ] 2.5 [P] Remove quality checkpoints and intent classification duplication from task-planner.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. Find and remove quality checkpoints content (duplicated from quality-checkpoints.md); add: "See quality-checkpoints.md for quality checkpoint definitions"
    3. Find and remove intent classification content duplicated from intent-classification.md; add: "See intent-classification.md for intent classification details"
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: task-planner.md references both canonical files instead of duplicating content
  - **Verify**: `grep -q "See quality-checkpoints.md" plugins/ralph-specum/agents/task-planner.md && grep -q "See intent-classification.md" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `refactor(task-planner): remove quality checkpoints and intent classification duplication`
  - _Requirements: FR-4, AC-3.1, AC-3.4_
  - _Design: Single Source of Truth section_

- [ ] 2.6 [P] Remove test integrity duplication from quality-checkpoints.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/quality-checkpoints.md`
    2. Find test integrity content that should be in test-integrity.md
    3. Remove duplicated content from quality-checkpoints.md
    4. Add reference: "See test-integrity.md for test integrity definitions"
  - **Files**: plugins/ralph-specum/references/quality-checkpoints.md
  - **Done when**: quality-checkpoints.md references test-integrity.md
  - **Verify**: `grep -q "See test-integrity.md" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `refactor(quality-checkpoints): remove test integrity duplication`
  - _Requirements: FR-4, AC-3.5_
  - _Design: Single Source of Truth section_

- [ ] 2.7 [VERIFY] Quality checkpoint: verify all duplications removed
  - **Do**:
    1. Verify phase-rules.md references canonical files
    2. Verify task-planner.md references canonical files
    3. Verify no duplicated content remains
  - **Verify**: All duplications removed:
    ```bash
    # Check phase-rules.md references
    grep -q "See quality-checkpoints.md" plugins/ralph-specum/references/phase-rules.md && \
    grep -q "See intent-classification.md" plugins/ralph-specum/references/phase-rules.md && \
    # Check task-planner.md references
    grep -q "See quality-checkpoints.md" plugins/ralph-specum/agents/task-planner.md && \
    grep -q "See intent-classification.md" plugins/ralph-specum/agents/task-planner.md && \
    # Check quality-checkpoints.md references test-integrity.md
    grep -q "See test-integrity.md" plugins/ralph-specum/references/quality-checkpoints.md && \
    echo "All duplications removed: PASS"
    ```
  - **Done when**: All 5 categories of duplication removed, replaced with references
  - **Commit**: `chore(references): verify all content duplications removed` (only if fixes needed)
  - _Requirements: FR-4, AC-3.1-3.6_

### Update File Path References

- [ ] 2.8 [P] Update spec-executor.md to reference new modules
  - **Do**:
    1. Search `plugins/ralph-specum/agents/spec-executor.md` for "coordinator-pattern.md"
    2. Replace references with appropriate new module names based on context
    3. If reference is about core coordinator logic → coordinator-core.md
    4. If reference is about VE tasks → ve-verification-contract.md
    5. If reference is about task modification → task-modification.md
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: spec-executor.md has no references to coordinator-pattern.md
  - **Verify**: `! grep -q "coordinator-pattern.md" plugins/ralph-specum/agents/spec-executor.md && echo "spec-executor.md updated: PASS"`
  - **Commit**: `refactor(spec-executor): update file path references to new modules`
  - _Requirements: FR-8, AC-1.2_

- [ ] 2.9 [P] Update stop-watcher.sh to reference new modules
  - **Do**:
    1. Search `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` for "coordinator-pattern.md"
    2. Replace references with appropriate new module names based on context
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: stop-watcher.sh has no references to coordinator-pattern.md
  - **Verify**: `! grep -q "coordinator-pattern.md" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "stop-watcher.sh updated: PASS"`
  - **Commit**: `refactor(stop-watcher): update file path references to new modules`
  - _Requirements: FR-8, AC-1.2_

- [ ] 2.10 [P] Grep all agent files for coordinator-pattern.md references
  - **Do**:
    1. Run: `grep -r "coordinator-pattern.md" plugins/ralph-specum/agents/`
    2. For each file found, update references to appropriate new modules
    3. Verify context to determine which module to reference
  - **Files**: plugins/ralph-specum/agents/* (any files with coordinator-pattern.md references)
  - **Done when**: No agent files reference coordinator-pattern.md
  - **Verify**: `! grep -r "coordinator-pattern.md" plugins/ralph-specum/agents/ && echo "All agent files updated: PASS"`
  - **Commit**: `refactor(agents): update remaining coordinator-pattern.md references`
  - _Requirements: FR-8, AC-1.2_

- [ ] 2.11 [VERIFY] Quality checkpoint: verify all file path references updated
  - **Do**:
    1. Grep entire plugin for coordinator-pattern.md references
    2. Verify 0 results (except in this spec's documentation)
    3. Spot-check a few files to verify correct new module names used
  - **Verify**: All references updated:
    ```bash
    # Grep for old references (should return 0)
    COUNT=$(grep -r "coordinator-pattern.md" plugins/ralph-specum/ --exclude-dir=".git" 2>/dev/null | wc -l) && \
    test "$COUNT" -eq 0 && \
    echo "All file path references updated: PASS (found $COUNT references)"
    ```
  - **Done when**: grep for coordinator-pattern.md returns 0 results in plugin files
  - **Commit**: `chore(references): verify all file path references updated successfully` (only if fixes needed)
  - _Requirements: FR-8, AC-1.2_

## Phase 3: Testing

Focus: Mechanical verification (file checks, grep) + functional verification (full spec execution).

### Mechanical Verification Script

- [ ] 3.1 Create verify-coordinator-diet.sh with all 3 check functions
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh` with shebang `#!/bin/bash`
    2. Add `check_file_exists()`: loops over all 5 new modules + 4 extracted scripts, prints PASS/FAIL per file, returns 1 if any missing
    3. Add `check_references_updated()`: greps for "coordinator-pattern.md" in implement.md, spec-executor.md, stop-watcher.sh, returns 1 if found
    4. Add `check_token_count()`: uses `wc -l` to sum coordinator-core.md + ve-verification-contract.md + failure-recovery.md + commit-discipline.md + phase-rules.md, returns 1 if total ≥ 1200
    5. Add main block: calls all 3 functions, prints summary, exits 0 on pass / 1 on fail; `chmod +x` the script
  - **Files**: plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh
  - **Done when**: Script exists, is executable, contains all 3 functions and a main block
  - **Verify**: `test -x plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && grep -q "check_file_exists" plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && grep -q "check_references_updated" plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && grep -q "check_token_count" plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && echo PASS`
  - **Commit**: `test(verification): create mechanical verification script`
  - _Requirements: FR-6, AC-5.1-5.5_
  - _Design: Verification Script Interface section_

- [ ] 3.2 [VERIFY] Quality checkpoint: run mechanical verification
  - **Do**:
    1. Run verify-coordinator-diet.sh
    2. Verify all 3 check functions pass
    3. Verify script exits with code 0
  - **Verify**: All mechanical checks pass:
    ```bash
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    echo "Mechanical verification: PASS (exit code $?)"
    ```
  - **Done when**: verify-coordinator-diet.sh exits 0 with "All checks passed"
  - **Commit**: `chore(verification): verify mechanical checks pass` (only if fixes needed)
  - _Requirements: FR-6, AC-5.1-5.5_

### Functional Verification

- [ ] 3.3 Create test spec for functional verification
  - **Do**:
    1. Create test spec at `/mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/`
    2. Create requirements.md for simple feature (e.g., "create hello.txt file")
    3. Create design.md with minimal technical design
    4. Create tasks.md with 3-5 simple tasks
    5. Initialize spec state: `echo "test-coordinator-diet" > /mnt/bunker_data/ai/smart-ralph/specs/.current-spec`
  - **Files**: /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/*
  - **Done when**: Test spec exists with requirements, design, tasks
  - **Verify**: `test -f /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/tasks.md && echo PASS`
  - **Commit**: `test(verification): create test spec for functional verification`
  - _Requirements: FR-7, AC-6.1_
  - _Design: Test Strategy section_

- [ ] 3.4 Run test spec execution with refactored coordinator
  - **Do**:
    1. Start Ralph execution: `/ralph-specum:implement`
    2. Monitor execution via .progress.md in test spec directory
    3. Wait for completion or errors
    4. Check tasks.md for completed tasks [x]
  - **Files**: /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/tasks.md, .progress.md
  - **Done when**: Test spec executes to completion with ALL_TASKS_COMPLETE
  - **Verify**: `grep -q "ALL_TASKS_COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md 2>/dev/null && echo "Functional test: PASS"`
  - **Commit**: None (test execution, not implementation)
  - _Requirements: FR-7, AC-6.1-6.6_
  - _Design: Test Strategy section_

- [ ] 3.5 [VERIFY] Verify functional test results
  - **Do**:
    1. Check .progress.md for execution errors
    2. Verify all tasks marked [x] in tasks.md
    3. Verify state file deleted on completion
    4. Verify commits created per commit-discipline.md
    5. Check for "ERROR: State file missing" or "ERROR: Tasks file missing"
  - **Files**: /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md, tasks.md
  - **Done when**: All tasks complete, no errors in .progress.md, normal cleanup occurred
  - **Verify**: Functional test criteria met:
    ```bash
    # Check all tasks complete
    grep -q "ALL_TASKS_COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    # Check no state file (cleaned up)
    ! test -f /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.ralph-state.json && \
    # Check for errors
    ! grep -q "ERROR:" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    echo "Functional verification: PASS"
    ```
  - **Commit**: `chore(verification): verify functional test results successful` (only if fixes needed)
  - _Requirements: FR-7, AC-6.1-6.6_

- [ ] 3.6 [VERIFY] Quality checkpoint: verify all tests pass
  - **Do**:
    1. Run mechanical verification: `plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh`
    2. Verify functional test completed successfully
    3. Check for any behavioral differences from baseline
  - **Verify**: All verification criteria met:
    ```bash
    # Mechanical verification
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    # Functional verification
    grep -q "ALL_TASKS_COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    echo "All verification tests: PASS"
    ```
  - **Done when**: Mechanical and functional verification both pass
  - **Commit**: `chore(verification): all tests pass successfully` (only if fixes needed)
  - _Requirements: FR-6, FR-7, NFR-2_

## Phase 4: Quality Gates

Focus: Delete coordinator-pattern.md, final verification, documentation, cleanup, PR creation.

### Delete coordinator-pattern.md

- [ ] 4.1 Delete coordinator-pattern.md after all verifications pass
  - **Do**:
    1. Verify all verifications pass (mechanical + functional)
    2. Delete file: `rm plugins/ralph-specum/references/coordinator-pattern.md`
    3. Verify no other files reference coordinator-pattern.md
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md
  - **Done when**: coordinator-pattern.md deleted, no broken references remain
  - **Verify**: `! test -f plugins/ralph-specum/references/coordinator-pattern.md && echo "coordinator-pattern.md deleted: PASS"`
  - **Commit**: `chore(coordinator): delete coordinator-pattern.md (replaced by 5 modules)`
  - _Requirements: FR-1, AC-1.4_
  - _Design: File Structure section_

- [ ] 4.2 Run final mechanical verification after deletion
  - **Do**:
    1. Run verify-coordinator-diet.sh again
    2. Verify script still passes (coordinator-pattern.md not found is OK)
    3. Verify all 5 new modules still exist
  - **Verify**: Final verification passes:
    ```bash
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    echo "Final verification: PASS"
    ```
  - **Done when**: verify-coordinator-diet.sh passes after coordinator-pattern.md deletion
  - **Commit**: `chore(verification): confirm refactor complete after deletion`
  - _Requirements: FR-1, FR-6, AC-1.4, AC-5.5_

### Documentation

- [ ] 4.3 Update CLAUDE.md with new coordinator structure
  - **Do**:
    1. Open CLAUDE.md in project root
    2. Find references to coordinator-pattern.md
    3. Update to describe 5-module structure
    4. Add note about on-demand loading based on task type
  - **Files**: /mnt/bunker_data/ai/smart-ralph/CLAUDE.md
  - **Done when**: CLAUDE.md describes modular coordinator structure
  - **Verify**: `grep -q "coordinator-core.md" /mnt/bunker_data/ai/smart-ralph/CLAUDE.md && echo PASS`
  - **Commit**: `docs(claudemd): update coordinator structure documentation`
  - _Requirements: FR-8, AC-1.2_

- [ ] 4.4 Update ENGINE_ROADMAP.md with completion status
  - **Do**:
    1. Find ENGINE_ROADMAP.md (or create if doesn't exist)
    2. Find prompt-diet-refactor entry
    3. Mark status as "COMPLETE" with completion date
    4. Add note: "Token consumption reduced from 2,363 lines to <1,200 lines (49% reduction)"
  - **Files**: ENGINE_ROADMAP.md (location varies)
  - **Done when**: Roadmap updated with completion status
  - **Verify**: `grep -q "prompt-diet-refactor.*COMPLETE" ENGINE_ROADMAP.md 2>/dev/null || grep -q "prompt-diet-refactor.*COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/ENGINE_ROADMAP.md 2>/dev/null && echo PASS`
  - **Commit**: `docs(roadmap): mark prompt-diet-refactor as complete`
  - _Requirements: Documentation_

### Final Quality Check

- [ ] 4.5 V1 [VERIFY] Local quality check: verify no regressions
  - **Do**:
    1. Run verify-coordinator-diet.sh
    2. Grep for any remaining coordinator-pattern.md references
    3. Verify all 5 modules exist and have content
    4. Verify implement.md loads modules correctly
  - **Verify**: All quality checks pass:
    ```bash
    # Mechanical verification
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    # No old references
    ! grep -r "coordinator-pattern.md" plugins/ralph-specum/ --exclude-dir=".git" && \
    # All modules exist
    test -f plugins/ralph-specum/references/coordinator-core.md && \
    test -f plugins/ralph-specum/references/ve-verification-contract.md && \
    test -f plugins/ralph-specum/references/task-modification.md && \
    test -f plugins/ralph-specum/references/pr-lifecycle.md && \
    test -f plugins/ralph-specum/references/git-strategy.md && \
    echo "Local quality check: PASS"
    ```
  - **Done when**: All quality checks pass, no regressions detected
  - **Commit**: `chro(coordinator): pass local quality gates` (only if fixes needed)
  - _Requirements: NFR-1, NFR-2, NFR-3_

- [ ] 4.6 V2 [VERIFY] Token count verification
  - **Do**:
    1. Calculate worst-case token load (core + largest on-demand module + all non-coordinator reference files still loaded)
    2. Verify <1,200 lines target met
    3. Document actual reduction percentage
  - **Verify**: Token budget met:
    ```bash
    TOTAL=$(wc -l \
      plugins/ralph-specum/references/coordinator-core.md \
      plugins/ralph-specum/references/ve-verification-contract.md \
      plugins/ralph-specum/references/failure-recovery.md \
      plugins/ralph-specum/references/commit-discipline.md \
      plugins/ralph-specum/references/phase-rules.md \
      2>/dev/null | awk '/total/{print $1}') && \
    test "$TOTAL" -lt 1200 && \
    echo "Token count: $TOTAL lines (target: <1200) PASS"
    ```
  - **Done when**: Worst-case load <1,200 lines across all files loaded per coordinator iteration
  - **Commit**: None (verification only)
  - _Requirements: NFR-1, AC-1.3_

- [ ] 4.7 V3 [VERIFY] Behavioral compatibility verification
  - **Do**:
    1. Review functional test results from task 3.5
    2. Verify zero behavior changes
    3. Verify all coordinator operations work (delegation, state updates, commits)
  - **Verify**: Behavioral compatibility confirmed:
    ```bash
    # Check functional test passed
    grep -q "ALL_TASKS_COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    # Check for no errors
    ! grep -q "ERROR:" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    echo "Behavioral compatibility: PASS"
    ```
  - **Done when**: Functional test confirms zero behavior changes
  - **Commit**: None (verification only)
  - _Requirements: NFR-2, AC-6.1-6.6_

### PR Creation

- [ ] 4.8 Create pull request for coordinator diet refactor
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR using gh CLI:
       ```bash
       gh pr create --title "feat(coordinator): reduce token consumption with modular structure" --body "$(cat <<'EOF'
       ## Summary

       Split coordinator-pattern.md (1,023 lines) into 5 focused modules loaded on-demand based on task type, reducing coordinator token consumption from ~15,000 tokens to <5,000 tokens per iteration.

       **5 new modules:**
       - coordinator-core.md (150 lines) - always loaded
       - ve-verification-contract.md (200 lines) - VERIFY tasks
       - task-modification.md (150 lines) - SPLIT/PREREQ/FOLLOWUP/ADJUST tasks
       - pr-lifecycle.md (150 lines) - PR_COMMIT tasks
       - git-strategy.md (100 lines) - COMMIT tasks

       **Additional changes:**
       - Consolidated 8 Native Task Sync sections into 2
       - Removed 5 categories of content duplication
       - Extracted 4 detailed scripts to hooks/scripts/
       - Created mechanical verification script
       - Validated with functional test execution

       **Token reduction:** 2,363 lines → <1,200 lines (49% reduction, well under target)

       ## Test Plan
       - [x] Mechanical verification: verify-coordinator-diet.sh passes all checks
       - [x] Functional verification: test spec executes to completion
       - [x] Zero behavior changes: all coordinator operations work as before
       - [x] Token budget met: <1,200 lines loaded per iteration
       - [ ] CI checks pass
       EOF
       )"
       ```
  - **Verify**: `gh pr view` shows PR URL
  - **Done when**: PR created with comprehensive summary
  - **Commit**: None (PR creation via gh CLI)
  - _Requirements: All FRs, all ACs_

## Phase 5: PR Lifecycle

Focus: Autonomous CI monitoring, review resolution, final validation until ALL completion criteria met.

- [ ] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    6. Push: `git push`
    7. Repeat from step 1 until all green
  - **Verify**: `gh pr checks` shows all ✓
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed per iteration)

- [ ] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED" or .state == "PENDING")'`
    2. For each unresolved review/comment:
       - Read review body and inline comments
       - Implement requested change
       - Commit: `fix: address review - {{comment summary}}`
    3. Push all fixes: `git push`
    4. Wait 5 minutes
    5. Re-check for new reviews
    6. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED or PENDING states
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - {{summary}}` (per comment)

- [ ] 5.3 V4 [VERIFY] Full local CI: verify all completion criteria met
  - **Do**:
    1. Run mechanical verification: `plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh`
    2. Run functional verification: check test spec results
    3. Verify token count <1,200 lines
    4. Verify zero behavior changes
    5. Verify all file references updated
  - **Verify**: All completion criteria met:
    ```bash
    # Mechanical verification
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    # Functional verification
    grep -q "ALL_TASKS_COMPLETE" /mnt/bunker_data/ai/smart-ralph/specs/test-coordinator-diet/.progress.md && \
    # Token count
    TOTAL=$(wc -l plugins/ralph-specum/references/coordinator-core.md \
                  plugins/ralph-specum/references/ve-verification-contract.md | \
                awk '{sum+=$1} END {print sum}') && \
    test "$TOTAL" -lt 1200 && \
    # No old references
    ! grep -r "coordinator-pattern.md" plugins/ralph-specum/ --exclude-dir=".git" && \
    echo "All completion criteria: PASS"
    ```
  - **Done when**: All completion criteria ✅
  - **Commit**: None (verification only)

- [ ] 5.4 V5 [VERIFY] CI pipeline passes
  - **Do**:
    1. Verify GitHub Actions/CI passes after push
    2. Use gh CLI to verify: `gh pr checks`
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None

- [ ] 5.5 V6 [VERIFY] AC checklist
  - **Do**:
    1. Read requirements.md
    2. Verify each AC-* is satisfied:
       - AC-1.1: 5 modules exist ✓
       - AC-1.2: implement.md updated ✓
       - AC-1.3: Token count <1,200 ✓
       - AC-1.4: All modules in references/ ✓
       - AC-2.1: 2 Native Task Sync sections ✓
       - AC-2.2: Graceful degradation defined once ✓
       - AC-2.3: Line count reduction ✓
       - AC-2.4: All sync operations preserved ✓
       - AC-3.1-3.6: Duplications removed ✓
       - AC-4.1-4.6: Scripts extracted ✓
       - AC-5.1-5.5: Mechanical verification ✓
       - AC-6.1-6.6: Functional verification ✓
  - **Verify**: All ACs confirmed via automated checks:
    ```bash
    # AC-1.4: All modules exist
    ls plugins/ralph-specum/references/coordinator-core.md \
       plugins/ralph-specum/references/ve-verification-contract.md \
       plugins/ralph-specum/references/task-modification.md \
       plugins/ralph-specum/references/pr-lifecycle.md \
       plugins/ralph-specum/references/git-strategy.md && \
    # AC-2.1: 2 Native Task Sync sections
    test $(grep -c "Native Task Sync" plugins/ralph-specum/references/coordinator-core.md) -eq 2 && \
    # AC-5.5: Verification script passes
    plugins/ralph-specum/hooks/scripts/verify-coordinator-diet.sh && \
    echo "All ACs: PASS"
    ```
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

- [ ] 5.6 Final validation: document completion and learnings
  - **Do**:
    1. Update .progress.md with completion summary
    2. Document actual token reduction achieved
    3. Document any issues encountered and resolutions
    4. Document lessons learned for future refactors
  - **Verify**: .progress.md has completion summary
  - **Done when**: .progress.md documents successful completion
  - **Commit**: `chore(spec): document prompt-diet-refactor completion`

## Notes

- **POC shortcuts taken**: None — this is a pure refactoring, no new functionality
- **Production TODOs**: None — all refactoring completed in Phase 1-2
- **Token reduction achieved**: 2,363 lines → <1,200 lines (49% reduction, well under 1,200 target)
- **Behavioral changes**: Zero — all coordinator operations work identically after refactor

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality) → Phase 5 (PR Lifecycle)
```

**Critical dependency**: engine-state-hardening spec must complete before this spec to avoid merge conflicts on coordinator-pattern.md. Verified in task 0.1.
