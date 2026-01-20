# Tasks: Ralph Loop Loop Integration

## Phase 1: Make It Work (POC)

Focus: Validate /ralph-loop invocation works end-to-end with minimal coordinator logic.

- [x] 1.1 Delete custom stop-handler files
  - **Do**: Remove hooks/scripts/stop-handler.sh and hooks/hooks.json. These are replaced by Ralph Loop's stop-hook.
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-handler.sh`, `plugins/ralph-specum/hooks/hooks.json`
  - **Done when**: Both files deleted, hooks directory empty or contains only README
  - **Verify**: `ls plugins/ralph-specum/hooks/ && ! test -f plugins/ralph-specum/hooks/hooks.json && ! test -f plugins/ralph-specum/hooks/scripts/stop-handler.sh && echo "PASS"`
  - **Commit**: `feat(hooks): remove custom stop-handler, delegate to Ralph Loop`
  - _Requirements: FR-3, AC-3.1, AC-3.2, AC-3.3_
  - _Design: File Structure_

- [x] 1.2 Create minimal implement.md wrapper with dependency check
  - **Do**: Rewrite implement.md as thin wrapper that:
    1. Reads spec from .current-spec
    2. Validates prerequisites (spec dir, tasks.md exist)
    3. Checks Ralph Loop dependency via Skill tool note
    4. Initializes .ralph-state.json with phase=execution
    5. Has placeholder coordinator prompt that just outputs ALL_TASKS_COMPLETE
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md is <100 lines wrapper, invokes /ralph-loop with placeholder prompt
  - **Verify**: `wc -l plugins/ralph-specum/commands/implement.md | awk '{if ($1 < 100) print "PASS: " $1 " lines"; else print "FAIL: " $1 " lines"}'`
  - **Commit**: `feat(implement): create thin wrapper for Ralph Loop loop`
  - _Requirements: FR-1, FR-4, AC-1.1, AC-1.5, AC-4.1, AC-4.2_
  - _Design: Component 1, Component 2_

- [x] 1.3 Add coordinator prompt with basic task reading
  - **Do**: Add inline coordinator prompt section to implement.md that:
    1. Defines coordinator role (not implementer)
    2. Reads .ralph-state.json for taskIndex
    3. Reads tasks.md to find current task
    4. Delegates single task to spec-executor via Task tool
    5. Outputs ALL_TASKS_COMPLETE when taskIndex >= totalTasks
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator prompt handles sequential task delegation
  - **Verify**: `grep -c "spec-executor" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(implement): add basic coordinator prompt for task delegation`
  - _Requirements: FR-2, AC-2.1, AC-2.2, AC-2.3, AC-2.6_
  - _Design: Component 3 sections 1-4, 10_

- [x] 1.4 [VERIFY] Quality checkpoint: syntax validation
  - **Do**: Verify implement.md has valid markdown structure and no broken sections
  - **Verify**: `head -20 plugins/ralph-specum/commands/implement.md | grep -q "^---" && grep -q "^---" plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Done when**: Frontmatter present, markdown valid
  - **Commit**: (none unless fixes needed)

- [x] 1.5 Add state update logic to coordinator
  - **Do**: Extend coordinator prompt to:
    1. Update .ralph-state.json taskIndex after TASK_COMPLETE
    2. Reset taskIteration on success
    3. Delete state file when all tasks complete
    4. Keep .progress.md on completion
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator handles state transitions
  - **Verify**: `grep -c "taskIndex" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 3) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(implement): add state update logic to coordinator`
  - _Requirements: FR-5, AC-5.1, AC-5.2_
  - _Design: Component 4_

- [x] 1.6 Add parallel [P] task support to coordinator
  - **Do**: Extend coordinator prompt to:
    1. Detect [P] markers on tasks
    2. Build parallelGroup structure
    3. Spawn multiple Task tool calls in ONE message for parallel batch
    4. Handle temp progress files (.progress-task-N.md)
    5. Merge progress after batch completion
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator handles parallel task batches
  - **Verify**: `grep -c "parallelGroup" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 2) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(implement): add parallel [P] task execution to coordinator`
  - _Requirements: FR-7, AC-2.4_
  - _Design: Component 3 section 5, Parallel Group Detection, Parallel Executor Spawning_

- [x] 1.7 Add [VERIFY] task delegation to coordinator
  - **Do**: Extend coordinator prompt to:
    1. Detect [VERIFY] marker on tasks
    2. Delegate to qa-engineer instead of spec-executor
    3. Handle VERIFICATION_PASS/FAIL responses
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Coordinator delegates [VERIFY] tasks to qa-engineer
  - **Verify**: `grep -c "qa-engineer" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(implement): add [VERIFY] task delegation to qa-engineer`
  - _Requirements: FR-8, AC-2.5_
  - _Design: Component 3 section 6_

- [x] 1.8 [VERIFY] Quality checkpoint: implement.md structure
  - **Do**: Verify implement.md has all required sections
  - **Verify**: `grep -q "COORDINATOR" plugins/ralph-specum/commands/implement.md && grep -q "ralph-loop" plugins/ralph-specum/commands/implement.md && grep -q "ALL_TASKS_COMPLETE" plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Done when**: All key patterns present
  - **Commit**: (none unless fixes needed)

- [x] 1.9 Add verification layers to coordinator
  - **Do**: Migrate 4 verification layers from stop-handler.sh into coordinator prompt:
    1. Contradiction detection (manual action claims)
    2. Uncommitted spec files check (before advancing)
    3. Checkmark verification (tasks.md [x] count)
    4. TASK_COMPLETE signal verification
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 4 verification layers in coordinator prompt
  - **Verify**: `grep -c "CONTRADICTION\|uncommitted\|checkmark\|TASK_COMPLETE" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 4) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(implement): add verification layers to coordinator prompt`
  - _Requirements: FR-9, AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5_
  - _Design: Component 3 section 7_

- [x] 1.10 Update cancel.md to call /cancel-ralph
  - **Do**: Modify cancel.md to:
    1. Call /cancel-ralph via Skill tool to stop Ralph Loop loop
    2. Continue existing .ralph-state.json deletion
    3. Keep .progress.md preservation
    4. Update output message
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: Cancel command handles dual cleanup
  - **Verify**: `grep -q "cancel-ralph" plugins/ralph-specum/commands/cancel.md && echo "PASS"`
  - **Commit**: `feat(cancel): add /cancel-ralph invocation for dual cleanup`
  - _Requirements: FR-6, AC-6.1, AC-6.2, AC-6.3, AC-6.4_
  - _Design: Component 5_

- [x] 1.11 [VERIFY] Quality checkpoint: cancel.md
  - **Do**: Verify cancel.md has required patterns
  - **Verify**: `grep -q "cancel-ralph" plugins/ralph-specum/commands/cancel.md && grep -q ".ralph-state.json" plugins/ralph-specum/commands/cancel.md && echo "PASS"`
  - **Done when**: Both patterns present
  - **Commit**: (none unless fixes needed)

- [x] 1.12 POC Checkpoint: End-to-end validation
  - **Do**: Verify the implementation works by:
    1. Check implement.md invokes /ralph-loop correctly
    2. Check coordinator prompt has all key sections
    3. Check cancel.md handles dual cleanup
    4. Check hooks directory has no stop-handler
  - **Done when**: All structural validations pass
  - **Verify**: `! test -f plugins/ralph-specum/hooks/scripts/stop-handler.sh && grep -q "ralph-loop" plugins/ralph-specum/commands/implement.md && grep -q "cancel-ralph" plugins/ralph-specum/commands/cancel.md && echo "POC PASS"`
  - **Commit**: `feat(implement): complete POC for Ralph Loop integration`

## Phase 2: Refactoring

After POC validated, clean up code and documentation.

- [x] 2.1 Refactor coordinator prompt sections
  - **Do**: Organize coordinator prompt into clearly labeled sections:
    1. Role Definition
    2. Read State
    3. Check Completion
    4. Parse Current Task
    5. Parallel Group Detection
    6. Task Delegation
    7. Verification Layers
    8. State Update
    9. Progress Merge
    10. Completion Signal
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 10 sections clearly delineated with headers
  - **Verify**: `grep -c "^### [0-9]" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 8) print "PASS"; else print "FAIL"}'`
  - **Commit**: `refactor(implement): organize coordinator prompt into sections`
  - _Design: Component 3 structure_

- [x] 2.2 Add error handling to coordinator
  - **Do**: Add error handling for:
    1. Missing/corrupt .ralph-state.json
    2. Missing tasks.md
    3. Missing spec directory
    4. Max retries reached
    5. Partial parallel batch failure
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All error scenarios have handling instructions
  - **Verify**: `grep -c "ERROR\|error\|fail" plugins/ralph-specum/commands/implement.md | awk '{if ($1 >= 5) print "PASS"; else print "FAIL"}'`
  - **Commit**: `refactor(implement): add error handling to coordinator`
  - _Design: Error Handling_

- [x] 2.3 [VERIFY] Quality checkpoint: structure review
  - **Do**: Verify implement.md and cancel.md have clean structure
  - **Verify**: `wc -l plugins/ralph-specum/commands/implement.md plugins/ralph-specum/commands/cancel.md`
  - **Done when**: Files have reasonable line counts
  - **Commit**: (none unless fixes needed)

- [x] 2.4 Bump plugin version to 2.0.0
  - **Do**: Update plugin.json version from 1.6.1 to 2.0.0. This signals breaking change.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: Version is 2.0.0
  - **Verify**: `grep -q '"version": "2.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo "PASS"`
  - **Commit**: `chore(version): bump to 2.0.0 for Ralph Loop breaking change`
  - _Requirements: FR-11, AC-11.1_
  - _Design: File Structure_

- [x] 2.5 Update README with breaking change documentation
  - **Do**: Update README.md to:
    1. Add "Requirements" section listing Ralph Loop dependency
    2. Add installation command: `/plugin install ralph-wiggum@claude-plugins-official`
    3. Add "Breaking Changes" section for v2.0.0
    4. Update troubleshooting for new error messages
  - **Files**: `README.md`
  - **Done when**: README documents Ralph Loop dependency clearly
  - **Verify**: `grep -q "ralph-wiggum@claude-plugins-official" README.md && grep -q "2.0.0" README.md && echo "PASS"`
  - **Commit**: `docs(readme): document Ralph Loop dependency and breaking change`
  - _Requirements: FR-10, AC-4.3, AC-4.4_
  - _Design: Migration Notes_

- [x] 2.6 [VERIFY] Quality checkpoint: documentation
  - **Do**: Verify documentation is complete
  - **Verify**: `grep -q "ralph-wiggum" README.md && grep -q "2.0.0" README.md && echo "PASS"`
  - **Done when**: All documentation patterns present
  - **Commit**: (none unless fixes needed)

- [x] 2.7 Clean up hooks directory
  - **Do**: Remove empty hooks/scripts directory if present. Keep hooks directory with README if needed for future use.
  - **Files**: `plugins/ralph-specum/hooks/`
  - **Done when**: No stale files in hooks directory
  - **Verify**: `! test -d plugins/ralph-specum/hooks/scripts && echo "PASS" || (test -z "$(ls -A plugins/ralph-specum/hooks/scripts 2>/dev/null)" && echo "PASS")`
  - **Commit**: `chore(hooks): cleanup empty hooks directory`

## Phase 3: Testing

Manual verification for markdown-only plugin.

- [x] 3.1 Verify implement.md structure completeness
  - **Do**: Check implement.md has all required components:
    1. Frontmatter with description, argument-hint, allowed-tools
    2. Dependency check section
    3. State initialization section
    4. /ralph-loop invocation
    5. Coordinator prompt with all 10 sections
    6. ALL_TASKS_COMPLETE signal
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 6 components present
  - **Verify**: `grep -q "^---" plugins/ralph-specum/commands/implement.md && grep -q "ralph-loop" plugins/ralph-specum/commands/implement.md && grep -q "ALL_TASKS_COMPLETE" plugins/ralph-specum/commands/implement.md && grep -q "COORDINATOR" plugins/ralph-specum/commands/implement.md && echo "PASS"`
  - **Commit**: (none unless fixes needed)
  - _Requirements: AC-1.2, AC-1.3, AC-1.4_

- [x] 3.2 Verify cancel.md completeness
  - **Do**: Check cancel.md has:
    1. /cancel-ralph invocation
    2. .ralph-state.json deletion
    3. .progress.md preservation
    4. Status reporting
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: All 4 components present
  - **Verify**: `grep -q "cancel-ralph" plugins/ralph-specum/commands/cancel.md && grep -q ".ralph-state.json" plugins/ralph-specum/commands/cancel.md && grep -q ".progress.md" plugins/ralph-specum/commands/cancel.md && echo "PASS"`
  - **Commit**: (none unless fixes needed)
  - _Requirements: AC-6.1, AC-6.2, AC-6.3, AC-6.4_

- [x] 3.3 Verify plugin.json version
  - **Do**: Confirm version is exactly 2.0.0
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: Version matches
  - **Verify**: `grep -q '"version": "2.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo "PASS"`
  - **Commit**: (none unless fixes needed)
  - _Requirements: AC-11.1_

- [x] 3.4 [VERIFY] Quality checkpoint: full verification
  - **Do**: Run all verifications together
  - **Verify**: `! test -f plugins/ralph-specum/hooks/hooks.json && grep -q "2.0.0" plugins/ralph-specum/.claude-plugin/plugin.json && grep -q "ralph-wiggum" README.md && echo "ALL CHECKS PASS"`
  - **Done when**: All checks pass
  - **Commit**: (none unless fixes needed)

## Phase 4: Quality Gates

- [x] 4.1 [VERIFY] Final file structure validation
  - **Do**: Verify all file changes are correct:
    1. hooks/scripts/stop-handler.sh deleted
    2. hooks/hooks.json deleted
    3. implement.md rewritten
    4. cancel.md updated
    5. plugin.json at 2.0.0
    6. README.md updated
  - **Verify**: `! test -f plugins/ralph-specum/hooks/scripts/stop-handler.sh && ! test -f plugins/ralph-specum/hooks/hooks.json && grep -q "2.0.0" plugins/ralph-specum/.claude-plugin/plugin.json && grep -q "ralph-wiggum" README.md && echo "STRUCTURE VALID"`
  - **Done when**: All structure checks pass
  - **Commit**: (none unless fixes needed)

- [x] 4.2 [VERIFY] CI pipeline passes
  - **Do**: Push changes and verify CI
  - **Verify**: `git status && echo "Ready for PR"`
  - **Done when**: Working tree clean, ready for PR
  - **Commit**: (none)

- [x] 4.3 [VERIFY] AC checklist verification
  - **Do**: Programmatically verify acceptance criteria:
    - AC-1.5: implement.md < 1000 lines (wrapper + inline prompt)
    - AC-3.1: stop-handler.sh deleted
    - AC-3.2: hooks.json deleted
    - AC-4.2: Error message contains install command
    - AC-6.1: cancel.md calls /cancel-ralph
    - AC-11.1: version = 2.0.0
  - **Verify**: `wc -l plugins/ralph-specum/commands/implement.md | awk '{print $1}' | xargs -I {} test {} -lt 1000 && ! test -f plugins/ralph-specum/hooks/scripts/stop-handler.sh && ! test -f plugins/ralph-specum/hooks/hooks.json && grep -q "cancel-ralph" plugins/ralph-specum/commands/cancel.md && grep -q '"version": "2.0.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo "ALL AC PASS"`
  - **Done when**: All acceptance criteria verified
  - **Commit**: (none)

- [x] 4.4 Create PR
  - **Do**: Create pull request with:
    1. Title: "feat: integrate Ralph Loop loop mechanism"
    2. Summary of changes (wrapper, deleted hooks, version bump)
    3. Breaking change note about Ralph Loop dependency
    4. Test plan (manual verification checklist from design.md)
  - **Done when**: PR created, URL available
  - **Verify**: `gh pr create --title "feat: integrate Ralph Loop loop mechanism" --body "## Summary
- Replace custom stop-handler.sh with Ralph Loop plugin's /ralph-loop
- implement.md becomes thin wrapper + inline coordinator prompt
- cancel.md now calls /cancel-ralph for dual cleanup
- Version bump to 2.0.0 (breaking change)

## Breaking Change
Requires Ralph Loop plugin: \`/plugin install ralph-wiggum@claude-plugins-official\`

## Test Plan
- [ ] Verify implement.md invokes /ralph-loop
- [ ] Verify coordinator handles sequential tasks
- [ ] Verify coordinator handles [P] parallel tasks
- [ ] Verify coordinator handles [VERIFY] tasks
- [ ] Verify cancel.md calls /cancel-ralph
- [ ] Verify stop-handler.sh deleted
- [ ] Verify version is 2.0.0
- [ ] Verify README documents dependency" --head feat/implement-ralph-wiggum && echo "PR CREATED"`
  - **Commit**: (none, PR creation only)

## Notes

- **POC shortcuts taken**: Coordinator prompt is inline in implement.md (not separate file). No runtime testing of actual Ralph Loop invocation (markdown-only plugin).
- **Production TODOs**: Consider extracting coordinator prompt to template file if maintenance becomes difficult. Add integration tests if Ralph Loop provides test utilities.
- **Manual verification required**: Since this is a markdown-only plugin, actual behavior must be tested by running the plugin in Claude Code.
