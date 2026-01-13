---
spec: qa-verification
phase: tasks
total_tasks: 18
created: 2026-01-13
---

# Tasks: QA Verification via [VERIFY] Tasks

## Phase 1: Make It Work (POC)

Focus: Validate [VERIFY] tasks work end-to-end. Create qa-engineer, basic spec-executor delegation, minimal task-planner update.

- [x] 1.1 Create qa-engineer agent
  - **Do**: Create new agent file with:
    1. Frontmatter: name, description, model: inherit, tools: [Read, Write, Edit, Bash, Glob, Grep]
    2. "When Invoked" section explaining task receipt from spec-executor
    3. Execution flow: parse commands, run via Bash, output VERIFICATION_PASS/FAIL
    4. AC checklist handling for V6 tasks
    5. Output format examples for pass and fail
    6. Mandatory block for VERIFICATION_FAIL conditions
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: Agent file exists with correct frontmatter and execution logic
  - **Verify**: `cat /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md | head -20` shows valid frontmatter
  - **Commit**: `feat(qa): create qa-engineer agent for [VERIFY] tasks`
  - _Requirements: FR-1, FR-5, FR-6, FR-7, AC-2.3, AC-2.4_
  - _Design: Component 1 qa-engineer Agent_

- [x] 1.2 Update spec-executor with [VERIFY] detection and delegation
  - **Do**: Add new section to spec-executor.md:
    1. Add "## [VERIFY] Task Handling" section after "Phase-Specific Rules"
    2. Add mandatory block with detection logic (check for "[VERIFY]" in task description)
    3. Add Task tool delegation instructions with context format
    4. Add result handling: VERIFICATION_PASS proceeds, VERIFICATION_FAIL keeps task unchecked
    5. Add rule "Never execute [VERIFY] tasks directly"
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor has [VERIFY] detection section with delegation logic
  - **Verify**: `grep -c "VERIFY" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md` returns > 5
  - **Commit**: `feat(qa): add [VERIFY] task detection to spec-executor`
  - _Requirements: FR-2, AC-2.1, AC-2.2, AC-2.5_
  - _Design: Component 2 spec-executor Updates_

- [x] 1.3 [VERIFY] Quality checkpoint: qa-engineer and spec-executor
  - **Do**: Verify both agent files created/updated correctly
  - **Verify**: Run these commands, ALL must succeed (exit 0):
    ```bash
    # Check qa-engineer.md exists and has required content
    test -f /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "^name: qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "VERIFICATION_PASS" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1

    # Check spec-executor.md has [VERIFY] section
    grep -q "\[VERIFY\] Task Handling" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    grep -q "qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    ```
  - **Pass criteria**: All 6 commands exit 0
  - **Fail criteria**: Any command exits non-zero
  - **Done when**: All verification commands pass
  - **Commit**: `chore(qa): pass quality checkpoint` (only if fixes needed)

- [x] 1.4 Update task-planner with [VERIFY] task format
  - **Do**: Add new section to task-planner.md:
    1. Add "## [VERIFY] Task Format" section after "Intermediate Quality Gate Checkpoints"
    2. Add mandatory block with standard [VERIFY] checkpoint format
    3. Add final verification sequence format (V4/V5/V6)
    4. Add note about using discovered commands from research.md
    5. Update existing Quality Checkpoint format in Tasks Structure to use [VERIFY] tag
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner has [VERIFY] format section and updated checkpoint example
  - **Verify**: `grep -c "\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md` returns > 10
  - **Commit**: `feat(qa): add [VERIFY] task format to task-planner`
  - _Requirements: FR-3, AC-1.1, AC-1.2, AC-1.4, AC-4.1, AC-4.2, AC-4.3, AC-4.4_
  - _Design: Component 3 task-planner Updates_

- [ ] 1.5 Update research-analyst with quality command discovery
  - **Do**: Add new section to research-analyst.md:
    1. Add "## Quality Command Discovery" section after "Related Specs Discovery"
    2. Add mandatory block with sources to check (package.json, Makefile, CI configs)
    3. Add specific commands to run for discovery
    4. Add output format for research.md Quality Commands section
    5. Add note about marking missing commands as "Not found"
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: research-analyst has Quality Command Discovery section
  - **Verify**: `grep -c "Quality Command" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md` returns > 3
  - **Commit**: `feat(qa): add quality command discovery to research-analyst`
  - _Requirements: FR-4, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5_
  - _Design: Component 4 research-analyst Updates_

- [ ] 1.6 [VERIFY] Quality checkpoint: task-planner and research-analyst
  - **Do**: Verify both agent files updated correctly
  - **Verify**: Run these commands, ALL must succeed (exit 0):
    ```bash
    # Check task-planner.md has [VERIFY] format section
    grep -q "\[VERIFY\] Task Format" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "V4.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "V5.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "V6.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1

    # Check research-analyst.md has Quality Command Discovery
    grep -q "Quality Command Discovery" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "package.json" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "Makefile" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    ```
  - **Pass criteria**: All 7 commands exit 0
  - **Fail criteria**: Any command exits non-zero
  - **Done when**: All verification commands pass
  - **Commit**: `chore(qa): pass quality checkpoint` (only if fixes needed)

- [ ] 1.7 [VERIFY] POC Checkpoint: All 4 agent files complete
  - **Do**: Verify all 4 agent modifications are complete per design
  - **Verify**: Run these commands, ALL must succeed (exit 0):
    ```bash
    # qa-engineer.md: exists with VERIFICATION_PASS/FAIL and mandatory block
    test -f /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "VERIFICATION_PASS" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "<mandatory>" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1

    # spec-executor.md: has [VERIFY] Task Handling section with qa-engineer reference
    grep -q "\[VERIFY\] Task Handling" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    grep -q "qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    grep -q "Task tool" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1

    # task-planner.md: has [VERIFY] Task Format section with V4/V5/V6
    grep -q "\[VERIFY\] Task Format" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "V4.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "V6.*AC checklist" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1

    # research-analyst.md: has Quality Command Discovery with sources
    grep -q "Quality Command Discovery" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    grep -q "package.json\|CI config" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    ```
  - **Pass criteria**: All 13 commands exit 0
  - **Fail criteria**: Any command exits non-zero
  - **Done when**: All verification commands pass
  - **Commit**: `feat(qa): complete POC for [VERIFY] tasks`

## Phase 2: Refactoring

After POC validated, clean up and add error handling.

- [ ] 2.1 Improve qa-engineer error handling
  - **Do**:
    1. Add error handling section for command failures
    2. Add timeout handling guidance
    3. Add output truncation rules (last 50 lines)
    4. Add SKIP handling for missing commands
    5. Ensure .progress.md logging is documented
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: Error handling section added with SKIP logic and truncation rules
  - **Verify**: `grep -c "SKIP\|timeout\|truncate" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md` returns > 2
  - **Commit**: `refactor(qa): add error handling to qa-engineer`
  - _Design: Error Handling table_
  - _Requirements: NFR-2_

- [ ] 2.2 Improve spec-executor [VERIFY] section with retry context
  - **Do**:
    1. Add clear instructions for logging VERIFICATION_FAIL to .progress.md
    2. Add context about task retry mechanism
    3. Ensure spec files are included in commit rule for [VERIFY] tasks
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: [VERIFY] section includes retry context and progress logging
  - **Verify**: `grep -c "retry\|.progress.md" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md` returns > 3
  - **Commit**: `refactor(qa): add retry context to spec-executor [VERIFY] handling`
  - _Requirements: AC-6.1, AC-6.2, AC-6.3_

- [ ] 2.3 [VERIFY] Quality checkpoint: refactoring complete
  - **Do**: Verify error handling and retry context added correctly
  - **Verify**: Run these commands, ALL must succeed (exit 0):
    ```bash
    # qa-engineer.md has error handling patterns
    grep -q "SKIP" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -qi "timeout\|truncate" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q ".progress.md" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1

    # spec-executor.md has retry context
    grep -qi "retry" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    grep -q ".progress.md" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    ```
  - **Pass criteria**: All 5 commands exit 0
  - **Fail criteria**: Any command exits non-zero
  - **Done when**: All verification commands pass
  - **Commit**: `chore(qa): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

No automated tests for markdown agent files. Testing via integration validation.

- [ ] 3.1 Validate qa-engineer structure against design
  - **Do**: Compare qa-engineer.md against design.md Component 1 spec:
    1. Check frontmatter matches design (name, description, tools)
    2. Verify VERIFICATION_PASS/FAIL output format matches design
    3. Verify AC checklist format matches design
    4. Verify mandatory blocks present
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: Agent structure matches design specification
  - **Verify**:
    - `grep "name: qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
    - `grep "VERIFICATION_PASS\|VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
  - **Commit**: `test(qa): validate qa-engineer against design` (if corrections made)
  - _Design: Component 1_

- [ ] 3.2 Validate spec-executor [VERIFY] section against design
  - **Do**: Compare spec-executor [VERIFY] section against design.md Component 2:
    1. Check detection logic matches design
    2. Verify Task tool delegation format matches design
    3. Verify VERIFICATION_PASS/FAIL handling matches design
    4. Verify mandatory block present
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: [VERIFY] section matches design specification
  - **Verify**: `grep "Task tool\|VERIFICATION_PASS\|VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `test(qa): validate spec-executor against design` (if corrections made)
  - _Design: Component 2_

- [ ] 3.3 Validate task-planner [VERIFY] format against design
  - **Do**: Compare task-planner [VERIFY] section against design.md:
    1. Check [VERIFY] task format matches design
    2. Verify final sequence (V4/V5/V6) order matches design
    3. Verify mandatory block present
    4. Verify research.md command discovery reference
  - **Files**: `/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: [VERIFY] format matches design specification
  - **Verify**: `grep "V4\|V5\|V6" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `test(qa): validate task-planner against design` (if corrections made)
  - _Design: Component 3_

- [ ] 3.4 [VERIFY] Quality checkpoint: all files match design
  - **Do**: Verify all modifications align with design
  - **Verify**: Run these commands, ALL must succeed (exit 0):
    ```bash
    # qa-engineer matches design Component 1
    grep -q "name: qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "tools:.*Read.*Bash.*Grep" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1
    grep -q "When Invoked" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || exit 1

    # spec-executor matches design Component 2
    grep -q "\[VERIFY\] Task Handling" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1
    grep -q "Task tool\|Task:" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || exit 1

    # task-planner matches design Component 3
    grep -q "\[VERIFY\] Task Format" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1
    grep -q "research.md" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || exit 1

    # research-analyst matches design Component 4
    grep -q "Quality Command Discovery" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || exit 1
    ```
  - **Pass criteria**: All 8 commands exit 0
  - **Fail criteria**: Any command exits non-zero
  - **Done when**: All verification commands pass
  - **Commit**: `chore(qa): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Verify all modified files:
    1. Check qa-engineer.md has all required sections
    2. Check spec-executor.md [VERIFY] section complete
    3. Check task-planner.md [VERIFY] format complete
    4. Check research-analyst.md Quality Command Discovery complete
  - **Verify**: All files contain expected content:
    - `grep "VERIFICATION" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md`
    - `grep "\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md`
    - `grep "\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md`
    - `grep "Quality Command" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: All grep commands return matches
  - **Commit**: `fix(qa): address any issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Push branch: `git push -u origin feat/qa-verification`
    4. Create PR: `gh pr create --title "feat(qa): Add [VERIFY] task verification system" --body "Adds qa-engineer agent and [VERIFY] task support per spec qa-verification"`
    5. If gh CLI unavailable, provide manual PR URL
  - **Verify**: `gh pr checks --watch` shows all checks passing
  - **Done when**: PR created, CI green
  - **If CI fails**: Read `gh pr checks`, fix issues, push fixes

- [ ] V4 [VERIFY] Full local validation
  - **Do**: Run complete local verification of all 4 agent files
  - **Verify**: Run ALL these commands, each must exit 0:
    ```bash
    # === qa-engineer.md verification ===
    # File exists
    test -f /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: qa-engineer.md not found"; exit 1; }
    # Has correct frontmatter name
    grep -q "^name: qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: frontmatter name missing"; exit 1; }
    # Has tools list with required tools
    grep -q "tools:.*Read" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: tools list missing Read"; exit 1; }
    grep -q "tools:.*Bash" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: tools list missing Bash"; exit 1; }
    # Has VERIFICATION_PASS and VERIFICATION_FAIL signals
    grep -q "VERIFICATION_PASS" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: VERIFICATION_PASS missing"; exit 1; }
    grep -q "VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: VERIFICATION_FAIL missing"; exit 1; }
    # Has mandatory block
    grep -q "<mandatory>" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: mandatory block missing"; exit 1; }
    # Has When Invoked section
    grep -q "When Invoked" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: When Invoked section missing"; exit 1; }
    # Has AC checklist handling
    grep -qi "AC.*checklist\|checklist.*AC" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/qa-engineer.md || { echo "FAIL: AC checklist handling missing"; exit 1; }

    # === spec-executor.md verification ===
    # Has [VERIFY] Task Handling section header
    grep -q "## \[VERIFY\] Task Handling" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: [VERIFY] Task Handling section missing"; exit 1; }
    # References qa-engineer for delegation
    grep -q "qa-engineer" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: qa-engineer reference missing"; exit 1; }
    # Has Task tool delegation instruction
    grep -qi "Task tool\|Task:" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: Task tool delegation missing"; exit 1; }
    # Has VERIFICATION_PASS handling
    grep -q "VERIFICATION_PASS" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: VERIFICATION_PASS handling missing"; exit 1; }
    # Has VERIFICATION_FAIL handling
    grep -q "VERIFICATION_FAIL" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: VERIFICATION_FAIL handling missing"; exit 1; }
    # Has mandatory block
    grep -q "<mandatory>" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/spec-executor.md || { echo "FAIL: mandatory block missing in spec-executor"; exit 1; }

    # === task-planner.md verification ===
    # Has [VERIFY] Task Format section header
    grep -q "## \[VERIFY\] Task Format" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: [VERIFY] Task Format section missing"; exit 1; }
    # Has V4 final verification task format
    grep -q "V4.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: V4 [VERIFY] format missing"; exit 1; }
    # Has V5 CI verification format
    grep -q "V5.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: V5 [VERIFY] format missing"; exit 1; }
    # Has V6 AC checklist format
    grep -q "V6.*\[VERIFY\]" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: V6 [VERIFY] format missing"; exit 1; }
    # References research.md for command discovery
    grep -q "research.md" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: research.md reference missing"; exit 1; }
    # Has mandatory block
    grep -q "<mandatory>" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/task-planner.md || { echo "FAIL: mandatory block missing in task-planner"; exit 1; }

    # === research-analyst.md verification ===
    # Has Quality Command Discovery section header
    grep -q "## Quality Command Discovery" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || { echo "FAIL: Quality Command Discovery section missing"; exit 1; }
    # Mentions package.json as source
    grep -q "package.json" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || { echo "FAIL: package.json source missing"; exit 1; }
    # Mentions Makefile as source
    grep -q "Makefile" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || { echo "FAIL: Makefile source missing"; exit 1; }
    # Mentions CI configs as source
    grep -qi "CI config\|\.github/workflows\|CI.*yml" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || { echo "FAIL: CI config source missing"; exit 1; }
    # Has mandatory block
    grep -q "<mandatory>" /home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents/research-analyst.md || { echo "FAIL: mandatory block missing in research-analyst"; exit 1; }

    echo "All V4 verification checks PASSED"
    ```
  - **Pass criteria**: All 27 grep/test commands exit 0 and "All V4 verification checks PASSED" printed
  - **Fail criteria**: Any command exits non-zero, error message indicates which check failed
  - **Done when**: All verification commands pass
  - **Commit**: `chore(qa): pass local CI` (only if fixes needed)

- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Verify CI pipeline after push
  - **Verify**: Run these commands:
    ```bash
    # Check PR exists
    gh pr view --json state -q '.state' | grep -q "OPEN" || { echo "FAIL: PR not open"; exit 1; }

    # Check CI status
    gh pr checks 2>/dev/null
    CI_STATUS=$?

    # If gh pr checks exits 0, all checks passed
    if [ $CI_STATUS -eq 0 ]; then
      echo "PASS: All CI checks green"
    else
      echo "FAIL: CI checks not passing, run 'gh pr checks' for details"
      exit 1
    fi
    ```
  - **Pass criteria**: `gh pr checks` exits 0 (all checks passing)
  - **Fail criteria**: `gh pr checks` exits non-zero or shows failing checks
  - **Done when**: All CI checks green
  - **Commit**: None (verification only)

- [ ] V6 [VERIFY] AC checklist against requirements.md
  - **Do**: Read requirements.md, verify each AC-* is satisfied by checking specific patterns in implementation files
  - **Verify**: Run ALL these AC verification commands:
    ```bash
    BASE="/home/tzachb/Projects/ralph-specum-qa-verification/plugins/ralph-specum/agents"

    echo "=== US-1: Integrated Verification Tasks ==="
    # AC-1.1: Tasks with [VERIFY] tag are recognized as verification tasks
    grep -q "\[VERIFY\]" $BASE/spec-executor.md && echo "AC-1.1 PASS: [VERIFY] tag recognized in spec-executor" || { echo "AC-1.1 FAIL"; exit 1; }

    # AC-1.2: [VERIFY] tasks placed at quality checkpoints (every 2-3 tasks) and at spec end
    grep -q "every 2-3 tasks\|2-3 tasks\|checkpoints" $BASE/task-planner.md && echo "AC-1.2 PASS: checkpoint frequency documented" || { echo "AC-1.2 FAIL"; exit 1; }

    # AC-1.3: Task-planner generates [VERIFY] tasks using commands discovered during research
    grep -q "research.md" $BASE/task-planner.md && echo "AC-1.3 PASS: research.md referenced for commands" || { echo "AC-1.3 FAIL"; exit 1; }

    # AC-1.4: [VERIFY] tasks follow standard task format (Do/Verify/Done when/Commit)
    grep -q "Do.*Verify.*Done" $BASE/task-planner.md && echo "AC-1.4 PASS: standard format documented" || { echo "AC-1.4 FAIL"; exit 1; }

    echo "=== US-2: Verification Task Delegation ==="
    # AC-2.1: spec-executor detects [VERIFY] tag in task description
    grep -q "\[VERIFY\].*detect\|detect.*\[VERIFY\]" $BASE/spec-executor.md && echo "AC-2.1 PASS: detection logic present" || { echo "AC-2.1 FAIL"; exit 1; }

    # AC-2.2: spec-executor delegates [VERIFY] tasks to qa-engineer agent via Task tool
    grep -q "qa-engineer" $BASE/spec-executor.md && grep -qi "Task tool\|Task:" $BASE/spec-executor.md && echo "AC-2.2 PASS: delegation to qa-engineer documented" || { echo "AC-2.2 FAIL"; exit 1; }

    # AC-2.3: qa-engineer runs specified verification commands
    grep -q "Bash" $BASE/qa-engineer.md && grep -qi "command\|run" $BASE/qa-engineer.md && echo "AC-2.3 PASS: command execution capability" || { echo "AC-2.3 FAIL"; exit 1; }

    # AC-2.4: qa-engineer outputs VERIFICATION_PASS or VERIFICATION_FAIL
    grep -q "VERIFICATION_PASS" $BASE/qa-engineer.md && grep -q "VERIFICATION_FAIL" $BASE/qa-engineer.md && echo "AC-2.4 PASS: signals documented" || { echo "AC-2.4 FAIL"; exit 1; }

    # AC-2.5: On VERIFICATION_FAIL, task remains unchecked for retry
    grep -qi "unchecked\|not.*complete\|NOT.*mark" $BASE/spec-executor.md && echo "AC-2.5 PASS: fail handling documented" || { echo "AC-2.5 FAIL"; exit 1; }

    echo "=== US-3: Quality Command Discovery ==="
    # AC-3.1: Research phase scans package.json scripts
    grep -q "package.json" $BASE/research-analyst.md && echo "AC-3.1 PASS: package.json scanning documented" || { echo "AC-3.1 FAIL"; exit 1; }

    # AC-3.2: Research phase checks Makefile for relevant targets
    grep -q "Makefile" $BASE/research-analyst.md && echo "AC-3.2 PASS: Makefile scanning documented" || { echo "AC-3.2 FAIL"; exit 1; }

    # AC-3.3: Research phase scans CI config files
    grep -qi "CI config\|\.github/workflows\|CI.*yml" $BASE/research-analyst.md && echo "AC-3.3 PASS: CI config scanning documented" || { echo "AC-3.3 FAIL"; exit 1; }

    # AC-3.4: Discovered commands documented in research.md
    grep -qi "research.md\|Quality Commands" $BASE/research-analyst.md && echo "AC-3.4 PASS: output format documented" || { echo "AC-3.4 FAIL"; exit 1; }

    # AC-3.5: Task-planner uses discovered commands
    grep -q "research.md\|discovered" $BASE/task-planner.md && echo "AC-3.5 PASS: task-planner uses discovered commands" || { echo "AC-3.5 FAIL"; exit 1; }

    echo "=== US-4: Final Verification Sequence ==="
    # AC-4.1: V4 task runs full local CI
    grep -q "V4.*\[VERIFY\].*local\|V4.*local.*CI" $BASE/task-planner.md && echo "AC-4.1 PASS: V4 local CI documented" || { echo "AC-4.1 FAIL"; exit 1; }

    # AC-4.2: V5 task verifies CI pipeline passes after push
    grep -q "V5.*\[VERIFY\].*CI\|V5.*CI.*pipeline" $BASE/task-planner.md && echo "AC-4.2 PASS: V5 remote CI documented" || { echo "AC-4.2 FAIL"; exit 1; }

    # AC-4.3: V6 task checks each AC from requirements.md
    grep -q "V6.*\[VERIFY\].*AC\|V6.*AC.*checklist" $BASE/task-planner.md && echo "AC-4.3 PASS: V6 AC checklist documented" || { echo "AC-4.3 FAIL"; exit 1; }

    # AC-4.4: Order is enforced: local CI, then remote CI, then AC checklist
    # Check V4 appears before V5 and V5 before V6 in file
    V4_LINE=$(grep -n "V4.*\[VERIFY\]" $BASE/task-planner.md | head -1 | cut -d: -f1)
    V5_LINE=$(grep -n "V5.*\[VERIFY\]" $BASE/task-planner.md | head -1 | cut -d: -f1)
    V6_LINE=$(grep -n "V6.*\[VERIFY\]" $BASE/task-planner.md | head -1 | cut -d: -f1)
    [ "$V4_LINE" -lt "$V5_LINE" ] && [ "$V5_LINE" -lt "$V6_LINE" ] && echo "AC-4.4 PASS: V4 < V5 < V6 order enforced" || { echo "AC-4.4 FAIL: wrong order"; exit 1; }

    echo "=== US-5: AC Traceability ==="
    # AC-5.1: qa-engineer reads requirements.md for AC checklist verification
    grep -q "requirements.md" $BASE/qa-engineer.md && echo "AC-5.1 PASS: requirements.md reading documented" || { echo "AC-5.1 FAIL"; exit 1; }

    # AC-5.2: Each AC-* entry is checked against implementation
    grep -qi "AC-\|AC.*check\|each.*AC" $BASE/qa-engineer.md && echo "AC-5.2 PASS: AC checking documented" || { echo "AC-5.2 FAIL"; exit 1; }

    # AC-5.3: AC verification results recorded in .progress.md
    grep -q ".progress.md" $BASE/qa-engineer.md && echo "AC-5.3 PASS: .progress.md logging documented" || { echo "AC-5.3 FAIL"; exit 1; }

    # AC-5.4: Any unverified AC causes VERIFICATION_FAIL
    grep -q "VERIFICATION_FAIL" $BASE/qa-engineer.md && grep -qi "FAIL\|fail" $BASE/qa-engineer.md && echo "AC-5.4 PASS: fail on unverified AC documented" || { echo "AC-5.4 FAIL"; exit 1; }

    echo "=== US-6: Verification Retry ==="
    # AC-6.1: On VERIFICATION_FAIL, task stays unchecked in tasks.md
    grep -qi "unchecked\|NOT.*mark\|not.*complete" $BASE/spec-executor.md && echo "AC-6.1 PASS: task stays unchecked on fail" || { echo "AC-6.1 FAIL"; exit 1; }

    # AC-6.2: spec-executor can retry the same [VERIFY] task after fixes
    grep -qi "retry\|next iteration\|re-run" $BASE/spec-executor.md && echo "AC-6.2 PASS: retry mechanism documented" || { echo "AC-6.2 FAIL"; exit 1; }

    # AC-6.3: Failure details logged in .progress.md
    grep -q ".progress.md" $BASE/spec-executor.md && echo "AC-6.3 PASS: failure logging documented" || { echo "AC-6.3 FAIL"; exit 1; }

    echo ""
    echo "=== ALL 24 ACs VERIFIED ==="
    echo "VERIFICATION_PASS"
    ```
  - **Pass criteria**: All 24 AC checks print "PASS" and final output shows "ALL 24 ACs VERIFIED" and "VERIFICATION_PASS"
  - **Fail criteria**: Any AC check prints "FAIL" and script exits with error
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None (verification only)

## Notes

- **POC shortcuts taken**: None significant, agent files are markdown configuration
- **Production TODOs**: Integration testing in real spec execution (outside this spec scope)
- **Files modified**:
  1. `plugins/ralph-specum/agents/qa-engineer.md` - NEW
  2. `plugins/ralph-specum/agents/spec-executor.md` - MODIFIED
  3. `plugins/ralph-specum/agents/task-planner.md` - MODIFIED
  4. `plugins/ralph-specum/agents/research-analyst.md` - MODIFIED
