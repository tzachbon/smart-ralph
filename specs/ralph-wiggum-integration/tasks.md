---
spec: ralph-wiggum-integration
phase: tasks
total_tasks: 10
created: 2026-02-05
generated: auto
---

# Tasks: ralph-wiggum-integration

## Phase 1: Make It Work (POC)

Focus: Get implement.md working with ralph-wiggum API. Skip tests.

- [x] 1.1 Update skill invocation path in implement.md
  - **Do**: Change `ralph-loop:ralph-loop` to `ralph-wiggum:ralph-wiggum` in implement.md skill invocation section
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Skill invocation references ralph-wiggum
  - **Verify**: `grep -q "ralph-wiggum:ralph-wiggum" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(implement): switch to ralph-wiggum skill invocation`
  - _Requirements: FR-1_
  - _Design: Component A_

- [x] 1.2 Update completion signal format in coordinator prompt
  - **Do**: Wrap ALL_TASKS_COMPLETE in `<promise>` tags in coordinator prompt section. Find all occurrences of `Output: ALL_TASKS_COMPLETE` and similar, change to `Output: <promise>ALL_TASKS_COMPLETE</promise>`
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: All completion outputs use `<promise>` tags
  - **Verify**: `grep -c "<promise>ALL_TASKS_COMPLETE</promise>" plugins/ralph-specum/commands/implement.md` returns at least 3
  - **Commit**: `feat(implement): use promise tags for completion signal`
  - _Requirements: FR-2_
  - _Design: Component B_

- [x] 1.3 Update error handling to not output promise on errors
  - **Do**: Ensure all "Do NOT output ALL_TASKS_COMPLETE" statements also say not to output the promise format. Search for "Do NOT output ALL_TASKS_COMPLETE" and update to mention promise format
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Error cases explicitly say not to output promise tags
  - **Verify**: `grep -c "Do NOT output <promise>" plugins/ralph-specum/commands/implement.md` returns at least 5
  - **Commit**: `feat(implement): clarify no promise output on errors`
  - _Requirements: FR-2_
  - _Design: Error Handling_

- [x] 1.4 [VERIFY] POC Checkpoint
  - **Do**: Verify implement.md has correct ralph-wiggum integration
  - **Done when**: All three POC changes verified
  - **Verify**: Run all grep checks from 1.1-1.3

## Phase 2: Refactoring

Clean up and update documentation.

- [x] 2.1 Update CLAUDE.md dependency reference
  - **Do**: Change all references from `ralph-loop` to `ralph-wiggum` in CLAUDE.md. Update install commands, description text, and any mentions of "Ralph Loop"
  - **Files**: CLAUDE.md
  - **Done when**: No references to ralph-loop remain (except historical context if any)
  - **Verify**: `grep -c "ralph-wiggum" CLAUDE.md` returns at least 3 AND `grep -c "ralph-loop" CLAUDE.md` returns 0
  - **Commit**: `docs(claude): update to ralph-wiggum dependency`
  - _Requirements: FR-3_
  - _Design: CLAUDE.md Changes_

- [x] 2.2 Update implement.md dependency check message
  - **Do**: Update the error message in "Ralph Loop Dependency Check" section to reference ralph-wiggum instead of Ralph Loop
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Error message references ralph-wiggum
  - **Verify**: `grep -q "ralph-wiggum@claude-plugins-official" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `docs(implement): update dependency error message`
  - _Requirements: FR-3_
  - _Design: Component A_

- [x] 2.3 [VERIFY] Documentation checkpoint
  - **Do**: Verify all documentation updated consistently
  - **Done when**: No stale references to ralph-loop
  - **Verify**: `grep -r "ralph-loop" plugins/ralph-specum/ CLAUDE.md 2>/dev/null | grep -v ".progress" | wc -l` returns 0

## Phase 3: Testing

Manual verification of the integration.

- [x] 3.1 Verify skill lookup works
  - **Do**: Check that ralph-wiggum:ralph-wiggum skill exists in available skills. Create a simple test by running skill search
  - **Files**: None (verification only)
  - **Done when**: Skill exists and can be found
  - **Verify**: `claude --version` succeeds (basic sanity check that claude CLI works)
  - **Commit**: None (verification task)
  - _Requirements: AC-1.1_

- [x] 3.2 [VERIFY] Integration test checkpoint
  - **Do**: Verify the full integration is correct by reviewing implement.md structure
  - **Done when**: All patterns correct
  - **Verify**: Read implement.md and verify skill name and promise format

## Phase 4: Quality Gates

- [x] 4.1 Bump plugin version
  - **Do**: Increment version from 2.11.3 to 2.11.4 in both plugin.json and marketplace.json
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files have version 2.11.4
  - **Verify**: `grep -q '"2.11.4"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"2.11.4"' .claude-plugin/marketplace.json`
  - **Commit**: `chore(ralph-specum): bump version to 2.11.4`

- [ ] 4.2 Create PR and verify
  - **Do**: Push branch, create PR with summary of ralph-wiggum integration changes
  - **Verify**: `gh pr view` shows PR created
  - **Done when**: PR ready for review
  - **Commit**: None (PR creation)

## Notes

- **POC shortcuts taken**: None needed - changes are straightforward text replacements
- **Production TODOs**: Test with real spec execution after merge
- **Key insight**: Coordinator prompt is already idempotent (state-file driven), so re-feeding works
