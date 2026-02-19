---
spec: karpathy-skills-rules
phase: tasks
total_tasks: 12
created: 2026-02-19
generated: auto
---

# Tasks: karpathy-skills-rules

## Phase 1: Make It Work (POC)

Focus: Add Karpathy rules to all target files. Validate content reads correctly.

- [x] 1.1 Add Karpathy rules section to CLAUDE.md
  - **Do**:
    1. Open `CLAUDE.md`
    2. Insert new `## Karpathy Coding Rules` section after the `## ⛔ CRITICAL SAFETY RULES` section (after line 10) and before `## Overview` (line 12)
    3. Use the CLAUDE.md Section Template from design.md verbatim
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md contains all 4 Karpathy rules between Safety Rules and Overview sections
  - **Verify**: `grep -c "Karpathy" CLAUDE.md` returns >= 1 && `grep -c "Surgical Changes" CLAUDE.md` returns >= 1 && `grep -c "Simplicity First" CLAUDE.md` returns >= 1 && `grep -c "Goal-Driven Execution" CLAUDE.md` returns >= 1
  - **Commit**: `docs(claude): add Karpathy coding rules to CLAUDE.md`
  - _Requirements: FR-1, AC-1.1, AC-1.2, AC-1.3_
  - _Design: CLAUDE.md Section_

- [x] 1.2 Add Karpathy rules to spec-executor agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/spec-executor.md`
    2. Insert `## Karpathy Rules` section before the `## Communication Style` section (before line 361)
    3. Use the spec-executor template from design.md (Surgical Changes + Simplicity First)
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor.md contains Karpathy Rules section with Surgical Changes and Simplicity First
  - **Verify**: `grep -c "Karpathy Rules" plugins/ralph-specum/agents/spec-executor.md` returns >= 1 && `grep "Surgical Changes" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `docs(spec-executor): add Karpathy rules (surgical + simplicity)`
  - _Requirements: FR-2, AC-2.1_
  - _Design: spec-executor template_

- [x] 1.3 Add Karpathy rules to task-planner agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. Insert `## Karpathy Rules` section before the `## Communication Style` section (before line 477)
    3. Use the task-planner template from design.md (Goal-Driven Execution)
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains Karpathy Rules section with Goal-Driven Execution
  - **Verify**: `grep -c "Karpathy Rules" plugins/ralph-specum/agents/task-planner.md` returns >= 1 && `grep "Goal-Driven Execution" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `docs(task-planner): add Karpathy rules (goal-driven)`
  - _Requirements: FR-3, AC-2.2_
  - _Design: task-planner template_

- [x] 1.4 Add Karpathy rules to architect-reviewer agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/architect-reviewer.md`
    2. Insert `## Karpathy Rules` section before the `## Communication Style` section (before line 229)
    3. Use the architect-reviewer template from design.md (Simplicity First)
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: architect-reviewer.md contains Karpathy Rules section with Simplicity First
  - **Verify**: `grep -c "Karpathy Rules" plugins/ralph-specum/agents/architect-reviewer.md` returns >= 1 && `grep "Simplicity First" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `docs(architect): add Karpathy rules (simplicity first)`
  - _Requirements: FR-4, AC-2.3_
  - _Design: architect-reviewer template_

- [x] 1.5 Add Karpathy rules to product-manager, research-analyst, plan-synthesizer agents
  - **Do**:
    1. Open `plugins/ralph-specum/agents/product-manager.md` -- insert `## Karpathy Rules` section before `## Communication Style` (before line 153). Use product-manager template (Think Before Coding).
    2. Open `plugins/ralph-specum/agents/research-analyst.md` -- insert `## Karpathy Rules` section before `## Communication Style` (before line 279). Use research-analyst template (Think reference).
    3. Open `plugins/ralph-specum/agents/plan-synthesizer.md` -- insert `## Karpathy Rules` section before `## Communication Style` (before line 542). Use plan-synthesizer template (all 4 condensed).
  - **Files**: `plugins/ralph-specum/agents/product-manager.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: All 3 agents contain Karpathy Rules sections with their tailored subsets
  - **Verify**: `grep -c "Karpathy Rules" plugins/ralph-specum/agents/product-manager.md` returns >= 1 && `grep -c "Karpathy Rules" plugins/ralph-specum/agents/research-analyst.md` returns >= 1 && `grep -c "Karpathy Rules" plugins/ralph-specum/agents/plan-synthesizer.md` returns >= 1
  - **Commit**: `docs(agents): add Karpathy rules to PM, researcher, synthesizer`
  - _Requirements: FR-5, FR-6, FR-7, AC-2.4, AC-2.5, AC-2.6_
  - _Design: Per-agent templates_

- [x] 1.6 Update communication-style and delegation-principle skills
  - **Do**:
    1. Open `plugins/ralph-specum/skills/communication-style/SKILL.md` -- add `## Karpathy Alignment` subsection at end with note that Simplicity First complements the existing conciseness rules
    2. Open `plugins/ralph-specum/skills/delegation-principle/SKILL.md` -- add `## Karpathy Alignment` subsection at end noting Surgical Changes aligns with coordinator-not-implementer principle
  - **Files**: `plugins/ralph-specum/skills/communication-style/SKILL.md`, `plugins/ralph-specum/skills/delegation-principle/SKILL.md`
  - **Done when**: Both skills reference Karpathy rules
  - **Verify**: `grep -c "Karpathy" plugins/ralph-specum/skills/communication-style/SKILL.md` returns >= 1 && `grep -c "Karpathy" plugins/ralph-specum/skills/delegation-principle/SKILL.md` returns >= 1
  - **Commit**: `docs(skills): add Karpathy alignment to communication-style and delegation-principle`
  - _Requirements: FR-8, FR-9, AC-3.1, AC-3.2_
  - _Design: Skill Updates_

- [x] 1.7 Bump plugin version to 3.6.0
  - **Do**:
    1. Open `plugins/ralph-specum/.claude-plugin/plugin.json` -- change `"version": "3.5.1"` to `"version": "3.6.0"`
    2. Open `.claude-plugin/marketplace.json` -- change `"version": "3.5.1"` to `"version": "3.6.0"` for the ralph-specum entry
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 3.6.0
  - **Verify**: `grep '"version": "3.6.0"' plugins/ralph-specum/.claude-plugin/plugin.json` && `grep '"version": "3.6.0"' .claude-plugin/marketplace.json`
  - **Commit**: `chore(ralph-specum): bump version to 3.6.0`
  - _Requirements: FR-10, AC-4.1, AC-4.2_
  - _Design: Version bump_

- [x] 1.8 POC Checkpoint
  - **Do**: Verify all files were updated correctly by spot-checking key content
  - **Done when**: All 11 files contain their expected Karpathy content
  - **Verify**: `grep -l "Karpathy" CLAUDE.md plugins/ralph-specum/agents/*.md plugins/ralph-specum/skills/*/SKILL.md | wc -l` returns 9 (CLAUDE.md + 6 agents + 2 skills)
  - **Commit**: `feat(karpathy): complete POC - all rules integrated`

## Phase 2: Refactoring

- [x] 2.1 Review consistency across all Karpathy sections
  - **Do**:
    1. Read all added Karpathy sections across the 9 files
    2. Ensure consistent formatting: all use `<mandatory>` tags, all use bullet format, all bold rule names
    3. Ensure no duplication with existing content in each file
    4. Fix any inconsistencies found
  - **Files**: All 9 modified files (CLAUDE.md, 6 agents, 2 skills)
  - **Done when**: All sections follow identical formatting patterns and no duplication exists
  - **Verify**: `grep -c "<mandatory>" plugins/ralph-specum/agents/spec-executor.md` shows expected count && `grep -c "<mandatory>" plugins/ralph-specum/agents/task-planner.md` shows expected count
  - **Commit**: `refactor(karpathy): normalize formatting across all rule sections`

## Phase 3: Testing

- [x] 3.1 Validate markdown structure of all modified files
  - **Do**:
    1. Read each modified file fully
    2. Verify no broken markdown (unclosed code blocks, malformed headers, broken tables)
    3. Verify frontmatter is intact for agent files (YAML between `---` markers)
    4. Verify no accidental content deletion (compare section count before/after)
  - **Files**: All 11 modified files
  - **Done when**: All files parse as valid markdown with intact structure
  - **Verify**: For each agent file: `head -5 plugins/ralph-specum/agents/spec-executor.md | grep "^---"` confirms frontmatter intact. Repeat for all agents.
  - **Commit**: `test(karpathy): validate markdown structure` (only if fixes needed)

## Phase 4: Quality Gates

- [x] 4.1 Final content review
  - **Do**: Read all modified files one final time. Confirm:
    1. CLAUDE.md has all 4 rules
    2. Each agent has its tailored subset
    3. Skills have Karpathy Alignment sections
    4. Version is 3.6.0 in both JSON files
    5. No existing content was accidentally modified or deleted
  - **Verify**: `grep -c "3.6.0" plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json` returns 2
  - **Done when**: All acceptance criteria from requirements.md confirmed
  - **Commit**: `fix(karpathy): address final review issues` (only if fixes needed)

- [x] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "docs(karpathy): enforce Karpathy coding rules across agents and skills" --body "## Summary\n- Add Karpathy's 4 coding rules to CLAUDE.md\n- Add tailored rule subsets to 6 agents\n- Update 2 skills with Karpathy alignment\n- Bump ralph-specum to v3.6.0\n\nSource: https://github.com/forrestchang/andrej-karpathy-skills"`
  - **Verify**: `gh pr checks` shows all green (or no CI configured for md-only changes)
  - **Done when**: PR created and ready for review

## Notes

- **POC shortcuts taken**: None -- all files edited in Phase 1 since changes are simple markdown insertions
- **Production TODOs**: None -- documentation changes are production-ready on merge
