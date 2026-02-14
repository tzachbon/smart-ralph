---
spec: fork-ralph-wiggum
phase: tasks
total_tasks: 17
created: 2026-02-14
---

# Tasks: Fix Stop Hook JSON Output Format

## Overview

Total tasks: 17
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Convert stop-watcher.sh output to JSON, add guard
2. Phase 2: Refactoring - Clean up settings, bump versions
3. Phase 3: Testing - Update all bats tests to assert JSON format
4. Phase 4: Quality Gates - Local quality check, PR creation
5. Phase 5: PR Lifecycle - CI monitoring, review resolution, final validation

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: All existing tests pass (no broken functionality)
- Modular & Reusable: Code follows project patterns, properly abstracted
- Real-World Validation: `bats tests/*.bats` passes with JSON assertions
- All Tests Pass: All bats tests green
- CI Green: All CI checks passing
- PR Ready: Pull request created, reviewed, approved
- Review Comments Resolved: All code review feedback addressed

> **Quality Checkpoints**: `bats tests/*.bats` is the only quality command for this project. Inserted every 2-3 tasks.

## Phase 1: Make It Work (POC)

Focus: Convert all 3 output blocks in stop-watcher.sh from plain text to JSON format. Add `stop_hook_active` guard. Prove the JSON output works via bats.

- [x] 1.1 Add JSON assertion helpers to test setup
  - **Do**:
    1. Open `tests/helpers/setup.bash`
    2. Add three new helper functions after the existing `assert_stderr_contains` function (after line 158):
       - `assert_json_block`: validates output is valid JSON with `decision="block"`
       - `assert_json_reason_contains`: validates JSON `reason` field contains expected text
       - `assert_json_system_message_contains`: validates JSON `systemMessage` field contains expected text
    3. Use exact implementations from design.md Component 5
  - **Files**: `tests/helpers/setup.bash`
  - **Done when**: Three new helper functions exist in setup.bash
  - **Verify**: `grep -c 'assert_json' tests/helpers/setup.bash` returns 3
  - **Commit**: `feat(stop-hook): add JSON assertion test helpers`
  - _Requirements: FR-10, AC-6.3_
  - _Design: Component 5_

- [x] 1.2 Parameterize hook input helpers with stop_hook_active
  - **Do**:
    1. Open `tests/helpers/setup.bash`
    2. Modify `create_hook_input()` (lines 64-74): add second parameter `stop_hook_active` defaulting to `false`, use `$stop_hook_active` (no quotes) in JSON output
    3. Modify `create_hook_input_with_transcript()` (lines 172-184): add third parameter `stop_hook_active` defaulting to `false`, use it in JSON output
    4. Use exact implementations from design.md Component 6
    5. IMPORTANT: Default changes from `true` to `false` -- this is intentional per design decision
  - **Files**: `tests/helpers/setup.bash`
  - **Done when**: Both functions accept `stop_hook_active` parameter with default `false`
  - **Verify**: `grep -c 'stop_hook_active.*false' tests/helpers/setup.bash` returns at least 2
  - **Commit**: `feat(stop-hook): parameterize stop_hook_active in test helpers`
  - _Requirements: FR-7, AC-3.1_
  - _Design: Component 6_

- [x] 1.3 Convert corrupt state error to JSON output
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Replace lines 90-97 (the `cat <<EOF ... EOF` block for corrupt state) with:
       - Capture the error text in `REASON` variable via heredoc
       - Output via `jq -n` with `decision: "block"`, `reason: $REASON`, `systemMessage: "Ralph-specum: corrupt state file"`
    3. Use exact implementation from design.md Component 2
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Corrupt state error outputs JSON instead of plain text
  - **Verify**: `grep -c 'jq -n' plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns at least 1
  - **Commit**: `feat(stop-hook): convert corrupt state error to JSON format`
  - _Requirements: FR-5, AC-4.1, AC-4.3_
  - _Design: Component 2_

- [x] 1.4 Convert max iterations error to JSON output
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Replace lines 112-122 (the `cat <<EOF ... EOF` block for max iterations) with:
       - Capture the error text in `REASON` variable via heredoc
       - Output via `jq -n` with `decision: "block"`, `reason: $REASON`, `systemMessage: "Ralph-specum: max iterations ($MAX_GLOBAL) reached"`
    3. Use exact implementation from design.md Component 3
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Max iterations error outputs JSON instead of plain text
  - **Verify**: `grep -c 'jq -n' plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns at least 2
  - **Commit**: `feat(stop-hook): convert max iterations error to JSON format`
  - _Requirements: FR-6, AC-4.2, AC-4.3_
  - _Design: Component 3_

- [x] 1.5 [VERIFY] Quality checkpoint: bats tests (partial)
  - **Do**: Run bats tests to check current state. Some tests will fail due to output format change -- that is expected. Verify error-path tests produce valid JSON.
  - **Verify**: `bash -c 'echo "{ invalid json here" | jq empty 2>/dev/null; echo $?'` returns non-zero (sanity check jq validates). Then run `bats tests/stop-hook.bats` and note which tests pass/fail. Error tests ("corrupt JSON", "max iterations") should now produce JSON output.
  - **Done when**: Corrupt state and max iterations tests produce JSON output (even if assertions need updating)
  - **Commit**: `chore(stop-hook): pass quality checkpoint` (only if fixes needed)

- [x] 1.6 Add stop_hook_active guard and convert continuation prompt to JSON
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Inside the `if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]` block (after line 134 where `MAX_TASK_ITER` is read), add the `stop_hook_active` guard from design.md Component 4:
       - Read `STOP_HOOK_ACTIVE` from `$INPUT` via `jq -r '.stop_hook_active // false'`
       - If `true`, log to stderr and `exit 0`
    3. Replace the `cat <<EOF ... EOF` continuation block (lines 144-160) with:
       - Capture prompt text in `REASON` variable via heredoc
       - Set `SYSTEM_MSG` variable
       - Output via `jq -n` with all 3 fields
    4. Use exact implementations from design.md Components 1 and 4
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Continuation prompt outputs JSON; `stop_hook_active=true` causes silent exit
  - **Verify**: `grep -c 'jq -n' plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns 3 (corrupt + max iter + continuation)
  - **Commit**: `feat(stop-hook): add stop_hook_active guard and JSON continuation output`
  - _Requirements: FR-1, FR-2, FR-3, FR-7, AC-1.1, AC-1.2, AC-1.3, AC-3.1, AC-3.2_
  - _Design: Components 1 and 4_

- [x] 1.7 POC Checkpoint: verify JSON output end-to-end
  - **Do**:
    1. Create a temp test workspace and state file
    2. Pipe hook input with `stop_hook_active: false` through stop-watcher.sh
    3. Verify stdout is valid JSON with `decision: "block"`
    4. Verify `reason` field contains "Continue spec"
    5. Verify `systemMessage` field is present
    6. Test with `stop_hook_active: true` and verify no output
  - **Verify**: Run inline bash validation:
    ```
    cd /tmp && mkdir -p poc-test/specs/test-spec/.claude && echo "test-spec" > poc-test/specs/.current-spec && echo '{"phase":"execution","taskIndex":0,"totalTasks":3,"taskIteration":1}' > poc-test/specs/test-spec/.ralph-state.json && echo '{"cwd":"/tmp/poc-test","stop_hook_active":false,"session_id":"test"}' | bash plugins/ralph-specum/hooks/scripts/stop-watcher.sh | jq -e '.decision == "block"' && echo "POC PASS" && rm -rf /tmp/poc-test
    ```
  - **Done when**: JSON output validates via jq, `stop_hook_active` guard works
  - **Commit**: `feat(stop-hook): complete POC - JSON output format working`
  - _Requirements: FR-1, FR-4, AC-1.1, AC-1.4_

## Phase 2: Refactoring

After POC validated, clean up configuration and version.

- [x] 2.1 Remove ralph-wiggum from settings and bump version
  - **Do**:
    1. Open `.claude/settings.json`
    2. Remove the `"ralph-wiggum@claude-plugins-official": true` line from `enabledPlugins`
    3. Open `plugins/ralph-specum/.claude-plugin/plugin.json`
    4. Change `"version": "3.1.1"` to `"version": "3.2.0"`
    5. Open `.claude-plugin/marketplace.json`
    6. Change `"version": "3.1.1"` to `"version": "3.2.0"` in the ralph-specum plugin entry
  - **Files**: `.claude/settings.json`, `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: ralph-wiggum removed from settings, both version files show 3.2.0
  - **Verify**: `jq '.enabledPlugins | has("ralph-wiggum@claude-plugins-official")' .claude/settings.json` returns `false` && `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json` returns `3.2.0` && `jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json` returns `3.2.0`
  - **Commit**: `chore(ralph-specum): remove ralph-wiggum dependency, bump to v3.2.0`
  - _Requirements: FR-8, FR-9, AC-5.1, AC-5.2_

## Phase 3: Testing

Update all bats tests to assert JSON format instead of plain text.

- [x] 3.1 Update stop-hook.bats continuation assertions to JSON
  - **Do**:
    1. Open `tests/stop-hook.bats`
    2. Update test "outputs continuation prompt when tasks remain (taskIndex=0)" (lines 74-83):
       - Replace `assert_output_contains "Continue spec: test-spec"` with `assert_json_block` + `assert_json_reason_contains "Continue spec: test-spec"`
       - Replace `assert_output_contains ".ralph-state.json"` with `assert_json_reason_contains ".ralph-state.json"`
       - Replace `assert_output_contains "spec-executor"` with `assert_json_reason_contains "spec-executor"`
       - Replace `assert_output_contains "ALL_TASKS_COMPLETE"` with `assert_json_reason_contains "ALL_TASKS_COMPLETE"`
    3. Update test "outputs continuation prompt when tasks remain (midway)" (lines 85-91):
       - Replace with `assert_json_block` + `assert_json_reason_contains "Continue spec: test-spec"`
    4. Update test "outputs continuation prompt when one task remains" (lines 93-99):
       - Replace with `assert_json_block` + `assert_json_reason_contains "Continue spec: test-spec"`
    5. Update test "continues normally when plugin is enabled via settings" (lines 191-198):
       - Replace with `assert_json_block` + `assert_json_reason_contains "Continue spec: test-spec"`
    6. Update test "continues when ALL_TASKS_COMPLETE signal not in transcript" (lines 240-256):
       - Replace `assert_output_contains "Continue spec"` with `assert_json_reason_contains "Continue spec"`
    7. Update test "handles missing transcript_path gracefully" (lines 258-269):
       - Replace `assert_output_contains "Continue spec"` with `assert_json_reason_contains "Continue spec"`
    8. Update test "handles non-existent transcript file gracefully" (lines 271-282):
       - Replace `assert_output_contains "Continue spec"` with `assert_json_reason_contains "Continue spec"`
  - **Files**: `tests/stop-hook.bats`
  - **Done when**: All continuation-related assertions use JSON helpers
  - **Verify**: `grep -c 'assert_json_block\|assert_json_reason_contains' tests/stop-hook.bats` returns at least 10
  - **Commit**: `test(stop-hook): update continuation assertions to JSON format`
  - _Requirements: FR-10, AC-6.1_
  - _Design: Test Strategy - stop-hook.bats Changes_

- [x] 3.2 Update stop-hook.bats error assertions to JSON
  - **Do**:
    1. Open `tests/stop-hook.bats`
    2. Update test "outputs error message for corrupt JSON" (lines 114-122):
       - Replace `assert_output_contains "ERROR: Corrupt state file"` with `assert_json_block` + `assert_json_reason_contains "ERROR: Corrupt state file"`
       - Replace `assert_output_contains "Recovery options"` with `assert_json_reason_contains "Recovery options"`
    3. Update test "handles corrupt JSON gracefully" (lines 105-112):
       - Replace `assert_output_not_contains "Continue spec"` with `assert_json_reason_contains "ERROR: Corrupt"` (error JSON output, not continuation)
  - **Files**: `tests/stop-hook.bats`
  - **Done when**: Error assertions use JSON helpers
  - **Verify**: `grep -c 'assert_json' tests/stop-hook.bats` returns at least 12
  - **Commit**: `test(stop-hook): update error assertions to JSON format`
  - _Requirements: FR-10, AC-6.2_
  - _Design: Test Strategy - stop-hook.bats Changes_

- [x] 3.3 [VERIFY] Quality checkpoint: bats stop-hook tests
  - **Do**: Run stop-hook.bats to verify all updated assertions pass
  - **Verify**: `bats tests/stop-hook.bats` exits 0 with all tests passing
  - **Done when**: All 24+ stop-hook tests pass (18 existing + updated assertions)
  - **Commit**: `chore(stop-hook): pass quality checkpoint` (only if fixes needed)

- [x] 3.4 Add new stop_hook_active guard tests
  - **Do**:
    1. Open `tests/stop-hook.bats`
    2. Add new test section after the "Plugin disabled" tests (after line 198):
       ```
       # =============================================================================
       # Test: stop_hook_active guard
       # =============================================================================
       ```
    3. Add test "exits silently when stop_hook_active is true":
       - `create_state_file "execution" 0 5 1`
       - Create hook input with `stop_hook_active=true`: use `create_hook_input "$TEST_WORKSPACE" true`
       - `run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"`
       - Assert `[ "$status" -eq 0 ]` and `[ -z "$output" ]`
    4. Add test "outputs JSON when stop_hook_active is false":
       - `create_state_file "execution" 0 5 1`
       - Create hook input with `stop_hook_active=false`: use `create_hook_input "$TEST_WORKSPACE" false`
       - `run bash -c "echo '$input' | bash '$STOP_WATCHER_SCRIPT'"`
       - Assert `assert_json_block` and `assert_json_reason_contains "Continue spec"`
    5. Add test "JSON output has all three required fields":
       - `create_state_file "execution" 0 5 1`
       - Run stop watcher
       - Assert `assert_json_block` + `assert_json_reason_contains "Continue spec"` + `assert_json_system_message_contains "Ralph-specum"`
    6. Add test "max iterations error is JSON format":
       - `create_state_file "execution" 2 5 1`
       - Set `globalIteration=100, maxGlobalIterations=100` via jq
       - Run stop watcher
       - Assert `assert_json_block` + `assert_json_reason_contains "Maximum global iterations"`
    7. Add test "corrupt state error still fires when stop_hook_active is true":
       - `create_corrupt_state_file`
       - Create hook input with `stop_hook_active=true`
       - Run stop watcher
       - Assert `assert_json_block` + `assert_json_reason_contains "ERROR: Corrupt"`
  - **Files**: `tests/stop-hook.bats`
  - **Done when**: 5 new tests added for guard behavior and JSON field validation
  - **Verify**: `bats tests/stop-hook.bats` exits 0
  - **Commit**: `test(stop-hook): add stop_hook_active guard and JSON field tests`
  - _Requirements: FR-7, AC-3.1, AC-3.2, AC-6.4_
  - _Design: New Tests Required_

- [x] 3.5 Update integration.bats assertions to JSON
  - **Do**:
    1. Open `tests/integration.bats`
    2. Replace ALL `assert_output_contains "Continue spec: test-spec"` with `assert_json_block` + `assert_json_reason_contains "Continue spec: test-spec"`. Affected tests:
       - "full loop completes 2-task spec" (lines 19, 27)
       - "loop handles task retry scenario" (lines 46, 54)
       - "loop terminates on state file deletion" (line 65)
       - "loop terminates on phase change" (line 83)
       - "handles switching between specs" (lines 105, 117)
       - "single task spec completes correctly" (line 132)
    3. Replace `assert_output_contains "Continue spec: other-spec"` (line 117) with `assert_json_reason_contains "Continue spec: other-spec"`
    4. Replace content assertions (lines 152, 160, 169, 176):
       - `.ralph-state.json` -> `assert_json_reason_contains ".ralph-state.json"`
       - `tasks.md` -> `assert_json_reason_contains "tasks.md"`
       - `spec-executor` -> `assert_json_reason_contains "spec-executor"`
       - `ALL_TASKS_COMPLETE` -> `assert_json_reason_contains "ALL_TASKS_COMPLETE"`
  - **Files**: `tests/integration.bats`
  - **Done when**: All integration test assertions use JSON helpers
  - **Verify**: `bats tests/integration.bats` exits 0
  - **Commit**: `test(integration): update assertions to JSON format`
  - _Requirements: FR-10, AC-6.1_
  - _Design: Test Strategy - integration.bats Changes_

- [x] 3.6 Update state-management.bats assertions to JSON
  - **Do**:
    1. Open `tests/state-management.bats`
    2. Update "stop hook uses taskIndex for continuation check" (line 294):
       - Replace `assert_output_contains "Continue spec"` with `assert_json_reason_contains "Continue spec"`
    3. Update "stop hook reads phase from state file" (line 320):
       - Replace `assert_output_contains "Continue"` with `assert_json_reason_contains "Continue"`
    4. Update "stop hook enforces maxGlobalIterations limit" (lines 351-352):
       - Replace `assert_output_contains "Maximum global iterations"` with `assert_json_block` + `assert_json_reason_contains "Maximum global iterations"`
       - Keep `assert_output_not_contains "Continue"` (still valid -- JSON reason has "Maximum" not "Continue")
    5. Update "stop hook allows execution when under maxGlobalIterations" (line 366):
       - Replace `assert_output_contains "Continue"` with `assert_json_reason_contains "Continue"`
    6. Update "maxGlobalIterations defaults to 100 when missing" (line 337):
       - Replace `assert_output_contains "Continue"` with `assert_json_reason_contains "Continue"`
  - **Files**: `tests/state-management.bats`
  - **Done when**: All state-management stop-hook assertions use JSON helpers
  - **Verify**: `bats tests/state-management.bats` exits 0
  - **Commit**: `test(state-mgmt): update stop-hook assertions to JSON format`
  - _Requirements: FR-10, AC-6.1_
  - _Design: Test Strategy - state-management.bats Changes_

- [x] 3.7 [VERIFY] Quality checkpoint: all bats tests pass
  - **Do**: Run all bats test files to verify zero regressions
  - **Verify**: `bats tests/*.bats` exits 0 with all tests passing
  - **Done when**: All tests pass (18+ existing + 5 new = 23+ total across all files)
  - **Commit**: `chore(stop-hook): pass quality checkpoint - all tests green` (only if fixes needed)
  - _Requirements: AC-6.5, AC-6.6_

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch. Branch management handled at startup. Should already be on `feat/fork-ralph-wiggum`.

- [x] 4.1 [VERIFY] Full local CI: bats tests/*.bats
  - **Do**: Run complete local CI suite (bats is the only quality command for this project)
  - **Verify**: `bats tests/*.bats` exits 0
  - **Done when**: All tests pass, zero regressions
  - **Commit**: `chore(stop-hook): pass local CI` (only if fixes needed)

- [x] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch: `git branch --show-current` (expect `feat/fork-ralph-wiggum`)
    2. If on default branch, STOP and alert user
    3. Push branch: `git push -u origin feat/fork-ralph-wiggum`
    4. Create PR: `gh pr create --title "feat(stop-hook): fix JSON output format for execution loop" --body "## Summary\n- Convert 3 plain text cat<<EOF output blocks in stop-watcher.sh to jq -n JSON format\n- Add stop_hook_active guard to prevent infinite re-invocation\n- Update all bats tests (stop-hook, integration, state-management) to assert JSON\n- Remove ralph-wiggum from settings, bump to v3.2.0\n\n## Test Plan\n- [x] All existing bats tests updated and passing\n- [x] 5 new guard/JSON field tests added\n- [ ] CI checks pass"`
  - **Verify**: `gh pr checks` shows all checks, `gh pr view --json url --jq '.url'` returns PR URL
  - **Done when**: PR created, CI running
  - **Commit**: None

## Phase 5: PR Lifecycle (Continuous Validation)

> Autonomous loop: continues until ALL completion criteria met.

- [x] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add <files> && git commit -m "fix(stop-hook): address CI failures"`
    6. Push: `git push`
    7. Repeat until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix(stop-hook): address CI failures` (as needed)

- [x] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED")'`
    2. For inline comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
    3. Implement requested changes
    4. Commit + push fixes
    5. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix(stop-hook): address review - {summary}` (per comment)

- [x] 5.3 [VERIFY] AC checklist
  - **Do**: Programmatically verify each acceptance criterion:
    1. AC-1.1: `bats tests/stop-hook.bats` passes (JSON with decision:block when tasks remain)
    2. AC-1.2: `grep -c 'assert_json_reason_contains.*Continue spec' tests/stop-hook.bats` > 0
    3. AC-1.3: `grep -c 'assert_json_system_message_contains' tests/stop-hook.bats` > 0
    4. AC-2.1-2.6: Silent exit tests pass in `bats tests/stop-hook.bats`
    5. AC-3.1-3.2: `grep 'stop_hook_active' tests/stop-hook.bats | wc -l` > 0
    6. AC-4.1-4.3: Error JSON tests pass in `bats tests/stop-hook.bats`
    7. AC-5.1: `jq '.enabledPlugins | has("ralph-wiggum@claude-plugins-official")' .claude/settings.json` returns false
    8. AC-5.2: `jq '.enabledPlugins | keys' .claude/settings.json` shows only ralph-specum and plugin-dev
    9. AC-6.1-6.6: `bats tests/*.bats` exits 0
    10. FR-9: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json` returns 3.2.0
  - **Verify**: All checks above pass
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: None significant -- the POC directly implements the final JSON format since the change is small and well-specified
- **Production TODOs**: Quick mode interaction with `stop_hook_active` guard (deferred, out of scope per design)
- **Key risk**: The `create_hook_input()` default flip from `true` to `false` affects how `run_stop_watcher()` works in all existing tests. If tests break unexpectedly, check whether a test relies on `stop_hook_active: true` suppressing output.

## Dependencies

```
1.1 (helpers) -> 1.2 (parameterize) -> 1.3-1.4 (error JSON) -> 1.6 (guard + continuation JSON) -> 1.7 (POC checkpoint)
2.1 (settings/version) - independent of Phase 1
3.1-3.6 (test updates) - depend on Phase 1 completion
4.1-4.2 (quality/PR) - depend on Phase 3
5.1-5.3 (PR lifecycle) - depend on Phase 4
```
