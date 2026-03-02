---
generated: auto
---

# Tasks: Autonomous E2E Verification

## Overview

Total tasks: 50

**POC-first workflow** (GREENFIELD):
1. Phase 1: Make It Work (POC) - 28 tasks (56%)
2. Phase 2: Refactoring - 9 tasks (18%)
3. Phase 3: Testing - 6 tasks (12%)
4. Phase 4: Quality Gates - 3 tasks (6%)
5. Phase 5: PR Lifecycle - 4 tasks (8%)

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: All existing tests pass (no broken functionality)
- Modular & Reusable: Code follows project patterns, properly abstracted
- Real-World Validation: Feature tested in actual environment (not just unit tests)
- All Tests Pass: Unit, integration, E2E all green
- CI Green: All CI checks passing
- PR Ready: Pull request created, reviewed, approved
- Review Comments Resolved: All code review feedback addressed

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks. Verification uses `test -f` and `grep` since this is a markdown-only plugin.

## Phase 1: Make It Work (POC)

Focus: Get all 8 files modified with VE content. Validate the system hangs together end-to-end. Accept rough prose, refine later.

### Research Phase: Verification Tooling Discovery

- [x] 1.1 Add Verification Tooling topic to parallel-research.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/parallel-research.md`
    2. In the "Topic Identification" table, add a new row: `| Verification Tooling | Explore | Dev server, test runner, browser deps, E2E configs, ports |`
    3. In the "Scaling by Complexity" section, note that Verification Tooling discovery is always assigned to an Explore agent
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`
  - **Done when**: parallel-research.md contains "Verification Tooling" row in topic table
  - **Verify**: `grep -q "Verification Tooling" plugins/ralph-specum/references/parallel-research.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add verification tooling topic to parallel research`
  - _Requirements: FR-2, AC-3.1_
  - _Design: Component 1_

- [x] 1.2 Add verification tooling discovery hints to research-analyst.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/research-analyst.md`
    2. After the "Quality Command Discovery" mandatory section, add a new mandatory section "## Verification Tooling Discovery"
    3. Include detection logic: dev server scripts (package.json scripts matching dev/start/serve), browser automation deps (playwright/puppeteer/cypress/selenium in deps), E2E config files, port detection, health endpoints, Docker detection
    4. Include output format: markdown table with Tool/Command/Detected From columns, Project Type line, Verification Strategy line
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: research-analyst.md has "Verification Tooling Discovery" section with detection commands and output format
  - **Verify**: `grep -q "Verification Tooling Discovery" plugins/ralph-specum/agents/research-analyst.md && grep -q "Project Type" plugins/ralph-specum/agents/research-analyst.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add verification tooling discovery to research-analyst`
  - _Requirements: FR-2, AC-3.2, AC-3.3, AC-3.4_
  - _Design: Component 1_

- [x] 1.3 [VERIFY] Quality checkpoint: file integrity
  - **Do**: Verify both modified files exist and contain expected new content
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/agents/research-analyst.md`
  - **Verify**: `test -f plugins/ralph-specum/references/parallel-research.md && test -f plugins/ralph-specum/agents/research-analyst.md && grep -q "Verification Tooling" plugins/ralph-specum/references/parallel-research.md && grep -q "Verification Tooling Discovery" plugins/ralph-specum/agents/research-analyst.md && echo PASS`
  - **Done when**: Both files contain new VE-related content
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Tasks Command: VE Prompt

- [x] 1.4 Add VE interview question to tasks.md Step 2
  - **Do**:
    1. Open `plugins/ralph-specum/commands/tasks.md`
    2. In Step 2's "Tasks Exploration Territory" list, add bullet: `- **E2E verification** -- add autonomous end-to-end verification tasks? (default YES). What should be tested end-to-end?`
    3. In the "Store Interview & Approach" section, add to the example: `- E2E verification: YES/NO -- [strategy or "auto"]`
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: tasks.md Step 2 contains E2E verification interview question and storage format
  - **Verify**: `grep -q "E2E verification" plugins/ralph-specum/commands/tasks.md && grep -q 'E2E verification: YES/NO' plugins/ralph-specum/commands/tasks.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE interview question to tasks command`
  - _Requirements: FR-7, AC-2.1, AC-2.2, AC-2.4_
  - _Design: Component 2_

- [x] 1.5 Add VE quick-mode context to tasks.md Step 3 delegation
  - **Do**:
    1. Open `plugins/ralph-specum/commands/tasks.md`
    2. In Step 3's delegation prompt instructions (the bulleted list under "Instruct to:"), add a bullet: `- If quick mode: auto-enable VE tasks. Pass verification tooling from research.md and strategy "auto" to task-planner`
    3. After the existing delegation instructions, add a note block explaining VE delegation context: include E2E Verification enabled/disabled, Verification Tooling section from research.md, and strategy
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: tasks.md Step 3 includes VE delegation context for both quick and normal modes
  - **Verify**: `grep -q "auto-enable VE tasks" plugins/ralph-specum/commands/tasks.md && grep -q "Verification Tooling" plugins/ralph-specum/commands/tasks.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE delegation context to tasks command`
  - _Requirements: FR-7, FR-8, AC-1.1_
  - _Design: Component 2_

- [x] 1.6 [VERIFY] Quality checkpoint: tasks command
  - **Do**: Verify tasks.md command contains all VE additions
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Verify**: `grep -c "E2E" plugins/ralph-specum/commands/tasks.md | xargs test 2 -le && echo PASS`
  - **Done when**: At least 2 E2E references in tasks command
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Task Planner: VE Task Generation

- [x] 1.7 Add project type detection section to task-planner.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. After the "VF Task Generation for Fix Goals" mandatory section, add a new mandatory section: `## VE Task Generation (E2E Verification)`
    3. Add project type detection table: Web App (dev server + browser deps -> start server, curl/browser check), API (dev server + health endpoint -> start server, curl endpoints), CLI (binary/script -> run commands, check output), Mobile (iOS/Android deps -> simulator if available), Library (no dev server, no UI -> build + import check only)
    4. Add instruction: "Read 'Verification Tooling' section from research.md to determine project type and available tools"
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains VE Task Generation section with project type detection table
  - **Verify**: `grep -q "VE Task Generation" plugins/ralph-specum/agents/task-planner.md && grep -q "Project Type" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE project type detection to task planner`
  - _Requirements: FR-9, AC-4.1, AC-4.3_
  - _Design: Component 3_

- [x] 1.8 Add VE task template to task-planner.md
  - **Do**:
    1. In the new "VE Task Generation" section (added in 1.7), add the VE task template block with 3 tasks: VE1 (startup), VE2 (check), VE3 (cleanup)
    2. VE1 template: start dev server in background, record PID, wait for ready with 60s timeout
    3. VE2 template: test critical user flow via curl/browser/CLI, verify expected output
    4. VE3 template: kill by PID, kill by port fallback, remove PID file, verify port free
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains VE1/VE2/VE3 task templates with Do/Verify/Done when/Commit fields
  - **Verify**: `grep -q "VE1" plugins/ralph-specum/agents/task-planner.md && grep -q "VE2" plugins/ralph-specum/agents/task-planner.md && grep -q "VE3" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE task templates to task planner`
  - _Requirements: FR-1, FR-4, FR-5, AC-4.2, AC-4.4, AC-4.5, AC-4.6_
  - _Design: Component 3_

- [x] 1.9 Add VE task rules to task-planner.md
  - **Do**:
    1. In the VE Task Generation section, after the template, add "VE Task Rules" subsection
    2. Rules: always sequential (never [P]), always [VERIFY] tag, VE-cleanup MUST always run, max 5 VE tasks (1 startup + 1-3 checks + 1 cleanup), commands from research.md not hardcoded, if no tooling: 1 VE task (build + import check) + cleanup
    3. Add placement rule: "VE tasks appear after V6 (AC checklist) and before Phase 5 (PR Lifecycle)"
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md contains VE task rules including placement, sequencing, and max count
  - **Verify**: `grep -q "VE Task Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "always sequential" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE task rules to task planner`
  - _Requirements: FR-1, AC-1.2, AC-4.7, NFR-1_
  - _Design: Component 3_

- [x] 1.10 [VERIFY] Quality checkpoint: task planner VE section
  - **Do**: Verify task-planner.md has complete VE section with detection, templates, and rules
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Verify**: `grep -q "VE Task Generation" plugins/ralph-specum/agents/task-planner.md && grep -q "VE1" plugins/ralph-specum/agents/task-planner.md && grep -q "VE Task Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "VE-cleanup" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Done when**: All 3 VE subsections present in task-planner.md
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 1.11 Add quick mode VE auto-enable logic to task-planner.md
  - **Do**:
    1. In the VE Task Generation section, add subsection "Quick Mode vs Normal Mode"
    2. Quick mode: always generate VE tasks, no user prompt needed. Use "auto" strategy (detect from research.md)
    3. Normal mode: check interview context for "E2E verification: YES/NO". If YES or not present (default YES), generate VE tasks. If NO, skip VE generation entirely.
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md distinguishes quick mode (auto-enable) from normal mode (interview-driven)
  - **Verify**: `grep -q "Quick Mode" plugins/ralph-specum/agents/task-planner.md && grep -q "auto-enable" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add quick/normal mode VE logic to task planner`
  - _Requirements: FR-7, AC-1.1, AC-2.3_
  - _Design: Component 3_

- [x] 1.12 Add library fallback VE template to task-planner.md
  - **Do**:
    1. In the VE Task Generation section, add "Library/No-Tooling Fallback" subsection
    2. Template: single VE1 task that runs build command and verifies import works, plus VE2 cleanup (minimal)
    3. No dev server startup needed; just verify build artifact is importable
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: task-planner.md has fallback VE template for library-type projects
  - **Verify**: `grep -q "Library" plugins/ralph-specum/agents/task-planner.md && grep -q "No.*Tooling\|No-Tooling\|no tooling\|fallback" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add library fallback VE template to task planner`
  - _Requirements: FR-9, AC-4.3_
  - _Design: Component 3_

- [x] 1.13 [VERIFY] Quality checkpoint: task planner complete
  - **Do**: Verify task-planner.md has all VE additions: generation section, templates, rules, quick/normal mode, fallback
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Verify**: `grep -c "VE" plugins/ralph-specum/agents/task-planner.md | xargs test 10 -le && echo PASS`
  - **Done when**: At least 10 VE references across all new subsections
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Phase Rules Extension

- [x] 1.14 Add VE Tasks section to phase-rules.md (POC workflow)
  - **Do**:
    1. Open `plugins/ralph-specum/references/phase-rules.md`
    2. After the "VF Task for Fix Goals" section (before "Quality Checkpoint Rules"), add new section: `## VE Tasks (E2E Verification)`
    3. Include: placement (V4 -> V5 -> V6 -> VE1 -> VE2 -> VE3 -> Phase 5), structure (startup + checks + cleanup), rules (sequential, [VERIFY] tagged, cleanup guaranteed, commands from research.md, recovery mode always enabled, max 3 retries per VE task)
    4. Include "When omitted" note: quick mode auto-enables, normal mode user can skip, library projects get minimal VE
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`
  - **Done when**: phase-rules.md contains VE Tasks section with placement, structure, rules, and omission guidance
  - **Verify**: `grep -q "VE Tasks" plugins/ralph-specum/references/phase-rules.md && grep -q "VE1.*VE2.*VE3" plugins/ralph-specum/references/phase-rules.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE tasks section to phase rules`
  - _Requirements: FR-10, FR-1_
  - _Design: Component 4_

- [x] 1.15 Add VE references to POC phase distribution in phase-rules.md
  - **Do**:
    1. In phase-rules.md POC workflow, update Phase 4 description to mention VE tasks placement between V6 and Phase 5
    2. In "POC Behaviors Per Phase" table, add a row for VE Tasks column or note that VE tasks appear in Phase 4's final verification sequence
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`
  - **Done when**: POC workflow sections reference VE task placement
  - **Verify**: `grep -A5 "Phase 4: Quality Gates" plugins/ralph-specum/references/phase-rules.md | grep -q "VE\|verification" && echo PASS`
  - **Commit**: `feat(ralph-specum): update POC phase distribution for VE tasks`
  - _Requirements: FR-10_
  - _Design: Component 4_

- [x] 1.16 Add VE references to TDD workflow in phase-rules.md
  - **Do**:
    1. In phase-rules.md TDD workflow section, add note that VE tasks apply identically: after V6 in Phase 3 (Quality Gates), before Phase 4 (PR Lifecycle)
    2. Reference the VE Tasks section for details
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`
  - **Done when**: TDD workflow references VE tasks in quality gates phase
  - **Verify**: `grep -A20 "TDD Phase 3" plugins/ralph-specum/references/phase-rules.md | grep -q "VE" && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE references to TDD workflow in phase rules`
  - _Requirements: FR-10_
  - _Design: Component 4_

- [x] 1.17 [VERIFY] Quality checkpoint: phase rules
  - **Do**: Verify phase-rules.md has VE section and both workflows reference it
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`
  - **Verify**: `grep -q "VE Tasks" plugins/ralph-specum/references/phase-rules.md && grep -q "VE1" plugins/ralph-specum/references/phase-rules.md && echo PASS`
  - **Done when**: VE Tasks section and VE task references present
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Quality Checkpoints Extension

- [x] 1.18 Add VE Task Format section to quality-checkpoints.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/quality-checkpoints.md`
    2. After the "VF Task for Fix Goals" section, add new section: `## VE Tasks (E2E Verification)`
    3. Include VE task format specification: VE1 (startup), VE2 (check), VE3 (cleanup) with standard Do/Verify/Done when/Commit fields
    4. Note that VE tasks use [VERIFY] tag and are delegated to qa-engineer
  - **Files**: `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Done when**: quality-checkpoints.md has VE task format section with all 3 task types
  - **Verify**: `grep -q "VE Tasks" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "VE1" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE task format to quality checkpoints`
  - _Requirements: FR-3, AC-4.2_
  - _Design: Component 5_

- [x] 1.19 Add verify-fix-reverify loop section to quality-checkpoints.md
  - **Do**:
    1. In the new VE section, add subsection "### Verify-Fix-Reverify Loop"
    2. Document the loop: qa-engineer outputs VERIFICATION_FAIL -> coordinator generates fix task via fixTaskMap -> fix task executes -> VE-check retries -> max 3 iterations -> VE-cleanup ALWAYS runs last
    3. Note: reuses existing recovery mode (maxFixTasksPerOriginal), no new loop mechanism
  - **Files**: `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Done when**: quality-checkpoints.md documents verify-fix-reverify loop with all 5 steps
  - **Verify**: `grep -q "Verify-Fix-Reverify" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "fixTaskMap\|recovery mode" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add verify-fix-reverify loop to quality checkpoints`
  - _Requirements: FR-6, AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5_
  - _Design: Component 5_

- [x] 1.20 Add VE-cleanup guarantee section to quality-checkpoints.md
  - **Do**:
    1. In the VE section, add subsection "### VE-Cleanup Guarantee"
    2. Document: VE-cleanup must run even if prior VE tasks fail; coordinator tracks VE-cleanup task index separately; if VE-check hits max retries, skip to VE-cleanup instead of stopping; VE-cleanup uses both PID-based and port-based kill
  - **Files**: `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Done when**: quality-checkpoints.md has VE-Cleanup Guarantee subsection
  - **Verify**: `grep -q "VE-Cleanup Guarantee" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "PID.*port\|port.*PID" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE-cleanup guarantee to quality checkpoints`
  - _Requirements: FR-5, AC-1.4, NFR-4_
  - _Design: Component 5_

- [x] 1.21 [VERIFY] Quality checkpoint: quality checkpoints file
  - **Do**: Verify quality-checkpoints.md has all 3 VE subsections
  - **Files**: `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Verify**: `grep -q "VE Tasks" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "Verify-Fix-Reverify" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "VE-Cleanup Guarantee" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Done when**: All 3 subsections present
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Templates: VE Tasks

- [x] 1.22 Add VE task template to POC workflow in templates/tasks.md
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. In the POC workflow section, after the V6 / VF task template (Phase 4 section, before Phase 5), add VE task templates: VE1 (startup), VE2 (check), VE3 (cleanup)
    3. Use template variables: `{{dev_cmd}}`, `{{port}}`, `{{health_endpoint}}`, `{{critical_flow_cmd}}`
    4. Include comment: `<!-- VE tasks generated from research.md Verification Tooling section -->`
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: POC workflow section in templates/tasks.md contains VE1/VE2/VE3 templates after V6
  - **Verify**: `grep -q "VE1" plugins/ralph-specum/templates/tasks.md && grep -q "VE2" plugins/ralph-specum/templates/tasks.md && grep -q "VE3" plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE templates to POC workflow in tasks template`
  - _Requirements: FR-1, AC-1.2_
  - _Design: Component 6_

- [x] 1.23 Add VE task template to TDD workflow in templates/tasks.md
  - **Do**:
    1. In templates/tasks.md TDD workflow section, after Phase 3 Quality Gates (before Phase 4 PR Lifecycle), add same VE task templates: VE1 (startup), VE2 (check), VE3 (cleanup)
    2. Include same template variables and comment as POC section
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: TDD workflow section in templates/tasks.md contains VE1/VE2/VE3 templates
  - **Verify**: `grep -c "VE1" plugins/ralph-specum/templates/tasks.md | xargs test 2 -le && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE templates to TDD workflow in tasks template`
  - _Requirements: FR-1, AC-1.2_
  - _Design: Component 6_

- [x] 1.24 [VERIFY] Quality checkpoint: templates
  - **Do**: Verify templates/tasks.md has VE templates in both workflows
  - **Files**: `plugins/ralph-specum/templates/tasks.md`
  - **Verify**: `grep -c "VE1" plugins/ralph-specum/templates/tasks.md | xargs test 2 -le && grep -c "VE-cleanup\|E2E cleanup" plugins/ralph-specum/templates/tasks.md | xargs test 2 -le && echo PASS`
  - **Done when**: At least 2 VE1 references (one per workflow) and 2 cleanup references
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### Coordinator: VE-Cleanup Guarantee

- [x] 1.25 Add VE-cleanup guarantee to coordinator-pattern.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/coordinator-pattern.md`
    2. In the "After Delegation" section, after the "no completion signal" handling, add a new subsection: "### VE Task Exception (Cleanup Guarantee)"
    3. Document: if the failed task is a VE task (description contains "E2E" and `[VERIFY]`), do not stop immediately. Instead: log VE failure in .progress.md, skip to VE-cleanup task (search forward for "E2E cleanup" in tasks.md), execute VE-cleanup, THEN output the error and stop
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: coordinator-pattern.md has VE cleanup guarantee section
  - **Verify**: `grep -q "VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "E2E cleanup" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE-cleanup guarantee to coordinator pattern`
  - _Requirements: FR-5, FR-6, AC-1.4, NFR-4_
  - _Design: Component 6_

- [x] 1.26 Add VE recovery mode note to coordinator-pattern.md
  - **Do**:
    1. In coordinator-pattern.md, in the "VERIFY Task Detection" section, add note: "VE tasks (description contains 'E2E') always have recovery mode enabled regardless of state file recoveryMode flag. VE failures are expected and recoverable."
    2. This ensures fix task generation works for VE tasks even without explicit --recovery-mode flag
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: coordinator-pattern.md notes VE tasks always have recovery mode enabled
  - **Verify**: `grep -q "recovery mode" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "VE tasks\|VE task" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `feat(ralph-specum): add VE recovery mode note to coordinator pattern`
  - _Requirements: FR-6, AC-5.1_
  - _Design: Component 6_

- [x] 1.27 [VERIFY] Quality checkpoint: coordinator pattern
  - **Do**: Verify coordinator-pattern.md has both VE additions
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Verify**: `grep -q "VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "recovery mode" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Done when**: Both VE-cleanup guarantee and recovery mode note present
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

### POC Checkpoint

- [x] 1.28 POC Checkpoint: verify all 8 files modified with VE content
  - **Do**:
    1. Verify all 8 target files contain VE-related content
    2. Verify VE task placement is after V6 and before Phase 5 in all relevant files
    3. Verify no contradictions between files (consistent naming VE1/VE2/VE3, consistent rules)
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: All 8 files modified, VE content consistent across all files
  - **Verify**: `test -f plugins/ralph-specum/references/parallel-research.md && grep -q "Verification Tooling" plugins/ralph-specum/references/parallel-research.md && grep -q "VE Task Generation" plugins/ralph-specum/agents/task-planner.md && grep -q "E2E verification" plugins/ralph-specum/commands/tasks.md && grep -q "VE Tasks" plugins/ralph-specum/references/phase-rules.md && grep -q "VE Tasks" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "VE1" plugins/ralph-specum/templates/tasks.md && grep -q "VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "Verification Tooling Discovery" plugins/ralph-specum/agents/research-analyst.md && echo POC_PASS`
  - **Commit**: `feat(ralph-specum): complete POC for autonomous E2E verification`

## Phase 2: Refactoring

Focus: Ensure consistency, fix rough prose, align naming conventions across all 8 files.

- [x] 2.1 Standardize VE naming in agent files
  - **Do**:
    1. Audit task-planner.md and research-analyst.md for consistent VE naming: VE1 (startup), VE2 (check), VE3 (cleanup)
    2. Ensure "VE" prefix used consistently (not "ve", "Ve", or "E2E verification task")
    3. Ensure "VE-cleanup" hyphenation is consistent
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: VE naming is consistent across both agent files
  - **Verify**: `grep -q "VE1" plugins/ralph-specum/agents/task-planner.md && grep -q "VE-cleanup" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `refactor(ralph-specum): standardize VE naming in agent files`
  - _Design: Components 1, 3_

- [x] 2.2 Standardize VE naming in reference files
  - **Do**:
    1. Audit phase-rules.md, quality-checkpoints.md, and coordinator-pattern.md for consistent VE naming
    2. Ensure "VE" prefix and "VE-cleanup" hyphenation match agent files
    3. Fix any inconsistencies found
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: VE naming is consistent across all 3 reference files
  - **Verify**: `for f in plugins/ralph-specum/references/phase-rules.md plugins/ralph-specum/references/quality-checkpoints.md plugins/ralph-specum/references/coordinator-pattern.md; do grep -q "VE1" "$f" || echo "MISSING VE1 in $f"; done && echo PASS`
  - **Commit**: `refactor(ralph-specum): standardize VE naming in reference files`
  - _Design: Components 4, 5, 6_

- [x] 2.3 Standardize VE naming in template and command files
  - **Do**:
    1. Audit templates/tasks.md and commands/tasks.md for consistent VE naming
    2. Ensure "VE" prefix and "VE-cleanup" hyphenation match other files
    3. Fix any inconsistencies found
  - **Files**: `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: VE naming is consistent across template and command files
  - **Verify**: `grep -q "VE1" plugins/ralph-specum/templates/tasks.md && grep -q "VE-cleanup\|E2E cleanup" plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: `refactor(ralph-specum): standardize VE naming in template and command files`
  - _Design: Components 2, 6_

- [x] 2.4 [VERIFY] Quality checkpoint: naming consistency
  - **Do**: Verify VE naming is consistent across all files after standardization
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Verify**: `grep -r "VE1" plugins/ralph-specum/ --include="*.md" -l | wc -l | xargs test 3 -le && echo PASS`
  - **Done when**: At least 3 files reference VE1 consistently
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 2.5 Ensure VE templates match task sizing rules
  - **Do**:
    1. Review VE task templates in task-planner.md and templates/tasks.md
    2. Ensure each VE task has max 4 Do steps, clear Verify command, Done when criteria
    3. Ensure VE templates follow same format as V4/V5/V6 templates
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: VE templates comply with task sizing rules and match V-series format
  - **Verify**: `grep -A10 "VE1" plugins/ralph-specum/agents/task-planner.md | grep -q "Do\|Verify\|Done when" && echo PASS`
  - **Commit**: `refactor(ralph-specum): align VE templates with task sizing rules`
  - _Design: Components 3, 6_

- [x] 2.6 Improve research-analyst detection logic prose
  - **Do**:
    1. Review verification tooling discovery section in research-analyst.md
    2. Ensure detection commands are clearly documented with expected output
    3. Ensure fallback ("No automated E2E tooling detected") is clearly documented
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: Detection logic is clear, well-formatted, and includes fallback
  - **Verify**: `grep -q "No automated E2E tooling detected\|No.*tooling detected" plugins/ralph-specum/agents/research-analyst.md && echo PASS`
  - **Commit**: `refactor(ralph-specum): improve research-analyst detection logic prose`
  - _Requirements: AC-3.4_
  - _Design: Component 1_

- [x] 2.7 [VERIFY] Quality checkpoint: detection and template quality
  - **Do**: Verify VE templates match sizing rules and detection logic has fallback
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/agents/research-analyst.md`
  - **Verify**: `grep -A10 "VE1" plugins/ralph-specum/agents/task-planner.md | grep -q "Do\|Verify" && grep -q "No.*tooling detected" plugins/ralph-specum/agents/research-analyst.md && echo PASS`
  - **Done when**: Templates comply with sizing rules, detection has fallback
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 2.8 Improve coordinator VE-cleanup skip-forward logic prose
  - **Do**:
    1. Review VE Task Exception section in coordinator-pattern.md
    2. Ensure skip-to-cleanup algorithm is unambiguous: search forward from failed task for "E2E cleanup" description, jump taskIndex to that task
    3. Ensure the "execute cleanup THEN stop with error" flow is clear
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Skip-to-cleanup logic is unambiguous and step-by-step
  - **Verify**: `grep -A10 "VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md | grep -q "skip\|jump\|search forward" && echo PASS`
  - **Commit**: `refactor(ralph-specum): clarify coordinator VE-cleanup skip logic`
  - _Requirements: AC-1.4, NFR-4_
  - _Design: Component 6_

- [x] 2.9 Add cross-references between files
  - **Do**:
    1. In phase-rules.md VE section, add: "See quality-checkpoints.md for VE format details and verify-fix-reverify loop"
    2. In quality-checkpoints.md VE section, add: "See phase-rules.md for VE placement rules"
    3. In task-planner.md VE section, add: "See phase-rules.md and quality-checkpoints.md for full VE documentation"
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: All 3 files cross-reference each other for VE documentation
  - **Verify**: `grep -q "quality-checkpoints.md" plugins/ralph-specum/references/phase-rules.md && grep -q "phase-rules.md" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `refactor(ralph-specum): add cross-references between VE documentation files`
  - _Design: Components 3, 4, 5_

- [x] 2.10 [VERIFY] Quality checkpoint: refactoring complete
  - **Do**: Verify all refactoring tasks improved consistency and cross-references
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/references/coordinator-pattern.md`, `plugins/ralph-specum/templates/tasks.md`
  - **Verify**: `grep -r "VE" plugins/ralph-specum/ --include="*.md" -l | wc -l | xargs test 6 -le && echo PASS`
  - **Done when**: At least 6 files reference VE content, cross-references in place
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Validate correctness of all VE additions via automated content checks.

- [x] 3.1 Verify research-analyst detection logic completeness
  - **Do**:
    1. Check research-analyst.md contains all 6 detection types: dev server, browser automation deps, E2E config files, port detection, health endpoints, Docker detection
    2. Check output format contains: Tool/Command/Detected From table, Project Type, Verification Strategy
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: All 6 detection types and output format elements present
  - **Verify**: `grep -q "dev.*server\|Dev Server\|dev server" plugins/ralph-specum/agents/research-analyst.md && grep -q "playwright\|Playwright\|browser" plugins/ralph-specum/agents/research-analyst.md && grep -q "Docker\|docker" plugins/ralph-specum/agents/research-analyst.md && grep -q "Project Type" plugins/ralph-specum/agents/research-analyst.md && grep -q "Verification Strategy" plugins/ralph-specum/agents/research-analyst.md && echo PASS`
  - **Commit**: `test(ralph-specum): verify research-analyst detection completeness`
  - _Requirements: AC-3.2, AC-3.3_

- [x] 3.2 Verify task-planner VE generation covers all project types
  - **Do**:
    1. Check task-planner.md project type table has 5 types: Web App, API, CLI, Mobile, Library
    2. Check each type has detection signal and VE approach columns filled
    3. Check library fallback template exists
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: All 5 project types documented with detection signals and approaches
  - **Verify**: `grep -q "Web App\|Web.*App" plugins/ralph-specum/agents/task-planner.md && grep -q "API" plugins/ralph-specum/agents/task-planner.md && grep -q "CLI" plugins/ralph-specum/agents/task-planner.md && grep -q "Mobile" plugins/ralph-specum/agents/task-planner.md && grep -q "Library" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `test(ralph-specum): verify task-planner covers all project types`
  - _Requirements: FR-9, AC-4.3_

- [x] 3.3 [VERIFY] Quality checkpoint: testing progress
  - **Do**: Run all verification commands from tasks 3.1-3.2
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/agents/task-planner.md`
  - **Verify**: `grep -q "Verification Tooling Discovery" plugins/ralph-specum/agents/research-analyst.md && grep -q "VE Task Generation" plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Done when**: Both verification checks pass
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

- [x] 3.4 Verify VE placement consistency across all files
  - **Do**:
    1. Check phase-rules.md states VE after V6, before Phase 5
    2. Check quality-checkpoints.md states VE after V6
    3. Check templates/tasks.md has VE after V6/VF in both POC and TDD sections
    4. Check task-planner.md states VE after V6, before Phase 5
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`
  - **Done when**: VE placement is consistent (after V6, before Phase 5) in all files
  - **Verify**: `grep -q "after V6\|V4.*V5.*V6.*VE\|After V6" plugins/ralph-specum/references/phase-rules.md && grep -q "after V6\|After V6\|V6.*VE" plugins/ralph-specum/references/quality-checkpoints.md && echo PASS`
  - **Commit**: `test(ralph-specum): verify VE placement consistency`
  - _Requirements: FR-1, AC-1.2_

- [x] 3.5 Verify backward compatibility (no broken existing content)
  - **Do**:
    1. Check phase-rules.md still has all original sections: Phase 1-5, VF Task, Quality Checkpoint Rules
    2. Check quality-checkpoints.md still has all original sections: Frequency Rules, [VERIFY] format, Final Verification Sequence, VF Task
    3. Check coordinator-pattern.md still has all original sections: Read State, Check Completion, Parse Current Task, Task Delegation, Verification Layers
    4. Check templates/tasks.md still has both POC and TDD workflow sections
  - **Files**: `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: All original content preserved, VE additions are additive only
  - **Verify**: `grep -q "Phase 1: Make It Work" plugins/ralph-specum/references/phase-rules.md && grep -q "Frequency Rules" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "Verification Layers" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "POC-FIRST WORKFLOW\|Phase 1: Make It Work" plugins/ralph-specum/templates/tasks.md && echo PASS`
  - **Commit**: `test(ralph-specum): verify backward compatibility preserved`
  - _Requirements: NFR-3_

- [x] 3.6 [VERIFY] Quality checkpoint: all testing complete
  - **Do**: Run comprehensive content verification across all 8 files
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Verify**: `for f in plugins/ralph-specum/references/parallel-research.md plugins/ralph-specum/agents/research-analyst.md plugins/ralph-specum/commands/tasks.md plugins/ralph-specum/agents/task-planner.md plugins/ralph-specum/references/phase-rules.md plugins/ralph-specum/references/quality-checkpoints.md plugins/ralph-specum/templates/tasks.md plugins/ralph-specum/references/coordinator-pattern.md; do test -f "$f" || echo "MISSING: $f"; done && echo ALL_FILES_EXIST`
  - **Done when**: All 8 files exist and pass content checks
  - **Commit**: `chore(ralph-specum): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

- [x] 4.1 [VERIFY] Full content verification of all 8 modified files
  - **Do**: Run comprehensive automated check across all files for VE content integrity
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Verify**: `grep -q "Verification Tooling" plugins/ralph-specum/references/parallel-research.md && grep -q "Verification Tooling Discovery" plugins/ralph-specum/agents/research-analyst.md && grep -q "E2E verification" plugins/ralph-specum/commands/tasks.md && grep -q "VE Task Generation" plugins/ralph-specum/agents/task-planner.md && grep -q "VE Tasks" plugins/ralph-specum/references/phase-rules.md && grep -q "VE Tasks" plugins/ralph-specum/references/quality-checkpoints.md && grep -q "VE1" plugins/ralph-specum/templates/tasks.md && grep -q "VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md && echo V4_PASS`
  - **Done when**: All 8 files contain expected VE content
  - **Commit**: `chore(ralph-specum): pass full content verification` (only if fixes needed)

- [x] 4.2 [VERIFY] Version bump check
  - **Do**: Check if plugin version needs bumping per project CLAUDE.md rules (any plugin file changed = version bump required)
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Verify**: `test -f plugins/ralph-specum/.claude-plugin/plugin.json && test -f .claude-plugin/marketplace.json && echo FILES_EXIST`
  - **Done when**: Version files exist and are ready for bumping (actual bump happens in commit)
  - **Commit**: None

- [x] 4.3 [VERIFY] AC checklist
  - **Do**: Programmatically verify each acceptance criterion is satisfied
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/references/coordinator-pattern.md`, `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Verify**: `grep -q "auto-enable VE\|quickMode.*VE\|quick mode.*VE\|Quick Mode" plugins/ralph-specum/agents/task-planner.md && grep -q "E2E verification" plugins/ralph-specum/commands/tasks.md && grep -q "Verification Tooling" plugins/ralph-specum/references/parallel-research.md && grep -q "VE1.*VE2.*VE3\|VE1.*startup\|E2E startup" plugins/ralph-specum/agents/task-planner.md && grep -q "VE-cleanup\|VE-Cleanup\|E2E cleanup" plugins/ralph-specum/agents/task-planner.md && grep -q "VE-Cleanup Guarantee\|VE Task Exception" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "Verify-Fix-Reverify\|verify-fix-reverify" plugins/ralph-specum/references/quality-checkpoints.md && echo V6_PASS`
  - **Done when**: All critical ACs confirmed met: AC-1.1 (quick mode auto-enable), AC-2.1 (interview question), AC-3.1 (research topic), AC-4.2 (VE format), AC-1.4 (cleanup guarantee), AC-5.1 (verify-fix-reverify)
  - **Commit**: None

## Phase 5: PR Lifecycle (Continuous Validation)

> Autonomous Loop: This phase continues until ALL completion criteria met.

- [x] 5.1 Bump plugin version
  - **Do**:
    1. Read current version from `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Bump minor version (new feature)
    3. Update same version in `.claude-plugin/marketplace.json` for the ralph-specum entry
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files have matching bumped version
  - **Verify**: `grep -q '"version"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"version"' .claude-plugin/marketplace.json && echo PASS`
  - **Commit**: `chore(ralph-specum): bump version for VE tasks feature`

- [x] 5.2 Create pull request
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat(ralph-specum): add autonomous E2E verification (VE tasks)" --body "$(cat <<'EOF'
## Summary
- Add VE (Verify E2E) tasks to task planning system that spin up real infrastructure and test built features end-to-end
- VE tasks auto-generated in quick mode, prompted in normal mode
- Verify-fix-reverify loop reuses existing recovery mode
- VE-cleanup guarantee prevents orphaned processes

## Changes
- 8 files modified: task-planner, phase-rules, quality-checkpoints, coordinator-pattern, tasks command, tasks template, parallel-research, research-analyst

## Test Plan
- [x] All 8 files contain VE content (automated grep checks)
- [x] VE placement consistent (after V6, before Phase 5)
- [x] Backward compatibility preserved (original content intact)
- [ ] CI checks pass
EOF
)"`
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Verify**: `gh pr view --json url -q .url 2>/dev/null`
  - **Done when**: PR created and URL returned
  - **Commit**: None

- [x] 5.3 Monitor CI and fix failures
  - **Do**:
    1. Check status: `gh pr checks`
    2. If failures: read logs, fix issues, push
    3. Repeat until all green
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix(ralph-specum): address CI failures` (as needed)

- [x] 5.4 Final validation
  - **Do**: Verify ALL completion criteria:
    1. All Phase 1-4 tasks complete
    2. CI checks all green
    3. All 8 files contain VE content
    4. No regressions in existing functionality
  - **Files**: `plugins/ralph-specum/references/parallel-research.md`, `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/references/phase-rules.md`, `plugins/ralph-specum/references/quality-checkpoints.md`, `plugins/ralph-specum/templates/tasks.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Verify**: `gh pr checks` all green
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: Rough prose accepted in Phase 1; refined in Phase 2 refactoring
- **Production TODOs**: None -- all additions are markdown documentation, no code to refactor
- **Version bump**: Required per CLAUDE.md rules since plugin files are modified. Must bump `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- **No tests needed**: This is a markdown-only change to a Claude Code plugin. Verification is content-based (grep/test -f)

## Dependencies

```text
Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality) -> Phase 5 (PR Lifecycle)
```

Within Phase 1:
- 1.1-1.2: Research phase files (independent)
- 1.4-1.5: Tasks command (depends on understanding from 1.1-1.2)
- 1.7-1.12: Task planner (core work, depends on understanding all prior)
- 1.14-1.16: Phase rules (depends on 1.7-1.9 for VE template reference)
- 1.18-1.20: Quality checkpoints (depends on 1.7-1.9)
- 1.22-1.23: Templates (depends on 1.7-1.9)
- 1.25-1.26: Coordinator (depends on 1.18-1.20 for cleanup guarantee reference)
- 1.28: POC checkpoint (depends on all above)
