---
spec: multi-spec-dirs
phase: tasks
total_tasks: 32
created: 2026-02-05
---

# Tasks: Multi-Spec Directories

## Phase 1: Make It Work (POC)

Focus: Validate path resolution works end-to-end. Skip tests, accept minimal implementation.

- [x] 1.1 Create path-resolver.sh with core functions
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/path-resolver.sh`
    2. Implement `ralph_get_specs_dirs()` - parse specs_dirs from settings, default to `["./specs"]`
    3. Implement `ralph_get_default_dir()` - return first specs_dir
    4. Implement `ralph_resolve_current()` - resolve .current-spec (bare name = ./specs/$name, full path = as-is)
    5. Implement `ralph_find_spec()` - find spec by name, return full path, exit 2 if ambiguous
    6. Implement `ralph_list_specs()` - list all specs as "name|path" pairs
  - **Files**: `plugins/ralph-specum/hooks/scripts/path-resolver.sh`
  - **Done when**: Script exists with 5 functions, sources without errors
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/path-resolver.sh && echo "Syntax OK"`
  - **Commit**: `feat(ralph-specum): add path-resolver.sh with core functions`
  - _Requirements: FR-4_
  - _Design: path-resolver.sh Implementation_

- [x] 1.2 Update settings-template.md with specs_dirs documentation
  - **Do**:
    1. Read current `plugins/ralph-specum/templates/settings-template.md`
    2. Add `specs_dirs: ["./specs"]` to frontmatter
    3. Add documentation section explaining specs_dirs setting
    4. Include examples for monorepo setup
  - **Files**: `plugins/ralph-specum/templates/settings-template.md`
  - **Done when**: Template has specs_dirs in frontmatter and documentation
  - **Verify**: `grep -q "specs_dirs" plugins/ralph-specum/templates/settings-template.md && echo "Found"`
  - **Commit**: `docs(ralph-specum): add specs_dirs setting to template`
  - _Requirements: FR-10_
  - _Design: Settings Extension_

- [x] 1.3 Update load-spec-context.sh to use path resolver
  - **Do**:
    1. Source path-resolver.sh at start of script
    2. Replace hardcoded `CURRENT_SPEC_FILE="$CWD/specs/.current-spec"` with resolver
    3. Replace hardcoded `SPEC_PATH="$CWD/specs/$SPEC_NAME"` with `ralph_resolve_current()`
    4. Update .current-spec check to search in first specs_dir
  - **Files**: `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
  - **Done when**: Hook uses resolver functions, no hardcoded `./specs/` paths except as fallback
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh && echo "Syntax OK"`
  - **Commit**: `refactor(ralph-specum): update load-spec-context.sh to use path resolver`
  - _Requirements: FR-6_
  - _Design: Hooks section_

- [x] 1.4 [VERIFY] Quality checkpoint: Shell syntax validation
  - **Do**: Validate all shell scripts have valid syntax
  - **Verify**: `for f in plugins/ralph-specum/hooks/scripts/*.sh; do bash -n "$f" || exit 1; done && echo "All scripts OK"`
  - **Done when**: All shell scripts pass syntax check
  - **Commit**: `chore(ralph-specum): fix shell script syntax issues` (only if fixes needed)

- [x] 1.5 Update stop-watcher.sh to use path resolver
  - **Do**:
    1. Source path-resolver.sh at start of script
    2. Replace hardcoded `CURRENT_SPEC_FILE="$CWD/specs/.current-spec"` with resolver
    3. Replace hardcoded `STATE_FILE="$CWD/specs/$SPEC_NAME/.ralph-state.json"` with resolver
    4. Update cleanup path to use resolved spec path
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Hook uses resolver functions, no hardcoded `./specs/` paths except as fallback
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "Syntax OK"`
  - **Commit**: `refactor(ralph-specum): update stop-watcher.sh to use path resolver`
  - _Requirements: FR-6_
  - _Design: Hooks section_

- [x] 1.6 Update status.md command for multi-root listing
  - **Do**:
    1. Replace hardcoded `./specs/` enumeration with `ralph_list_specs()` usage
    2. Update .current-spec reading to use `ralph_resolve_current()`
    3. Group output by specs_dir root
    4. Show `[dir-name]` suffix for non-default roots
    5. Add directory context to each spec listing
  - **Files**: `plugins/ralph-specum/commands/status.md`
  - **Done when**: Command lists specs from all configured dirs with directory context
  - **Verify**: `grep -q "ralph_list_specs\|all specs\|multi" plugins/ralph-specum/commands/status.md && echo "Found"`
  - **Commit**: `feat(ralph-specum): update status.md for multi-root listing`
  - _Requirements: AC-3.1, AC-3.2, AC-3.3, AC-3.4_
  - _Design: status.md Specific Changes_

- [x] 1.7 Update switch.md command with disambiguation
  - **Do**:
    1. Replace hardcoded path validation with `ralph_find_spec()` usage
    2. Update available specs listing with `ralph_list_specs()`
    3. Handle exit code 2 (ambiguous) with disambiguation prompt
    4. Support full path specification for disambiguation
    5. Write full path to .current-spec for non-default roots
  - **Files**: `plugins/ralph-specum/commands/switch.md`
  - **Done when**: Command handles multi-root search and disambiguation
  - **Verify**: `grep -q "disambiguation\|ralph_find_spec\|ambiguous" plugins/ralph-specum/commands/switch.md && echo "Found"`
  - **Commit**: `feat(ralph-specum): update switch.md with disambiguation support`
  - _Requirements: AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5_
  - _Design: switch.md Specific Changes, Disambiguation Flow_

- [x] 1.8 [VERIFY] Quality checkpoint: Command syntax validation
  - **Do**: Verify command files are valid markdown with proper frontmatter
  - **Verify**: `for f in plugins/ralph-specum/commands/*.md; do head -1 "$f" | grep -q "^---$" && echo "$f OK" || echo "$f FAIL"; done`
  - **Done when**: All command files have valid frontmatter
  - **Commit**: `chore(ralph-specum): fix command frontmatter issues` (only if fixes needed)

- [x] 1.9 Update start.md with --specs-dir flag
  - **Do**:
    1. Add `--specs-dir <path>` to argument parsing
    2. Update spec creation to use specified dir or `ralph_get_default_dir()`
    3. Update .current-spec writing to store full path for non-default roots
    4. Update worktree copying to use active spec's root
    5. Update spec scanner to search all `specs_dirs`
    6. Validate --specs-dir is in configured specs_dirs array
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Command supports --specs-dir flag and uses resolver for paths
  - **Verify**: `grep -q "\-\-specs-dir" plugins/ralph-specum/commands/start.md && echo "Found"`
  - **Commit**: `feat(ralph-specum): add --specs-dir flag to start.md`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, FR-2, FR-9_
  - _Design: start.md Specific Changes_

- [x] 1.10 Update new.md with --specs-dir flag
  - **Do**:
    1. Add `--specs-dir <path>` to argument parsing
    2. Update spec creation path to use specified dir or `ralph_get_default_dir()`
    3. Update basePath in .ralph-state.json to use resolved path
    4. Update .current-spec writing to store full path for non-default roots
  - **Files**: `plugins/ralph-specum/commands/new.md`
  - **Done when**: Command supports --specs-dir flag and creates specs in specified dir
  - **Verify**: `grep -q "\-\-specs-dir" plugins/ralph-specum/commands/new.md && echo "Found"`
  - **Commit**: `feat(ralph-specum): add --specs-dir flag to new.md`
  - _Requirements: AC-2.3_
  - _Design: Command Updates Pattern_

- [x] 1.11 Update cancel.md for multi-root search
  - **Do**:
    1. Update spec finding to use `ralph_find_spec()` instead of hardcoded path
    2. Handle disambiguation if spec name exists in multiple roots
    3. Update cleanup paths to use resolved spec path
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: Command finds and cancels specs from any configured root
  - **Verify**: `grep -q "ralph_find_spec\|multi" plugins/ralph-specum/commands/cancel.md && echo "Found"`
  - **Commit**: `refactor(ralph-specum): update cancel.md for multi-root search`
  - _Requirements: FR-5_
  - _Design: Command Updates Pattern_

- [x] 1.12 [VERIFY] Quality checkpoint: Shell syntax and command frontmatter
  - **Do**: Validate all shell scripts and command files
  - **Verify**: `for f in plugins/ralph-specum/hooks/scripts/*.sh; do bash -n "$f" || exit 1; done && for f in plugins/ralph-specum/commands/*.md; do head -1 "$f" | grep -q "^---$" || exit 1; done && echo "All OK"`
  - **Done when**: All shell scripts and commands pass validation
  - **Commit**: `chore(ralph-specum): fix validation issues` (only if fixes needed)

- [x] 1.13 Update remaining commands to use resolver (research, requirements, design, tasks, implement, refactor)
  - **Do**:
    1. Update `commands/research.md` - replace hardcoded spec path with resolver usage
    2. Update `commands/requirements.md` - replace hardcoded spec path with resolver usage
    3. Update `commands/design.md` - replace hardcoded spec path with resolver usage
    4. Update `commands/tasks.md` - replace hardcoded spec path with resolver usage
    5. Update `commands/implement.md` - replace hardcoded spec path with resolver usage
    6. Update `commands/refactor.md` - replace hardcoded spec path with resolver usage
    7. Each command: update "Determine Active Spec" section to use `ralph_resolve_current()`
  - **Files**:
    - `plugins/ralph-specum/commands/research.md`
    - `plugins/ralph-specum/commands/requirements.md`
    - `plugins/ralph-specum/commands/design.md`
    - `plugins/ralph-specum/commands/tasks.md`
    - `plugins/ralph-specum/commands/implement.md`
    - `plugins/ralph-specum/commands/refactor.md`
  - **Done when**: All 6 commands use resolver instead of hardcoded `./specs/`
  - **Verify**: `for cmd in research requirements design tasks implement refactor; do grep -q "ralph_resolve_current\|dynamic path\|path resolver" plugins/ralph-specum/commands/$cmd.md || echo "$cmd missing"; done`
  - **Commit**: `refactor(ralph-specum): update 6 commands to use path resolver`
  - _Requirements: FR-5_
  - _Design: Command Updates Pattern_

- [x] 1.14 Update help.md to document multi-dir functionality
  - **Do**:
    1. Add section explaining specs_dirs configuration
    2. Document --specs-dir flag for start/new commands
    3. Add example monorepo setup
    4. Mention disambiguation behavior for duplicate names
  - **Files**: `plugins/ralph-specum/commands/help.md`
  - **Done when**: Help command documents multi-directory features
  - **Verify**: `grep -q "specs_dirs\|multi" plugins/ralph-specum/commands/help.md && echo "Found"`
  - **Commit**: `docs(ralph-specum): document multi-dir functionality in help`
  - _Requirements: FR-11_
  - _Design: File Structure_

- [ ] 1.15 [VERIFY] Quality checkpoint: All commands updated
  - **Do**: Verify all 12 commands reference resolver or dynamic paths
  - **Verify**: `for f in plugins/ralph-specum/commands/*.md; do grep -l "ralph_resolve_current\|specs_dirs\|dynamic path\|path resolver\|--specs-dir" "$f" >/dev/null || echo "Missing: $f"; done | grep -c "Missing:" | xargs test 0 -eq && echo "All commands updated"`
  - **Done when**: All commands have dynamic path references
  - **Commit**: `chore(ralph-specum): ensure all commands use dynamic paths` (only if fixes needed)

- [ ] 1.16 Update agents to use dynamic paths from delegation
  - **Do**:
    1. Update `agents/research-analyst.md` - replace `./specs/` refs with dynamic path from delegation context
    2. Update `agents/product-manager.md` - use basePath from delegation
    3. Update `agents/architect-reviewer.md` - use spec path from delegation
    4. Update `agents/task-planner.md` - use spec path from delegation
    5. Update `agents/spec-executor.md` - use basePath from state
    6. Update `agents/plan-synthesizer.md` - use spec path from delegation
    7. Update `agents/qa-engineer.md` - use spec path from delegation
    8. Update `agents/refactor-specialist.md` - use spec path from delegation
    9. Each agent: mention path comes from Task delegation, not hardcoded
  - **Files**:
    - `plugins/ralph-specum/agents/research-analyst.md`
    - `plugins/ralph-specum/agents/product-manager.md`
    - `plugins/ralph-specum/agents/architect-reviewer.md`
    - `plugins/ralph-specum/agents/task-planner.md`
    - `plugins/ralph-specum/agents/spec-executor.md`
    - `plugins/ralph-specum/agents/plan-synthesizer.md`
    - `plugins/ralph-specum/agents/qa-engineer.md`
    - `plugins/ralph-specum/agents/refactor-specialist.md`
  - **Done when**: All 8 agents reference dynamic paths, not hardcoded `./specs/`
  - **Verify**: `for f in plugins/ralph-specum/agents/*.md; do grep -l "basePath\|delegation\|dynamic" "$f" >/dev/null || echo "Missing: $f"; done | grep -c "Missing:" | xargs test 0 -eq && echo "All agents updated"`
  - **Commit**: `refactor(ralph-specum): update 8 agents to use dynamic paths`
  - _Requirements: FR-7_
  - _Design: Agents section_

- [ ] 1.17 POC Checkpoint: Validate end-to-end multi-dir workflow
  - **Do**:
    1. Create test settings file with specs_dirs config
    2. Verify path-resolver.sh functions work correctly
    3. Test spec creation in non-default directory
    4. Test status listing from multiple dirs
    5. Test switch between specs in different dirs
  - **Verify**:
    ```bash
    cd /Users/zachbonfil/projects/smart-ralph-multi-spec-dirs && \
    source plugins/ralph-specum/hooks/scripts/path-resolver.sh && \
    ralph_get_specs_dirs && \
    ralph_get_default_dir && \
    echo "POC validation passed"
    ```
  - **Done when**: Path resolver functions execute without error, return expected defaults
  - **Commit**: `feat(ralph-specum): complete multi-spec-dirs POC`
  - _Requirements: Success Criteria_
  - _Design: Architecture_

## Phase 2: Refactoring

After POC validated, clean up code and improve consistency.

- [ ] 2.1 Extract common patterns in commands to use consistent resolver invocation
  - **Do**:
    1. Review all 12 commands for consistent resolver usage pattern
    2. Standardize "Determine Active Spec" sections across commands
    3. Ensure consistent error messages for spec not found
    4. Ensure consistent handling of .current-spec format
  - **Files**: All command files in `plugins/ralph-specum/commands/`
  - **Done when**: All commands use identical pattern for spec resolution
  - **Verify**: `grep -h "Determine Active Spec" plugins/ralph-specum/commands/*.md | sort -u | wc -l | xargs test 1 -ge && echo "Consistent"`
  - **Commit**: `refactor(ralph-specum): standardize resolver pattern in commands`
  - _Design: Command Updates Pattern_

- [ ] 2.2 Add error handling to path-resolver.sh
  - **Do**:
    1. Add validation for RALPH_CWD existence
    2. Add error messages for invalid paths in specs_dirs
    3. Add logging for skipped invalid paths (warn, continue)
    4. Handle edge cases: empty specs_dirs, trailing slashes, spaces in paths
  - **Files**: `plugins/ralph-specum/hooks/scripts/path-resolver.sh`
  - **Done when**: All error paths handled with clear messages
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/path-resolver.sh && echo "Syntax OK"`
  - **Commit**: `refactor(ralph-specum): add error handling to path-resolver.sh`
  - _Design: Error Handling_

- [ ] 2.3 [VERIFY] Quality checkpoint: Shell scripts and commands
  - **Do**: Run syntax validation on all shell scripts and verify command structure
  - **Verify**: `for f in plugins/ralph-specum/hooks/scripts/*.sh; do bash -n "$f" || exit 1; done && echo "All shell scripts OK"`
  - **Done when**: All shell scripts pass syntax validation
  - **Commit**: `chore(ralph-specum): fix shell script issues` (only if fixes needed)

- [ ] 2.4 Improve disambiguation UX in switch command
  - **Do**:
    1. Format disambiguation output clearly with numbered options
    2. Show full paths with directory context
    3. Provide example command for each option
    4. Handle "no specs found" gracefully
  - **Files**: `plugins/ralph-specum/commands/switch.md`
  - **Done when**: Disambiguation provides clear, actionable guidance
  - **Verify**: `grep -q "example\|1\.\|2\." plugins/ralph-specum/commands/switch.md && echo "Found"`
  - **Commit**: `refactor(ralph-specum): improve disambiguation UX in switch`
  - _Design: Disambiguation Flow_

- [ ] 2.5 Bump plugin version
  - **Do**:
    1. Update version in `plugins/ralph-specum/.claude-plugin/plugin.json` (2.11.1 -> 2.12.0)
    2. Update version in `.claude-plugin/marketplace.json` for ralph-specum entry (2.11.1 -> 2.12.0)
  - **Files**:
    - `plugins/ralph-specum/.claude-plugin/plugin.json`
    - `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 2.12.0
  - **Verify**: `grep -q "2.12.0" plugins/ralph-specum/.claude-plugin/plugin.json && grep -q "2.12.0" .claude-plugin/marketplace.json && echo "Version bumped"`
  - **Commit**: `chore(ralph-specum): bump version to 2.12.0 for multi-spec-dirs`

## Phase 3: Testing

- [ ] 3.1 Create unit tests for path-resolver.sh functions
  - **Do**:
    1. Create test script at `plugins/ralph-specum/hooks/scripts/test-path-resolver.sh`
    2. Test `ralph_get_specs_dirs()` with: no settings, empty array, single dir, multiple dirs
    3. Test `ralph_get_default_dir()` returns first configured dir
    4. Test `ralph_resolve_current()` with: bare name, full path, missing file
    5. Test `ralph_find_spec()` with: unique name, ambiguous name, not found
    6. Test `ralph_list_specs()` with: empty, single root, multiple roots
  - **Files**: `plugins/ralph-specum/hooks/scripts/test-path-resolver.sh`
  - **Done when**: Test script covers all 5 functions with edge cases
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && echo "Tests passed"`
  - **Commit**: `test(ralph-specum): add unit tests for path-resolver.sh`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3, AC-5.1, AC-5.2_
  - _Design: Test Strategy - Unit Tests_

- [ ] 3.2 Create integration tests for multi-dir workflow
  - **Do**:
    1. Create test script at `plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh`
    2. Test: create spec in default dir, verify .current-spec content
    3. Test: create spec with --specs-dir, verify full path in .current-spec
    4. Test: list specs from multiple roots
    5. Test: switch between specs in different roots
    6. Test: backward compat - bare name .current-spec resolves to ./specs/
    7. Clean up test artifacts after each test
  - **Files**: `plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh`
  - **Done when**: Integration test script covers key workflows
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh && echo "Integration tests passed"`
  - **Commit**: `test(ralph-specum): add integration tests for multi-dir workflow`
  - _Requirements: AC-2.1, AC-2.2, AC-4.1, AC-4.2, AC-5.3, AC-5.4_
  - _Design: Test Strategy - Integration Tests_

- [ ] 3.3 [VERIFY] Quality checkpoint: All tests pass
  - **Do**: Run all test scripts and verify they pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh && echo "All tests passed"`
  - **Done when**: Both unit and integration tests pass
  - **Commit**: `chore(ralph-specum): fix test failures` (only if fixes needed)

- [ ] 3.4 Add backward compatibility tests
  - **Do**:
    1. Add test cases to integration test for:
       - No settings file -> defaults to ./specs/
       - Existing bare .current-spec -> resolves to ./specs/$name
       - All commands work without any config
       - No warnings/errors for users without custom config
  - **Files**: `plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh`
  - **Done when**: Backward compat scenarios tested
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh && echo "Backward compat tests passed"`
  - **Commit**: `test(ralph-specum): add backward compatibility tests`
  - _Requirements: AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5_
  - _Design: Migration Path_

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: All commands must pass:
    - Shell syntax: `for f in plugins/ralph-specum/hooks/scripts/*.sh; do bash -n "$f" || exit 1; done`
    - Tests: `bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh`
    - Integration: `bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(ralph-specum): address quality issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Push branch: `git push -u origin feat/multi-spec-dirs`
    4. Create PR: `gh pr create --title "feat(ralph-specum): add multi-spec directories support" --body "..."`
  - **Verify**: `gh pr checks --watch` - all checks must show passing
  - **Done when**: All CI checks green, PR ready for review
  - **Commit**: None (PR creation, not code change)

## Phase 5: PR Lifecycle

- [ ] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Check CI status: `gh pr checks`
    2. If failures: read logs, fix issues, push fixes
    3. Re-verify until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: CI pipeline fully green
  - **Commit**: `fix(ralph-specum): resolve CI failures` (if needed)

- [ ] 5.2 Address review comments
  - **Do**:
    1. Read PR comments: `gh pr view --comments`
    2. Address each comment with code changes or discussion
    3. Push fixes, re-request review if needed
  - **Verify**: `gh pr view --json reviewDecision -q .reviewDecision` returns "APPROVED" or no blocking comments
  - **Done when**: All review feedback addressed
  - **Commit**: `fix(ralph-specum): address review feedback` (if needed)

- [ ] 5.3 [VERIFY] AC checklist
  - **Do**: Verify each acceptance criterion programmatically:
    - AC-1.1: `grep -q "specs_dirs" plugins/ralph-specum/templates/settings-template.md`
    - AC-1.3: Test default behavior without config
    - AC-2.1: Verify start.md has --specs-dir handling
    - AC-3.1: Verify status.md lists from all roots
    - AC-4.1: Verify switch.md has disambiguation
    - AC-5.1: Test no config = ./specs/ default
  - **Verify**: Run all AC verification commands, all must pass
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

- [ ] 5.4 [VERIFY] Full local CI equivalent
  - **Do**: Run complete validation suite
  - **Verify**:
    ```bash
    for f in plugins/ralph-specum/hooks/scripts/*.sh; do bash -n "$f" || exit 1; done && \
    bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && \
    bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh && \
    echo "Full CI passed"
    ```
  - **Done when**: All validations pass
  - **Commit**: `chore(ralph-specum): final quality pass` (if fixes needed)

- [ ] 5.5 [VERIFY] CI pipeline passes
  - **Do**: Verify GitHub Actions/CI passes after push
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None

## Notes

### POC Shortcuts Taken
- Minimal error messages in path-resolver.sh (improved in Phase 2)
- Basic disambiguation output (improved UX in Phase 2)
- No validation of specs_dirs paths exist (added in Phase 2)

### Production TODOs
- Add proper logging/debug mode to path-resolver.sh
- Consider caching specs_dirs to avoid repeated settings parsing
- Add `--reorganize` flag for spec migration (FR-12, lower priority)

### Dependencies
- Tasks 1.3-1.16 all depend on 1.1 (path-resolver.sh creation)
- Phase 2 depends on Phase 1 POC validation (1.17)
- Phase 3 tests depend on Phase 2 refactoring
- Phase 4-5 depend on Phase 3 tests passing
