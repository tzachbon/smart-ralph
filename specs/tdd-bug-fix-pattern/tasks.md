---
generated: auto
spec: tdd-bug-fix-pattern
granularity: coarse
workflow: mid-sized (additive reference file changes)
---

# Tasks: TDD Bug Fix Pattern

## Phase 1: Core File Changes

Focus: Add BUG_FIX intent type and reproduce-first workflow across 5 reference files. All changes are additive -- no existing sections removed.

- [x] 1.1 [P] Add BUG_FIX intent to `intent-classification.md`
  - **Do**:
    1. Read `plugins/ralph-specum/references/intent-classification.md`
    2. In the **Classification Logic** block, insert BUG_FIX as item 0 (before TRIVIAL), with keywords: fix, resolve, debug, broken, failing, not working, error, bug, patch, crash, regression, reproduce, repro, issue. Min/Max questions: 5/5.
    3. Add priority rule note: TRIVIAL-specific keywords (typo, spelling, minor, tiny, rename, update text) override BUG_FIX when both match.
    4. In the **Dialogue Depth by Intent** table, add BUG_FIX row (5 | 5).
    5. In the **Store Intent** block, add BUG_FIX to the valid Type values list.
  - **Files**: `plugins/ralph-specum/references/intent-classification.md`
  - **Done when**: File contains `BUG_FIX` in Classification Logic block AND in the Dialogue Depth table AND in Store Intent block
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md | wc -l | xargs -I{} sh -c '[ {} -ge 3 ] && echo PASS || echo FAIL'`
  - **Commit**: `feat(intent-classification): add BUG_FIX intent type with priority rule`
  - _Requirements: FR-1, AC-1.1, AC-1.2, AC-1.3_

- [ ] 1.2 [P] Add Bug Interview section to `goal-interview.md`
  - **Do**:
    1. Read `plugins/ralph-specum/references/goal-interview.md`
    2. After the `## Prerequisites` section, insert a new `## Bug Interview (BUG_FIX Intent)` section with: intro sentence, the 5 exact bug questions (Q1 repro steps, Q2 expected vs actual, Q3 when started, Q4 regression check, Q5 fastest repro command), an `### After Bug Interview` note (skip approach proposals, skip Spec Location Interview, store in `## Interview Responses`).
  - **Files**: `plugins/ralph-specum/references/goal-interview.md`
  - **Done when**: File contains `## Bug Interview (BUG_FIX Intent)` section with all 5 numbered questions
  - **Verify**: `sg --pattern '## Bug Interview' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/goal-interview.md && echo PASS`
  - **Commit**: `feat(goal-interview): add structured bug interview with 5 questions`
  - _Requirements: FR-3, AC-2.1, AC-2.2_

- [ ] 1.3 [VERIFY] Quality checkpoint: files exist and contain required sections
  - **Do**: Verify both 1.1 and 1.2 changes landed correctly
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'Bug Interview' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/goal-interview.md > /dev/null && echo PASS`
  - **Done when**: Both grep commands find their patterns
  - **Commit**: None

- [ ] 1.4 Add Bug TDD Workflow and canonical BEFORE format to `phase-rules.md`
  - **Do**:
    1. Read `plugins/ralph-specum/references/phase-rules.md`
    2. In the **Workflow Selection** table, add BUG_FIX row: `| BUG_FIX | Bug TDD | Reproduce first, then TDD to lock in fix and prevent regression |`
    3. In the **Workflow Selection** header block, update the intro sentence to include BUG_FIX in the valid types.
    4. After the TDD Workflow section (before `## VF Task for Fix Goals`), insert a new `# Bug TDD Workflow (BUG_FIX)` section containing:
       - Phase 0 description and rules (no code changes, STOP if repro fails), including the diagnostic-first principle: only make code changes when certain of the solution; otherwise (1) address root cause not symptoms, (2) add descriptive logging and error messages to track state, (3) add test functions to isolate the problem
       - Phase 0 task format (0.1 [VERIFY] Reproduce bug, 0.2 [VERIFY] Confirm repro consistency)
       - Canonical `## Reality Check (BEFORE)` format block (with fields: Reproduction command, Exit code, Output, Confirmed failing, Timestamp)
       - Note that first [RED] task must reference BEFORE state
       - Note that Phase 2/3/4 same as TDD, VF is mandatory
    5. In the existing `## VF Task for Fix Goals` section, update the trigger condition to: "When `.progress.md` contains `## Reality Check (BEFORE)` OR Intent Classification is `BUG_FIX`"
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`
  - **Done when**: File contains `Bug TDD Workflow` section, `Phase 0` task templates, canonical BEFORE format, and updated VF condition
  - **Verify**: `sg --pattern 'Bug TDD Workflow' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md && sg --pattern 'Reality Check' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md && echo PASS`
  - **Commit**: `feat(phase-rules): add Bug TDD workflow with Phase 0 reproduce and canonical BEFORE format`
  - _Requirements: FR-2, FR-4, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-4.1, AC-5.5_

- [ ] 1.5 [VERIFY] Quality checkpoint: phase-rules.md integrity
  - **Do**: Confirm phase-rules.md has BUG_FIX in workflow table and Bug TDD section
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md | wc -l | xargs -I{} sh -c '[ {} -ge 2 ] && echo PASS || echo FAIL'`
  - **Done when**: BUG_FIX appears at least twice (table row + workflow section)
  - **Commit**: None

- [ ] 1.6 Flesh out step 10 in `quick-mode.md`
  - **Do**:
    1. Read `plugins/ralph-specum/references/quick-mode.md`
    2. In the **Quick Mode Execution Sequence**, replace step 10's stub line `"For fix goals: run reproduction, document BEFORE state"` with full logic:
       - (a) INFER reproduction command: scan goal text for backtick content or "run X"/"by running X" patterns; fallback priority: (1) goal text command, (2) pnpm/npm/yarn test, (3) skip with warning
       - (b) RUN command: capture stdout + stderr + exit code
       - (c) WRITE canonical `## Reality Check (BEFORE)` block to .progress.md (matching format defined in phase-rules.md)
       - (d) If confirmed failing: continue
       - (e) If NOT confirmed failing (cmd exits 0): append WARNING to .progress.md, continue (non-interactive, do not block)
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Step 10 in Quick Mode Execution Sequence contains sub-steps a through e with explicit command inference logic
  - **Verify**: `sg --pattern 'INFER' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/quick-mode.md && echo PASS`
  - **Commit**: `feat(quick-mode): implement step 10 BEFORE state capture for fix goals`
  - _Requirements: FR-5, AC-6.1, AC-6.2, AC-6.3_

- [ ] 1.7 Add Bug TDD Task Planning section to `task-planner.md`
  - **Do**:
    1. Read `plugins/ralph-specum/agents/task-planner.md`
    2. Locate the Workflow Selection section (where intent type determines workflow)
    3. Append a new `## Bug TDD Task Planning (BUG_FIX intent)` section with these 5 rules:
       1. Always prepend Phase 0 with exactly two tasks: `0.1 [VERIFY] Reproduce bug` and `0.2 [VERIFY] Confirm repro is consistent` -- use repro command from bug interview Q5 or from `## Reality Check (BEFORE)` or fallback to test runner
       2. First [RED] task must reference BEFORE state ("from Reality Check (BEFORE)")
       3. VF task is mandatory (always include, regardless of BEFORE state presence)
       4. No GREENFIELD Phase 1 POC -- BUG_FIX always uses Bug TDD workflow
       5. Reproduction command sources (priority): Q5 interview response > `## Reality Check (BEFORE)` > project test runner from research.md
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: File contains `## Bug TDD Task Planning (BUG_FIX intent)` section with all 5 rules
  - **Verify**: `sg --pattern 'Bug TDD Task Planning' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(task-planner): add Bug TDD task planning section with Phase 0 prepend and mandatory VF`
  - _Requirements: FR-6, AC-3.1, AC-4.5_

- [ ] 1.8 [VERIFY] Quality checkpoint: all 5 files modified
  - **Do**: Verify all 5 target files contain their BUG_FIX additions
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'Bug Interview' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/goal-interview.md > /dev/null && sg --pattern 'Bug TDD Workflow' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md > /dev/null && sg --pattern 'INFER' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/quick-mode.md > /dev/null && sg --pattern 'Bug TDD Task Planning' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/agents/task-planner.md > /dev/null && echo ALL_FILES_PASS`
  - **Done when**: All 5 patterns found, prints `ALL_FILES_PASS`
  - **Commit**: None

## Phase 2: Bump Plugin Version

- [ ] 2.1 Bump plugin version in manifest files
  - **Do**:
    1. Read `plugins/ralph-specum/.claude-plugin/plugin.json` -- note current version
    2. Increment patch version (e.g. 3.1.0 -> 3.1.1)
    3. Write updated `plugin.json` with new version
    4. Read `.claude-plugin/marketplace.json` -- find ralph-specum entry
    5. Update the ralph-specum version to match the new patch version
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show the same bumped patch version
  - **Verify**: `node -e "const p=require('/Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/.claude-plugin/plugin.json'); const m=require('/Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/.claude-plugin/marketplace.json'); const mp=m.plugins.find(x=>x.name==='ralph-specum'); console.log(p.version===mp.version ? 'VERSIONS_MATCH' : 'MISMATCH: '+p.version+' vs '+mp.version)"`
  - **Commit**: `chore(ralph-specum): bump version for BUG_FIX workflow addition`

## Phase 3: Quality Gates and PR

- [ ] 3.1 [VERIFY] Verify no existing content removed (additive-only check)
  - **Do**: Confirm all existing intent types and their routing logic are still present
  - **Verify**: `sg --pattern 'TRIVIAL' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'REFACTOR' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'GREENFIELD' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'MID_SIZED' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && echo EXISTING_INTENTS_PRESERVED`
  - **Done when**: All 4 existing intent types still present, prints `EXISTING_INTENTS_PRESERVED`
  - **Commit**: None
  - _Requirements: NFR-1, AC-1.4_

- [ ] 3.2 [VERIFY] V4 Full local CI (lint/typecheck for markdown plugin)
  - **Do**: Run any available quality checks on the plugin files
  - **Verify**: `ls /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/.claude-plugin/plugin.json && node -e "JSON.parse(require('fs').readFileSync('/Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/.claude-plugin/plugin.json','utf8')); console.log('plugin.json valid JSON')" && node -e "JSON.parse(require('fs').readFileSync('/Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/.claude-plugin/marketplace.json','utf8')); console.log('marketplace.json valid JSON')" && echo CI_PASS`
  - **Done when**: Both JSON files parse without error
  - **Commit**: `chore(tdd-bug-fix-pattern): pass quality gate` (if fixes needed)

- [ ] 3.3 Create PR
  - **Do**:
    1. Verify current branch: `git branch --show-current` (should be a feature branch)
    2. Push branch: `git push -u origin <branch-name>`
    3. Create PR: `gh pr create --title "feat(ralph-specum): add BUG_FIX intent with reproduce-first workflow" --body "$(cat <<'EOF'\n## Summary\n- Add BUG_FIX intent type to intent-classification.md (priority 0, before TRIVIAL)\n- Add structured 5-question bug interview to goal-interview.md\n- Add Bug TDD Workflow with Phase 0 (Reproduce) and canonical BEFORE state format to phase-rules.md\n- Implement quick-mode.md step 10 stub with command inference and BEFORE state capture\n- Add Bug TDD Task Planning section to task-planner.md\n- All changes additive; no breaking changes to existing TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED routing\n\n## Test plan\n- [ ] BUG_FIX appears in intent-classification.md before TRIVIAL\n- [ ] goal-interview.md contains 5 structured bug questions\n- [ ] phase-rules.md Bug TDD Workflow section with Phase 0 tasks exists\n- [ ] quick-mode.md step 10 has INFER/RUN/WRITE sub-steps\n- [ ] task-planner.md Bug TDD Task Planning section exists\n- [ ] Existing TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED intents unchanged\n- [ ] Plugin version bumped in plugin.json and marketplace.json\n\n🤖 Generated with Claude Code\nEOF\n)"`
  - **Verify**: `gh pr view --json url -q .url`
  - **Done when**: PR created and URL returned
  - **Commit**: None

- [ ] 3.4 [VERIFY] V5 CI pipeline passes
  - **Do**: Wait for and verify CI checks on the PR
  - **Verify**: `gh pr checks --watch 2>&1 | tail -5`
  - **Done when**: All CI checks green
  - **Commit**: None

- [ ] 3.5 [VERIFY] V6 AC checklist
  - **Do**: Verify each acceptance criterion is satisfied by checking file content
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern 'Bug Interview' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/goal-interview.md > /dev/null && sg --pattern 'Phase 0' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md > /dev/null && sg --pattern 'Reality Check' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md > /dev/null && sg --pattern 'INFER' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/quick-mode.md > /dev/null && sg --pattern 'Bug TDD Task Planning' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/agents/task-planner.md > /dev/null && echo AC_ALL_PASS`
  - **Done when**: All patterns found, prints `AC_ALL_PASS`
  - **Commit**: None

- [ ] VF [VERIFY] Goal verification: BUG_FIX workflow fully added
  - **Do**:
    1. Read BEFORE state from .progress.md if present
    2. Re-run the original goal verification: check all 5 files for their new sections
    3. Confirm "fix login bug" would be classified as BUG_FIX (not TRIVIAL or MID_SIZED) by checking keyword list in intent-classification.md
    4. Confirm Phase 0 task template exists in phase-rules.md before the RED task template
    5. Document AFTER state in .progress.md
  - **Verify**: `sg --pattern 'BUG_FIX' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/intent-classification.md > /dev/null && sg --pattern '0.1' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md > /dev/null && sg --pattern 'Confirmed failing' /Users/zachbonfil/projects/smart-ralph/.claude/worktrees/groovy-snacking-gosling/plugins/ralph-specum/references/phase-rules.md > /dev/null && echo VF_PASS`
  - **Done when**: BUG_FIX routing exists, Phase 0 tasks exist, canonical BEFORE format with "Confirmed failing" field exists -- prints `VF_PASS`
  - **Commit**: `chore(tdd-bug-fix-pattern): verify BUG_FIX workflow fully implemented`
  - _Requirements: All FRs, AC-1.1 through AC-6.3_

## Notes

- This spec modifies markdown reference files only -- no code compilation, no test runner available
- Quality "CI" for this project means valid JSON manifests + grep-based content verification
- All 5 file changes are additive; any content deletion is a bug
- VF task re-runs the same grep checks used throughout to confirm final state
- Plugin version bump is required per CLAUDE.md for any plugin file change
