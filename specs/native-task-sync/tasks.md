# Tasks: native-task-sync

## Phase 1: Make It Work (POC)

- [x] 1.1 Add native sync state fields to implement.md
  - **Do**: In implement.md Step 3, add `nativeTaskMap: {}`, `nativeSyncEnabled: true`, `nativeSyncFailureCount: 0` to the jq merge pattern that initializes .ralph-state.json. Add these fields to the "Preserved fields" documentation comment. Update the example JSON block to include these fields.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: The jq merge in Step 3 includes all 3 new fields. Backward compatibility note added.
  - **Verify**: Read implement.md and confirm the 3 fields appear in the merge pattern and example JSON
  - **Commit**: `feat(native-sync): add sync state fields to implement.md`

- [x] 1.2 Add batch push strategy to coordinator-pattern.md
  - **Do**: Add a "## Git Push Strategy" section to coordinator-pattern.md (after commit discipline reference or in the coordinator prompt area). The section instructs the coordinator to NOT push after every commit. Instead: push after completing each phase, push after every 5 commits if within a long phase, push before creating a PR, push when awaitingApproval is set. Also update the stop-hook continuation prompt's Resume section to include "Do NOT push after every commit - batch pushes per phase or every 5 commits."
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`, `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Git Push Strategy section exists in coordinator-pattern.md and stop-hook resume mentions batch pushing
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "PASS"` and read coordinator-pattern.md for the new section
  - **Commit**: `feat(native-sync): add batch push strategy to coordinator`

- [x] 1.3 Add Initial Setup sync section to coordinator-pattern.md
  - **Do**: Add a new "## Native Task Sync - Initial Setup" section after "Read State" and before "Check Completion" in coordinator-pattern.md. This section: checks nativeSyncEnabled, parses all tasks from tasks.md, creates TaskCreate for each task with subject (FR-11 format), description (first 1-2 sub-items), and activeForm (FR-12 format). Marks already-completed tasks as completed. Stores nativeTaskMap in state. On failure, sets nativeSyncEnabled to false.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: The Initial Setup section exists with complete logic for parsing tasks.md and creating native tasks
  - **Verify**: Read coordinator-pattern.md and confirm the section exists between "Read State" and "Check Completion"
  - **Commit**: `feat(native-sync): add initial task creation to coordinator`

- [x] 1.4 Add Pre-Delegation and Post-Verification sync sections
  - **Do**: Add two new sections to coordinator-pattern.md: (1) "## Native Task Sync - Bidirectional Check" before Task Delegation that reconciles tasks.md [x] marks with native task status; (2) "## Native Task Sync - Pre-Delegation" before Task Delegation that marks current task in_progress with activeForm; (3) "## Native Task Sync - Post-Verification" after verification layers that marks task completed. Each section checks nativeSyncEnabled first and skips if false.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: All 3 sections exist at the correct positions in coordinator-pattern.md
  - **Verify**: Read coordinator-pattern.md and confirm 3 new sections exist at correct integration points
  - **Commit**: `feat(native-sync): add pre-delegation, bidirectional, and post-verification sync`

- [x] 1.5 [VERIFY] Quality check: validate modified files
  - **Do**: Verify coordinator-pattern.md is valid markdown with no broken sections. Verify implement.md jq pattern is syntactically correct. Run `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` to confirm no syntax regressions.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "PASS"`
  - **Done when**: All files pass validation
  - **Commit**: `chore(native-sync): pass quality checkpoint` (if fixes needed)

- [x] 1.6 Add sync instructions to stop-hook continuation prompt
  - **Do**: In stop-watcher.sh, add `NATIVE_SYNC` variable extraction from state file (around line 144): `NATIVE_SYNC=$(jq -r '.nativeSyncEnabled // true' "$STATE_FILE" 2>/dev/null || echo "true")`. Add NativeSync to the State line in the continuation prompt. Update the Resume section in REASON to include sync steps: (a) rebuild nativeTaskMap if empty, (b) TaskUpdate current task to in_progress, (c) after TASK_COMPLETE: TaskUpdate to completed, (d) on completion: finalize all native tasks.
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh extracts NATIVE_SYNC, includes it in State line, and Resume section has sync instructions
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "PASS"`
  - **Commit**: `feat(native-sync): add sync instructions to stop-hook continuation prompt`

- [x] 1.7 Add Failure, Modification, Completion, and Parallel sync sections
  - **Do**: Add 4 remaining sync sections to coordinator-pattern.md: (1) "## Native Task Sync - Failure" in failure handling path - updates task subject with retry count; (2) "## Native Task Sync - Modification" in modification request handler - handles SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP by creating/updating native tasks and extending nativeTaskMap; (3) "## Native Task Sync - Completion" before ALL_TASKS_COMPLETE - ensures all native tasks show completed; (4) "## Native Task Sync - Parallel" in parallel execution section - marks all group tasks in_progress simultaneously.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: All 4 sections exist at correct positions with complete logic
  - **Verify**: Read coordinator-pattern.md and confirm all 8 sync sections total exist (Initial Setup + Bidirectional + Pre-Delegation + Post-Verification + Failure + Modification + Completion + Parallel)
  - **Commit**: `feat(native-sync): add failure, modification, completion, and parallel sync sections`

- [x] 1.8 [VERIFY] POC checkpoint: end-to-end validation
  - **Do**: Verify all changes are coherent: (1) implement.md initializes 3 new state fields; (2) coordinator-pattern.md has 8 sync sections at correct integration points; (3) stop-watcher.sh extracts NATIVE_SYNC and includes sync instructions in resume prompt. Read all 3 files and verify sync logic flow is complete from init through completion.
  - **Verify**: Read all 3 modified files and confirm the full sync flow: init -> bidirectional check -> pre-delegation -> post-verification -> failure -> modification -> completion -> parallel
  - **Done when**: All 3 files modified, all 8 sync sections present, stop-hook has sync in resume
  - **Commit**: `feat(native-sync): complete POC`

## Phase 2: Refactoring

- [x] 2.1 Clean up sync section formatting and consistency
  - **Do**: Review all 8 sync sections in coordinator-pattern.md for consistent formatting: (1) Each section starts with nativeSyncEnabled check; (2) Each section uses consistent nativeTaskMap lookup pattern; (3) Error handling is uniform (log warning, continue); (4) Ensure consistent use of FR-11 subject format and FR-12 activeForm format across all sections. Fix any inconsistencies found.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: All 8 sections follow consistent patterns for sync checks, lookups, and error handling
  - **Verify**: Read coordinator-pattern.md and confirm consistent formatting across all sync sections
  - **Commit**: `refactor(native-sync): normalize sync section formatting`

- [x] 2.2 Add graceful degradation counter logic
  - **Do**: In the coordinator-pattern.md sync sections, ensure the nativeSyncFailureCount logic is explicit: (1) On successful TaskCreate/TaskUpdate: reset counter to 0 in state; (2) On failure: increment counter, if >= 3 set nativeSyncEnabled to false and log to .progress.md; (3) Add this pattern to the Initial Setup section (most likely to fail with many calls) and document that other sections inherit the same pattern.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Failure counter logic is explicit with reset-on-success and disable-at-3 behavior
  - **Verify**: Read coordinator-pattern.md and confirm failure counter logic in Initial Setup section
  - **Commit**: `refactor(native-sync): add explicit failure counter logic`

- [ ] 2.3 [VERIFY] Quality check: all files coherent
  - **Do**: Run `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`. Read coordinator-pattern.md and verify section ordering is correct (sync sections don't break existing flow). Verify implement.md jq merge pattern.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "PASS"`
  - **Done when**: All files pass validation, section ordering is correct
  - **Commit**: `chore(native-sync): pass quality checkpoint` (if fixes needed)

## Phase 3: Quality Gates

- [ ] 3.1 Bump plugin version
  - **Do**: Bump the patch version in both `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` for the ralph-specum entry. This is required per CLAUDE.md for any plugin change.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Version bumped in both files
  - **Verify**: Read both files and confirm version numbers match and are higher than current
  - **Commit**: `chore(ralph-specum): bump version for native-task-sync feature`

- [ ] 3.2 [VERIFY] Final validation: V4 Full local CI
  - **Do**: Run `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` to validate bash syntax. Validate all JSON files: `jq empty .claude-plugin/marketplace.json && jq empty plugins/ralph-specum/.claude-plugin/plugin.json`. Read all 3 modified files one final time to verify correctness.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && jq empty .claude-plugin/marketplace.json && jq empty plugins/ralph-specum/.claude-plugin/plugin.json && echo "ALL PASS"`
  - **Done when**: All validation commands pass
  - **Commit**: `chore(native-sync): pass final validation` (if fixes needed)

## Phase 4: PR Lifecycle

- [ ] 4.1 Create pull request
  - **Do**: Create a PR with title "feat(ralph-specum): add native Claude Code task sync to implement loop". Include summary of changes: 3 files modified, 8 sync integration points, graceful degradation, bidirectional sync. Push branch and create PR via `gh pr create`.
  - **Files**: None (git operations only)
  - **Done when**: PR created and URL returned
  - **Verify**: `gh pr view --json url -q .url`
  - **Commit**: None (PR creation only)

- [ ] 4.2 [VERIFY] CI pipeline and review
  - **Do**: Check if CI passes. If CI fails, fix issues and push. Check for review comments, address if any.
  - **Verify**: `gh pr checks` shows all green or no CI configured
  - **Done when**: PR is ready to merge (CI green, no unresolved comments)
  - **Commit**: None (or fix commits if CI fails)
