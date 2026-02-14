---
spec: return-ralph-wrigum
phase: tasks
total_tasks: 19
created: 2026-02-14
generated: auto
---

# Tasks: return-ralph-wrigum

## Phase 1: Make It Work (POC)

Focus: Get implement.md invoking /ralph-loop and stop-watcher.sh passive. Skip test updates.

- [x] 1.1 Strip loop control output from stop-watcher.sh
  - **Do**: Remove the continuation prompt output block from stop-watcher.sh while keeping all logging, cleanup, and validation logic.
    1. Remove the `if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]` block that outputs the `cat <<EOF` continuation prompt (approximately lines 131-161)
    2. Remove the `RECOVERY_MODE` and `MAX_TASK_ITER` reads that only served the continuation prompt
    3. Keep ALL other logic: jq check, CWD extraction, path resolver, settings check, spec resolution, state file check, race condition safeguard, ALL_TASKS_COMPLETE transcript detection, corrupt state check, state reading for logging, global iteration limit check, stderr logging line, orphan cleanup
    4. Ensure the script still exits cleanly with `exit 0`
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh does not output ANY continuation prompts to stdout; only writes to stderr for logging
  - **Verify**: `! grep -q 'Continue spec:' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q 'echo.*ralph-specum.*>&2' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "PASS"`
  - **Commit**: `feat(stop-hook): make stop-watcher passive, remove loop control output`
  - _Requirements: FR-4, FR-5, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5_
  - _Design: Component 2_

- [x] 1.2 Add Ralph Wiggum dependency check to implement.md
  - **Do**: Add a dependency check section to implement.md before state initialization.
    1. Add section "## Check Ralph Wiggum Dependency" after "## Validate Prerequisites"
    2. Include instructions to verify `/ralph-loop` command exists (attempt Skill tool invocation)
    3. If not found, output error with install command: `/plugin install ralph-wiggum@claude-plugins-official`
    4. Do NOT proceed with state changes if dependency missing
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md has dependency check section with clear error message
  - **Verify**: `grep -q 'ralph-wiggum@claude-plugins-official' plugins/ralph-specum/commands/implement.md && grep -q 'Ralph Wiggum' plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Commit**: `feat(implement): add Ralph Wiggum dependency check`
  - _Requirements: FR-6, AC-4.3_
  - _Design: Component 1, Dependency Check_

- [x] 1.3 Modify implement.md to invoke /ralph-loop instead of outputting prompt directly
  - **Do**: Change the execution start mechanism from direct prompt output to Ralph Wiggum invocation.
    1. In the "## Start Execution" section, replace the instruction to "output the coordinator prompt below" with instructions to invoke `/ralph-loop`
    2. Add max-iterations calculation: `maxIterations = totalTasks * maxTaskIterations * 2`
    3. Add the invocation instruction: Call `/ralph-loop "<coordinator-prompt>" --max-iterations $maxIterations --completion-promise "ALL_TASKS_COMPLETE"` using the Skill tool
    4. Keep the entire "## Coordinator Prompt" section intact (all orchestration logic) - it becomes the prompt text passed to /ralph-loop
    5. Update the "DESIGN NOTE: Prompt Duplication" comment to explain ralph-loop re-injection replaces stop-watcher continuation
    6. Update the frontmatter `allowed-tools` to include `Skill` if not already present
    7. Remove the "## Output on Start" section at the end (ralph-loop handles this)
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md invokes /ralph-loop with coordinator prompt instead of outputting it directly
  - **Verify**: `grep -q 'ralph-loop' plugins/ralph-specum/commands/implement.md && grep -q 'completion-promise' plugins/ralph-specum/commands/implement.md && grep -q 'ALL_TASKS_COMPLETE' plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Commit**: `feat(implement): invoke ralph-loop instead of direct prompt output`
  - _Requirements: FR-1, FR-2, AC-1.1, AC-1.2, AC-1.3, AC-1.4_
  - _Design: Component 1_

- [ ] 1.4 [VERIFY] Quality checkpoint: implement.md structure
  - **Do**: Verify implement.md has valid structure with Ralph Wiggum integration
  - **Verify**: `head -10 plugins/ralph-specum/commands/implement.md | grep -q "^---" && grep -q "ralph-loop" plugins/ralph-specum/commands/implement.md && grep -q "COORDINATOR" plugins/ralph-specum/commands/implement.md && grep -q "spec-executor" plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Done when**: Frontmatter present, ralph-loop invocation present, coordinator logic present
  - **Commit**: (none unless fixes needed)

- [x] 1.5 Update cancel.md to call /cancel-ralph
  - **Do**: Add Ralph Wiggum loop cancellation before existing file cleanup.
    1. Add step to invoke `/cancel-ralph` via Skill tool BEFORE deleting state files
    2. Add note that /cancel-ralph may fail silently if no active Ralph loop (this is OK)
    3. Keep ALL existing cleanup logic: delete .ralph-state.json, remove spec directory, clear .current-spec, update Spec Index
    4. Update output message to include "Stopped Ralph loop" line
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: cancel.md calls /cancel-ralph before file cleanup
  - **Verify**: `grep -q 'cancel-ralph' plugins/ralph-specum/commands/cancel.md && grep -q '.ralph-state.json' plugins/ralph-specum/commands/cancel.md && echo "PASS"`
  - **Commit**: `feat(cancel): add /cancel-ralph invocation for dual cleanup`
  - _Requirements: FR-3, AC-2.1, AC-2.2, AC-2.3, AC-2.4_
  - _Design: Component 3_

- [ ] 1.6 [VERIFY] POC Checkpoint: structural validation
  - **Do**: Verify all three components are structurally correct
  - **Verify**: `grep -q 'ralph-loop' plugins/ralph-specum/commands/implement.md && grep -q 'cancel-ralph' plugins/ralph-specum/commands/cancel.md && ! grep -q 'Continue spec:' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "POC PASS"`
  - **Done when**: implement.md uses ralph-loop, cancel.md uses cancel-ralph, stop-watcher.sh is passive
  - **Commit**: `feat(ralph-specum): complete POC - Ralph Wiggum integration`

## Phase 2: Refactoring

Clean up code, update documentation, bump version.

- [x] 2.1 Bump version to 4.0.0 in both manifests
  - **Do**: Update version in plugin.json and marketplace.json
    1. Update `plugins/ralph-specum/.claude-plugin/plugin.json` version from "3.1.1" to "4.0.0"
    2. Update `.claude-plugin/marketplace.json` ralph-specum version from "3.1.1" to "4.0.0"
    3. Verify both versions match
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 4.0.0
  - **Verify**: `grep -q '"version": "4.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"version": "4.0.0"' .claude-plugin/marketplace.json && echo "PASS"`
  - **Commit**: `chore(version): bump to v4.0.0 - re-introduce Ralph Wiggum dependency`
  - _Requirements: FR-9, AC-6.1, AC-6.2, AC-6.3_
  - _Design: Component 4_

- [x] 2.2 Update README.md with Ralph Wiggum dependency
  - **Do**: Update README to document the Ralph Wiggum dependency and breaking change.
    1. Update the description line from "Self-contained execution loop. No external dependencies." to mention Ralph Wiggum dependency
    2. Add "Requirements" subsection in Installation listing Ralph Wiggum as a required dependency
    3. Add install command: `/plugin install ralph-wiggum@claude-plugins-official`
    4. Add "Breaking Changes in v4.0.0" section documenting the dependency requirement
    5. Update Troubleshooting section with "Ralph Wiggum not found" error resolution
  - **Files**: `README.md`
  - **Done when**: README documents Ralph Wiggum dependency with install instructions
  - **Verify**: `grep -q 'ralph-wiggum@claude-plugins-official' README.md && grep -q '4.0.0' README.md && echo "PASS"`
  - **Commit**: `docs(readme): document Ralph Wiggum dependency and v4.0.0 breaking change`
  - _Requirements: FR-7, AC-4.1, AC-4.2_
  - _Design: Component 4_

- [x] 2.3 Update CLAUDE.md with dependency information
  - **Do**: Update the project CLAUDE.md to reflect Ralph Wiggum dependency.
    1. Update the "Dependencies" section to list Ralph Wiggum as required
    2. Update the "Execution Flow" section description to mention ralph-loop
    3. Add note in "Key Files" about the dependency relationship
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md accurately describes Ralph Wiggum dependency
  - **Verify**: `grep -q 'ralph-wiggum' CLAUDE.md && grep -q 'ralph-loop' CLAUDE.md && echo "PASS"`
  - **Commit**: `docs(claude-md): update for Ralph Wiggum dependency`
  - _Requirements: AC-4.4_
  - _Design: Component 4_

- [ ] 2.4 [VERIFY] Quality checkpoint: documentation and version
  - **Do**: Verify all documentation and version changes are consistent
  - **Verify**: `grep -q '"version": "4.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"version": "4.0.0"' .claude-plugin/marketplace.json && grep -q 'ralph-wiggum' README.md && grep -q 'ralph-wiggum' CLAUDE.md && echo "PASS"`
  - **Done when**: All documentation and version files consistent
  - **Commit**: (none unless fixes needed)

## Phase 3: Testing

Update bats tests for passive stop-watcher behavior.

- [x] 3.1 Update stop-hook.bats for passive behavior
  - **Do**: Modify stop-hook tests to verify stop-watcher.sh is passive (no loop control output).
    1. Read current tests/stop-hook.bats to understand existing test structure
    2. Update tests that check for continuation prompt output to instead verify NO output
    3. Keep tests for: silent exit on no state, silent exit on wrong phase, silent exit on completion, corrupt JSON handling, missing jq handling
    4. Add test: "outputs nothing to stdout when tasks remain" (verify passive behavior)
    5. Keep tests for logging to stderr
    6. Remove or update tests that assert continuation prompt content
  - **Files**: `tests/stop-hook.bats`
  - **Done when**: All stop-hook tests verify passive behavior, none expect continuation prompts
  - **Verify**: `bats tests/stop-hook.bats`
  - **Commit**: `test(stop-hook): update tests for passive stop-watcher behavior`
  - _Requirements: FR-8, AC-5.1, AC-5.2_
  - _Design: Component 2_

- [x] 3.2 Update state-management.bats if needed
  - **Do**: Review and update state management tests for compatibility.
    1. Read current tests/state-management.bats
    2. Verify tests do not depend on stop-watcher loop control
    3. Update any tests that assume self-contained loop behavior
    4. Add test for .claude/ralph-loop.local.md coexistence if applicable
  - **Files**: `tests/state-management.bats`
  - **Done when**: State management tests pass with Ralph Wiggum integration
  - **Verify**: `bats tests/state-management.bats`
  - **Commit**: `test(state): update state management tests for Ralph Wiggum integration`
  - _Requirements: AC-5.3_

- [ ] 3.3 Run all bats tests
  - **Do**: Execute full test suite to verify no regressions.
    1. Run `bats tests/` to execute all test files
    2. If any tests fail, fix the issues
    3. Verify all tests pass
  - **Files**: `tests/`
  - **Done when**: All bats tests pass (exit code 0)
  - **Verify**: `bats tests/`
  - **Commit**: `fix(tests): address test failures` (if needed)
  - _Requirements: NFR-1, AC-5.3_

- [ ] 3.4 [VERIFY] Quality checkpoint: all tests green
  - **Do**: Verify all tests pass and no regressions
  - **Verify**: `bats tests/ && echo "ALL TESTS PASS"`
  - **Done when**: All tests pass
  - **Commit**: (none unless fixes needed)

## Phase 4: Quality Gates

- [ ] 4.1 Run shellcheck on all scripts
  - **Do**: Lint all shell scripts for quality.
    1. Run shellcheck on hooks/scripts/*.sh
    2. Fix any warnings/errors introduced by changes
    3. Verify all scripts pass
  - **Files**: `plugins/ralph-specum/hooks/scripts/*.sh`
  - **Done when**: All scripts pass shellcheck
  - **Verify**: `shellcheck plugins/ralph-specum/hooks/scripts/*.sh && echo "PASS"`
  - **Commit**: `fix: address shellcheck warnings` (if needed)
  - _Requirements: NFR-2_

- [ ] 4.2 [VERIFY] Local quality check
  - **Do**: Run all quality checks locally
    1. Run bats tests: `bats tests/`
    2. Run shellcheck: `shellcheck plugins/ralph-specum/hooks/scripts/*.sh`
    3. Verify Ralph Wiggum references present: `grep -r "ralph-loop" plugins/ralph-specum/commands/implement.md`
    4. Verify version consistency: both manifests at 4.0.0
  - **Verify**: `bats tests/ && shellcheck plugins/ralph-specum/hooks/scripts/*.sh && grep -q '"version": "4.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo "ALL QUALITY CHECKS PASS"`
  - **Done when**: All quality commands pass
  - **Commit**: `fix: address any final quality issues` (if needed)

- [ ] 4.3 Create PR and verify CI
  - **Do**: Push branch and create PR with gh CLI.
    1. Verify not on main/default branch; if on main, create branch `feat/return-ralph-wiggum`
    2. Push branch: `git push -u origin HEAD`
    3. Create PR with title, summary, breaking change note, and test plan
    4. Wait for CI: `gh pr checks --watch`
  - **Done when**: PR created and CI passing
  - **Verify**: `gh pr view --json url -q .url`
  - **Commit**: None (PR creation only)
  - _Requirements: FR-10, NFR-2, AC-5.4_

## Notes

- **POC shortcuts taken**: No runtime testing of actual /ralph-loop invocation (markdown-only plugin). Dependency check relies on Skill tool detection pattern.
- **Production TODOs**: Monitor for hook conflict edge cases between Ralph Wiggum stop-hook and our stop-watcher.sh. Consider if max-iterations=N bug affects us (use space syntax).
- **Key risk**: Hook execution order is not guaranteed by Claude Code. If our stop-watcher outputs before Ralph Wiggum's hook, it could interfere. Mitigated by making stop-watcher completely passive (no stdout output).
- **Manual verification required**: Actual Ralph Wiggum loop behavior must be tested by running the plugin in Claude Code with Ralph Wiggum installed.
