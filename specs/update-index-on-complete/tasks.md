---
generated: auto
---

# Tasks: Update Index on Spec Completion

## Phase 1: Make It Work (POC)

Focus: Add index update calls to both ALL_TASKS_COMPLETE detection paths in stop-watcher.sh.

- [x] 1.1 Add index update to primary ALL_TASKS_COMPLETE detection path
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. In the primary detection block (line ~70-75), insert `"$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true` between the comment about state file cleanup (line 73) and `exit 0` (line 74)
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: Primary ALL_TASKS_COMPLETE block calls update-spec-index.sh before exit 0
  - **Verify**: `grep -A2 'ALL_TASKS_COMPLETE detected in transcript"' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'update-spec-index.sh' && echo PASS`
  - **Commit**: `feat(ralph-specum): update spec index on ALL_TASKS_COMPLETE (primary path)`
  - _Requirements: FR-1, FR-3, FR-4, AC-1.1_
  - _Design: stop-watcher.sh Primary path_

- [x] 1.2 Add index update to fallback ALL_TASKS_COMPLETE detection path
  - **Do**:
    1. In the fallback detection block (line ~77-80), insert `"$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true` before `exit 0`
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: Fallback ALL_TASKS_COMPLETE block calls update-spec-index.sh before exit 0
  - **Verify**: `grep -A2 'ALL_TASKS_COMPLETE detected in transcript (tail-end)' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'update-spec-index.sh' && echo PASS`
  - **Commit**: `feat(ralph-specum): update spec index on ALL_TASKS_COMPLETE (fallback path)`
  - _Requirements: FR-2, FR-3, FR-4, AC-1.3_
  - _Design: stop-watcher.sh Fallback path_

- [x] 1.3 [VERIFY] Verify both paths have index update and script structure is valid
  - **Do**:
    1. Verify both ALL_TASKS_COMPLETE paths call update-spec-index.sh
    2. Verify error suppression pattern (`2>/dev/null || true`) is present on both calls
    3. Verify `$SCRIPT_DIR` is used for path resolution on both calls
    4. Run bash syntax check on modified script
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -c 'update-spec-index.sh.*--quiet' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q '2' && echo PASS`
  - **Done when**: Script has valid bash syntax, both paths contain the index update call with correct error suppression
  - **Commit**: None

## Phase 4: Quality Gates

- [x] 4.1 Bump plugin version in plugin.json and marketplace.json
  - **Do**:
    1. Bump version in `plugins/ralph-specum/.claude-plugin/plugin.json` from `4.4.0` to `4.5.0` (minor: new feature)
    2. Bump version in `.claude-plugin/marketplace.json` for the ralph-specum entry from `4.4.0` to `4.5.0`
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files show version `4.5.0`
  - **Verify**: `grep -q '"4.5.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"4.5.0"' .claude-plugin/marketplace.json && echo PASS`
  - **Commit**: `chore(ralph-specum): bump version to 4.5.0`
  - _Requirements: Version bump required per CLAUDE.md_

- [x] 4.2 [VERIFY] Final verification: script syntax + AC checklist
  - **Do**:
    1. Verify bash syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. AC-1.1: Primary path calls update-spec-index.sh before exit 0
    3. AC-1.2: Both calls use `2>/dev/null || true` (non-blocking)
    4. AC-1.3: Both detection paths have the call
    5. AC-2.1: Script still ends primary/fallback blocks with `exit 0`
    6. AC-2.2: implement.md Section 10 is NOT modified (defense in depth preserved)
    7. Verify version bumps are consistent
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -c 'update-spec-index.sh.*--quiet.*2>/dev/null.*|| true' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q '2' && grep -q '"4.5.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"4.5.0"' .claude-plugin/marketplace.json && echo ALL_AC_PASS`
  - **Done when**: All acceptance criteria verified via automated checks
  - **Commit**: None

## Phase 5: PR Lifecycle

- [x] 5.1 Create PR
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Stage and push changes
    3. Create PR via `gh pr create`
  - **Verify**: `gh pr view --json state -q '.state' | grep -q 'OPEN' && echo PASS`
  - **Done when**: PR is open and targeting main
  - **Commit**: None

- [x] 5.2 [VERIFY] CI pipeline passes
  - **Do**: Monitor CI checks on the PR
  - **Verify**: `gh pr checks | grep -v 'pass\|✓' | wc -l | grep -q '^0$' && echo PASS`
  - **Done when**: All CI checks green
  - **Commit**: None (fix and push if CI fails)

## Notes

- **Scope**: 2 lines added to stop-watcher.sh + version bump. No new files, no new components.
- **Error handling**: `2>/dev/null || true` ensures index update failures never block spec completion.
- **Idempotency**: update-spec-index.sh rebuilds from scratch, so double-calls (hook + coordinator) are safe.
- **Not modified**: implement.md Section 10 index call kept as defense in depth per AC-2.2.
