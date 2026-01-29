---
spec: add-walk-through-of
phase: tasks
total_tasks: 14
created: 2026-01-29
generated: auto
---

# Tasks: Phase Walkthrough

## Overview

Total tasks: 14
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Add walkthrough to one agent
2. Phase 2: Refactoring - Apply pattern to all agents
3. Phase 3: Testing - Validate walkthroughs generated correctly
4. Phase 4: Quality Gates - Local checks and PR creation
5. Phase 5: PR Lifecycle - CI monitoring and review

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: All existing agent behavior preserved
- Modular & Reusable: Walkthrough pattern consistent across agents
- Real-World Validation: Walkthrough visible in .progress.md after phase run
- CI Green: All CI checks passing
- PR Ready: Pull request created, reviewed, approved

## Phase 1: Make It Work (POC)

Focus: Add walkthrough generation to research-analyst as proof of concept.

- [x] 1.1 Update progress.md template with walkthrough section
  - **Do**: Add "## Phase Walkthrough" section template to progress.md
    1. Read current template
    2. Add section after "## Learnings" with placeholder format
    3. Include table header and summary line format
  - **Files**: `plugins/ralph-specum/templates/progress.md`
  - **Done when**: Template has Phase Walkthrough section with table format
  - **Verify**: `grep -q "Phase Walkthrough" plugins/ralph-specum/templates/progress.md`
  - **Commit**: `feat(walkthrough): add phase walkthrough section to progress template`
  - _Requirements: FR-4, AC-4.1_
  - _Design: progress.md template_

- [x] 1.2 Add walkthrough generation to research-analyst
  - **Do**: Add "## Generate Phase Walkthrough" section to research-analyst.md
    1. Add mandatory block after "Append Learnings" section
    2. Include git diff commands for change detection
    3. Include markdown table formatting instructions
    4. Include append to .progress.md instructions
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: Agent has walkthrough generation section with git commands and format
  - **Verify**: `grep -q "Phase Walkthrough" plugins/ralph-specum/agents/research-analyst.md && grep -q "git diff" plugins/ralph-specum/agents/research-analyst.md`
  - **Commit**: `feat(walkthrough): add walkthrough generation to research-analyst`
  - _Requirements: FR-1, FR-2, FR-3, AC-1.1, AC-2.1-2.4_
  - _Design: Walkthrough Generator_

- [ ] 1.3 [VERIFY] Quality checkpoint: POC agent updated
  - **Do**: Verify research-analyst has walkthrough section with correct format
  - **Verify**: Run these commands, ALL must exit 0:
    ```bash
    grep -q "## Generate Phase Walkthrough" plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "git diff" plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "<mandatory>" plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "\.progress\.md" plugins/ralph-specum/agents/research-analyst.md || exit 1
    ```
  - **Done when**: All 4 checks pass
  - **Commit**: `chore(walkthrough): pass quality checkpoint` (only if fixes needed)

## Phase 2: Refactoring

Apply walkthrough pattern to remaining agents.

- [ ] 2.1 Add walkthrough generation to product-manager
  - **Do**: Copy walkthrough section from research-analyst, adapt for requirements phase
    1. Add "## Generate Phase Walkthrough" section
    2. Update phase name reference
    3. Keep same git diff and format logic
  - **Files**: `plugins/ralph-specum/agents/product-manager.md`
  - **Done when**: Agent has walkthrough generation section
  - **Verify**: `grep -q "Phase Walkthrough" plugins/ralph-specum/agents/product-manager.md`
  - **Commit**: `feat(walkthrough): add walkthrough generation to product-manager`
  - _Requirements: FR-1, AC-1.2_
  - _Design: Walkthrough Generator_

- [ ] 2.2 Add walkthrough generation to architect-reviewer
  - **Do**: Copy walkthrough section, adapt for design phase
    1. Add "## Generate Phase Walkthrough" section
    2. Update phase name reference
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Agent has walkthrough generation section
  - **Verify**: `grep -q "Phase Walkthrough" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `feat(walkthrough): add walkthrough generation to architect-reviewer`
  - _Requirements: FR-1, AC-1.3_
  - _Design: Walkthrough Generator_

- [ ] 2.3 Add walkthrough generation to task-planner
  - **Do**: Copy walkthrough section, adapt for tasks phase
    1. Add "## Generate Phase Walkthrough" section
    2. Update phase name reference
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Agent has walkthrough generation section
  - **Verify**: `grep -q "Phase Walkthrough" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `feat(walkthrough): add walkthrough generation to task-planner`
  - _Requirements: FR-1, AC-1.4_
  - _Design: Walkthrough Generator_

- [ ] 2.4 [VERIFY] Quality checkpoint: all agents updated
  - **Do**: Verify all 4 agents have walkthrough sections
  - **Verify**: Run these commands, ALL must exit 0:
    ```bash
    grep -q "Phase Walkthrough" plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "Phase Walkthrough" plugins/ralph-specum/agents/product-manager.md || exit 1
    grep -q "Phase Walkthrough" plugins/ralph-specum/agents/architect-reviewer.md || exit 1
    grep -q "Phase Walkthrough" plugins/ralph-specum/agents/task-planner.md || exit 1
    ```
  - **Done when**: All 4 agents have walkthrough sections
  - **Commit**: `chore(walkthrough): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Validate walkthrough functionality via file inspection.

- [ ] 3.1 Validate walkthrough format consistency
  - **Do**: Check all agents use same walkthrough format
    1. Verify all agents have git diff command
    2. Verify all agents have table format specification
    3. Verify all agents reference .progress.md
  - **Files**: (read-only validation)
  - **Done when**: Format consistent across all agents
  - **Verify**: Run these commands:
    ```bash
    for agent in research-analyst product-manager architect-reviewer task-planner; do
      grep -q "git diff" plugins/ralph-specum/agents/${agent}.md || { echo "FAIL: $agent missing git diff"; exit 1; }
      grep -q "\.progress\.md" plugins/ralph-specum/agents/${agent}.md || { echo "FAIL: $agent missing progress.md ref"; exit 1; }
    done
    echo "All agents have consistent walkthrough format"
    ```
  - **Commit**: `test(walkthrough): validate format consistency` (if fixes needed)
  - _Requirements: AC-2.1, AC-2.2_

- [ ] 3.2 [VERIFY] Quality checkpoint: testing complete
  - **Do**: Final validation of all walkthrough implementations
  - **Verify**: All agents pass format validation from 3.1
  - **Done when**: All format checks pass
  - **Commit**: `chore(walkthrough): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Verify all modified files have correct content
    1. Check progress template updated
    2. Check all 4 agents have walkthrough sections
    3. Verify no syntax errors in markdown
  - **Verify**: Run all validation commands:
    ```bash
    grep -q "Phase Walkthrough" plugins/ralph-specum/templates/progress.md || exit 1
    for agent in research-analyst product-manager architect-reviewer task-planner; do
      grep -q "Phase Walkthrough" plugins/ralph-specum/agents/${agent}.md || exit 1
    done
    echo "All files validated"
    ```
  - **Done when**: All checks pass
  - **Commit**: `fix(walkthrough): address any issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat(walkthrough): add phase walkthrough summaries" --body "Adds walkthrough generation to spec agents per spec add-walk-through-of"`
  - **Verify**: `gh pr checks --watch` shows all checks passing
  - **Done when**: PR created, CI green
  - **If CI fails**: Read `gh pr checks`, fix issues, push fixes

## Phase 5: PR Lifecycle (Continuous Validation)

- [ ] 5.1 Create pull request
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR with summary
  - **Verify**: `gh pr view` shows PR URL
  - **Done when**: PR created and URL returned
  - **Commit**: None

- [ ] 5.2 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs, fix, push
    4. Repeat until all green
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed)

- [ ] 5.3 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews`
    2. Implement requested changes
    3. Push fixes
  - **Verify**: No unresolved reviews
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - <summary>` (per comment)

- [ ] 5.4 Final validation
  - **Do**: Verify ALL completion criteria met:
    1. All agents have walkthrough sections
    2. Template updated
    3. CI green
    4. No review comments pending
  - **Verify**: All checks pass
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: None - straightforward pattern replication
- **Production TODOs**: None - feature complete after this spec
- **Files modified**:
  1. `plugins/ralph-specum/templates/progress.md` - Add walkthrough section
  2. `plugins/ralph-specum/agents/research-analyst.md` - Add walkthrough generation
  3. `plugins/ralph-specum/agents/product-manager.md` - Add walkthrough generation
  4. `plugins/ralph-specum/agents/architect-reviewer.md` - Add walkthrough generation
  5. `plugins/ralph-specum/agents/task-planner.md` - Add walkthrough generation

## Dependencies

```
Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality) -> Phase 5 (PR Lifecycle)
```
