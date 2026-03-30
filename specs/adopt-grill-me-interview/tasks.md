# Tasks: Adopt Grill-Me Interview

## Phase 1: Make It Work (POC)

Focus: Apply all five SKILL.md changes, clean up goal-interview.md, bump versions, add bats tests.

- [x] 1.1 Delete Intent-Based Depth Scaling table from SKILL.md
  - **Do**:
    1. Open `plugins/ralph-specum/skills/interview-framework/SKILL.md`
    2. Remove the entire `## Intent-Based Depth Scaling` section (heading + table rows, up to but not including `## Completion Signal Detection`)
    3. Verify the surrounding sections are intact and no blank lines are orphaned
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: `## Intent-Based Depth Scaling` heading and its table are gone; `## Completion Signal Detection` follows directly after `## Option Limit Rule`
  - **Verify**: `! grep -q "Intent-Based Depth Scaling" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `refactor(interview-framework): remove intent-based depth scaling table`
  - _Requirements: FR-3, AC-2.1_

- [x] 1.2 Remove `askedCount >= minRequired` guard from Completion Signal Detection
  - **Do**:
    1. In `SKILL.md`, locate the `## Completion Signal Detection` code block
    2. Delete the `if askedCount >= minRequired:` line and its indentation wrapper, leaving only the `for signal in completionSignals:` loop and its body
    3. Preserve the `completionSignals = [...]` definition line unchanged
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: Code block contains `completionSignals` definition and `for signal` loop but no `askedCount >= minRequired` condition
  - **Verify**: `! grep -q "askedCount >= minRequired" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `refactor(interview-framework): remove minRequired gate from completion signal check`
  - _Requirements: FR-3, FR-4, AC-2.2, AC-2.4_

- [x] 1.3 Rewrite Phase 1 WHILE loop as decision-tree traversal
  - **Do**:
    1. In `SKILL.md`, locate `### Phase 1: UNDERSTAND (Adaptive Dialogue)` and its fenced `text` code block (the WHILE loop)
    2. Replace the entire code block with the decision-tree pseudocode from design.md "New Phase 1 Algorithm" section (steps 1-4 + DECISION-TREE TRAVERSAL block)
    3. Update the section heading to `### Phase 1: UNDERSTAND (Decision-Tree)` to match the design diagram
    4. Update the **Key rules** bullet list: replace the em-dash in "You mentioned X — does that mean" with a regular hyphen or restructure to avoid it
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: `WHILE askedCount` is gone; `DECISION-TREE TRAVERSAL` label is present; `next_unblocked_open_node` appears in the pseudocode
  - **Verify**: `grep -q "DECISION-TREE" plugins/ralph-specum/skills/interview-framework/SKILL.md && ! grep -q "WHILE askedCount" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `feat(interview-framework): rewrite Phase 1 as decision-tree traversal`
  - _Requirements: FR-6, AC-4.1, AC-4.2, AC-4.3_

- [x] 1.4 Add `[Recommended]` convention to question format in SKILL.md
  - **Do**:
    1. In `SKILL.md` Phase 1 pseudocode, the new decision-tree block already shows the `[Recommended]` option format -- confirm it is present from task 1.3
    2. Add a new `## Recommendation Format` section after `## Option Limit Rule` (before the Completion Signal Detection section) documenting the `[Recommended]` label convention, using the exact content from design.md "Recommendation Format" section (rules + yaml example)
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: `## Recommendation Format` section exists with `[Recommended]` label rules and the yaml example showing `[Recommended] ./specs/ (default)`
  - **Verify**: `grep -q "\[Recommended\]" plugins/ralph-specum/skills/interview-framework/SKILL.md && grep -q "Recommendation Format" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `feat(interview-framework): add [Recommended] label convention for Phase 1 questions`
  - _Requirements: FR-1, FR-2, AC-1.1, AC-1.2, AC-1.3, AC-1.4_

- [x] 1.5 Add Codebase-First Exploration section to SKILL.md
  - **Do**:
    1. In `SKILL.md`, add a new `## Codebase-First Exploration` section after the `## Recommendation Format` section and before `## Completion Signal Detection`
    2. Use the exact content from design.md "Codebase-First Rule (New Section for SKILL.md)" (the three-bullet markdown block distinguishing codebase facts from user decisions)
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: `## Codebase-First Exploration` heading is present; "Codebase fact" and "User decision" bullet items appear in that section
  - **Verify**: `grep -q "## Codebase-First Exploration" plugins/ralph-specum/skills/interview-framework/SKILL.md && grep -q "Codebase fact" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `feat(interview-framework): add Codebase-First Exploration section`
  - _Requirements: FR-5, AC-3.1, AC-3.2, AC-3.3, AC-3.4_

- [x] 1.6 Remove duplicate `<mandatory>` block from goal-interview.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/goal-interview.md`
    2. Delete lines 32-38: the entire `<mandatory>...</mandatory>` XML block (the codebase-fact-vs-user-decision block)
    3. Verify the `## Brainstorming Dialogue` section still contains the prose reference to SKILL.md and flows coherently into `## Goal Exploration Territory`
  - **Files**: `plugins/ralph-specum/references/goal-interview.md`
  - **Done when**: `<mandatory>` block is gone; "Apply adaptive dialogue from" line and `## Goal Exploration Territory` are adjacent with no orphaned text
  - **Verify**: `! grep -q "is this a codebase fact or a user decision" plugins/ralph-specum/references/goal-interview.md && grep -q "skills/interview-framework/SKILL.md" plugins/ralph-specum/references/goal-interview.md && echo PASS`
  - **Commit**: `refactor(goal-interview): remove duplicate codebase-first mandatory block`
  - _Requirements: FR-7, AC-5.1, AC-5.2, AC-5.3_

- [ ] 1.7 Bump plugin version to 4.9.0 in both manifest files
  - **Do**:
    1. In `plugins/ralph-specum/.claude-plugin/plugin.json`, change `"version": "4.8.4"` to `"version": "4.9.0"`
    2. In `.claude-plugin/marketplace.json`, find the `ralph-specum` entry and change its `"version": "4.8.4"` to `"version": "4.9.0"`
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files contain `"version": "4.9.0"` for the ralph-specum plugin
  - **Verify**: `grep -q '"version": "4.9.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -A5 '"name": "ralph-specum"' .claude-plugin/marketplace.json | grep -q '"version": "4.9.0"' && echo PASS`
  - **Commit**: `chore(ralph-specum): bump version to 4.9.0`
  - _Requirements: FR-8, AC-6.1, AC-6.2, AC-6.3_

- [ ] 1.8 Create tests/interview-framework.bats with 14 content assertions
  - **Do**:
    1. Create `tests/interview-framework.bats` (flat location matching existing test files like `tests/stop-hook.bats`)
    2. Use `#!/usr/bin/env bats` header, no `load 'helpers/setup.bash'` (file-read tests only)
    3. Define `SKILL_FILE` and `GOAL_INTERVIEW` variables at top
    4. Write all 14 `@test` blocks from design.md "Test Strategy" section verbatim
  - **Files**: `tests/interview-framework.bats`
  - **Done when**: File exists with 14 `@test` blocks; all tests pass with `bats tests/interview-framework.bats`
  - **Verify**: `bats tests/interview-framework.bats`
  - **Commit**: `test(interview-framework): add bats content tests for SKILL.md`
  - _Requirements: FR-9, AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5, AC-7.6_

## Phase 2: Refactoring

Focus: Clean up SKILL.md structure and ensure consistent section ordering and prose quality.

- [ ] 2.1 Review SKILL.md structure and clean up section ordering and prose
  - **Do**:
    1. Read the full updated `SKILL.md` end-to-end
    2. Verify section order matches design: Option Limit Rule -> Recommendation Format -> Codebase-First Exploration -> Completion Signal Detection -> 3-Phase Algorithm (Phase 1 decision-tree, Phase 2, Phase 3) -> Adaptive Depth -> Context Accumulator
    3. Fix any orphaned blank lines, inconsistent heading levels, or prose fragments left from the edits
    4. Ensure the Phase 1 heading reads `### Phase 1: UNDERSTAND (Decision-Tree)` consistently
    5. Remove any leftover references to `askedCount`, `maxAllowed`, or `minRequired` outside the advisory floor note (if any remain in prose text)
  - **Files**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
  - **Done when**: Sections appear in design order; no leftover `askedCount`/`maxAllowed` references outside the decision-tree pseudocode advisory note; no orphaned blank lines
  - **Verify**: `! grep -q "maxAllowed" plugins/ralph-specum/skills/interview-framework/SKILL.md && ! grep -q "askedCount >= minRequired" plugins/ralph-specum/skills/interview-framework/SKILL.md && echo PASS`
  - **Commit**: `refactor(interview-framework): clean up SKILL.md section ordering and prose`

## Phase 3: Testing

Focus: Run full bats suite and confirm all 14 new tests plus existing tests pass.

- [ ] 3.1 Run full bats test suite and fix any failures
  - **Do**:
    1. Run `bats tests/` to execute all test files including the new `tests/interview-framework.bats`
    2. For each failing test: identify the mismatch between SKILL.md content and the test assertion, fix the SKILL.md content (or the test if the assertion is wrong)
    3. Repeat until `bats tests/` exits 0
  - **Files**: `tests/interview-framework.bats`, `plugins/ralph-specum/skills/interview-framework/SKILL.md` (if fixes needed)
  - **Done when**: `bats tests/` exits 0 with all tests passing including the 14 new interview-framework tests
  - **Verify**: `bats tests/`
  - **Commit**: `test(interview-framework): all bats tests passing`
  - _Requirements: AC-7.6_

## Phase 4: Quality Gates

- [ ] V4 [VERIFY] Full local CI: run bats suite + verify file contents
  - **Do**:
    1. `bats tests/` -- all tests pass
    2. Spot-check SKILL.md for the five required patterns
    3. Verify goal-interview.md cleanup is complete
    4. Verify both version files are at 4.9.0
  - **Verify**: `bats tests/ && ! grep -q "Intent-Based Depth Scaling" plugins/ralph-specum/skills/interview-framework/SKILL.md && ! grep -q "askedCount >= minRequired" plugins/ralph-specum/skills/interview-framework/SKILL.md && grep -q "DECISION-TREE" plugins/ralph-specum/skills/interview-framework/SKILL.md && grep -q "\[Recommended\]" plugins/ralph-specum/skills/interview-framework/SKILL.md && grep -q "Codebase-First Exploration" plugins/ralph-specum/skills/interview-framework/SKILL.md && ! grep -q "is this a codebase fact or a user decision" plugins/ralph-specum/references/goal-interview.md && grep -q '"version": "4.9.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo ALL_PASS`
  - **Done when**: All commands exit 0
  - **Commit**: None (fix commits go on individual failing items)

- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Push branch and verify GitHub Actions passes
  - **Verify**: `gh pr checks --watch`
  - **Done when**: All CI checks green (plugin-version-check.yml, bats-tests.yml)
  - **Commit**: None

- [ ] V6 [VERIFY] AC checklist
  - **Do**:
    1. AC-1.1/1.2/1.3/1.4: `grep -q "\[Recommended\]" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    2. AC-2.1: `! grep -q "Intent-Based Depth Scaling" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    3. AC-2.2: `! grep -q "WHILE askedCount" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    4. AC-2.4: `grep -q "completionSignals" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    5. AC-3.1/3.2/3.4: `grep -q "## Codebase-First Exploration" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    6. AC-4.1/4.2: `grep -q "DECISION-TREE" plugins/ralph-specum/skills/interview-framework/SKILL.md`
    7. AC-5.1: `! grep -q "is this a codebase fact or a user decision" plugins/ralph-specum/references/goal-interview.md`
    8. AC-5.2: `grep -q "skills/interview-framework/SKILL.md" plugins/ralph-specum/references/goal-interview.md`
    9. AC-6.1/6.2: `grep -q '"version": "4.9.0"' plugins/ralph-specum/.claude-plugin/plugin.json`
    10. AC-7.1 through AC-7.6: `bats tests/interview-framework.bats`
  - **Verify**: All grep commands exit 0, bats passes
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

## Phase 5: PR Lifecycle

- [ ] 5.1 Create PR and monitor CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat(interview-framework): adopt grill-me patterns" --body "$(cat <<'EOF'
## Summary
- Rewrites Phase 1 UNDERSTAND algorithm from a count-bounded WHILE loop to a dependency-ordered decision-tree traversal
- Adds [Recommended] label convention to every Phase 1 question with rationale in question text
- Adds Codebase-First Exploration section enforcing automatic lookup before asking the user
- Removes Intent-Based Depth Scaling table and minRequired gate; completion signals are the sole exit mechanism
- Removes duplicate <mandatory> codebase-first block from goal-interview.md (single source of truth in SKILL.md)
- Bumps version to 4.9.0 (minor: new interview behavior)
- Adds 14 bats content tests verifying key structural invariants in SKILL.md

## Test plan
- [ ] bats tests/interview-framework.bats passes (14 tests green)
- [ ] bats tests/ passes (full suite, no regressions)
- [ ] plugin-version-check.yml passes (4.9.0 in both manifest files)
- [ ] bats-tests.yml passes (all tests green in CI)
EOF
)"`
    4. Monitor CI: `gh pr checks --watch`
    5. Fix any CI failures, push, re-check
  - **Files**: None (git operations only)
  - **Done when**: PR created, all CI checks green, PR ready for review
  - **Verify**: `gh pr checks` shows all passing
  - **Commit**: None

## Notes

- **POC shortcuts**: Tasks 1.1-1.5 are individual targeted edits to SKILL.md rather than a single rewrite -- this makes each commit reviewable and easier to revert if one change causes test failures.
- **Test file location**: `tests/interview-framework.bats` (flat, matches existing `tests/stop-hook.bats` pattern). AC-7.1 mentions `tests/skills/` but design.md and .progress.md confirmed flat convention.
- **No helpers needed**: The new bats file reads static files only -- no `load 'helpers/setup.bash'` required.
- **minRequired advisory**: AC-2.3 says keep minRequired as advisory floor. The new decision-tree pseudocode does not include a hard minRequired check; the advisory is implicit in "if you have enough context to propose meaningful approaches." No explicit minRequired variable needs to remain in SKILL.md.
