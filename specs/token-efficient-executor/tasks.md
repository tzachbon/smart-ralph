# Tasks: token-efficient-executor

## Overview

Total tasks: 6

**Workflow**: Simplified (write -> verify -> E2E -> finalize)
**Scope**: Single file rewrite: `plugins/ralph-specum/agents/spec-executor.md`

## Phase 1: Write the Rewrite

- [ ] 1.1 Rewrite spec-executor.md from design.md sections
  - **Do**:
    1. Read `specs/token-efficient-executor/design.md` section-by-section content spec (Section 2)
    2. Assemble the complete new `spec-executor.md` by concatenating: frontmatter (unchanged) + all 13 XML sections (`<role>`, `<input>`, `<flow>`, `<rules>`, `<tdd>`, `<verify_tasks>`, `<parallel>`, `<explore>`, `<progress>`, `<modifications>`, `<errors>`, `<output_protocol>`, `<bookend>`) using the exact "Rewritten content" code blocks from design.md
    3. Write the assembled file to `plugins/ralph-specum/agents/spec-executor.md`
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: File contains frontmatter + 13 XML sections, reads as a coherent agent prompt
  - **Verify**: `wc -l plugins/ralph-specum/agents/spec-executor.md | awk '{print ($1 <= 200) ? "PASS: "$1" lines" : "FAIL: "$1" lines (max 200)"}'`
  - **Commit**: `refactor(spec-executor): rewrite prompt from 570 to ~184 lines`
  - _Requirements: FR-1, FR-2, FR-3, FR-7, FR-8, NFR-1, NFR-2, NFR-7 / Design: Section 2_

## Phase 2: Content Verification

- [ ] 2.1 Verify rewritten content meets all acceptance criteria
  - **Do**:
    1. Verify line count <= 200: `wc -l plugins/ralph-specum/agents/spec-executor.md`
    2. Verify all 13 XML section tags present: `<role>`, `<input>`, `<flow>`, `<rules>`, `<tdd>`, `<verify_tasks>`, `<parallel>`, `<explore>`, `<progress>`, `<modifications>`, `<errors>`, `<output_protocol>`, `<bookend>`
    3. Verify TASK_COMPLETE signal preserved in output_protocol section
    4. Verify TASK_MODIFICATION_REQUEST signal preserved in modifications section with JSON schema
    5. Verify zero ALL-CAPS emphasis words (CRITICAL, MUST, ALWAYS, NEVER, NON-NEGOTIABLE) except in signal names (TASK_COMPLETE, TASK_MODIFICATION_REQUEST) and tag names ([RED], [GREEN], [YELLOW], [VERIFY])
    6. Verify bookend strategy: critical rules appear in both `<role>` and `<bookend>` sections
    7. Verify few-shot examples: at least 2 output examples (pass and fail cases) in `<output_protocol>`
    8. Verify suppression list present in `<output_protocol>`
    9. Verify all 9 unique behavioral rules preserved (end-to-end validation, TDD tags, task modification requests, commit discipline, execution rules, progress updates, Karpathy rules, output format, communication style)
    10. Cross-check: verify TASK_COMPLETE output format in rewritten prompt is compatible with stop-watcher.sh pattern matching (read hooks/scripts/stop-watcher.sh to confirm)
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: All 9 checks pass
  - **Verify**: `wc -l plugins/ralph-specum/agents/spec-executor.md | awk '{exit ($1 > 200)}'  && grep -c '</role>\|</input>\|</flow>\|</rules>\|</tdd>\|</verify_tasks>\|</parallel>\|</explore>\|</progress>\|</modifications>\|</errors>\|</output_protocol>\|</bookend>' plugins/ralph-specum/agents/spec-executor.md | awk '{exit ($1 != 13)}'  && grep -q 'TASK_COMPLETE' plugins/ralph-specum/agents/spec-executor.md && grep -q 'TASK_MODIFICATION_REQUEST' plugins/ralph-specum/agents/spec-executor.md && echo PASS`
  - **Commit**: `chore(spec-executor): pass content verification checkpoint`
  - _Requirements: FR-3, FR-4, FR-5, FR-6, FR-7, AC-1.1, AC-1.2, AC-2.1, AC-2.2, AC-2.3 / Design: Sections 4-5_

## Phase 3: E2E Verification

- [ ] 3.1 E2E test: invoke rewritten executor on a sample task
  - **Do**:
    1. Use task 1.1 of this spec (token-efficient-executor) as the test input -- it is a completed, simple file-write task
    2. Invoke the rewritten spec-executor agent via Task tool with: basePath=./specs/token-efficient-executor, specName=token-efficient-executor, task index 0, task block from tasks.md, and .progress.md context
    3. Capture the executor's output and verify it contains TASK_COMPLETE followed by status:/commit:/verify: fields
    4. Verify the executor does not produce suppressed output patterns (no task echoing, no reasoning narration, no celebration)
    5. Verify commit includes tasks.md and progress file
    6. Regression checks: verify no AskUserQuestion calls in executor output, .ralph-state.json unmodified after execution, commit message matches task's Commit line
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: Executor output contains "TASK_COMPLETE" and "status:" fields, no suppressed patterns present, regression checks pass
  - **Verify**: Executor output contains TASK_COMPLETE signal and key:value status fields
  - **Commit**: `chore(spec-executor): pass E2E verification`
  - _Requirements: AC-3.1, AC-2.4, NFR-5 / Design: Section 7_

## Phase 4: Finalize

- [ ] 4.1 Bump plugin version
  - **Do**:
    1. Bump version from `4.7.2` to `4.8.0` in `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Bump version from `4.7.2` to `4.8.0` in `.claude-plugin/marketplace.json` (ralph-specum entry)
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files show version `4.8.0`
  - **Verify**: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json | grep -c '4.8.0' | awk '{exit ($1 != 2)}'  && echo PASS`
  - **Commit**: `chore(ralph-specum): bump version to 4.8.0`
  - _Requirements: CLAUDE.md version bump policy_

- [ ] 4.2 Create PR
  - **Do**:
    1. Push branch: `git push -u origin $(git branch --show-current)`
    2. Create PR with summary of changes: 570-line prompt rewritten to ~184 lines (68% reduction), output constraints added for ~90% output token reduction, zero behavioral change
  - **Files**: none (git operation)
  - **Done when**: PR created and URL returned
  - **Verify**: `gh pr view --json url --jq .url`
  - **Commit**: none

## Dependencies

```
1.1 (write) -> 2.1 (verify content) -> 3.1 (E2E test) -> 4.1 (version bump) -> 4.2 (PR)
```
