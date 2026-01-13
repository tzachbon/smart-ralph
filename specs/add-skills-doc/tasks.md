---
spec: add-skills-doc
phase: tasks
total_tasks: 5
created: 2026-01-13
generated: auto
---

# Tasks: add-skills-doc

## Phase 1: Make It Work (POC)

Focus: Create the skills directory and SKILL.md file.

- [x] 1.1 Create skills directory structure
  - **Do**: Create `plugins/ralph-specum/skills/spec-workflow/` directory
  - **Files**: `plugins/ralph-specum/skills/spec-workflow/`
  - **Done when**: Directory exists
  - **Verify**: `ls plugins/ralph-specum/skills/spec-workflow/`
  - **Commit**: `feat(skills): add skills directory structure`
  - _Requirements: FR-1_
  - _Design: Architecture_

- [x] 1.2 Create SKILL.md with all command mappings
  - **Do**: Create SKILL.md with frontmatter (name, description) and body listing all 11 commands grouped by intent
  - **Files**: `plugins/ralph-specum/skills/spec-workflow/SKILL.md`
  - **Done when**: File contains all commands with intent-based grouping
  - **Verify**: `cat plugins/ralph-specum/skills/spec-workflow/SKILL.md | grep -c "ralph-specum:"` returns 11
  - **Commit**: `feat(skills): add SKILL.md for spec workflow`
  - _Requirements: FR-2, FR-3, FR-4_
  - _Design: SKILL.md Content Design_

- [x] 1.X POC Checkpoint
  - **Do**: Verify SKILL.md exists with proper structure
  - **Done when**: File readable with correct format
  - **Verify**: `head -10 plugins/ralph-specum/skills/spec-workflow/SKILL.md`
  - **Commit**: `feat(skills): complete skills documentation`

## Phase 2: Refactoring

- [x] 2.1 Review and polish descriptions
  - **Do**: Ensure all descriptions are concise (<100 chars) and action-oriented
  - **Files**: `plugins/ralph-specum/skills/spec-workflow/SKILL.md`
  - **Done when**: Descriptions match command frontmatter style
  - **Verify**: Manual review of content
  - **Commit**: `refactor(skills): polish skill descriptions`
  - _Requirements: NFR-2_

## Phase 3: Testing

No automated tests needed for documentation files.

## Phase 4: Quality Gates

- [x] 4.1 Create PR and verify (pushed directly to main)
  - **Do**: Push branch, create PR with description of changes
  - **Verify**: `gh pr create --title "feat(skills): add SKILL.md for command discovery" --body "Adds skills/spec-workflow/SKILL.md so Claude Code can auto-invoke commands based on user intent"`
  - **Done when**: PR created
  - **Commit**: N/A (PR creation only)

## Notes

- **POC shortcuts taken**: None needed, this is simple documentation
- **Production TODOs**: Consider adding more skills groupings if plugin grows
