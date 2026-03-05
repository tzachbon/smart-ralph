---
generated: auto
---

# Tasks: Parallel Task Execution

## Overview

Total tasks: 43

POC-first workflow (GREENFIELD -- adding new [P] marker capability):
1. Phase 1: Make It Work (POC) - Add [P] support to task-planner, template, and stop-watcher
2. Phase 2: Refactoring - Clean up and consolidate additions
3. Phase 3: Testing - Verify via automated grep/bash checks
4. Phase 4: Quality Gates - Local checks and PR creation
5. Phase 5: PR Lifecycle - CI monitoring, review resolution

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: Existing stop-watcher behavior unchanged for non-[P] tasks
- Modular & Reusable: [P] rules section is self-contained in task-planner.md
- Real-World Validation: stop-watcher correctly emits parallel continuation prompt
- All Tests Pass: Grep-based validation confirms all patterns present
- CI Green: All CI checks passing
- PR Ready: Pull request created, reviewed, approved
- Review Comments Resolved: All code review feedback addressed

> **Quality Checkpoints**: Intermediate quality gate checks inserted every 2-3 tasks.

## Phase 1: Make It Work (POC)

Focus: Add [P] marker support to all 3 files + version bumps. Get it working end-to-end.

### Task-Planner Agent Updates

- [x] 1.1 [P] Add [P] marker rules section to task-planner agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. Add a new `## [P] Parallel Task Marking` section after the existing `## [VERIFY] Task Format` section (around line 343)
    3. Include the rules from design.md: all 4 conditions for marking [P], format example, and rules (VERIFY breaks groups, single [P] = sequential, max 5, phase boundaries break groups)
    4. Include the "When in doubt, keep sequential" guidance
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains `## [P] Parallel Task Marking` section with all 4 conditions and rules
  - **Verify**: `grep -c '\[P\] Parallel Task Marking' plugins/ralph-specum/agents/task-planner.md | grep -q '1' && echo PASS`
  - **Commit**: `feat(task-planner): add [P] parallel task marking rules`
  - _Requirements: FR-1, US-1_
  - _Design: Component 1 - Task Planner Agent_

- [x] 1.2 [P] Add [P] heuristics to task-planner agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. Within the `## [P] Parallel Task Marking` section (added in 1.1), add a subsection for auto-detection heuristics
    3. Include heuristics: check Files: sections for overlap, check Do: for references to other tasks' outputs, shared config file detection (package.json, tsconfig.json, etc.)
    4. Add example showing 2 [P] tasks with different Files: sections followed by a [VERIFY] checkpoint
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains parallelizability heuristics with file-overlap detection guidance
  - **Verify**: `grep -c 'file overlap' plugins/ralph-specum/agents/task-planner.md | grep -qv '0' && echo PASS`
  - **Commit**: `feat(task-planner): add [P] auto-detection heuristics`
  - _Requirements: FR-1, FR-2, US-1_
  - _Design: Component 1 - Parallelizability Rules_

- [x] 1.3 [P] Add [P] to POC task examples in task-planner agent
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. In the `### POC Structure (GREENFIELD)` section, modify the example tasks 1.1 and 1.2 to show [P] usage
    3. Change `- [ ] 1.1 [Specific task name]` to `- [ ] 1.1 [P] [Specific task name]` and similarly for 1.2
    4. Keep 1.3 as [VERIFY] (unchanged) to show the pattern of [P] tasks followed by [VERIFY] breaking the group
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: POC example shows [P] markers on tasks 1.1 and 1.2, with [VERIFY] on 1.3
  - **Verify**: `grep -A1 '1.1 \[P\]' plugins/ralph-specum/agents/task-planner.md | head -1 | grep -q '\[P\]' && echo PASS`
  - **Commit**: `feat(task-planner): add [P] to POC task examples`
  - _Requirements: FR-1, FR-9_
  - _Design: Component 1 - Task Planner Agent_

- [x] 1.4 [VERIFY] Quality checkpoint: verify task-planner.md changes
  - **Do**: Verify all 3 task-planner additions are present and well-formed
  - **Verify**: `grep -c '\[P\]' plugins/ralph-specum/agents/task-planner.md | awk '{print ($1 >= 5) ? "PASS" : "FAIL: only " $1 " [P] occurrences"}'`
  - **Done when**: task-planner.md has [P] rules section, heuristics, and updated examples (at least 5 [P] references)
  - **Commit**: `chore(task-planner): pass quality checkpoint` (only if fixes needed)

### Templates Updates

- [x] 1.5 [P] Add [P] examples to POC section in tasks template
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. In the POC Phase 1 section, modify template tasks 1.1 and 1.2 to include [P] markers
    3. Change `- [ ] 1.1 {{Specific task name}}` to `- [ ] 1.1 [P] {{Specific task name}}` and similarly for 1.2
    4. Keep 1.3 Quality Checkpoint unchanged (demonstrates [VERIFY] breaking parallel group)
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: POC template shows [P] on tasks 1.1 and 1.2
  - **Verify**: `grep '1.1 \[P\]' plugins/ralph-specum/templates/tasks.md | grep -q '\[P\]' && echo PASS`
  - **Commit**: `feat(templates): add [P] markers to POC task examples`
  - _Requirements: FR-1, FR-9_
  - _Design: Component 2 - Tasks Template_

- [x] 1.6 [P] Add [P] examples to TDD section in tasks template
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. In the TDD Phase 1 section, the [RED]/[GREEN]/[YELLOW] tasks cannot be parallel (they depend on each other within a triplet)
    3. Add a new example after the first triplet (after 1.4 [VERIFY]) showing two independent [P] [RED] tests: `- [ ] 1.5 [P] [RED] Failing test: {{expected behavior B}}` and `- [ ] 1.6 [P] [RED] Failing test: {{expected behavior C}}`
    4. Add a comment explaining: "Adjacent [RED] tests for independent behaviors can be [P] since they don't depend on each other"
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: TDD template shows [P] usage with [RED] tests for independent behaviors
  - **Verify**: `grep '\[P\] \[RED\]' plugins/ralph-specum/templates/tasks.md | grep -q '\[P\]' && echo PASS`
  - **Commit**: `feat(templates): add [P] markers to TDD task examples`
  - _Requirements: FR-1, FR-9_
  - _Design: Component 2 - Tasks Template_

- [x] 1.7 [P] Add [P] marker documentation to task writing guide in template
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. In the `## Task Writing Guide` section, add a brief note about [P] markers after the existing sizing rules line
    3. Add: **Parallel markers**: Mark independent tasks with `[P]` for concurrent execution. Adjacent [P] tasks form a parallel group. [VERIFY] tasks always break groups.
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: Task Writing Guide section mentions [P] markers
  - **Verify**: `grep 'Parallel markers' plugins/ralph-specum/templates/tasks.md | grep -q '\[P\]' && echo PASS`
  - **Commit**: `feat(templates): add [P] marker documentation to task writing guide`
  - _Requirements: FR-1_
  - _Design: Component 2 - Tasks Template_

- [x] 1.8 [VERIFY] Quality checkpoint: verify template changes
  - **Do**: Verify all template [P] additions are present
  - **Verify**: `grep -c '\[P\]' plugins/ralph-specum/templates/tasks.md | awk '{print ($1 >= 4) ? "PASS" : "FAIL: only " $1 " [P] occurrences"}'`
  - **Done when**: templates/tasks.md has [P] in POC section, TDD section, and task writing guide (at least 4 references)
  - **Commit**: `chore(templates): pass quality checkpoint` (only if fixes needed)

### Stop-Watcher Updates

- [x] 1.9 Add [P] marker detection to stop-watcher task block extraction
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. After the existing TASK_BLOCK extraction (around line 231), add a check for [P] marker in the first line of TASK_BLOCK
    3. Add: `IS_PARALLEL="false"` before the check, then `if echo "$TASK_BLOCK" | head -1 | grep -q '\[P\]'; then IS_PARALLEL="true"; fi`
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh detects [P] marker and sets IS_PARALLEL variable
  - **Verify**: `grep 'IS_PARALLEL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'true' && echo PASS`
  - **Commit**: `feat(stop-watcher): add [P] marker detection`
  - _Requirements: FR-2, US-2_
  - _Design: Component 3 - Stop-Watcher_

- [x] 1.10 Add parallel group scanning to stop-watcher
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. After the IS_PARALLEL check (added in 1.9), add an awk script that scans for consecutive [P] tasks when IS_PARALLEL=true
    3. The awk script should: start from TASK_INDEX, collect all consecutive tasks with [P] marker, stop at non-[P] task or EOF
    4. Store result in PARALLEL_TASKS variable and replace TASK_BLOCK with it
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: When IS_PARALLEL=true, stop-watcher extracts all consecutive [P] tasks into TASK_BLOCK
  - **Verify**: `grep 'PARALLEL_TASKS' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'awk' && echo PASS`
  - **Commit**: `feat(stop-watcher): add parallel group scanning for consecutive [P] tasks`
  - _Requirements: FR-2, FR-3, US-2_
  - _Design: Component 3 - Stop-Watcher_

- [x] 1.11 [VERIFY] Quality checkpoint: verify stop-watcher [P] detection logic
  - **Do**: Verify stop-watcher has IS_PARALLEL detection and awk-based group scanning
  - **Verify**: `grep -c 'IS_PARALLEL\|PARALLEL_TASKS' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | awk '{print ($1 >= 3) ? "PASS" : "FAIL: only " $1 " references"}'`
  - **Done when**: stop-watcher.sh has both [P] detection and group scanning
  - **Commit**: `chore(stop-watcher): pass quality checkpoint` (only if fixes needed)

- [x] 1.12 Add parallel continuation prompt to stop-watcher
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. In the REASON heredoc (around line 241), add conditional parallel dispatch instructions when IS_PARALLEL=true
    3. When IS_PARALLEL=true, change the `## Current Task` header to `## Current Task Group (PARALLEL)` and add parallel dispatch instructions: "These are [P] tasks -- dispatch ALL in ONE message via Task tool. Each gets progressFile: .progress-task-$INDEX.md. After all complete: merge progress, advance taskIndex past group."
    4. When IS_PARALLEL=false, keep existing behavior unchanged
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Parallel tasks get distinct continuation prompt with parallel dispatch instructions
  - **Verify**: `grep 'PARALLEL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'dispatch ALL' && echo PASS`
  - **Commit**: `feat(stop-watcher): add parallel continuation prompt with dispatch instructions`
  - _Requirements: FR-3, US-2, US-3_
  - _Design: Component 3 - Stop-Watcher_

- [x] 1.13 Add parallel-specific system message to stop-watcher
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Modify the SYSTEM_MSG variable (around line 264) to include parallel indicator when IS_PARALLEL=true
    3. When IS_PARALLEL=true, append " (PARALLEL GROUP)" to the system message
    4. This gives the user visible feedback that parallel execution is happening
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: System message includes "(PARALLEL GROUP)" when [P] tasks detected
  - **Verify**: `grep 'PARALLEL GROUP' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q 'SYSTEM_MSG\|msg' && echo PASS`
  - **Commit**: `feat(stop-watcher): add parallel indicator to system message`
  - _Requirements: NFR-5, US-6_
  - _Design: Component 3 - Stop-Watcher_

- [x] 1.14 [VERIFY] Quality checkpoint: verify stop-watcher continuation prompt
  - **Do**: Verify stop-watcher has complete parallel support: detection, scanning, prompt, system message
  - **Verify**: `grep -c 'IS_PARALLEL\|PARALLEL_TASKS\|PARALLEL GROUP\|dispatch ALL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | awk '{print ($1 >= 4) ? "PASS" : "FAIL: only " $1 " parallel references"}'`
  - **Done when**: All 4 parallel components present in stop-watcher.sh
  - **Commit**: `chore(stop-watcher): pass quality checkpoint` (only if fixes needed)

### Version Bumps

- [x] 1.15 [P] Bump version in plugin.json
  - **Do**:
    1. Open `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Change `"version": "4.2.4"` to `"version": "4.3.0"` (minor bump for new feature)
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: plugin.json version is "4.3.0"
  - **Verify**: `grep '"version": "4.3.0"' plugins/ralph-specum/.claude-plugin/plugin.json && echo PASS`
  - **Commit**: `chore(ralph-specum): bump version to 4.3.0`
  - _Requirements: NFR-2_

- [x] 1.16 [P] Bump version in marketplace.json
  - **Do**:
    1. Open `.claude-plugin/marketplace.json`
    2. In the ralph-specum plugin entry, change `"version": "4.2.4"` to `"version": "4.3.0"`
  - **Files**: `.claude-plugin/marketplace.json`
  - **Done when**: marketplace.json ralph-specum version is "4.3.0"
  - **Verify**: `jq '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json | grep -q '4.3.0' && echo PASS`
  - **Commit**: `chore(marketplace): bump ralph-specum version to 4.3.0`
  - _Requirements: NFR-2_

- [x] 1.17 [VERIFY] Quality checkpoint: verify version bumps
  - **Do**: Verify both version files are consistent at 4.3.0
  - **Verify**: `grep '"4.3.0"' plugins/ralph-specum/.claude-plugin/plugin.json && jq '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json | grep '4.3.0' && echo PASS`
  - **Done when**: Both plugin.json and marketplace.json show version 4.3.0
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### POC End-to-End Validation

- [x] 1.18 [P] Validate task-planner [P] section is well-structured
  - **Do**:
    1. Read `plugins/ralph-specum/agents/task-planner.md` and verify:
    2. The [P] section has mandatory tags wrapping rules
    3. The 4 conditions for marking [P] are listed
    4. Max group size of 5 is mentioned
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: [P] section contains all required elements
  - **Verify**: `grep -c 'Max group size\|max.*5\|Max.*5' plugins/ralph-specum/agents/task-planner.md | awk '{print ($1 >= 1) ? "PASS" : "FAIL: missing max group size"}'`
  - **Commit**: None

- [x] 1.19 [P] Validate stop-watcher bash syntax
  - **Do**:
    1. Run bash syntax check on stop-watcher.sh
    2. Verify the script has no syntax errors after all modifications
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: bash -n reports no syntax errors
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: None

- [x] 1.20 [VERIFY] POC Checkpoint: end-to-end validation
  - **Do**: Verify all 3 modified files have [P] support and versions are bumped
  - **Verify**: `grep '\[P\] Parallel Task Marking' plugins/ralph-specum/agents/task-planner.md && grep '\[P\]' plugins/ralph-specum/templates/tasks.md && grep 'IS_PARALLEL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep '"4.3.0"' plugins/ralph-specum/.claude-plugin/plugin.json && bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo POC_COMPLETE`
  - **Done when**: All files modified, versions bumped, bash syntax valid
  - **Commit**: `feat(ralph-specum): complete POC for [P] parallel task execution`

- [x] 1.21 Create draft PR and push
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create draft PR: `gh pr create --draft --title "feat(ralph-specum): add [P] parallel task execution markers" --body "$(cat <<'EOF'
## Summary
- Add [P] inline marker support to task-planner agent for marking parallelizable tasks
- Add [P] examples to tasks.md template (both POC and TDD sections)
- Update stop-watcher to detect [P] groups and emit parallel continuation prompts
- Bump version to 4.3.0

## Changes
- `agents/task-planner.md`: New [P] marking rules, heuristics, and examples
- `templates/tasks.md`: [P] examples in POC and TDD sections
- `hooks/scripts/stop-watcher.sh`: Parallel group detection and dispatch instructions
- Version bump in plugin.json and marketplace.json

## Test Plan
- [ ] task-planner.md has [P] rules section with mandatory tags
- [ ] templates/tasks.md has [P] in POC and TDD sections
- [ ] stop-watcher.sh detects [P] and emits parallel prompt
- [ ] bash -n passes on stop-watcher.sh
- [ ] Versions consistent at 4.3.0
- [ ] CI checks pass
EOF
)"`
  - **Verify**: `gh pr view --json state --jq .state | grep -q 'OPEN' && echo PASS`
  - **Done when**: Draft PR created and pushed
  - **Commit**: None

## Phase 2: Refactoring

Focus: Clean up and ensure consistency across all additions.

- [x] 2.1 Ensure [P] rules use mandatory tags in task-planner
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. Wrap the [P] rules section content in `<mandatory>` tags (matching the pattern used by [VERIFY] and other sections)
    3. Ensure the section is inside mandatory tags for enforcement
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: [P] rules section wrapped in `<mandatory>` tags
  - **Verify**: `awk '/<mandatory>/,/<\/mandatory>/{if(/\[P\] Parallel Task Marking/) found=1} END{print found ? "PASS" : "FAIL"}' plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `refactor(task-planner): wrap [P] rules in mandatory tags`
  - _Design: Component 1_

- [x] 2.2 Add [P] to task-planner quality checklist
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. In the `## Quality Checklist` section (around line 690), add a new checklist item for [P]: `- [ ] Independent tasks marked [P] where file overlap is zero`
    3. Add under the POC-specific section: `- [ ] [P] groups have max 5 tasks, broken by [VERIFY] checkpoints`
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Quality checklist includes [P] verification items
  - **Verify**: `grep 'marked \[P\]' plugins/ralph-specum/agents/task-planner.md | grep -q 'checklist\|Quality\|file overlap\|Independent' && echo PASS`
  - **Commit**: `refactor(task-planner): add [P] items to quality checklist`
  - _Requirements: FR-1_

- [x] 2.3 [VERIFY] Quality checkpoint: verify refactoring consistency
  - **Do**: Verify task-planner.md has mandatory tags and quality checklist items for [P]
  - **Verify**: `grep '<mandatory>' plugins/ralph-specum/agents/task-planner.md | wc -l | awk '{print ($1 >= 1) ? "PASS" : "FAIL"}' && grep 'marked \[P\]' plugins/ralph-specum/agents/task-planner.md && echo REFACTOR_PASS`
  - **Done when**: Mandatory tags present and quality checklist updated
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 2.4 Ensure stop-watcher parallel block is well-commented
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Add a comment block before the IS_PARALLEL detection explaining the parallel group logic
    3. Comment: `# Parallel group detection: if current task has [P] marker, scan for consecutive [P] tasks and include all in continuation prompt`
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Parallel detection block has explanatory comment
  - **Verify**: `grep 'Parallel group detection' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: `refactor(stop-watcher): add comments for parallel group detection`
  - _Design: Component 3_

- [x] 2.5 Ensure template [P] examples have clear boundary comments
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. Add a markdown comment before the [P] TDD example explaining when [P] is valid with TDD: `<!-- [P] is valid for independent [RED] tests, but NOT within a single R-G-Y triplet -->`
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: TDD [P] example has explanatory comment
  - **Verify**: `grep 'NOT within a single R-G-Y triplet' plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: `refactor(templates): add clarifying comment for [P] in TDD context`
  - _Design: Component 2_

- [x] 2.6 [VERIFY] Quality checkpoint: verify refactoring complete
  - **Do**: Verify all refactoring tasks are reflected in the files
  - **Verify**: `grep 'Parallel group detection' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep 'NOT within a single R-G-Y' plugins/ralph-specum/templates/tasks.md && grep 'marked \[P\]' plugins/ralph-specum/agents/task-planner.md && echo REFACTOR_COMPLETE`
  - **Done when**: All 3 files have proper comments and structure
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Verify all changes via automated checks since there's no test runner for this plugin.

- [x] 3.1 Verify task-planner [P] rules content completeness
  - **Do**:
    1. Run comprehensive grep checks against task-planner.md to verify all required [P] content
    2. Check for: 4 conditions, max group size, phase boundaries, [VERIFY] breaks groups, "When in doubt" guidance
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: All 5 content checks pass
  - **Verify**: `grep 'file overlap' plugins/ralph-specum/agents/task-planner.md && grep 'max.*5\|Max.*5' plugins/ralph-specum/agents/task-planner.md && grep 'phase.*boundar' plugins/ralph-specum/agents/task-planner.md && grep 'VERIFY.*break\|break.*group' plugins/ralph-specum/agents/task-planner.md && grep 'doubt.*sequential\|sequential.*doubt' plugins/ralph-specum/agents/task-planner.md && echo ALL_CONTENT_PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: FR-1, FR-6_

- [x] 3.2 Verify task-planner [P] examples are valid markdown
  - **Do**:
    1. Verify task-planner.md [P] examples follow the exact task format: `- [ ] X.Y [P] Task name`
    2. Verify the examples include Do, Files, Done when, Verify, Commit fields
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: [P] examples in task-planner follow standard task format
  - **Verify**: `grep -A5 '\[P\].*task\|[P].*Create\|[P].*Specific' plugins/ralph-specum/agents/task-planner.md | grep -q 'Do\|Files\|Done when' && echo PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: FR-1_

- [x] 3.3 [VERIFY] Quality checkpoint: task-planner content tests
  - **Do**: Run all task-planner content verifications
  - **Verify**: `grep '\[P\] Parallel Task Marking' plugins/ralph-specum/agents/task-planner.md && grep '<mandatory>' plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Done when**: All task-planner content checks pass
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 3.4 Verify template [P] markers in POC section
  - **Do**:
    1. Verify templates/tasks.md has [P] markers on POC tasks 1.1 and 1.2
    2. Verify task 1.3 (Quality Checkpoint) does NOT have [P]
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: POC template correctly shows [P] on independent tasks and not on [VERIFY]
  - **Verify**: `grep '1.1 \[P\]' plugins/ralph-specum/templates/tasks.md && grep '1.2 \[P\]' plugins/ralph-specum/templates/tasks.md && ! grep '1.3 \[P\]' plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: FR-1, FR-9_

- [x] 3.5 Verify template [P] markers in TDD section
  - **Do**:
    1. Verify templates/tasks.md has [P] [RED] markers for independent test tasks
    2. Verify the TDD triplet tasks (1.1-1.3) do NOT have [P]
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: TDD template correctly shows [P] only on independent tasks
  - **Verify**: `grep '\[P\] \[RED\]' plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: FR-1, FR-9_

- [x] 3.6 [VERIFY] Quality checkpoint: template content tests
  - **Do**: Run all template content verifications
  - **Verify**: `grep -c '\[P\]' plugins/ralph-specum/templates/tasks.md | awk '{print ($1 >= 4) ? "PASS" : "FAIL"}'`
  - **Done when**: Template has at least 4 [P] references
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 3.7 Verify stop-watcher [P] detection with mock task block
  - **Do**:
    1. Create a small test: pipe a mock [P] task line through the detection logic
    2. `echo "- [ ] 1.2 [P] Create user service" | head -1 | grep -q '\[P\]' && echo "DETECTED"`
    3. Also test negative: `echo "- [ ] 1.3 [VERIFY] Quality checkpoint" | head -1 | grep -q '\[P\]' || echo "NOT_DETECTED"`
  - **Done when**: [P] detection logic correctly identifies [P] and rejects non-[P] tasks
  - **Verify**: `echo "- [ ] 1.2 [P] Create user service" | head -1 | grep -q '\[P\]' && echo "- [ ] 1.3 [VERIFY] Quality checkpoint" | head -1 | grep -q '\[P\]' || echo PASS`
  - **Commit**: None (inline test)
  - _Requirements: FR-2_

- [x] 3.8 Verify stop-watcher bash syntax after all changes
  - **Do**:
    1. Run `bash -n` on the modified stop-watcher.sh
    2. Verify no syntax errors introduced by parallel detection additions
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: bash -n passes with exit code 0
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: NFR-2_

- [x] 3.9 Verify backward compatibility: non-[P] tasks unchanged
  - **Do**:
    1. Verify stop-watcher still has IS_PARALLEL="false" as default
    2. Verify the existing sequential REASON heredoc is unchanged for non-parallel tasks
    3. Verify IS_PARALLEL check wraps the parallel-specific code (not replacing sequential)
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Non-[P] task flow is identical to pre-change behavior
  - **Verify**: `grep 'IS_PARALLEL="false"' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep '## Current Task' plugins/ralph-specum/hooks/scripts/stop-watcher.sh | head -1 | grep -qv 'PARALLEL' && echo PASS`
  - **Commit**: None (read-only verification)
  - _Requirements: FR-9, NFR-2, NFR-3_

- [x] 3.10 [VERIFY] Quality checkpoint: all stop-watcher tests
  - **Do**: Run comprehensive stop-watcher verifications
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep 'IS_PARALLEL="false"' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep 'dispatch ALL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo ALL_STOP_WATCHER_PASS`
  - **Done when**: All stop-watcher tests pass
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 3.11 Verify version consistency across files
  - **Do**:
    1. Check that plugin.json and marketplace.json both have version 4.3.0
    2. Verify they match each other
  - **Done when**: Both version files show 4.3.0 for ralph-specum
  - **Verify**: `V1=$(jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json) && V2=$(jq -r '.plugins[] | select(.name=="ralph-specum") | .version' .claude-plugin/marketplace.json) && [ "$V1" = "$V2" ] && [ "$V1" = "4.3.0" ] && echo PASS`
  - **Commit**: None (read-only verification)

## Phase 4: Quality Gates

- [x] 4.1 [VERIFY] Full local validation: all files, all checks
  - **Do**: Run complete validation suite
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep '\[P\] Parallel Task Marking' plugins/ralph-specum/agents/task-planner.md && grep '\[P\]' plugins/ralph-specum/templates/tasks.md && jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json | grep '4.3.0' && echo FULL_LOCAL_PASS`
  - **Done when**: All local checks pass
  - **Commit**: `fix(ralph-specum): address any remaining issues` (only if fixes needed)

- [x] 4.2 Push latest changes and verify CI is green
  - **Do**:
    1. Push all changes: `git push`
    2. Wait for CI: `gh pr checks --watch`
    3. If CI fails: read logs with `gh run view --log-failed`, fix issues, push again
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes on the draft PR
  - **Commit**: `fix: address CI failures` (only if fixes needed)

- [x] 4.3 [VERIFY] CI pipeline passes
  - **Do**: Verify GitHub Actions/CI passes after push
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None

- [x] 4.3.1 Mark PR as ready for review
  - **Do**:
    1. Verify CI is green: `gh pr checks`
    2. Mark PR ready: `gh pr ready`
  - **Verify**: `gh pr view --json isDraft --jq .isDraft | grep -q 'false' && echo PASS`
  - **Done when**: PR is no longer in draft mode, marked ready for review
  - **Commit**: None

- [x] 4.4 [VERIFY] AC checklist
  - **Do**: Verify each acceptance criterion from requirements.md
  - **Verify**:
    1. US-1 (task author marks [P]): `grep '\[P\] Parallel Task Marking' plugins/ralph-specum/agents/task-planner.md && echo AC_US1_PASS`
    2. US-2 (coordinator identifies groups): `grep 'Parallel Group Detection' plugins/ralph-specum/hooks/scripts/stop-watcher.sh || grep 'IS_PARALLEL' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo AC_US2_PASS`
    3. US-6 (user sees parallel): `grep 'PARALLEL GROUP' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo AC_US6_PASS`
    4. FR-1 (markdown format): `grep '\[P\]' plugins/ralph-specum/templates/tasks.md && echo AC_FR1_PASS`
    5. FR-9 (backward compat): `grep 'IS_PARALLEL="false"' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo AC_FR9_PASS`
    6. NFR-2 (no breaking): `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo AC_NFR2_PASS`
  - **Done when**: All AC checks pass
  - **Commit**: None

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met.

- [x] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Check status: `gh pr checks`
    2. If failures: read logs with `gh run view --log-failed`
    3. Fix issues locally
    4. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    5. Push: `git push`
    6. Repeat until all green
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed)

- [x] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED")'`
    2. For inline comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
    3. Implement requested changes
    4. Push fixes
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - {{summary}}` (per comment)

- [x] 5.3 Final validation
  - **Do**: Verify ALL completion criteria:
    1. All tasks checked: `grep -c '^\s*- \[x\]' specs/parallel-tasks-execution/tasks.md`
    2. No unchecked remain: `grep -c '^\s*- \[ \]' specs/parallel-tasks-execution/tasks.md | grep -q '^0$'`
    3. CI green: `gh pr checks`
    4. bash syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Verify**: All commands pass, all criteria met
  - **Done when**: All completion criteria confirmed
  - **Commit**: None

## Notes

- **POC shortcuts**: None -- this spec is small enough to implement fully in POC phase
- **No test framework**: This plugin has no test runner; verification is via grep/bash checks
- **Dogfooding**: This tasks.md itself uses [P] markers to demonstrate the feature
- **Existing infrastructure**: coordinator-pattern.md and spec-executor.md already have parallel support; we only add [P] awareness to task-planner, template, and stop-watcher
- **[P] groups in this spec**: Tasks 1.1-1.3 (parallel task-planner edits), 1.5-1.7 (parallel template edits), 1.15-1.16 (parallel version bumps), 1.18-1.19 (parallel validation)

## Dependencies

```text
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality) → Phase 5 (PR Lifecycle)

Within Phase 1:
- Tasks 1.1-1.3 [P] (task-planner) → 1.4 [VERIFY]
- Tasks 1.5-1.7 [P] (templates) → 1.8 [VERIFY]
- Tasks 1.9-1.10 (stop-watcher, sequential due to code dependency) → 1.11 [VERIFY]
- Tasks 1.12-1.13 (stop-watcher cont'd) → 1.14 [VERIFY]
- Tasks 1.15-1.16 [P] (version bumps) → 1.17 [VERIFY]
- Tasks 1.18-1.19 [P] (validation) → 1.20 [VERIFY] POC Checkpoint
```
