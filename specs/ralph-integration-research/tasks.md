---
spec: ralph-integration-research
phase: tasks
total_tasks: 16
created: 2026-01-22
---

# Tasks: Ralph Loop Dependency Removal

## Execution Context

| Decision | Response |
|----------|----------|
| Testing depth | Standard - bats-core unit tests + manual integration verification |
| Deployment | Standard CI/CD pipeline - PR with GitHub Actions tests, merge to main |

## Phase 1: Make It Work (POC)

Focus: Validate stop-hook loop logic works end-to-end. Skip tests initially.

- [ ] 1.1 [BLOCKER] Add loop logic to stop-watcher.sh
  - **Do**:
    1. Read current stop-watcher.sh (67 lines, cleanup only)
    2. Add `stop_hook_active` check at FIRST line after reading input (FR-3)
    3. Add transcript path parsing from hook input
    4. Add `ALL_TASKS_COMPLETE` detection via `grep -q` (FR-2)
    5. Add `globalIteration` tracking and `maxGlobalIterations` limit check (FR-7, FR-8)
    6. Add atomic iteration counter update (temp file + mv pattern)
    7. Add block JSON output with decision and reason (FR-1)
    8. Only block when `phase = "execution"` (FR-4)
    9. Keep existing cleanup logic at end
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Hook returns `{"decision": "block", "reason": "..."}` during execution phase and exits 0 on completion/non-execution
  - **Verify**: `echo '{"stop_hook_active": true}' | bash plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo "exit code: $?"` returns exit 0 with empty output
  - **Commit**: `feat(hooks): add loop control logic to stop-watcher.sh`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-7, FR-8, AC-2.1, AC-2.2, AC-2.3, AC-2.4_
  - _Design: Stop Hook Algorithm_

- [ ] 1.2 Modify implement.md to remove skill invocation
  - **Do**:
    1. Remove "Ralph Loop Dependency Check" section entirely (FR-5)
    2. Remove "Invoke Ralph Loop" section (Step 2: Invoke Ralph Loop Skill)
    3. Keep coordinator prompt writing to `.coordinator-prompt.md`
    4. Add `globalIteration: 1` and `maxGlobalIterations: 100` to state initialization
    5. Change final output to indicate coordinator prompt is ready (no skill invocation)
    6. Keep "Output on Start" section but update wording
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md has no references to `ralph-loop`, `ralph-wiggum`, or Skill tool invocation
  - **Verify**: `grep -c "ralph-loop\|ralph-wiggum\|Skill tool" plugins/ralph-specum/commands/implement.md` returns 0
  - **Commit**: `feat(commands): remove ralph-loop dependency from implement.md`
  - _Requirements: FR-5, AC-1.2_
  - _Design: implement.md (Modified)_

- [ ] 1.3 Modify cancel.md to remove skill invocation
  - **Do**:
    1. Remove step 1 that invokes `ralph-loop:cancel-ralph` skill (FR-6)
    2. Keep state file deletion logic
    3. Update output to remove "Stopped Ralph loop (/ralph-loop:cancel-ralph)" reference
    4. Keep `.progress.md` preservation
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: cancel.md has no references to `ralph-loop`, `cancel-ralph`, or Skill tool
  - **Verify**: `grep -c "ralph-loop\|cancel-ralph\|Skill tool" plugins/ralph-specum/commands/cancel.md` returns 0
  - **Commit**: `feat(commands): remove ralph-loop dependency from cancel.md`
  - _Requirements: FR-6, AC-3.1, AC-3.2, AC-3.3_
  - _Design: cancel.md (Modified)_

- [ ] 1.4 [VERIFY] Quality checkpoint: shellcheck && grep verification
  - **Do**: Run shellcheck on stop-watcher.sh and verify no ralph-loop references remain
  - **Verify**: `shellcheck plugins/ralph-specum/hooks/scripts/stop-watcher.sh 2>&1 | grep -v "SC" || true` exits 0; `grep -r "ralph-loop\|ralph-wiggum" plugins/ralph-specum/commands/*.md | wc -l` returns 0
  - **Done when**: No shellcheck errors and no ralph-loop references in commands
  - **Commit**: `chore(hooks): pass quality checkpoint` (only if fixes needed)

- [ ] 1.5 POC Checkpoint: Local integration test
  - **Do**:
    1. Create temp spec directory with mock state file in execution phase
    2. Create mock transcript without `ALL_TASKS_COMPLETE`
    3. Test hook returns block JSON
    4. Create mock transcript with `ALL_TASKS_COMPLETE`
    5. Test hook allows exit (no JSON, state deleted)
    6. Test `stop_hook_active=true` returns immediately
  - **Files**: None (manual verification script)
  - **Done when**: All 3 scenarios work: block when incomplete, allow when complete, allow when stop_hook_active
  - **Verify**: Create and run inline test script:
    ```bash
    TEMP=$(mktemp -d) && mkdir -p "$TEMP/specs/test" && echo "test" > "$TEMP/specs/.current-spec" && \
    echo '{"phase":"execution","taskIndex":0,"totalTasks":5,"globalIteration":1,"maxGlobalIterations":100}' > "$TEMP/specs/test/.ralph-state.json" && \
    TRANSCRIPT="$TEMP/transcript.txt" && echo "working..." > "$TRANSCRIPT" && \
    OUTPUT=$(echo "{\"stop_hook_active\":false,\"cwd\":\"$TEMP\",\"transcript_path\":\"$TRANSCRIPT\"}" | bash plugins/ralph-specum/hooks/scripts/stop-watcher.sh) && \
    echo "$OUTPUT" | grep -q '"decision": "block"' && echo "PASS: blocks incomplete" && \
    echo "ALL_TASKS_COMPLETE" >> "$TRANSCRIPT" && \
    OUTPUT2=$(echo "{\"stop_hook_active\":false,\"cwd\":\"$TEMP\",\"transcript_path\":\"$TRANSCRIPT\"}" | bash plugins/ralph-specum/hooks/scripts/stop-watcher.sh) && \
    [ -z "$OUTPUT2" ] && echo "PASS: allows complete" && \
    rm -rf "$TEMP"
    ```
  - **Commit**: `feat(ralph-specum): complete POC for dependency removal`
  - _Requirements: AC-2.1, AC-2.2, AC-2.5_
  - _Design: Stop Hook Decision Flow_

## Phase 2: Documentation Updates

Focus: Update README and CLAUDE.md to remove ralph-wiggum references.

- [ ] 2.1 Update README.md to remove ralph-wiggum dependency
  - **Do**:
    1. Remove "Requirements" section referencing ralph-wiggum (FR-9)
    2. Update "Installation" sections to remove ralph-wiggum install steps
    3. Update "Troubleshooting" to remove ralph-wiggum related items
    4. Update "Breaking Changes" section to document v3.0 removal of dependency
    5. Remove "Ralph Loop + Spec-Driven Development = <3" tagline
    6. Update ralph-speckit installation to also remove dependency
  - **Files**: `README.md`
  - **Done when**: README has no references to ralph-wiggum, ralph-loop, or plugin dependency
  - **Verify**: `grep -c "ralph-wiggum\|ralph-loop" README.md` returns 0
  - **Commit**: `docs(readme): remove ralph-wiggum dependency references`
  - _Requirements: FR-9, AC-1.1, AC-1.2_
  - _Design: File Structure table_

- [ ] 2.2 Update CLAUDE.md to remove dependency reference
  - **Do**:
    1. Update "Dependencies" section to remove ralph-loop requirement
    2. Update any references to Ralph Loop plugin
    3. Keep other documentation intact
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md has no references to ralph-wiggum, ralph-loop dependency
  - **Verify**: `grep -c "ralph-wiggum\|ralph-loop" CLAUDE.md` returns 0
  - **Commit**: `docs(claude): remove ralph-loop dependency reference`
  - _Requirements: FR-9_
  - _Design: File Structure table_

- [ ] 2.3 [VERIFY] Quality checkpoint: documentation verification
  - **Do**: Verify no orphaned references to ralph-wiggum or ralph-loop in any documentation
  - **Verify**: `grep -r "ralph-wiggum\|ralph-loop" . --include="*.md" | grep -v specs/ | grep -v ".progress" | wc -l` returns 0
  - **Done when**: No ralph-loop references in documentation outside specs
  - **Commit**: `chore(docs): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Add bats-core unit tests for stop-watcher.sh.

- [ ] 3.1 Create bats-core test file for stop-watcher.sh
  - **Do**:
    1. Create `plugins/ralph-specum/tests/` directory
    2. Create `stop-watcher.bats` with setup/teardown functions
    3. Add test: `stop_hook_active=true` exits immediately
    4. Add test: phase != execution allows exit
    5. Add test: missing state file allows exit
    6. Add test: `ALL_TASKS_COMPLETE` in transcript cleans up state
    7. Add test: incomplete tasks returns block JSON
    8. Add test: `maxGlobalIterations` exceeded allows exit
    9. Add test: malformed state file handles gracefully
  - **Files**: `plugins/ralph-specum/tests/stop-watcher.bats`
  - **Done when**: Test file exists with 7+ test cases covering all decision branches
  - **Verify**: `test -f plugins/ralph-specum/tests/stop-watcher.bats && grep -c "@test" plugins/ralph-specum/tests/stop-watcher.bats` returns >= 7
  - **Commit**: `test(hooks): add bats-core tests for stop-watcher.sh`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3, AC-2.4_
  - _Design: Test Strategy: Stop Hook (bats-core)_

- [ ] 3.2 [RISKY] Run bats-core tests locally
  - **Do**:
    1. Install bats-core if not present (`brew install bats-core` or equivalent)
    2. Run tests: `bats plugins/ralph-specum/tests/stop-watcher.bats`
    3. Fix any failing tests
    4. Verify all tests pass
  - **Files**: May need fixes to `stop-watcher.bats` or `stop-watcher.sh`
  - **Done when**: All bats tests pass locally
  - **Verify**: `bats plugins/ralph-specum/tests/stop-watcher.bats`
  - **Commit**: `test(hooks): ensure all bats tests pass` (if fixes needed)
  - _Requirements: NFR-2_
  - _Design: Running Tests_

- [ ] 3.3 [VERIFY] Quality checkpoint: test coverage verification
  - **Do**: Verify tests cover critical paths
  - **Verify**: `bats plugins/ralph-specum/tests/stop-watcher.bats --tap | grep -c "^ok"` >= 7
  - **Done when**: At least 7 test cases pass
  - **Commit**: `chore(tests): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [x] 4.1 Create GitHub Actions workflow for bats tests
  - **Do**:
    1. Create `.github/workflows/test.yml`
    2. Configure trigger for push to main and PRs affecting plugins/ralph-specum
    3. Add step to install bats-core via apt-get
    4. Add step to run tests
    5. Follow conventions from existing workflows (ubuntu-latest, actions/checkout@v4)
  - **Files**: `.github/workflows/test.yml`
  - **Done when**: Workflow file exists with correct triggers and bats execution
  - **Verify**: `test -f .github/workflows/test.yml && grep -q "bats" .github/workflows/test.yml`
  - **Commit**: `ci(hooks): add GitHub Actions workflow for bats tests`
  - _Requirements: NFR-2_
  - _Design: CI/CD: GitHub Actions Workflow_

- [ ] 4.2 Bump plugin version
  - **Do**:
    1. Update version in `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Update version in `.claude-plugin/marketplace.json`
    3. Use version 3.0.0 (major bump for breaking change: removed dependency)
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files have version 3.0.0
  - **Verify**: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json` returns "3.0.0" && `jq -r '.plugins[] | select(.name=="ralph-specum") | .version' .claude-plugin/marketplace.json` returns "3.0.0"
  - **Commit**: `chore(release): bump ralph-specum to v3.0.0`

- [ ] 4.3 [VERIFY] Full local CI: shellcheck && bats && grep verification
  - **Do**: Run complete local CI suite
  - **Verify**: `shellcheck plugins/ralph-specum/hooks/scripts/stop-watcher.sh && bats plugins/ralph-specum/tests/stop-watcher.bats && grep -r "ralph-wiggum\|ralph-loop" plugins/ralph-specum/commands/*.md | wc -l | grep -q "^0$"`
  - **Done when**: All checks pass
  - **Commit**: `chore(ralph-specum): pass local CI` (if fixes needed)

- [ ] 4.4 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Push branch: `git push -u origin <branch-name>`
    4. Create PR using gh CLI with summary of changes
    5. Wait for CI to complete
  - **Verify**: `gh pr checks --watch` shows all checks passing
  - **Done when**: PR created with passing CI
  - **Commit**: None (PR creation only)

- [ ] 4.5 [VERIFY] AC checklist verification
  - **Do**:
    1. Verify AC-1.1: No ralph-wiggum install required - `grep -c "ralph-wiggum" README.md` = 0
    2. Verify AC-1.2: No error messages about missing plugins - no ralph-loop references in implement.md
    3. Verify AC-2.1: Stop hook blocks during execution - bats test passes
    4. Verify AC-2.2: Stop hook allows on completion - bats test passes
    5. Verify AC-2.3: maxGlobalIterations enforced - bats test passes
    6. Verify AC-2.4: stop_hook_active checked - bats test passes
    7. Verify AC-3.1, AC-3.2: cancel.md deletes state directly - no skill invocation
  - **Verify**: All verification commands pass as documented above
  - **Done when**: All acceptance criteria confirmed met via automated checks
  - **Commit**: None

## Notes

- **POC shortcuts taken**: None - implementation is straightforward bash modifications
- **Production TODOs**: Consider adding `jq` availability warning in implement.md
- **Breaking change**: v3.0.0 removes ralph-wiggum dependency - update MIGRATION.md if exists
- **Risk areas**:
  - Stop hook exit code behavior - tested via bats
  - Transcript path availability - graceful fallback implemented
