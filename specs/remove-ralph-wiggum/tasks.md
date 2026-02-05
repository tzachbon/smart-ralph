---
spec: remove-ralph-wiggum
phase: tasks
total_tasks: 16
created: 2026-02-05
generated: auto
---

# Tasks: remove-ralph-wiggum

## Phase 1: Make It Work (POC)

Focus: Get loop control working in stop-hook. Skip tests.

- [x] 1.1 Add loop control logic to stop-watcher.sh
  - **Do**: Modify stop-watcher.sh to output continuation prompt when taskIndex < totalTasks
    1. After existing state reading section, add loop control logic
    2. Check if phase == "execution" and taskIndex < totalTasks
    3. If true, output continuation prompt with spec path and state location
    4. Continuation prompt tells Claude to read state, delegate task, update state
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: Stop-hook outputs continuation prompt when more tasks exist
  - **Verify**: `echo '{"phase":"execution","taskIndex":0,"totalTasks":5}' > /tmp/test-state.json && cat stop-watcher.sh | grep -q "taskIndex.*totalTasks"`
  - **Commit**: `feat(stop-hook): add loop control logic for task execution`
  - _Requirements: FR-1, FR-2_
  - _Design: Stop-Hook (Loop Controller)_

- [x] 1.2 Simplify implement.md to write state directly
  - **Do**: Remove ralph-loop dependency and skill invocation
    1. Remove "Ralph Loop Dependency Check" section
    2. Remove "Invoke Ralph Loop" section (step 1 and 2)
    3. Keep state file writing logic
    4. Output coordinator prompt directly in implement.md (no file, no skill)
    5. Remove .coordinator-prompt.md file references
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: implement.md writes state and outputs coordinator prompt without calling ralph-loop skill
  - **Verify**: `grep -v "ralph-loop" plugins/ralph-specum/commands/implement.md | grep -q "coordinator"`
  - **Commit**: `feat(implement): inline coordinator prompt, remove ralph-loop dependency`
  - _Requirements: FR-4, FR-5_
  - _Design: implement.md (Simplified)_

- [x] 1.3 Simplify cancel.md to delete files only
  - **Do**: Remove skill invocation, simplify to file deletion
    1. Remove "Stop Ralph loop" section that invokes ralph-loop:cancel-ralph
    2. Keep file deletion: rm .ralph-state.json, rm -rf spec directory
    3. Keep .current-spec clearing
    4. Update output to remove "Stopped Ralph loop" line
  - **Files**: plugins/ralph-specum/commands/cancel.md
  - **Done when**: cancel.md works without ralph-loop skill
  - **Verify**: `grep -v "ralph-loop" plugins/ralph-specum/commands/cancel.md && ! grep -q "Skill tool" plugins/ralph-specum/commands/cancel.md`
  - **Commit**: `feat(cancel): simplify to file deletion, remove ralph-loop dependency`
  - _Requirements: FR-6, FR-7_
  - _Design: cancel.md (Simplified)_

- [x] 1.4 Remove ralph-loop references from skills and documentation
  - **Do**: Clean up all remaining ralph-loop/ralph-wiggum references
    1. Update skills/smart-ralph/references/ralph-loop-integration.md - remove or mark deprecated
    2. Search for "ralph-loop" and "ralph-wiggum" in all .md files
    3. Update CLAUDE.md if it references ralph-loop dependency
    4. Remove any comments mentioning ralph-loop
  - **Files**: plugins/ralph-specum/skills/smart-ralph/references/ralph-loop-integration.md, CLAUDE.md
  - **Done when**: No functional ralph-loop references remain
  - **Verify**: `! grep -r "ralph-loop:ralph-loop" plugins/ralph-specum/ && ! grep -r "ralph-wiggum@" plugins/ralph-specum/`
  - **Commit**: `chore: remove ralph-loop/ralph-wiggum references`
  - _Requirements: AC-1.4_
  - _Design: Migration Notes_

- [x] 1.5 POC Checkpoint
  - **Do**: Verify loop control works end-to-end
    1. Create test spec with 2 simple tasks
    2. Run /ralph-specum:implement
    3. Verify stop-hook triggers continuation
    4. Verify tasks complete in sequence
    5. Verify loop terminates at end
  - **Done when**: Execution loop works without ralph-loop plugin
  - **Verify**: Manual test of 2-task spec completing
  - **Commit**: `feat(ralph-specum): complete POC - self-contained execution loop`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3_

## Phase 2: Refactoring

Clean up code after POC validated.

- [x] 2.1 Extract coordinator prompt to reusable function/template
  - **Do**: Create coordinator-prompt.sh or inline template
    1. Extract large coordinator prompt text from implement.md
    2. Create function or heredoc template for maintainability
    3. Ensure stop-hook and implement.md use consistent prompt
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh, plugins/ralph-specum/commands/implement.md
  - **Done when**: Coordinator prompt is DRY and maintainable
  - **Verify**: Type check passes (shellcheck on .sh files)
  - **Commit**: `refactor(coordinator): extract prompt to reusable template`
  - _Design: coordinator-prompt.sh_

- [x] 2.2 Add error handling for edge cases
  - **Do**: Handle edge cases in stop-hook
    1. Handle missing jq gracefully (already exists, verify)
    2. Handle missing state file (exit silently)
    3. Handle corrupt JSON (log warning, exit)
    4. Handle disabled plugin setting (already exists)
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: All edge cases handled without crashing
  - **Verify**: shellcheck passes
  - **Commit**: `refactor(stop-hook): add comprehensive error handling`
  - _Design: Error Handling_

- [x] 2.3 Update spec-executor documentation
  - **Do**: Update agent documentation to reflect no ralph-loop
    1. Update spec-executor.md comments about stop-hook
    2. Ensure "State File Protection" section is accurate
    3. Remove any ralph-loop references in agents
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: Agent docs accurate for v3.0.0
  - **Verify**: No ralph-loop references in agents/
  - **Commit**: `docs(agents): update for v3.0.0 self-contained loop`

## Phase 3: Testing

Add bats-core tests.

- [x] 3.1 Set up bats-core test infrastructure
  - **Do**: Create test directory and helpers
    1. Create tests/ directory
    2. Create tests/helpers/setup.bash with common fixtures
    3. Add .gitignore entry for test artifacts
    4. Create sample .ralph-state.json fixtures
  - **Files**: tests/helpers/setup.bash, tests/.gitignore
  - **Done when**: Test infrastructure ready
  - **Verify**: `ls tests/helpers/setup.bash`
  - **Commit**: `test: add bats-core test infrastructure`
  - _Requirements: AC-3.1_

- [x] 3.2 Add stop-hook unit tests
  - **Do**: Write bats tests for stop-hook logic
    1. Test: exits silently when no state file
    2. Test: exits silently when phase != execution
    3. Test: exits silently when taskIndex >= totalTasks
    4. Test: outputs continuation prompt when tasks remain
    5. Test: handles corrupt JSON gracefully
    6. Test: handles missing jq
  - **Files**: tests/stop-hook.bats
  - **Done when**: All stop-hook state machine tests pass
  - **Verify**: `bats tests/stop-hook.bats`
  - **Commit**: `test(stop-hook): add unit tests for loop control`
  - _Requirements: AC-3.2, AC-3.3, AC-3.4_

- [x] 3.3 Add state management tests
  - **Do**: Write bats tests for state file operations
    1. Test: state file created correctly by implement
    2. Test: state file deleted by cancel
    3. Test: taskIndex updates correctly
  - **Files**: tests/state-management.bats
  - **Done when**: State management tests pass
  - **Verify**: `bats tests/state-management.bats`
  - **Commit**: `test(state): add state management tests`
  - _Requirements: AC-3.1_

## Phase 4: Quality Gates

- [x] 4.1 Bump version to 3.0.0
  - **Do**: Update version in both manifest files
    1. Update plugins/ralph-specum/.claude-plugin/plugin.json version to "3.0.0"
    2. Update .claude-plugin/marketplace.json ralph-specum version to "3.0.0"
    3. Verify versions match
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files show version 3.0.0
  - **Verify**: `grep '"version": "3.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep '"version": "3.0.0"' .claude-plugin/marketplace.json`
  - **Commit**: `chore(version): bump to v3.0.0 - remove ralph-loop dependency`
  - _Requirements: FR-10_

- [x] 4.2 Add GitHub Actions CI for bats tests
  - **Do**: Create workflow file
    1. Create .github/workflows/bats-tests.yml
    2. Trigger on push and pull_request
    3. Install bats-core
    4. Run all .bats files in tests/
    5. Report status
  - **Files**: .github/workflows/bats-tests.yml
  - **Done when**: Workflow file exists and is valid
  - **Verify**: `cat .github/workflows/bats-tests.yml | grep -q "bats"`
  - **Commit**: `ci: add GitHub Actions workflow for bats tests`
  - _Requirements: FR-9, AC-4.1, AC-4.2, AC-4.3, AC-4.4_

- [ ] 4.3 Run shellcheck on all scripts
  - **Do**: Lint all shell scripts
    1. Run shellcheck on hooks/scripts/*.sh
    2. Fix any warnings/errors
    3. Verify all scripts pass
  - **Files**: plugins/ralph-specum/hooks/scripts/*.sh
  - **Done when**: All scripts pass shellcheck
  - **Verify**: `shellcheck plugins/ralph-specum/hooks/scripts/*.sh`
  - **Commit**: `fix: address shellcheck warnings`
  - _Requirements: NFR-2_

- [ ] 4.4 [VERIFY] Local quality check
  - **Do**: Run all quality checks locally
    1. Run bats tests: `bats tests/`
    2. Run shellcheck: `shellcheck plugins/ralph-specum/hooks/scripts/*.sh`
    3. Verify no ralph-loop references: `! grep -r "ralph-loop" plugins/ralph-specum/`
  - **Verify**: All checks pass
  - **Done when**: All commands exit 0
  - **Commit**: `fix: address any final quality issues` (if needed)

- [ ] 4.5 Create PR and verify CI
  - **Do**: Push branch, create PR
    1. Ensure not on main branch
    2. Push branch: `git push -u origin HEAD`
    3. Create PR: `gh pr create --title "feat(ralph-specum): v3.0.0 - remove ralph-loop dependency" --body "..."`
    4. Wait for CI: `gh pr checks --watch`
  - **Verify**: `gh pr checks` all green
  - **Done when**: PR created and CI passing
  - **Commit**: None (PR creation)

## Notes

- **POC shortcuts taken**: No tests initially, inline prompt may be verbose
- **Production TODOs**: Optimize prompt size, consider caching
- **Breaking change**: v3.0.0 requires users to NOT have ralph-loop installed (conflicts possible)
