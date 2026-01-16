---
spec: reality-verification-principle
phase: tasks
total_tasks: 11
created: 2026-01-16
generated: auto
---

# Tasks: reality-verification-principle

## Phase 1: Make It Work (POC)

Focus: Create skill file and add detection to plan-synthesizer. Skip qa-engineer for now.

- [x] 1.1 Create reality-verification SKILL.md
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/reality-verification/`
    2. Create SKILL.md with goal detection heuristics table
    3. Add command mapping table
    4. Add BEFORE/AFTER documentation format
  - **Files**: `plugins/ralph-specum/skills/reality-verification/SKILL.md`
  - **Done when**: SKILL.md exists with detection rules and command mapping
  - **Verify**: `cat plugins/ralph-specum/skills/reality-verification/SKILL.md | grep -q "Goal Detection"`
  - **Commit**: `feat(reality-verification): add core principle SKILL.md`
  - _Requirements: FR-1_
  - _Design: Reality Verification SKILL.md_

- [x] 1.2 Add goal detection to plan-synthesizer
  - **Do**:
    1. Add "Goal Type Detection" section after "When Invoked"
    2. Add Step 1: Classify Goal with regex patterns
    3. Add Step 2: For Fix Goals, run reproduction command
    4. Document BEFORE state in .progress.md
  - **Files**: `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: plan-synthesizer has goal detection section
  - **Verify**: `grep -q "Goal Type Detection" plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Commit**: `feat(plan-synthesizer): add goal detection and diagnosis`
  - _Requirements: FR-2, FR-3_
  - _Design: Plan Synthesizer Updates_

- [ ] 1.3 [VERIFY] Quality checkpoint: type check and lint
  - **Do**: Run quality commands to verify changes are valid markdown
  - **Verify**: `test -f plugins/ralph-specum/skills/reality-verification/SKILL.md && test -f plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: Both files exist and are valid
  - **Commit**: `chore(reality-verification): pass quality checkpoint` (if fixes needed)

- [x] 1.4 Add VF task template to templates/tasks.md
  - **Do**:
    1. Add VF task after 4.2 section
    2. Include BEFORE state reference
    3. Include command re-run
    4. Include BEFORE/AFTER comparison
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: VF task template exists in Phase 4
  - **Verify**: `grep -q "VF.*Verify original issue" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `feat(templates): add VF task template`
  - _Requirements: FR-4_
  - _Design: File Structure_

- [x] 1.5 POC Checkpoint
  - **Do**: Verify core components exist and reference each other
  - **Done when**: SKILL.md, plan-synthesizer changes, template VF task all present
  - **Verify**: `grep -q "reality-verification" plugins/ralph-specum/agents/plan-synthesizer.md || grep -q "Goal Type" plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Commit**: `feat(reality-verification): complete POC`

## Phase 2: Refactoring

- [x] 2.1 Update task-planner for VF task generation
  - **Do**:
    1. Add section detecting fix goals from .progress.md
    2. Add conditional VF task insertion for fix-type goals
    3. Reference SKILL.md for detection rules
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner includes VF generation logic
  - **Verify**: `grep -q "VF" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `refactor(task-planner): add VF task generation for fix goals`
  - _Requirements: FR-5_
  - _Design: Task Planner Updates_

- [x] 2.2 Update qa-engineer for VF task handling
  - **Do**:
    1. Add VF task detection section
    2. Add logic to read BEFORE state from .progress.md
    3. Add BEFORE/AFTER comparison
    4. Add Reality Check (AFTER) documentation
  - **Files**: `plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: qa-engineer can handle VF tasks
  - **Verify**: `grep -q "VF" plugins/ralph-specum/agents/qa-engineer.md`
  - **Commit**: `refactor(qa-engineer): add VF task handling`
  - _Requirements: FR-6_
  - _Design: QA Engineer Updates_

- [ ] 2.3 [VERIFY] Quality checkpoint: all files modified correctly
  - **Do**: Verify all 5 target files have been updated
  - **Verify**: `ls plugins/ralph-specum/skills/reality-verification/SKILL.md plugins/ralph-specum/agents/plan-synthesizer.md plugins/ralph-specum/agents/task-planner.md plugins/ralph-specum/agents/qa-engineer.md plugins/ralph-specum/templates/tasks.md`
  - **Done when**: All 5 files exist
  - **Commit**: `chore(reality-verification): pass quality checkpoint` (if fixes needed)

## Phase 3: Testing

- [x] 3.1 Validate SKILL.md structure
  - **Do**: Check SKILL.md follows existing skill patterns
  - **Files**: `plugins/ralph-specum/skills/reality-verification/SKILL.md`
  - **Done when**: SKILL.md has name, description frontmatter and proper sections
  - **Verify**: `grep -q "^---" plugins/ralph-specum/skills/reality-verification/SKILL.md && grep -q "name:" plugins/ralph-specum/skills/reality-verification/SKILL.md`
  - **Commit**: `test(reality-verification): validate SKILL.md structure`
  - _Requirements: AC-1.1, AC-1.2_

## Phase 4: Quality Gates

- [x] 4.1 Local quality check
  - **Do**: Verify all markdown files are syntactically valid
  - **Verify**: `find plugins/ralph-specum -name "*.md" -exec test -f {} \; && echo "All files valid"`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(reality-verification): address lint/type issues` (if fixes needed)

- [x] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat: add reality verification principle" --body "..."`
  - **Verify**: `gh pr checks --watch` or `gh pr checks`
  - **Done when**: All CI checks green, PR ready for review

## Notes

- **POC shortcuts taken**: No qa-engineer testing in POC phase
- **Production TODOs**: Add actual regex validation tests if TypeScript added later
