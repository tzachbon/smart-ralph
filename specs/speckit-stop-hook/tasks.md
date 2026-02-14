---
spec: speckit-stop-hook
phase: tasks
total_tasks: 12
created: 2026-02-14
generated: auto
---

# Tasks: speckit-stop-hook

## Phase 1: Make It Work (POC)

Focus: Get the self-contained loop controller working end-to-end. Skip tests, accept direct port approach.

- [x] 1.1 Rewrite stop-watcher.sh as self-contained loop controller
  - **Do**: Replace the current 56-line passive watcher with a full loop controller. Port the logic from `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` with these adaptations:
    1. Remove path-resolver sourcing (lines 22-25 of specum) — use fixed `.specify/` path instead
    2. Read `.specify/.current-feature` instead of calling `ralph_resolve_current`
    3. State file at `.specify/specs/$FEATURE_NAME/.speckit-state.json` instead of `$SPEC_PATH/.ralph-state.json`
    4. Settings file at `.claude/ralph-speckit.local.md` instead of `ralph-specum.local.md`
    5. Log prefix `[ralph-speckit]` instead of `[ralph-specum]`
    6. Continuation prompt references speckit paths/commands (`/speckit:implement`, `/speckit:cancel`)
    7. Include: settings check, race condition handling, transcript detection, corrupt JSON handling, global iteration limit, stop_hook_active guard, JSON continuation output, temp file cleanup
  - **Files**: `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh is ~160 lines, reads speckit state, outputs JSON `{decision, reason, systemMessage}` when tasks remain
  - **Verify**: `bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh` (syntax check passes)
  - **Commit**: `feat(speckit): rewrite stop-watcher as self-contained loop controller`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-15_
  - _Design: Component A_

- [ ] 1.2 Update implement.md to remove ralph-loop dependency
  - **Do**: Modify implement.md to output the coordinator prompt directly:
    1. Remove "Ralph Loop Dependency Check" section (lines 13-19)
    2. Remove "Invoke Ralph Loop" section — specifically: Step 1 (write .coordinator-prompt.md) and Step 2 (invoke ralph-loop skill)
    3. Replace with "Start Execution" section that says: "After writing the state file, output the coordinator prompt below. This starts the execution loop. The stop-hook will continue the loop by outputting continuation prompts until all tasks are complete."
    4. Add design note about prompt duplication (matching specum pattern from `plugins/ralph-specum/commands/implement.md:116-121`)
    5. Update "Output on Start" to remove ralph-loop references
    6. Keep the full coordinator prompt section unchanged (it's the source of truth)
  - **Files**: `plugins/ralph-speckit/commands/implement.md`
  - **Done when**: No references to `ralph-loop`, `ralph-wiggum`, or `.coordinator-prompt.md` remain in implement.md
  - **Verify**: `grep -c 'ralph-loop\|ralph-wiggum\|coordinator-prompt' plugins/ralph-speckit/commands/implement.md` returns 0
  - **Commit**: `feat(speckit): remove ralph-loop dependency from implement command`
  - _Requirements: FR-9, FR-10, FR-11_
  - _Design: Component B_

- [ ] 1.3 Update cancel.md for self-contained cancellation
  - **Do**: Remove external skill dependency from cancel.md:
    1. Remove the `ralph-wiggum:cancel-ralph` skill invocation (line 33-34 area)
    2. Replace cleanup step 1 with just: "Delete state file" (direct `rm`)
    3. Update output template: change `[x] Stopped Ralph Loop loop (/cancel-ralph)` to `[x] Removed .speckit-state.json`
    4. Keep: state file deletion, .progress.md preservation, display of state before cancellation
  - **Files**: `plugins/ralph-speckit/commands/cancel.md`
  - **Done when**: No references to `ralph-wiggum`, `cancel-ralph`, or `Ralph Loop` remain
  - **Verify**: `grep -c 'ralph-wiggum\|cancel-ralph\|Ralph Loop' plugins/ralph-speckit/commands/cancel.md` returns 0
  - **Commit**: `feat(speckit): self-contained cancel without external plugin`
  - _Requirements: FR-12_
  - _Design: Component C_

- [ ] 1.4 Update state schema for forward compatibility
  - **Do**: Modify speckit-state.schema.json:
    1. Change `"additionalProperties": false` to `"additionalProperties": true`
    2. Add `recoveryMode` property: `{"type": "boolean", "default": false, "description": "Enable iterative failure recovery"}`
    3. Add `maxFixTasksPerOriginal` property: `{"type": "integer", "default": 3, "minimum": 1, "description": "Max fix tasks per original failed task"}`
    4. Add `fixTaskMap` property: `{"type": "object", "default": {}, "description": "Tracks fix task attempts per original task"}`
  - **Files**: `plugins/ralph-speckit/schemas/speckit-state.schema.json`
  - **Done when**: Schema validates existing state files AND allows new fields
  - **Verify**: `echo '{"featureId":"001","name":"test","basePath":".specify/specs/001-test","phase":"execution","taskIndex":0,"totalTasks":5,"taskIteration":1,"maxTaskIterations":5,"globalIteration":1,"maxGlobalIterations":100,"awaitingApproval":false,"recoveryMode":false}' | jq .` succeeds
  - **Commit**: `feat(speckit): update state schema for forward compatibility`
  - _Requirements: FR-13_
  - _Design: Component D_

- [ ] 1.5 Bump version to 1.0.0
  - **Do**: Update version in both manifest files:
    1. `plugins/ralph-speckit/.claude-plugin/plugin.json`: change `"version": "0.4.0"` to `"version": "1.0.0"`
    2. `.claude-plugin/marketplace.json`: change ralph-speckit entry `"version": "0.4.0"` to `"version": "1.0.0"`
  - **Files**: `plugins/ralph-speckit/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 1.0.0 for ralph-speckit
  - **Verify**: `jq -r '.version' plugins/ralph-speckit/.claude-plugin/plugin.json && jq -r '.plugins[] | select(.name=="ralph-speckit") | .version' .claude-plugin/marketplace.json` both return 1.0.0
  - **Commit**: `chore(speckit): bump version to 1.0.0 for self-contained execution`
  - _Requirements: FR-14_
  - _Design: Component E_

- [ ] 1.6 POC Checkpoint
  - **Do**: Verify the stop-watcher produces valid JSON output end-to-end:
    1. Create a temp directory with `.specify/.current-feature` and `.specify/specs/test/.speckit-state.json`
    2. Pipe `{"cwd": "<tmpdir>"}` into the stop-watcher script
    3. Verify stdout contains valid JSON with `decision`, `reason`, `systemMessage`
    4. Verify implement.md and cancel.md have no external plugin references
  - **Done when**: Manual end-to-end test passes — stop-watcher outputs valid JSON, implement.md and cancel.md are self-contained
  - **Verify**: Create temp state, pipe to stop-watcher, validate JSON output with jq
  - **Commit**: `feat(speckit): complete POC for self-contained execution loop`

## Phase 2: Refactoring

After POC validated, ensure code quality and consistency.

- [ ] 2.1 Align stop-watcher comments and structure with specum
  - **Do**: Review the new stop-watcher.sh and ensure:
    1. Header comment matches specum pattern (describes all 3 responsibilities)
    2. Section comments are clear (settings check, race condition, transcript detection, etc.)
    3. DESIGN NOTE comment about prompt duplication is present
    4. Variable naming is consistent (FEATURE_NAME not SPEC_NAME, etc.)
    5. Error messages reference speckit commands consistently
  - **Files**: `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
  - **Done when**: Code is well-commented, consistent naming throughout
  - **Verify**: `bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh` passes
  - **Commit**: `refactor(speckit): align stop-watcher comments and structure`
  - _Design: Architecture_

- [ ] 2.2 Verify implement.md coordinator prompt consistency
  - **Do**: Ensure the coordinator prompt in implement.md is internally consistent:
    1. All references use `.specify/specs/$feature/` paths (not `./specs/`)
    2. State file references use `.speckit-state.json` (not `.ralph-state.json`)
    3. Completion signal references `ALL_TASKS_COMPLETE`
    4. Task delegation references `spec-executor` and `qa-engineer` agents
    5. Error messages reference `/speckit:implement` and `/speckit:cancel`
  - **Files**: `plugins/ralph-speckit/commands/implement.md`
  - **Done when**: No stale specum references remain in implement.md
  - **Verify**: `grep -c 'ralph-specum\|\.ralph-state\|/ralph-specum' plugins/ralph-speckit/commands/implement.md` returns 0
  - **Commit**: `refactor(speckit): verify implement.md internal consistency`
  - _Design: Component B_

## Phase 3: Testing

- [ ] 3.1 Create speckit test helper setup.bash
  - **Do**: Create `tests/speckit-helpers/setup.bash` adapted from `tests/helpers/setup.bash`:
    1. Point STOP_WATCHER_SCRIPT to `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
    2. Remove PATH_RESOLVER_SCRIPT export (speckit doesn't use it)
    3. `setup()`: create `.specify/specs/test-feature/` and `.specify/.current-feature`
    4. `create_state_file()`: write `.speckit-state.json` with speckit fields (featureId, name, basePath)
    5. `create_settings_file()`: write `.claude/ralph-speckit.local.md`
    6. `_extract_json_from_output()`: filter `[ralph-speckit]` not `[ralph-specum]`
    7. Keep all assertion helpers unchanged
    8. Keep transcript helpers unchanged
  - **Files**: `tests/speckit-helpers/setup.bash`
  - **Done when**: Helper file exists with speckit-adapted directory structure and state creation
  - **Verify**: `bash -n tests/speckit-helpers/setup.bash` passes
  - **Commit**: `test(speckit): add test helpers for speckit stop-watcher`
  - _Requirements: NFR-4_
  - _Design: Component G_

- [ ] 3.2 Create speckit-stop-hook.bats test suite
  - **Do**: Create `tests/speckit-stop-hook.bats` mirroring `tests/stop-hook.bats`:
    1. Load `speckit-helpers/setup.bash`
    2. Port all test cases, adapting for speckit paths:
       - No state file → exits silently
       - Non-execution phase → exits silently
       - taskIndex >= totalTasks → exits silently
       - Tasks remain → outputs JSON continuation prompt
       - Corrupt JSON → outputs error JSON
       - Missing jq → exits gracefully
       - Invalid hook input → exits gracefully
       - Plugin disabled via settings → exits silently
       - stop_hook_active guard → exits silently
       - JSON has all three required fields
       - Max iterations error → exits cleanly with stderr
       - Transcript ALL_TASKS_COMPLETE detection
    3. Update assertions: `ralph-speckit` prefix, `Continue feature:` instead of `Continue spec:`
  - **Files**: `tests/speckit-stop-hook.bats`
  - **Done when**: All test cases pass: `bats tests/speckit-stop-hook.bats`
  - **Verify**: `bats tests/speckit-stop-hook.bats`
  - **Commit**: `test(speckit): add stop-watcher test suite`
  - _Requirements: NFR-4_
  - _Design: Component F_

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Run all quality checks locally:
    1. `bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh` (syntax)
    2. `bats tests/speckit-stop-hook.bats` (speckit tests)
    3. `bats tests/stop-hook.bats` (ensure specum tests still pass — no regression)
    4. Verify no `ralph-loop` or `ralph-wiggum` references in speckit plugin: `grep -r 'ralph-loop\|ralph-wiggum' plugins/ralph-speckit/`
    5. Verify version is 1.0.0 in both manifest files
  - **Verify**: All commands pass with exit code 0
  - **Done when**: All quality checks pass, no regressions
  - **Commit**: `fix(speckit): address quality issues` (if needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**: Push branch, create PR with gh CLI
  - **Verify**: `gh pr checks --watch` all green
  - **Done when**: PR ready for review

## Notes

- **POC shortcuts taken**: Tests deferred to Phase 3; stop-watcher is a direct port with path substitutions
- **Production TODOs**: Consider adding SessionStart hook for speckit (like specum has) in a follow-up
- **Key adaptation**: speckit uses `.specify/.current-feature` + `.speckit-state.json` vs specum's `specs/.current-spec` + `.ralph-state.json`. No path-resolver needed since speckit has a fixed directory structure.
